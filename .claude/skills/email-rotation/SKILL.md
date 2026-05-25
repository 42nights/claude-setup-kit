---
name: email-rotation
description: Rotate outbound emails across multiple domains/accounts with rate limiting, warm-up tracking, and deliverability safeguards.
---

# Email Rotation

Send bulk personalized emails across multiple sender accounts without exceeding per-account rate limits. Handles rotation, warm-up schedules, delay randomization, and daily quota tracking.

## How It Works

1. You provide a list of sender accounts (Gmail addresses on separate domains)
2. The skill assigns each email to the next account in round-robin order
3. Each account respects its own daily limit (based on warm-up stage)
4. Random delays between sends simulate human cadence
5. When an account hits its limit, it's skipped for the rest of the day

## Prerequisites

- **Gmail connector** — run `/connect` to authorize each sender account
- **DNS records** — every sending domain must have SPF, DKIM, and DMARC configured
- **Separate domains** — never send bulk from your primary corporate domain

## Quick Start

### 1. Define Accounts

Create `rules/email-rotation-accounts.json`:

```json
{
  "accounts": [
    {
      "email": "outreach@getcompany.com",
      "domain": "getcompany.com",
      "warm_up_start": "2026-05-20",
      "daily_limit_override": null
    },
    {
      "email": "hello@trycompany.io",
      "domain": "trycompany.io",
      "warm_up_start": "2026-05-15",
      "daily_limit_override": null
    },
    {
      "email": "team@companymail.dev",
      "domain": "companymail.dev",
      "warm_up_start": "2026-05-01",
      "daily_limit_override": 100
    }
  ],
  "global": {
    "max_per_account_per_day": 500,
    "delay_min_seconds": 120,
    "delay_max_seconds": 300,
    "warm_up_weeks": 4
  }
}
```

### 2. Prepare Contacts

CSV, Notion database, or inline list. Minimum fields: `email`, `name`. Optional: `company`, `role`, `custom_field`.

### 3. Send a Campaign

```
/schedule "Every weekday at 9am:
1. Load accounts from rules/email-rotation-accounts.json
2. Load unsent contacts from [Notion DB / CSV path]
3. For each contact, rotate to the next available account
4. Personalize using rules/outreach-template.md
5. Send via Gmail connector
6. Log the send in rules/email-rotation-log.csv
7. Stop when all accounts hit their daily limit or contacts are exhausted"
```

Or run interactively: ask Claude to send a batch and it will use the rotation script.

## Rotation Logic

**Round-robin** is the default: contact 1 → account A, contact 2 → account B, contact 3 → account C, contact 4 → account A, etc.

When an account hits its daily limit, it's removed from the rotation pool for the rest of the day. Remaining accounts absorb the load.

### Effective Daily Capacity

```
total_daily_capacity = sum(daily_limit for each account)
```

With 3 accounts at 50/day each = 150 emails/day.
With 3 fully warmed accounts at 500/day = 1,500 emails/day.

## Warm-Up Schedule

New accounts cannot safely send at full volume. The skill auto-calculates each account's daily limit based on days since `warm_up_start`:

| Week | Days Since Start | Daily Limit                        |
| ---- | ---------------- | ---------------------------------- |
| 1    | 0–6              | 5                                  |
| 2    | 7–13             | 15                                 |
| 3    | 14–20            | 40                                 |
| 4    | 21–27            | 100                                |
| 5+   | 28+              | 500 (or `max_per_account_per_day`) |

`daily_limit_override` in the account config bypasses the warm-up curve — use only for accounts already warmed up externally.

## Rate Limiting

Three layers of protection:

1. **Per-account daily cap** — warm-up-aware, never exceeds `max_per_account_per_day` (default 500)
2. **Inter-send delay** — random wait between `delay_min_seconds` and `delay_max_seconds` (default 2–5 minutes)
3. **Global stop** — campaign halts when all accounts are exhausted for the day

### Gmail API Limits Reference

| Limit                      | Value              |
| -------------------------- | ------------------ |
| Daily sending (free Gmail) | 500 / day          |
| Daily sending (Workspace)  | 2,000 / day        |
| Recipients per message     | 500                |
| Messages per minute        | ~20 (undocumented) |

The skill defaults to the free Gmail 500 cap. Set `max_per_account_per_day: 2000` for Workspace accounts.

## Send Tracking

Every send is logged to `rules/email-rotation-log.csv`:

```csv
timestamp,sender_account,recipient_email,recipient_name,subject,status,message_id
2026-05-25T09:01:23Z,outreach@getcompany.com,lead@example.com,Jane Doe,Quick question,sent,msg_abc123
```

The log enables:

- Daily count queries per account (prevents over-sending across sessions)
- Duplicate detection (never email the same person from the same account twice in a campaign)
- Follow-up scheduling (find contacts where status=sent and days_since > 3)

## Deliverability Checklist

Before running any campaign, verify each sending domain:

- [ ] **SPF record** — `v=spf1 include:_spf.google.com ~all`
- [ ] **DKIM** — enabled in Google Workspace admin or Gmail settings
- [ ] **DMARC** — `v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com`
- [ ] **Domain age** — at least 2 weeks old before sending
- [ ] **Warm-up started** — `warm_up_start` date set in config
- [ ] **Unsubscribe link** — template includes an opt-out mechanism
- [ ] **Reply-to set** — replies go to a monitored inbox

## Template Personalization

Create `rules/outreach-template.md`:

```markdown
Subject: {subject_line}

Hi {name},

{body}

Best,
{sender_name}

---

If you'd rather not hear from me, just reply "unsubscribe".
```

Available variables: `{name}`, `{email}`, `{company}`, `{role}`, `{sender_name}`, `{sender_email}`, `{custom_field}`, `{subject_line}`, `{body}`.

Claude personalizes `{body}` per contact using their company/role context. Static variables are replaced directly.

## Anti-Patterns

- **Never send identical emails** — even with rotation, identical content triggers spam filters. Always personalize.
- **Never skip warm-up** — sending 500 emails from a day-old account will burn the domain.
- **Never send from your primary domain** — use dedicated outreach domains.
- **Never ignore bounces** — if a send fails, pause the account and investigate before continuing.
- **Never exceed 500/day on free Gmail** — the account will be temporarily suspended.

## Script Reference

The rotation engine lives in `scripts/rotate.py`. It's called by Claude during campaign execution — you don't run it directly.

Core functions:

- `load_accounts(config_path)` — parse account config, compute warm-up limits
- `get_daily_counts(log_path, date)` — count today's sends per account from the log
- `next_account(accounts, daily_counts)` — return the next account under its limit
- `record_send(log_path, sender, recipient, subject, message_id)` — append to send log
- `compute_warm_up_limit(warm_up_start, today)` — calculate safe daily limit

## Integration with Routines

This skill works with the [routines skill](../routines/SKILL.md) for scheduling. Use `/schedule` for persistent campaigns that survive session restarts.

For bounce monitoring, schedule a separate routine:

```
/schedule "Every 2 hours, check all sender inboxes for bounce-back emails.
If any found:
1. Mark the recipient as bounced in rules/email-rotation-log.csv
2. If bounces from one account exceed 5% of sends, pause that account
3. Send me a push notification with the bounce summary"
```
