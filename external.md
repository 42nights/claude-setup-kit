# External Services — Setup & Integration

Third-party services that plug into the Claude Code workflow. Each section covers what it does, how to set it up, and how it connects to the rest of the stack.

## Code Review

### CodeRabbit

AI code review that posts line-by-line comments on PRs with one-click fixes.

**What it does:** Reviews every PR automatically — catches bugs, security issues, missing edge cases. Generates sequence diagrams, PR summaries, and a walkthrough of changes.

**Setup (CLI):**

```bash
# Install the GitHub App on your org
open "https://github.com/apps/coderabbitai/installations/select_target"
# Select your org → All repositories → Install & Authorize
# GitHub will ask for sudo confirmation (passkey or email code)
```

**Setup (config):**

Create `.coderabbit.yaml` in your repo root:

```yaml
language: en-US

reviews:
  profile: concise
  request_changes_workflow: false
  high_level_summary: true
  poem: false
  collapse_walkthrough: true
  path_instructions:
    - path: "src/**"
      instructions: "Review strictly for bugs, security, and correctness."
    - path: "docs/**"
      instructions: "Light review — check for accuracy only."
    - path: "tests/**"
      instructions: "Check test coverage and edge cases."

chat:
  auto_reply: true
```

**Verify:**

```bash
gh api /orgs/<your-org>/installations \
  --jq '.installations[] | select(.app_slug == "coderabbitai") | .id'
```

**Connects to:** Every PR triggers a review. Works alongside Codex overseer hooks — CodeRabbit catches different things (it sees the full PR, not just the diff since last edit).

---

### Greptile

Codebase-aware AI review. Indexes your full repo so reviews understand architecture, not just syntax.

**What it does:** Understands how your code fits together. Catches issues like "this function is called from 3 places and your change breaks 2 of them." Also provides a Genius API ($0.45/query) for programmatic codebase questions.

**Setup (CLI):**

```bash
# 1. Sign up
open "https://app.greptile.com/signup"
# Sign in with GitHub → Create org → Select GitHub as provider → Connect

# 2. Install the GitHub App on your org
open "https://github.com/apps/greptile-apps/installations/select_target"
# Select your org → All repositories → Install

# 3. Back in Greptile, select your org → Enable All repos → Next
```

**Verify:**

```bash
gh api /orgs/<your-org>/installations \
  --jq '.installations[] | select(.app_slug == "greptile-apps") | .id'
```

**Gotchas:**

- Initial indexing takes 1-2 hours for large repos
- No public API for team provisioning
- Genius API key is in developer settings (not the main dashboard)

**Connects to:** Reviews PRs alongside CodeRabbit. Greptile catches architecture-level issues that line-by-line reviewers miss.

---

### OpenAI Codex CLI (Overseer)

Structural code review from a different model. Used as the "second pair of eyes" in hooks.

**What it does:** Reviews uncommitted diffs and plans from a completely separate model/session. Catches issues Claude might miss because it's not reviewing its own work.

**Setup:**

```bash
npm install -g @openai/codex
export OPENAI_API_KEY=sk-...  # add to ~/.zshrc
```

**Verify:**

```bash
codex --version
```

**Connects to:** Powers `codex-review-diff.sh` (Stop + PostToolUse hooks) and `codex-review-plan.sh` (PreToolUse on ExitPlanMode). This is the structural separation pattern — a different model reviewing the primary agent's output.

---

## CI / Runners

### Blacksmith

Managed GitHub Actions runners. 2x faster builds, 4x faster cache, 60% cheaper than GitHub-hosted runners.

**What it does:** Drop-in replacement for `ubuntu-latest`. One-line YAML change.

**Setup (CLI):**

```bash
# 1. Sign up and install the GitHub App
open "https://app.blacksmith.sh"
# Sign in with GitHub → Install on your org

# 2. Patch your workflow files
# Replace:
#   runs-on: ubuntu-latest
# With:
#   runs-on: blacksmith-2vcpu-ubuntu-2404
```

**Patch all workflows at once:**

