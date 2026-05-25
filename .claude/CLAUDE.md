# Available Skills

When a skill is needed, read its SKILL.md directly — no need to search the file tree. When a new skill is installed or removed, update this list in CLAUDE.md to keep it current.

| Skill                      | Path                                                 | What it does                                                                                               |
| -------------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| browser-harness            | `.claude/skills/browser-harness/SKILL.md`            | Browser automation via CDP — screenshots, coordinate clicks, scraping. Connects to user's running Chrome.  |
| interface-design           | `.claude/skills/interface-design/SKILL.md`           | UI craft for dashboards, apps, tools — spacing, depth, typography, critique loop.                          |
| gcloud                     | `.claude/skills/gcloud/SKILL.md`                     | GCP architecture — Cloud Run, GKE, BigQuery, IAM, cost optimization.                                       |
| stripe                     | `.claude/skills/stripe/SKILL.md`                     | Stripe API — checkout, subscriptions, webhooks, usage-based billing, customer portal.                      |
| vercel                     | `.claude/skills/vercel/SKILL.md`                     | Frontend — React, Next.js, Tailwind, bundle analysis, accessibility.                                       |
| better-auth-best-practices | `.claude/skills/better-auth-best-practices/SKILL.md` | Better Auth server/client config, sessions, plugins, adapters.                                             |
| create-auth-skill          | `.claude/skills/create-auth-skill/SKILL.md`          | Scaffold auth flows with Better Auth — detect framework, configure, add OAuth.                             |
| emil-design-eng            | `.claude/skills/emil-design-eng/SKILL.md`            | Emil Kowalski's UI polish philosophy — animation, component design, invisible details.                     |
| find-skills                | `.claude/skills/find-skills/SKILL.md`                | Discover and install community skills via `npx skills`.                                                    |
| routines                   | `.claude/skills/routines/SKILL.md`                   | Scheduled automations — email outreach, PR review, deploy checks, standups.                                |
| setup                      | `.claude/skills/setup/SKILL.md`                      | Guided setup — CLI tools, connectors, plugins, rules configuration.                                        |
| email-rotation             | `.claude/skills/email-rotation/SKILL.md`             | Rotate outbound emails across multiple domains with rate limiting, warm-up, and deliverability safeguards. |

**Plugins (installed via settings.json, not local skill folders):**

| Plugin         | Source                       | What it does                                                              |
| -------------- | ---------------------------- | ------------------------------------------------------------------------- |
| vercel         | `claude-plugins-official`    | Deployment, AI architecture, performance — 22+ sub-skills.                |
| openai-codex   | `openai/codex-plugin-cc`     | Structural code review from a separate model.                             |
| paper          | `paper-design/agent-plugins` | Design system tokens and components.                                      |
| railway-skills | `railwayapp/railway-skills`  | Railway deployment, services, logs, metrics.                              |
| gsap-skills    | `greensock/gsap-skills`      | GSAP animations — core API, timelines, ScrollTrigger, React, performance. |
| caveman        | `JuliusBrussee/caveman`      | Output compression (~65-75%), terse prose, token savings.                 |

# Rules

- Ask, don't assume. If something is unclear, ask before writing a single line. Never make silent assumptions about intent, architecture, or requirements.
- Simplest solution first. Always implement the simplest thing that could work. Do not add abstractions or flexibility that weren't explicitly requested.
- Don't touch unrelated code. If a file or function is not directly part of the current task, do not modify it.
- Flag uncertainty explicitly. If you are not confident about an approach, say so before proceeding.
- No preamble. Never open responses with filler phrases. Start with the actual answer.
- Match length to task. Keep responses as concise or detailed as the task requires.
- Show options before big changes. Present 2-3 approaches and wait for confirmation before restructuring code or rewriting large sections.
- Confirm before destructive actions. Explicitly ask before deleting files, overwriting code, force-pushing, or running migrations.

# Codex Access

You have access to OpenAI Codex via the codex-plugin-cc plugin. Use it when:

- You're unsure about an approach and want a second opinion from a different model
- You want an independent code review before committing
- You need to delegate a subtask to a structurally separate reviewer

The Codex overseer hooks also run automatically on Stop (reviews uncommitted diffs) and ExitPlanMode (reviews plans). These use the Codex CLI in a subprocess — a different model, different session, no shared context.

# Skill Lookup

When you need information from a skill, use `grep` to search its SKILL.md for the relevant section instead of reading the entire file. Only read the full SKILL.md when the whole context is necessary (e.g., first-time setup or unfamiliar skill).

# Skill Usage Logging

After every skill invocation:

1. Update the `**Last used:**` date in that skill's `usage-log.md`
2. Append a log entry in this format:

```
| YYYY-MM-DD | one-line task summary | what worked well | what to repeat or avoid next time |
```

Before using a skill, read its `usage-log.md` first — it contains patterns from prior usage that should inform your approach. Prioritize entries marked "repeat" and avoid patterns marked "avoid".

Each `usage-log.md` also tracks `**Installed:**` date. When installing a new skill, set this to today. If a skill's installed date is stale (6+ months), check for updates from its source repo.

Keep entries concise (one line each). Don't log trivial or failed invocations. If a skill has no `usage-log.md`, create one with the installed/last-used header.
