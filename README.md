# Claude Setup Kit

Drop-in `.claude/` config with Codex overseer hooks, Pyrefly type checking, Prettier auto-format, an interface-design skill, and integrations for CodeRabbit, Greptile, and Blacksmith.

## Quick Start

Give this link to Claude Code:

```
https://github.com/42nights/claude-setup-kit
```

Then say:

> set up my claude using this repo

Claude will read the docs and install everything.

## Manual Install

```bash
git clone https://github.com/42nights/claude-setup-kit.git /tmp/claude-setup-kit
cp -r /tmp/claude-setup-kit/.claude ~/
chmod +x ~/.claude/hooks/*.sh
```

Then install the CLI tools:

```bash
npm install -g @openai/codex prettier
pip3 install pyrefly browser-harness
```

Set your OpenAI key for the Codex overseer:

```bash
echo 'export OPENAI_API_KEY=sk-...' >> ~/.zshrc
```

## What's Inside

### Hooks (`~/.claude/hooks/`)

| Hook                   | Event                          | What it does                                                                           |
| ---------------------- | ------------------------------ | -------------------------------------------------------------------------------------- |
| `codex-review-diff.sh` | Stop, PostToolUse (Edit/Write) | Sends uncommitted diff to OpenAI Codex for independent review. Blocks if issues found. |
| `codex-review-plan.sh` | PreToolUse (ExitPlanMode)      | Reviews plans before approval — catches missing edge cases, security gaps.             |
| Pyrefly check          | Stop                           | Type-checks Python files. Only runs if `.py` files exist.                              |
| Prettier               | PostToolUse (Edit/Write)       | Auto-formats every file Claude edits.                                                  |

The Codex hooks implement **structural separation** — a different model (OpenAI) reviews Claude's output in a clean session with no shared context. This catches issues that self-review cannot.

### Skills (`~/.claude/skills/`)

**interface-design** — Build dashboards, apps, and tools with craft. Includes spacing grids, depth systems, typography principles, and a critique/audit loop.

### Commands (`~/.claude/commands/`)

| Command     | Purpose                                                       |
| ----------- | ------------------------------------------------------------- |
| `/init`     | Start a UI build — establishes design direction before coding |
| `/critique` | Self-review for craft gaps, then rebuild                      |
| `/audit`    | Check code against your design system                         |
| `/extract`  | Pull patterns from existing code into a system                |
| `/status`   | Show current design system state                              |

### Plugins & Connectors

**Plugins** (marketplace): Vercel, Railway, Paper design system

**Claude.ai connectors** (MCP): Linear, Granola, Notion, Google Drive

## Docs

- **[instructions.md](instructions.md)** — Step-by-step setup for every component
- **[flow.md](flow.md)** — How everything chains together (review loops, Granola→Linear pipeline, design flow)
- **[external.md](external.md)** — CLI/manual setup for CodeRabbit, Greptile, Blacksmith, and other 3rd-party tools

## Requirements

- Node.js 20+
- Python 3.9+
- [OpenAI Codex CLI](https://github.com/openai/codex) (`npm i -g @openai/codex`)
- `OPENAI_API_KEY` environment variable
