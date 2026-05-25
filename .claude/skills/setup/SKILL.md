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
echo 'export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1' >> ~/.zshrc
```

### 2. Install CLI tools

Check which are missing and install only those:

```bash
command -v codex || npm install -g @openai/codex
command -v oxlint || npm install -g oxlint
command -v prettier || npm install -g prettier
command -v ruff || pip3 install ruff
command -v browser-harness || pip install browser-harness
```

Ask the user for their `OPENAI_API_KEY` if `codex` is installed but the env var is not set.

### 3. Connect services

Go through each connector one at a time. Explain what it enables, ask if they want it, then connect and verify.

Each connector has two states:

- **Not yet authed** → an `authenticate` tool is visible (e.g., `mcp__claude_ai_Linear__authenticate`). Call it to get an OAuth URL, tell the user to open it and authorize, then the real tools appear.
- **Already authed** → real tools are visible (e.g., `mcp__claude_ai_Linear__list_teams`). Skip to verification.

For each connector below, check which state it's in, then act accordingly.

| Connector        | What it enables                     | Verify with                                       |
| ---------------- | ----------------------------------- | ------------------------------------------------- |
| **Linear**       | Issues, projects, cycles, documents | `list_teams` returns teams                        |
| **Granola**      | Meeting transcripts → action items  | `get_account_info` returns email                  |
| **Notion**       | Read/write pages and databases      | `authenticate` tool disappears, real tools appear |
| **Google Drive** | Read shared files                   | `authenticate` tool disappears, real tools appear |
| **Gmail**        | Search, read, send emails           | `authenticate` tool disappears, real tools appear |

After each connection, summarize what's now available (e.g., "Linear connected — you can now create issues, manage projects, and track cycles from Claude Code").

### 4. Verify plugins

Check that marketplace plugins are registered in settings.json:

- Vercel (`vercel@claude-plugins-official`)
- Railway (`railwayapp/railway-skills`)
- Paper (`paper-design/agent-plugins`)
- OpenAI Codex (`openai/codex-plugin-cc`)
- GSAP Skills (`greensock/gsap-skills`)
- Caveman (`JuliusBrussee/caveman`)

### 5. Set up rules

Tell the user about `rules/instruct.md`. Explain that anything they write there becomes a standing directive that the Codex overseer enforces on every review. Ask if they have any project rules they want to add now (architecture boundaries, testing requirements, security constraints, style preferences).

### 6. Verify everything works

Run a quick check:

```bash
codex --version
oxlint --version
ruff --version
npx prettier --version
```

Confirm hooks exist:

```bash
ls ~/.claude/hooks/codex-review-*.sh ~/.claude/hooks/auto-format.sh
```

Confirm settings.json is valid:

```bash
python3 -c "import json; json.load(open('$HOME/.claude/settings.json')); print('settings.json valid')"
```

## After Setup

Tell the user:

- "Your Codex overseer will review every diff and plan automatically"
- "Ruff checks Python, oxlint checks JS/TS, auto-format.sh formats 7 languages — all on save"
- "Edit `rules/instruct.md` anytime to change what Codex enforces"
- "Use `/find-skills` to discover more community skills"
