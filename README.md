# Claude Setup Kit

## Quick Start

Give Claude Code this link:

```
https://github.com/42nights/claude-setup-kit
```

Then say: **"set up my claude using this repo"** or **"add this on top of my existing claude"**

### Manual install

```bash
git clone https://github.com/42nights/claude-setup-kit.git /tmp/kit
cp -r /tmp/kit/.claude ~/
chmod +x ~/.claude/hooks/*.sh
npm install -g @openai/codex prettier oxlint
pip3 install pyrefly
echo 'export OPENAI_API_KEY=sk-...' >> ~/.zshrc
```

Connect in **claude.ai > Settings > Connected Apps**: Linear, Granola, Notion, Google Drive, Gmail.

## File Tree

```
.claude/
├── CLAUDE.md                          # Global rules (Karpathy-style) + Codex access
├── settings.json                      # Hooks, plugins, permissions
│
├── hooks/
│   ├── codex-review-diff.sh           # Codex reviews diffs on Stop + Edit/Write
│   └── codex-review-plan.sh           # Codex reviews plans on ExitPlanMode
│
├── commands/
│   ├── init.md                        # /init — start a UI build with design direction
│   ├── critique.md                    # /critique — self-review for craft, then rebuild
│   ├── audit.md                       # /audit — check code vs design system
│   ├── extract.md                     # /extract — pull patterns from code into system.md
│   └── status.md                      # /status — show design system state
│
└── skills/
    ├── interface-design/              # UI craft — spacing, depth, typography, critique loop
    │   └── references/
    ├── stripe/                        # Stripe API, webhooks, subscriptions, checkout
    ├── gcloud/                        # GCP — Cloud Run, GKE, BigQuery, IAM, cost optimization
    │   ├── references/
    │   └── scripts/
    ├── vercel/                        # Frontend — React, Next.js, Tailwind, deployment
    ├── better-auth-best-practices/    # Auth patterns and security
    ├── create-auth-skill/             # Scaffold auth flows with Better Auth
    ├── emil-design-eng/               # Emil Kowalski's UI polish philosophy
    └── find-skills/                   # Discover and install community skills

rules/
└── instruct.md                        # Your project rules — Codex enforces these

instructions.md                        # Full setup guide for every component
flow.md                                # How everything chains together
hooks.md                               # What each hook does and why
external.md                            # CodeRabbit, Greptile, Blacksmith, CLI tools
```

## Rules

The `rules/` folder is your alignment layer. Write architecture, security, testing, or style rules in markdown — the Codex hooks read every `.md` file in `rules/` and enforce them when reviewing Claude's diffs and plans.

Edit `rules/instruct.md` or add more files anytime. Codex picks them up on the next review.

## Docs

| File                               | What's in it                                                            |
| ---------------------------------- | ----------------------------------------------------------------------- |
| [instructions.md](instructions.md) | Step-by-step setup: CLI tools, connectors, plugins, skills              |
| [flow.md](flow.md)                 | How pieces chain: review loop, Granola→Linear, design flow, PR workflow |
| [hooks.md](hooks.md)               | What each hook does, dedup logic, structural separation explained       |
| [external.md](external.md)         | CodeRabbit, Greptile, Blacksmith, Codex, Pyrefly, oxlint, Prettier      |
