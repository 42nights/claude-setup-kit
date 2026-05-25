---
name: routines
description: Set up recurring Claude routines — email outreach, PR reviews, deploy checks, and other scheduled automations using CronCreate or /schedule.
---

# Routines

Recurring tasks that Claude runs on a schedule. Use for anything that needs to happen regularly without manual prompting.

## How It Works

Two ways to create routines:

1. **CronCreate** — session-scoped by default, durable if `durable: true`
2. **/schedule** — creates persistent remote agents that survive session restarts

Durable routines persist to `.claude/scheduled_tasks.json`. Session-only routines die when Claude exits.

Recurring tasks auto-expire after 7 days. Tell the user when setting them up.

## Email Outreach

The primary use case. Claude reads a contact list, drafts personalized emails, and sends them on a schedule via Gmail connector.

### Setup

1. Connect Gmail via `/connect`
2. Prepare a contact list (CSV, Notion database, or inline)
3. Create the routine:

```
/schedule "Every weekday at 9am, check the outreach sheet in Notion for unsent contacts.
For each one:
1. Read their company and role
2. Draft a personalized email based on the template in rules/outreach-template.md
3. Send via Gmail
4. Mark as sent in Notion with today's date
Stop after 10 emails per run."
```

### Outreach Patterns

**Cold outreach with follow-ups:**

```
/schedule "Every weekday at 10am:
1. Check Notion outreach DB for contacts where status = 'sent' and days_since_sent >= 3
2. Draft a follow-up email (shorter, reference the original)
3. Send via Gmail
4. Update status to 'followed-up' in Notion
Max 5 follow-ups per run."
```

**Warm intro pipeline:**

```
/schedule "Every Monday at 9am:
1. Check Granola for meetings from last week mentioning introductions
2. Draft intro emails connecting the relevant people
3. Queue drafts in Gmail (don't send — let me review)
4. Post a summary to Linear as a task"
```

### Rules for Outreach

Add to `rules/outreach.md` so Codex enforces:

```markdown
- Never send more than 15 emails per day
- Always include an unsubscribe line
- Never send the same template to the same person twice
- Follow-ups stop after 2 attempts
- All emails must be personalized — no bulk identical copies
```

## Other Routine Examples

### PR Review

```
/schedule "Every weekday at 9am, check open PRs on 42nights org.
For each PR older than 24h without a review:
1. Read the diff
2. Post a review comment with findings
3. Post a summary to Linear"
```

### Deploy Health

```
/schedule "Every 6 hours, check Railway and Vercel deployments.
If any service is down or erroring:
1. Check logs for the root cause
2. Create a Linear issue with severity and logs
3. Send me a push notification"
```

### Standup Summary

```
/schedule "Every weekday at 8:45am:
1. Pull yesterday's Granola meeting notes
2. Pull yesterday's Linear activity (issues moved, PRs merged)
3. Draft a standup summary
4. Post it to the team Slack channel"
```

## Cron Syntax

Standard 5-field: `minute hour day-of-month month day-of-week`

```
7 9 * * 1-5     # Weekdays at 9:07am (avoid :00 marks)
*/30 * * * *    # Every 30 minutes
3 9 * * 1       # Mondays at 9:03am
0 */6 * * *     # Every 6 hours
```

Avoid minute 0 and 30 — spread load by picking odd minutes.

## Important

- **Gmail connector required** for any email routine
- **Granola connector** for meeting-based routines
- **Linear connector** for issue tracking routines
- **Notion connector** for database-driven outreach
- Durable routines survive restarts: set `durable: true` or use `/schedule`
- Session routines expire when Claude exits
- All recurring routines auto-expire after 7 days — re-create or use `/schedule` for persistence
