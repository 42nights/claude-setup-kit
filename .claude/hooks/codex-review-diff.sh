#!/usr/bin/env bash
# Stop hook — at the end of every turn where Claude touched code,
# run codex review against the uncommitted diff and surface findings
# back to Claude (via JSON decision=block) so they get addressed
# before Claude actually hands control back.
#
# Cadence: fires on Stop event (= when Claude is about to give the
# user back the floor). Skips when there are no code changes.

set -uo pipefail

# Don't run inside the codex CLI's own subprocess (avoid recursion if
# codex ever spawns a Claude Code child).
if [[ -n "${CODEX_SESSION_ID:-}" ]]; then exit 0; fi

# Read the hook payload (Claude Code passes JSON on stdin). We don't
# parse it for now; we use cwd-based git state.
payload=$(cat || true)

# Are we in a git repo?
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$repo_root" ]]; then exit 0; fi

# Any uncommitted changes?
if git -C "$repo_root" diff --quiet HEAD -- 2>/dev/null && \
   git -C "$repo_root" diff --quiet --cached HEAD -- 2>/dev/null && \
   [[ -z "$(git -C "$repo_root" ls-files --others --exclude-standard)" ]]; then
  exit 0  # nothing to review
fi

# Dedupe: hash the current diff. If we've already reviewed this exact
# diff in the last 30 minutes, skip. Prevents infinite loops where
# codex finding → Claude addresses → Stop → codex re-reviews → same
# finding → block forever.
dedupe_dir="${TMPDIR:-/tmp}/codex-review-diff"
mkdir -p "$dedupe_dir"
diff_hash=$(git -C "$repo_root" diff HEAD 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
marker="$dedupe_dir/${diff_hash:0:16}"
if [[ -f "$marker" ]]; then
  # Marker exists — already reviewed this diff. Check age.
  age_sec=$(( $(date +%s) - $(stat -f %m "$marker" 2>/dev/null || stat -c %Y "$marker") ))
  if (( age_sec < 1800 )); then
    exit 0
  fi
fi
touch "$marker"

# Look for /rules or .rules folder by walking up from repo root.
rules_dir=""
if [[ -d "$repo_root/rules" ]]; then rules_dir="$repo_root/rules"; fi
if [[ -z "$rules_dir" && -d "$repo_root/.rules" ]]; then rules_dir="$repo_root/.rules"; fi

extra_context=""
if [[ -n "$rules_dir" ]]; then
  extra_context=$(find "$rules_dir" -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null \
    | xargs -0 -I{} sh -c 'echo "=== {} ==="; cat "{}"; echo' 2>/dev/null \
    | head -c 32768 || true)
fi

if ! command -v codex >/dev/null 2>&1; then exit 0; fi

prompt="Review the uncommitted diff at $repo_root. Find real bugs, security issues, missing edge cases, and correctness gaps. Under 300 words. Cite file paths and line numbers. Skip style nits."
if [[ -n "$extra_context" ]]; then
  prompt+=$'\n\nProject rules to apply during review:\n\n'"$extra_context"
fi

# Run codex review of the uncommitted diff. Use `codex review --uncommitted`
# which is the dedicated path for diff review.
cd "$repo_root"
review_output=$(codex review --uncommitted --title "Stop hook auto-review" 2>&1 \
  | grep -v "^exec\b" \
  | grep -v "^\s*$" \
  | tail -100 || true)

if [[ -z "$review_output" ]]; then exit 0; fi

# If codex found no actionable issues, let Stop proceed.
if echo "$review_output" | grep -qiE "no.*discrete.*actionable|no.*issues found|clean|no.*flaws"; then
  exit 0
fi

# Otherwise block Stop with the findings so Claude addresses them.
# Output JSON on stdout per Claude Code hook protocol.
escaped=$(printf '%s' "$review_output" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" 2>/dev/null || printf '%s' "$review_output")
cat <<EOF
{"decision": "block", "reason": "Codex auto-review found issues in the uncommitted diff. Address them, then re-stop. (Set marker $marker exists to bypass for 30 min.)\\n\\n$escaped"}
EOF
