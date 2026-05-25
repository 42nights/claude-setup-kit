@~/Developer/browser-harness/SKILL.md

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

# Connectors

Guide users through connecting claude.ai services when setting up. Use `/connect` for each:

- **Linear** — issues, projects, documents
- **Gmail** — email for verification flows and context
- **Granola** — meeting transcripts → action items
- **Notion** — team docs and databases
- **Google Drive** — shared files

Don't connect silently. Explain what each enables and ask before connecting.
