# Flow — How Everything Works Together

This documents how each piece connects and the actual workflows they enable.

## The Core Loop: Write → Review → Fix → Ship

```
You prompt Claude
    ↓
Claude writes code (Edit/Write)
    ↓
PostToolUse fires:
    1. Prettier auto-formats the file
    2. Codex reviews the uncommitted diff
    ↓
Claude stops (Stop event)
    ↓
Stop hooks fire:
    1. Codex reviews full uncommitted diff
    2. Pyrefly type-checks (Python projects only)
    ↓
If issues found → Claude is blocked, fixes them, re-stops
If clean → Claude responds to you
```

The dedup guard (diff hash + 30-min marker) prevents infinite loops. If Claude produces the same diff twice, the review is skipped.

## Plan Review Flow

```
Claude creates a plan (ExitPlanMode)
    ↓
PreToolUse hook fires:
    codex-review-plan.sh sends the plan to Codex
    ↓
Codex independently reviews for:
    - Missing edge cases
    - Security gaps
    - Race conditions
    - Verification holes
    ↓
Findings injected into Claude's context
    ↓
Claude folds findings into the plan before you approve
```

This is structural separation — a different model (OpenAI) reviews the plan so Claude can't self-approve. The reviewer has no shared context with the author.

## Meeting → Issue Pipeline (Granola → Linear)

```
After a meeting:
    "what did we decide in yesterday's standup about the auth migration?"
    ↓
Claude queries Granola:
    query_granola_meetings("auth migration")
    get_meeting_transcript(meeting_id)
    ↓
Extracts action items, decisions, blockers
    ↓
Claude creates Linear issues:
    save_issue({title, description, assignee, project, priority})
    ↓
Links back to meeting for context
```

Real usage: after a client call, ask Claude to "create Linear issues from today's call with [client name]" — it pulls the transcript from Granola, extracts commitments, and files them as issues with the right project/priority.

## Design → Code Flow (interface-design skill)

```
/init
    ↓
Claude reads SKILL.md (craft principles, spacing grids, depth systems)
    ↓
Asks: who is the user, what must they accomplish, what should it feel like?
    ↓
Proposes: palette, depth, surfaces, typography, spacing
    ↓
You approve direction
    ↓
Claude builds UI with established system
    ↓
/critique — Claude self-reviews for craft gaps, rebuilds weak areas
    ↓
/audit — checks code against design system for violations
    ↓
Offers to save patterns to .interface-design/system.md
```

The system persists per-project. Future `/init` calls reuse the established system.

## Service Provisioning Flow (browser-harness)

```
"set up CodeRabbit for 42nights org"
    ↓
Claude uses browser-harness to control your Chrome:
    1. Opens service sign-up page
    2. Clicks "Sign in with GitHub"
    3. Navigates OAuth consent
    4. Selects org, enables repos
    5. Extracts API keys from settings
    ↓
Stores credentials:
    ~/.42nights/credentials.json (chmod 600)
    OS keychain via keyring (if available)
    ↓
GitHub sudo prompts:
    → Sends code via email
    → Opens Gmail in new tab
    → Reads verification code from email
    → Enters code and submits
```

This works for CodeRabbit, Greptile, Blacksmith, and any service with GitHub OAuth. The browser-harness skill uses coordinate clicks and screenshots — no brittle CSS selectors.

## PR Workflow

```
Claude finishes work
    ↓
"push and make a pr"
    ↓
Claude:
    1. git add specific files (never git add -A)
    2. Commits with descriptive message
    3. Pushes branch
    4. gh pr create with summary + test plan
    ↓
CI runs:
    - verify-services.yml checks service installations
    - Any repo-specific CI
    ↓
CodeRabbit auto-reviews the PR (line-by-line comments)
Greptile adds architecture-aware context to review
```

## Notification Flow (Superset)

Superset hooks fire on nearly every event (SessionStart, Stop, PostToolUse, PermissionRequest, etc.) to send push notifications so you can monitor agent activity from your phone.

## Plugin Agents

### Vercel

Three specialized agents available:

- `vercel:ai-architect` — AI SDK patterns, providers, agents, MCP
- `vercel:deployment-expert` — CI/CD, preview URLs, rollbacks, domains
- `vercel:performance-optimizer` — Core Web Vitals, caching, bundle size

### Railway

Full infrastructure management:

- Create/manage projects, services, environments
- Deploy, view logs, check metrics
- Set environment variables, generate domains

## Key Principle: Structural Separation

The overseer pattern (Codex reviewing Claude's work) only works because:

1. **Different model** — OpenAI, not Anthropic
2. **Different session** — no shared context, clean eval
3. **Different process** — subprocess, not prompt injection

Prompting alone cannot replicate this. The reviewer must be structurally unable to share the author's context.
