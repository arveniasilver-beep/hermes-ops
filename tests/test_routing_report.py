from __future__ import annotations

import sqlite3
import sys
import tempfile
import time
import unittest
from contextlib import closing
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import routing_report  # noqa: E402


SESSION_SCHEMA = """
CREATE TABLE sessions (
    model TEXT,
    started_at REAL,
    ended_at REAL,
    end_reason TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    cache_read_tokens INTEGER,
    cache_write_tokens INTEGER,
    api_call_count INTEGER,
    tool_call_count INTEGER,
    estimated_cost_usd REAL,
    actual_cost_usd REAL
)
"""

KANBAN_SCHEMA = """
CREATE TABLE task_runs (
    task_id TEXT,
    profile TEXT,
    status TEXT,
    outcome TEXT,
    started_at INTEGER,
    ended_at INTEGER
)
"""


class RoutingReportTests(unittest.TestCase):
    def test_cost_and_retry_aggregation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            original_home = routing_report.HERMES_HOME
            routing_report.HERMES_HOME = Path(temp_dir)
            try:
                now = time.time()
                profile_dir = (
                    routing_report.HERMES_HOME
                    / "profiles"
                    / "owner-fast-worker"
                )
                profile_dir.mkdir(parents=True)
                with closing(
                    sqlite3.connect(profile_dir / "state.db")
                ) as connection:
                    connection.execute(SESSION_SCHEMA)
                    connection.execute(
                        """
                        INSERT INTO sessions VALUES (
                            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
                        )
                        """,
                        (
                            "deepseek/deepseek-v4-flash",
                            now - 30,
                            now,
                            "completed",
                            1_000_000,
                            500_000,
                            100_000,
                            50_000,
                            2,
                            3,
                            99.0,
                            None,
                        ),
                    )

                    connection.commit()

                with closing(
                    sqlite3.connect(routing_report.HERMES_HOME / "kanban.db")
                ) as connection:
                    connection.execute(KANBAN_SCHEMA)
                    connection.executemany(
                        "INSERT INTO task_runs VALUES (?, ?, ?, ?, ?, ?)",
                        [
                            (
                                "task-1",
                                "owner-fast-worker",
                                "failed",
                                "failed",
                                int(now) - 20,
                                int(now) - 15,
                            ),
                            (
                                "task-1",
                                "owner-fast-worker",
                                "completed",
                                "completed",
                                int(now) - 10,
                                int(now),
                            ),
                        ],
                    )
                    connection.commit()

                report = routing_report.build_report(1)
                worker = report["profiles"]["owner-fast-worker"]

                self.assertEqual(worker["sessions"], 1)
                self.assertEqual(worker["input_tokens"], 1_000_000)
                self.assertEqual(worker["kanban_runs"], 2)
                self.assertEqual(worker["kanban_completed"], 1)
                self.assertEqual(worker["kanban_retries"], 1)
                self.assertAlmostEqual(worker["kanban_success_rate"], 0.5)
                self.assertAlmostEqual(
                    worker["current_price_estimate_usd"], 0.28728
                )
                self.assertAlmostEqual(
                    report["routing_summary"]["current_price_estimate_usd"],
                    0.28728,
                )
            finally:
                routing_report.HERMES_HOME = original_home


if __name__ == "__main__":
    unittest.main()
