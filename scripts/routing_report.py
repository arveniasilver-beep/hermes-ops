from __future__ import annotations

import argparse
import json
import os
import sqlite3
import time
from collections import Counter
from contextlib import closing
from pathlib import Path
from typing import Any


HERMES_HOME = Path(os.environ.get("LOCALAPPDATA", "")) / "hermes"
PROFILE_MODELS = {
    "owner-orchestrator": "mimo-v2.5",
    "owner-fast-worker": "deepseek-v4-flash",
    "owner-engineer": "deepseek-v4-pro",
    "owner-vision": "mimo-v2.5",
    "owner-operator": "mimo-v2.5-pro",
}
PRO_PROFILES = {"owner-engineer", "owner-operator"}

# USD per one million tokens. Refresh from the official provider pages when
# either vendor changes pricing. Cache writes use the normal input rate.
PRICING_VERSION = "2026-06-29"
PRICES = {
    "mimo-v2.5-pro": {"input": 0.435, "output": 0.87, "cache": 0.0036},
    "mimo-v2.5": {"input": 0.14, "output": 0.28, "cache": 0.0028},
    "deepseek-v4-pro": {"input": 0.435, "output": 0.87, "cache": 0.003625},
    "deepseek-v4-flash": {"input": 0.14, "output": 0.28, "cache": 0.0028},
}


def normalize_model(model: str | None, fallback: str) -> str:
    value = (model or fallback).strip().lower()
    return value.rsplit("/", 1)[-1]


def current_cost(row: sqlite3.Row, fallback_model: str) -> float | None:
    model = normalize_model(row["model"], fallback_model)
    price = PRICES.get(model)
    if not price:
        return None
    amount = (
        int(row["input_tokens"] or 0) * price["input"]
        + int(row["output_tokens"] or 0) * price["output"]
        + int(row["cache_read_tokens"] or 0) * price["cache"]
        + int(row["cache_write_tokens"] or 0) * price["input"]
    )
    return amount / 1_000_000


def empty_profile(profile: str) -> dict[str, Any]:
    return {
        "profile": profile,
        "configured_model": PROFILE_MODELS[profile],
        "sessions": 0,
        "active_sessions": 0,
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_read_tokens": 0,
        "cache_write_tokens": 0,
        "api_calls": 0,
        "tool_calls": 0,
        "duration_seconds": 0.0,
        "recorded_cost_usd": 0.0,
        "current_price_estimate_usd": 0.0,
        "unknown_price_sessions": 0,
        "end_reasons": {},
        "kanban_runs": 0,
        "kanban_completed": 0,
        "kanban_retries": 0,
        "kanban_success_rate": None,
        "kanban_average_duration_seconds": None,
        "kanban_outcomes": {},
    }


def load_sessions(profile: str, since: float, result: dict[str, Any]) -> None:
    db_path = HERMES_HOME / "profiles" / profile / "state.db"
    if not db_path.exists():
        return
    query = """
        SELECT model, started_at, ended_at, end_reason,
               input_tokens, output_tokens, cache_read_tokens,
               cache_write_tokens, api_call_count, tool_call_count,
               estimated_cost_usd, actual_cost_usd
          FROM sessions
         WHERE started_at >= ?
    """
    with closing(sqlite3.connect(db_path)) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(query, (since,)).fetchall()

    reasons: Counter[str] = Counter()
    for row in rows:
        result["sessions"] += 1
        result["active_sessions"] += int(row["ended_at"] is None)
        for key in (
            "input_tokens",
            "output_tokens",
            "cache_read_tokens",
            "cache_write_tokens",
        ):
            result[key] += int(row[key] or 0)
        result["api_calls"] += int(row["api_call_count"] or 0)
        result["tool_calls"] += int(row["tool_call_count"] or 0)
        if row["ended_at"] is not None:
            result["duration_seconds"] += max(
                0.0, float(row["ended_at"]) - float(row["started_at"])
            )
        recorded = row["actual_cost_usd"]
        if recorded is None:
            recorded = row["estimated_cost_usd"]
        result["recorded_cost_usd"] += float(recorded or 0.0)
        estimate = current_cost(row, PROFILE_MODELS[profile])
        if estimate is None:
            result["unknown_price_sessions"] += 1
        else:
            result["current_price_estimate_usd"] += estimate
        reasons[row["end_reason"] or "active"] += 1
    result["end_reasons"] = dict(sorted(reasons.items()))


