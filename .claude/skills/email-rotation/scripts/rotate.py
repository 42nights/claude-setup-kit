from __future__ import annotations

import csv
import json
import os
import random
import time
from datetime import date, datetime, timezone


WARM_UP_SCHEDULE = [
    (7, 5),
    (14, 15),
    (21, 40),
    (28, 100),
]
DEFAULT_MAX_DAILY = 500
DEFAULT_DELAY_MIN = 120
DEFAULT_DELAY_MAX = 300
DEFAULT_WARM_UP_WEEKS = 4


def compute_warm_up_limit(warm_up_start: str, today: date | None = None) -> int:
    today = today or date.today()
    start = date.fromisoformat(warm_up_start)
    days_active = (today - start).days

    if days_active < 0:
        return 0

    for threshold_days, limit in WARM_UP_SCHEDULE:
        if days_active < threshold_days:
            return limit

    return DEFAULT_MAX_DAILY


def load_accounts(config_path: str) -> tuple[list[dict], dict]:
    with open(config_path) as f:
        config = json.load(f)

    global_settings = config.get("global", {})
    max_daily = global_settings.get("max_per_account_per_day", DEFAULT_MAX_DAILY)

    accounts = []
    for acct in config["accounts"]:
        if acct.get("daily_limit_override") is not None:
            effective_limit = min(acct["daily_limit_override"], max_daily)
        else:
            warm_limit = compute_warm_up_limit(acct["warm_up_start"])
            effective_limit = min(warm_limit, max_daily)

        accounts.append(
            {
                "email": acct["email"],
                "domain": acct["domain"],
                "daily_limit": effective_limit,
            }
        )

    return accounts, global_settings


def get_daily_counts(log_path: str, target_date: date | None = None) -> dict[str, int]:
    target_date = target_date or date.today()
    counts: dict[str, int] = {}

    if not os.path.exists(log_path):
        return counts

    with open(log_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            ts = row.get("timestamp", "")
            if not ts:
                continue
            row_date = datetime.fromisoformat(ts.replace("Z", "+00:00")).date()
            if row_date == target_date:
                sender = row.get("sender_account", "")
                counts[sender] = counts.get(sender, 0) + 1

    return counts


def next_account(
    accounts: list[dict],
    daily_counts: dict[str, int],
    last_index: int = -1,
) -> tuple[dict | None, int]:
    n = len(accounts)
    for offset in range(1, n + 1):
        idx = (last_index + offset) % n
        acct = accounts[idx]
        used = daily_counts.get(acct["email"], 0)
        if used < acct["daily_limit"]:
            return acct, idx
    return None, -1


def record_send(
    log_path: str,
    sender: str,
    recipient_email: str,
    recipient_name: str,
    subject: str,
    message_id: str,
) -> None:
    file_exists = os.path.exists(log_path)

    os.makedirs(os.path.dirname(log_path) or ".", exist_ok=True)

    with open(log_path, "a", newline="") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(
                [
                    "timestamp",
                    "sender_account",
                    "recipient_email",
                    "recipient_name",
                    "subject",
                    "status",
                    "message_id",
                ]
            )
        writer.writerow(
            [
                datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
                sender,
                recipient_email,
                recipient_name,
                subject,
                "sent",
                message_id,
            ]
        )


def random_delay(
    min_seconds: int = DEFAULT_DELAY_MIN, max_seconds: int = DEFAULT_DELAY_MAX
) -> None:
    delay = random.randint(min_seconds, max_seconds)
    time.sleep(delay)


def run_campaign(
    config_path: str,
    contacts: list[dict],
    log_path: str,
    send_fn=None,
    dry_run: bool = False,
) -> dict:
    accounts, global_settings = load_accounts(config_path)
    delay_min = global_settings.get("delay_min_seconds", DEFAULT_DELAY_MIN)
    delay_max = global_settings.get("delay_max_seconds", DEFAULT_DELAY_MAX)

    daily_counts = get_daily_counts(log_path)
    last_index = -1
    sent = 0
    skipped = 0
    exhausted = False

    for contact in contacts:
        acct, last_index = next_account(accounts, daily_counts, last_index)
        if acct is None:
            exhausted = True
            skipped += len(contacts) - sent - skipped
            break

        if dry_run:
            print(
                f"[DRY RUN] {acct['email']} -> {contact['email']} ({contact.get('name', 'Unknown')})"
            )
            sent += 1
            daily_counts[acct["email"]] = daily_counts.get(acct["email"], 0) + 1
            continue

        message_id = ""
        if send_fn:
            message_id = send_fn(
                sender=acct["email"],
                to=contact["email"],
                name=contact.get("name", ""),
                company=contact.get("company", ""),
                role=contact.get("role", ""),
            )

        record_send(
            log_path=log_path,
            sender=acct["email"],
            recipient_email=contact["email"],
            recipient_name=contact.get("name", ""),
            subject=contact.get("subject", ""),
            message_id=message_id or "",
        )

        daily_counts[acct["email"]] = daily_counts.get(acct["email"], 0) + 1
        sent += 1

        if sent < len(contacts):
            random_delay(delay_min, delay_max)

    return {
        "sent": sent,
        "skipped": skipped,
        "exhausted": exhausted,
        "daily_counts": daily_counts,
    }


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python rotate.py <config.json> <contacts.csv> [--dry-run]")
        sys.exit(1)

    config_file = sys.argv[1]
    contacts_file = sys.argv[2]
    is_dry_run = "--dry-run" in sys.argv

    with open(contacts_file, newline="") as f:
        reader = csv.DictReader(f)
        contact_list = list(reader)

    log_file = os.path.join(os.path.dirname(config_file), "email-rotation-log.csv")

    result = run_campaign(
        config_path=config_file,
        contacts=contact_list,
        log_path=log_file,
        dry_run=is_dry_run,
    )

    print(f"\nResults: {result['sent']} sent, {result['skipped']} skipped")
    if result["exhausted"]:
        print("All accounts hit their daily limit.")
    print("Counts per account:")
    for email, count in result["daily_counts"].items():
        print(f"  {email}: {count}")
