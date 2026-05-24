#!/usr/bin/env bash
# PreToolUse hook for ExitPlanMode — runs codex review against the
# plan file before Claude asks the user to approve it. Surfaces real
# bugs/edge cases so plans don't ship under-specified.
#
# Reads Claude Code's hook payload (JSON) from stdin and writes a
# review summary to stdout. The output appears in Claude's transcript
# as the hook's result, so Claude can fold findings in before the user
# accepts.

set -euo pipefail

# Read the hook payload from stdin (JSON). Pipe-safe even if empty.
payload=$(cat || true)

# Try to extract the plan file path from the payload. The system
# prompt hardcodes the canonical location, so a fallback works fine.
plan_file=""
if command -v jq >/dev/null 2>&1 && [[ -n "$payload" ]]; then
  plan_file=$(printf '%s' "$payload" | jq -r '.tool_input.plan_file_path // .tool_input.plan // empty' 2>/dev/null || true)
fi
if [[ -z "$plan_file" ]]; then
  plan_file=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1 || true)
fi
if [[ ! -f "$plan_file" ]]; then
  echo "[codex-review] no plan file found, skipping review"
  exit 0
fi

# Look for /rules or .rules folder by walking up from CWD (cap 5 levels
# so we don't escape past the repo root).
rules_dir=""
cur="$PWD"
for _ in 1 2 3 4 5; do
  if [[ -d "$cur/rules" ]]; then rules_dir="$cur/rules"; break; fi
  if [[ -d "$cur/.rules" ]]; then rules_dir="$cur/.rules"; break; fi
  if [[ "$cur" == "/" || "$cur" == "$HOME" ]]; then break; fi
  cur=$(dirname "$cur")
done

extra_context=""
if [[ -n "$rules_dir" ]]; then
  # Inline rules content, capped at 32KB so codex's context doesn't blow up.
  extra_context=$(find "$rules_dir" -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null \
    | xargs -0 -I{} sh -c 'echo "=== {} ==="; cat "{}"; echo' 2>/dev/null \
    | head -c 32768 || true)
fi

# Build the codex prompt.
prompt="Independently review the plan at $plan_file."
prompt+=$'\n\nFind real flaws, do not agree just to agree. Under 400 words. Focus on bugs, missing edge cases, security/correctness gaps, race conditions, and verification holes. Cite file paths and line numbers where applicable.'
if [[ -n "$extra_context" ]]; then
  prompt+=$'\n\nProject rules to apply during review:\n\n'"$extra_context"
fi

# Run codex. --skip-git-repo-check because the plan file lives in
# ~/.claude/plans/, outside any repo. --sandbox read-only so codex
# can't accidentally write anything.
if ! command -v codex >/dev/null 2>&1; then
  echo "[codex-review] codex CLI not installed, skipping"
  exit 0
fi

echo "[codex-review] reviewing $plan_file..."
codex exec --skip-git-repo-check --sandbox read-only "$prompt" 2>&1 | tail -120 || {
  echo "[codex-review] codex returned non-zero; continuing without blocking"
  exit 0
}
