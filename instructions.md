# Setup Instructions

Everything in `.claude/` goes into your home directory at `~/.claude/`. The hooks, skills, commands, and settings work globally across all projects.

## Prerequisites

```bash
# Node.js (for Prettier, Codex)
node --version  # v20+

# Python 3 (for Pyrefly)
python3 --version

# GitHub CLI
gh --version
```

## 1. Install the .claude folder

```bash
cp -r .claude ~/
chmod +x ~/.claude/hooks/*.sh
```

## 2. Install CLI tools

### OpenAI Codex CLI (powers the review hooks)

```bash
npm install -g @openai/codex
export OPENAI_API_KEY=sk-...  # add to ~/.zshrc
```

Codex is used as a structurally separate reviewer — a different model/session reviews Claude's output to prevent self-checking bias.

### Pyrefly (Python type checker)

```bash
pip3 install pyrefly
```

Only runs on projects with `.py` files. The hook auto-detects.

### Prettier (auto-formatter)

```bash
npm install -g prettier
```

Runs automatically on every file Claude edits or writes. No config needed — Prettier uses its defaults or your project's `.prettierrc`.

### browser-harness (browser automation via CDP)

```bash
# Follow install instructions at:
# https://github.com/browser-use/browser-harness
pip install browser-harness
```

Used for automating 3rd-party service sign-ups (CodeRabbit, Greptile, etc.) by controlling your running Chrome via CDP. The global CLAUDE.md references the SKILL.md from this repo.

## 3. Claude.ai Connectors (MCP Servers)

These are configured in Claude.ai settings, not locally. Go to **claude.ai > Settings > Connected Apps** or the Claude Code connector settings.

### Linear

Enables: create/read issues, projects, comments, milestones, documents, labels, cycles.

**Setup:** Connect via OAuth in Claude.ai settings. Select your Linear workspace.

**Key tools:** `get_issue`, `save_issue`, `list_issues`, `get_project`, `save_project`, `list_projects`, `save_comment`, `get_document`

### Granola

Enables: query meeting transcripts, get meeting details, list folders.

**Setup:** Connect via OAuth in Claude.ai settings.

**Key tools:** `query_granola_meetings`, `get_meeting_transcript`, `list_meetings`, `get_account_info`

### Notion

Enables: read/write Notion pages and databases.

**Setup:** Connect via OAuth in Claude.ai settings. Authorize access to your workspace.

### Google Drive

Enables: read files from Google Drive.

**Setup:** Connect via OAuth in Claude.ai settings.

## 4. Plugins (Marketplace)

Configured in `settings.json` under `enabledPlugins` and `extraKnownMarketplaces`.

### Vercel

```json
"enabledPlugins": {
  "vercel@claude-plugins-official": true
}
```

Provides deployment management, AI architecture, and performance optimization agents.

### Railway

```json
"extraKnownMarketplaces": {
  "railway-skills": {
    "source": { "source": "github", "repo": "railwayapp/railway-skills" }
  }
}
```

Provides project/service/deployment management, environment variables, logs, metrics.

### Paper (Design System)

```json
"extraKnownMarketplaces": {
  "paper": {
    "source": { "source": "github", "repo": "paper-design/agent-plugins" }
  }
}
```

Design system tokens and components.

## 5. Skills

### interface-design

Located at `.claude/skills/interface-design/`. A comprehensive UI design skill for building dashboards, apps, and tools with craft and consistency.

Includes:

- `SKILL.md` — core principles, spacing grids, depth systems, typography
- `references/principles.md` — design philosophy
- `references/example.md` — worked examples
- `references/validation.md` — quality checks
- `references/critique.md` — self-review patterns

### Custom Commands (slash commands)

Located in `.claude/commands/`:

| Command     | Purpose                                                          |
| ----------- | ---------------------------------------------------------------- |
| `/init`     | Build UI with craft — establishes design direction before coding |
| `/critique` | Review your build for craft gaps, then rebuild what defaulted    |
| `/audit`    | Check code against your design system for violations             |
| `/extract`  | Pull design patterns from existing code into a system.md         |
| `/status`   | Show current design system state                                 |

## 6. Settings Explained

Key settings in `settings.json`:

```
defaultMode: "auto"          — auto-approve safe operations
effortLevel: "xhigh"         — maximum reasoning effort
agentPushNotifEnabled: true  — get push notifications from background agents
skipAutoPermissionPrompt: true
```
