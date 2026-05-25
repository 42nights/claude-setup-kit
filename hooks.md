# Hooks

Every hook in `settings.json` explained.

## Stop Hooks

Fire when Claude is about to hand control back to you.

### Codex Review (`codex-review-diff.sh`)

Sends the uncommitted diff to OpenAI Codex CLI for independent review. If Codex finds bugs, security issues, or correctness gaps, it **blocks** Claude from stopping and injects the findings so Claude addresses them first.

- Skips if no uncommitted changes
- Skips if the same diff was already reviewed in the last 30 minutes (dedup via content hash)
- Skips inside Codex's own subprocess (recursion guard via `CODEX_SESSION_ID`)
- Reads project `/rules` or `.rules` folder and includes them in the review prompt
- Outputs JSON `{"decision": "block", "reason": "..."}` to prevent Claude from stopping

This is the **structural separation** pattern: a different model (OpenAI) in a different process reviews Claude's work. Prompting alone can't replicate this — the reviewer must be structurally unable to share the author's context.

### Ruff Check (Python)

```
ls *.py **/*.py → if found → ruff check . >&2 || exit 2
```

Lints Python files on every stop. Only runs if the project has `.py` files. Exit code 2 tells Claude to fix the errors before proceeding. Ruff replaces Pyrefly/Flake8 for linting and Black for formatting.

### oxlint Check

```
ls *.ts *.tsx *.js *.jsx **/* → if found → oxlint >&2 || exit 2
```

Lints JS/TS files on every stop. Same pattern as Pyrefly — auto-detects, exit 2 blocks.

## PreToolUse Hooks

Fire before a tool runs. Can block execution.

### Plan Review (`codex-review-plan.sh`)

**Matcher:** `ExitPlanMode` — fires when Claude tries to finalize a plan.

Sends the plan file to Codex for independent review before you approve it. Catches missing edge cases, security gaps, race conditions, and verification holes. Output appears in Claude's transcript so it can fold findings in.

- Finds the plan file from the hook payload or `~/.claude/plans/`
- Includes project `/rules` in the review prompt
- Non-blocking — findings are advisory, not a hard block

## PostToolUse Hooks

Fire after a tool completes. Cannot block.

### Codex Review on Edit/Write

Same `codex-review-diff.sh` as the Stop hook, but fires after each Edit or Write. Catches issues incrementally, not just at the end.

### Auto-Format (`auto-format.sh`)

**Matcher:** `Edit|Write`

Routes each edited file to the right formatter based on extension:

| Extension                                                                                 | Formatter                |
| ----------------------------------------------------------------------------------------- | ------------------------ |
| `.ts`, `.tsx`, `.js`, `.jsx`, `.css`, `.html`, `.json`, `.yaml`, `.md`, `.vue`, `.svelte` | Prettier                 |
| `.py`, `.pyi`                                                                             | Ruff (format + lint fix) |
| `.go`                                                                                     | gofmt                    |
| `.rs`                                                                                     | rustfmt                  |
| `.java`                                                                                   | google-java-format       |
| `.kt`, `.kts`                                                                             | ktlint                   |
| `.c`, `.h`, `.cpp`, `.hpp`, `.cc`                                                         | clang-format             |

Each formatter only runs if installed (`command -v` check). Exits 0 silently if the formatter is missing — install only the ones you need.

### Superset Notifications

**Matcher:** `*` (all tools)

Sends push notifications for every tool use so you can monitor agent activity from your phone. Requires `SUPERSET_HOME_DIR` env var.

## Other Events

### UserPromptSubmit, SessionStart, SessionEnd, PostToolUseFailure, PermissionRequest

All wired to Superset notification hooks. No code review or formatting — just monitoring.

## Dedup & Loop Prevention

The Codex review hooks won't loop forever:

1. Each review hashes the current diff (`shasum -a 256`)
2. Writes a marker file to `$TMPDIR/codex-review-diff/<hash>`
3. If the same hash is seen within 30 minutes, the review is skipped
4. So: Claude edits → review → fixes → new diff → review → fixes → same diff → **skip** → done