def load_kanban(since: int, profiles: dict[str, dict[str, Any]]) -> None:
    db_path = HERMES_HOME / "kanban.db"
    if not db_path.exists():
        return
    query = """
        SELECT task_id, profile, status, outcome, started_at, ended_at
          FROM task_runs
         WHERE started_at >= ?
    """
    with closing(sqlite3.connect(db_path)) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(query, (since,)).fetchall()

    grouped: dict[str, list[sqlite3.Row]] = {name: [] for name in profiles}
    for row in rows:
        if row["profile"] in grouped:
            grouped[row["profile"]].append(row)

    for profile, items in grouped.items():
        result = profiles[profile]
        outcomes: Counter[str] = Counter()
        attempts: Counter[str] = Counter()
        ended = 0
        duration = 0.0
        completed = 0
        for row in items:
            attempts[row["task_id"]] += 1
            outcome = row["outcome"] or row["status"] or "unknown"
            outcomes[outcome] += 1
            completed += int(row["outcome"] == "completed")
            if row["ended_at"] is not None:
                ended += 1
                duration += max(0, int(row["ended_at"]) - int(row["started_at"]))
        result["kanban_runs"] = len(items)
        result["kanban_completed"] = completed
        result["kanban_retries"] = sum(max(0, count - 1) for count in attempts.values())
        result["kanban_success_rate"] = completed / ended if ended else None
        result["kanban_average_duration_seconds"] = duration / ended if ended else None
        result["kanban_outcomes"] = dict(sorted(outcomes.items()))


def build_report(days: int) -> dict[str, Any]:
    now = time.time()
    since = now - days * 86400
    profiles = {name: empty_profile(name) for name in PROFILE_MODELS}
    for name, result in profiles.items():
        load_sessions(name, since, result)
    load_kanban(int(since), profiles)

    cheap = [row for name, row in profiles.items() if name not in PRO_PROFILES]
    pro = [row for name, row in profiles.items() if name in PRO_PROFILES]
    total_sessions = sum(row["sessions"] for row in profiles.values())
    pro_sessions = sum(row["sessions"] for row in pro)
    total_cost = sum(row["current_price_estimate_usd"] for row in profiles.values())
    pro_cost = sum(row["current_price_estimate_usd"] for row in pro)
    return {
        "generated_at_epoch": int(now),
        "window_days": days,
        "pricing_version": PRICING_VERSION,
        "profiles": profiles,
        "routing_summary": {
            "total_sessions": total_sessions,
            "economical_sessions": sum(row["sessions"] for row in cheap),
            "pro_sessions": pro_sessions,
            "pro_session_share": pro_sessions / total_sessions if total_sessions else None,
            "current_price_estimate_usd": total_cost,
            "pro_cost_estimate_usd": pro_cost,
            "pro_cost_share": pro_cost / total_cost if total_cost else None,
        },
        "coverage_notes": [
            "Costs are local estimates from successful usage records, not invoices.",
            "Auxiliary calls and provider retries may be absent from state.db.",
            "Kanban completion is a workflow outcome, not independent verification proof.",
            "Task type and user-correction events are not natively recorded by Hermes 0.18.2.",
        ],
    }


def fmt_int(value: int) -> str:
    return f"{value:,}"


def print_report(report: dict[str, Any]) -> None:
    print(
        f"Hermes routing report: last {report['window_days']} day(s), "
        f"pricing snapshot {report['pricing_version']}"
    )
    header = (
        f"{'PROFILE':22} {'MODEL':22} {'SESS':>5} {'INPUT':>12} "
        f"{'OUTPUT':>12} {'COST USD':>10} {'RUNS':>5} {'OK':>5} {'RETRY':>5}"
    )
    print(header)
    print("-" * len(header))
    for name, row in report["profiles"].items():
        print(
            f"{name:22} {row['configured_model']:22} {row['sessions']:>5} "
            f"{fmt_int(row['input_tokens']):>12} {fmt_int(row['output_tokens']):>12} "
            f"{row['current_price_estimate_usd']:>10.4f} "
            f"{row['kanban_runs']:>5} {row['kanban_completed']:>5} "
            f"{row['kanban_retries']:>5}"
        )
    summary = report["routing_summary"]
    pro_share = summary["pro_session_share"]
    print()
    print(
        "Economical / Pro sessions: "
        f"{summary['economical_sessions']} / {summary['pro_sessions']}"
        + (f" (Pro {pro_share:.1%})" if pro_share is not None else "")
    )
    print(f"Current-price total estimate: ${summary['current_price_estimate_usd']:.4f}")
    print("Coverage notes:")
    for note in report["coverage_notes"]:
        print(f"  - {note}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Aggregate Hermes profile usage, current-price estimates, and Kanban runs."
    )
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    if args.days < 1:
        parser.error("--days must be at least 1")
    report = build_report(args.days)
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_report(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