```bash
find .github/workflows -name '*.yml' -o -name '*.yaml' | while read f; do
  sed -i '' 's/runs-on: ubuntu-latest/runs-on: blacksmith-2vcpu-ubuntu-2404/g' "$f"
  sed -i '' 's/runs-on: ubuntu-22.04/runs-on: blacksmith-2vcpu-ubuntu-2404/g' "$f"
  sed -i '' 's/runs-on: ubuntu-24.04/runs-on: blacksmith-2vcpu-ubuntu-2404/g' "$f"
done
```

**Verify:**

```bash
# Check the Blacksmith dashboard
open "https://app.blacksmith.sh/<your-org>/runs/workflows"
```

**Gotchas:**

- GitHub Actions only (no GitLab/Jenkins)
- Needs org admin for GitHub App install
- Runner names: `blacksmith-2vcpu-ubuntu-2404`, `blacksmith-4vcpu-ubuntu-2404`, etc.

---

## Type Checking

### Pyrefly

Python type checker. Runs automatically on Stop if the project has `.py` files.

**Setup:**

```bash
pip3 install pyrefly
```

The hook in `settings.json` auto-detects Python projects:

```json
{
  "type": "command",
  "command": "ls *.py **/*.py 2>/dev/null | head -1 | grep -q . && ($HOME/Library/Python/3.9/bin/pyrefly check >&2 || exit 2) || true",
  "timeout": 30
}
```

Adjust the path if your `pyrefly` binary is elsewhere (`which pyrefly` to find it).

**Reference:** https://pyrefly.org/blog/pyrefly-agentic-loop/

---

## Formatting

### Prettier

Auto-formats every file Claude edits or writes.

**Setup:**

```bash
npm install -g prettier
```

The hook runs via `npx prettier --write` on PostToolUse for Edit and Write events. Uses your project's `.prettierrc` if present, otherwise Prettier defaults.

No configuration needed — it just works.

---

## Browser Automation

### browser-harness

Direct browser control via Chrome DevTools Protocol. Used for automating 3rd-party service provisioning.

**What it does:** Controls your running Chrome instance to navigate sign-up flows, OAuth consents, and admin dashboards. Uses coordinate clicks and screenshots — not brittle CSS selectors.

**Setup:**

```bash
pip install browser-harness
```

**Usage pattern:**

```bash
browser-harness <<'PY'
new_tab("https://example.com/signup")
wait_for_load()
capture_screenshot()  # see the page
click_at_xy(400, 300)  # click what you see
PY
```

**Key principles:**

- Screenshots first, then coordinate clicks
- `new_tab()` for first navigation (never `goto_url` — it clobbers the user's active tab)
- Auth walls → stop and ask the user, never type credentials
- After every action, re-screenshot to verify

**Connects to:** Service provisioning scripts in `.claude/skills/ai-dev-workflow/` use browser-harness for CodeRabbit, Greptile, and Blacksmith sign-up automation.

---

## Notification / Monitoring

### Superset

Push notifications for agent activity. Fires on session start/end, tool use, permission requests, and errors.

**Setup:** Requires `SUPERSET_HOME_DIR` environment variable pointing to the Superset installation with a `hooks/notify.sh` script.

**What it monitors:**

- Session start/end
- Every tool use (PostToolUse)
- Tool failures (PostToolUseFailure)
- Permission requests
- User prompt submissions

---

## Quick Reference

| Service         | Install Command               | Verify Command                              |
| --------------- | ----------------------------- | ------------------------------------------- |
| Codex CLI       | `npm i -g @openai/codex`      | `codex --version`                           |
| Pyrefly         | `pip3 install pyrefly`        | `pyrefly --version`                         |
| Prettier        | `npm i -g prettier`           | `npx prettier --version`                    |
| browser-harness | `pip install browser-harness` | `which browser-harness`                     |
| CodeRabbit      | GitHub App install            | `gh api /orgs/ORG/installations --jq '...'` |
| Greptile        | GitHub App install            | `gh api /orgs/ORG/installations --jq '...'` |
| Blacksmith      | GitHub App install            | Open `app.blacksmith.sh/ORG`                |
