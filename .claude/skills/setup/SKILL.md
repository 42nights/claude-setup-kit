---
name: setup
description: Guide users through full Claude Code environment setup — CLI tools, connectors, plugins, and rules configuration.
---

# Setup

Use when a user says "set up my claude", "install the kit", or links to the claude-setup-kit repo.

## Flow

Walk the user through each step in order. Check what's already done and skip it.

### 1. Install the .claude folder

```bash
git clone https://github.com/42nights/claude-setup-kit.git /tmp/kit
cp -r /tmp/kit/.claude ~/
chmod +x ~/.claude/hooks/*.sh
```

### 2. Install CLI tools

Check which are missing and install only those:

```bash
# Check and install
command -v codex || npm install -g @openai/codex
command -v oxlint || npm install -g oxlint
command -v prettier || npm install -g prettier
python3 -c "import pyrefly" 2>/dev/null || pip3 install pyrefly
```

Ask the user for their `OPENAI_API_KEY` if `codex` is installed but the env var is not set.

### 3. Connect claude.ai services

Guide the user through connecting each service. Use `/connect` to start the OAuth flow for each:

**Required connectors:**

- **Linear** — issue tracking, project management. "Connect Linear so I can create and manage issues."
- **Gmail** — email access for verification flows and context. "Connect Gmail so I can read and send emails."

**Recommended connectors:**

- **Granola** — meeting transcripts. "Connect Granola to pull action items from meetings into Linear."
- **Notion** — docs and databases. "Connect Notion to read your team's documentation."
- **Google Drive** — file access. "Connect Google Drive to read shared documents."

For each one, tell the user what it enables and ask if they want to connect it. Don't connect all of them silently.

### 4. Verify plugins

Check that marketplace plugins are registered in settings.json:

- Vercel (`vercel@claude-plugins-official`)
- Railway (`railwayapp/railway-skills`)
- Paper (`paper-design/agent-plugins`)
- OpenAI Codex (`openai/codex-plugin-cc`)

### 5. Set up rules

Tell the user about `rules/instruct.md`. Explain that anything they write there becomes a standing directive that the Codex overseer enforces on every review. Ask if they have any project rules they want to add now (architecture boundaries, testing requirements, security constraints, style preferences).

### 6. Verify everything works

Run a quick check:

```bash
codex --version
oxlint --version
pyrefly --version
npx prettier --version
```

Confirm hooks exist:

```bash
ls ~/.claude/hooks/codex-review-*.sh
```

Confirm settings.json is valid:

```bash
python3 -c "import json; json.load(open('$HOME/.claude/settings.json')); print('settings.json valid')"
```

## After Setup

Tell the user:

- "Your Codex overseer will review every diff and plan automatically"
- "Pyrefly checks Python, oxlint checks JS/TS, Prettier formats everything — all on save"
- "Edit `rules/instruct.md` anytime to change what Codex enforces"
- "Use `/find-skills` to discover more community skills"
