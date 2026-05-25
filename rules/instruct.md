# Project Rules

This file is read by the Codex overseer hooks before every review. When Codex reviews Claude's diffs or plans, it checks compliance against these rules.

Update this file whenever you want to change what Codex enforces.

## How It Works

The hooks (`codex-review-diff.sh` and `codex-review-plan.sh`) walk up from the current directory looking for a `rules/` or `.rules/` folder. Every `.md` and `.txt` file inside is concatenated and injected into the Codex review prompt as "project rules to apply during review."

So anything you write here becomes a standing directive that Codex will hold Claude accountable to.

## What to Put Here

Rules that Claude might drift from without external enforcement:

- Architecture boundaries ("services never import from the CLI package")
- Naming conventions ("all API routes use kebab-case")
- Security requirements ("never store secrets in git, always use env vars")
- Testing standards ("every new endpoint needs an integration test")
- Code style ("no default exports, no barrel files")
- Framework constraints ("only use server components for data fetching")
- Deployment rules ("never push directly to main")
- Performance constraints ("no synchronous file I/O in request handlers")

## Example

```markdown
## Architecture

- packages/api never imports from packages/web
- All database queries go through the repository layer, never raw SQL in handlers
- No circular dependencies between workspace packages

## Security

- All user input must be validated with zod before use
- Never log PII (email, name, IP) at info level — only debug
- API keys stored in environment variables, never in code or config files

## Testing

- Every new API endpoint requires at least one happy-path and one error-path test
- Tests must not depend on external services — mock all HTTP calls
- No test should take longer than 5 seconds

## Style

- No default exports except for Next.js pages/layouts
- Prefer named functions over arrow functions for top-level declarations
- No console.log in committed code — use the logger
```

## Multiple Files

You can split rules across files:

```
rules/
├── instruct.md       # this file (meta + general rules)
├── architecture.md   # dependency boundaries, module structure
├── security.md       # auth, secrets, input validation
└── testing.md        # coverage requirements, test patterns
```

All files are concatenated. Use whatever organization makes sense for your team.
