# Setup Instructions

Everything in `.claude/` goes into your home directory at `~/.claude/`. The hooks, skills, commands, and settings work globally across all projects.

## Prerequisites

```bash
node --version    # v20+ (for Prettier, Codex)
python3 --version # (for Ruff)
gh --version      # GitHub CLI
```

## 1. Install the .claude folder

```bash
cp -r .claude ~/
chmod +x ~/.claude/hooks/*.sh

# Add environment defaults to your shell profile
echo 'export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1' >> ~/.zshrc
```

## 2. Install CLI tools

```bash
npm install -g @openai/codex prettier oxlint
pip3 install ruff browser-harness
```

Set your OpenAI key for the Codex review hooks:

```bash
echo 'export OPENAI_API_KEY=sk-...' >> ~/.zshrc
```

For details on each tool (what it does, how it connects, gotchas), see [external.md](external.md).

## 3. Claude.ai Connectors (MCP Servers)

Configured in **claude.ai > Settings > Connected Apps**, not locally. One-time OAuth setup per service:

| Connector    | What it enables                                                   |
| ------------ | ----------------------------------------------------------------- |
| Linear       | Issues, projects, comments, milestones, documents, labels, cycles |
| Granola      | Meeting transcripts, details, folders                             |
| Notion       | Read/write pages and databases                                    |
| Google Drive | Read files                                                        |
| Gmail        | Search, read, send emails (useful for GitHub sudo verification)   |

## 4. Plugins

All plugins are pre-configured in [`.claude/settings.json`](.claude/settings.json) under `enabledPlugins` and `extraKnownMarketplaces`. No manual setup needed — they activate on first use.

See the plugin table in [`.claude/CLAUDE.md`](.claude/CLAUDE.md#available-skills) for the full list with descriptions.

## 5. Skills

All local skills live in `.claude/skills/`. The full registry with paths and descriptions is in [`.claude/CLAUDE.md`](.claude/CLAUDE.md#available-skills) — Claude reads that table directly instead of scanning the file tree.

### Custom Commands (slash commands)

Located in `.claude/commands/`:

| Command     | Purpose                                                          |
| ----------- | ---------------------------------------------------------------- |
| `/init`     | Build UI with craft — establishes design direction before coding |
| `/critique` | Review your build for craft gaps, then rebuild what defaulted    |
| `/audit`    | Check code against your design system for violations             |
| `/extract`  | Pull design patterns from existing code into a system.md         |
| `/status`   | Show current design system state                                 |

## 6. Settings

All settings are in [`.claude/settings.json`](.claude/settings.json). Key defaults this kit ships:

```
defaultMode: "auto"              — auto-approve safe operations
effortLevel: "xhigh"            — maximum reasoning effort
alwaysThinkingEnabled: true     — extended thinking on by default
showThinkingSummaries: true     — show full thinking summaries
tui: "fullscreen"               — flicker-free rendering, mouse support
agentPushNotifEnabled: true     — push notifications from background agents
```

### Research Preview / Experimental Options

| Setting                      | Type   | Kit Default    | What it does                                             |
| ---------------------------- | ------ | -------------- | -------------------------------------------------------- |
| `alwaysThinkingEnabled`      | bool   | **`true`**     | Extended thinking on by default                          |
| `showThinkingSummaries`      | bool   | `true`         | Show full thinking instead of collapsed blocks           |
| `effortLevel`                | enum   | `"xhigh"`      | Reasoning depth: `low`, `medium`, `high`, `xhigh`, `max` |
| `tui`                        | enum   | `"fullscreen"` | Alt-screen rendering, no flicker, mouse support          |
| `fastMode`                   | bool   | `false`        | 2.5x faster Opus at higher cost. Toggle with `/fast`     |
| `skillListingBudgetFraction` | number | `0.01`         | Fraction of context for skill descriptions (0-1)         |
| `maxSkillDescriptionChars`   | number | `1536`         | Max chars per skill in context                           |
| `worktree.bgIsolation`       | enum   | `"worktree"`   | Isolation for background agent edits                     |
| `disableRemoteControl`       | bool   | `false`        | Disable remote control feature                           |

**Environment variables (set in `~/.zshrc`):**

| Variable                                | Effect                                                           |
| --------------------------------------- | ---------------------------------------------------------------- |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | Fixed thinking budget instead of adaptive (**kit default: `1`**) |
| `CLAUDE_CODE_DISABLE_THINKING`          | Force thinking off                                               |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT`        | Remove 1M context models from picker                             |
| `CLAUDE_CODE_DISABLE_FAST_MODE`         | Disable fast mode entirely                                       |
| `CLAUDE_CODE_NO_FLICKER`                | Enable fullscreen rendering (legacy)                             |
| `CLAUDE_CODE_DISABLE_MOUSE`             | Disable mouse capture in fullscreen                              |
| `CLAUDE_CODE_SCROLL_SPEED`              | Mouse wheel speed multiplier (1-20)                              |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY`       | Disable auto memory                                              |
| `CLAUDE_CODE_ENABLE_AWAY_SUMMARY`       | Show session recap when returning                                |
| `CLAUDE_CODE_EFFORT_LEVEL`              | Set effort level via env                                         |
| `DISABLE_AUTOUPDATER`                   | Disable auto-updates                                             |

## 7. Hooks

All hooks are configured in `settings.json`. See [hooks.md](hooks.md) for detailed documentation, dedup logic, and how each hook connects to the workflow.

## 8. Autonomous & Long-Running Modes

### Goal Mode

Set a completion condition and Claude keeps working automatically until it's met. A small fast model (Haiku) evaluates after each turn.

```bash
/goal all tests pass and lint is clean     # Set a goal
/goal                                       # Check status
/goal clear                                 # Remove goal
```

- Per-session only, no persistent setting
- Requires Claude Code v2.1.139+
- Best for tasks with verifiable end states: "tests pass", "build succeeds", "migration complete"

### Long-Running Sessions

- **Remote sessions (Desktop/Web):** Run on Anthropic's cloud — continues if you close the app.
- **Background agents:** Launch with `run_in_background: true`. You get notified on completion.
- **Scheduled routines:** Use `/schedule` or the routines skill for cron-based recurring tasks.
- **Remote Control:** Steer a local session from another device via `--remote-control`.
