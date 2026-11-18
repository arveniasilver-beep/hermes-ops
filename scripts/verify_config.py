from __future__ import annotations

import os
import sqlite3
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path

import yaml
from packaging.version import Version


HERMES_HOME = Path(os.environ.get("LOCALAPPDATA", "")) / "hermes"
PROFILES = HERMES_HOME / "profiles"

EXPECTED = {
    "owner-orchestrator": {
        "provider": "xiaomi",
        "model": "mimo-v2.5",
        "tools": {"web", "browser", "vision", "skills", "todo", "memory", "session_search", "clarify", "kanban"},
        "secret": "XIAOMI_API_KEY",
    },
    "owner-fast-worker": {
        "provider": "deepseek",
        "model": "deepseek-v4-flash",
        "tools": {"web", "browser", "terminal", "file", "code_execution", "skills", "todo", "memory", "session_search", "clarify", "kanban"},
        "secret": "DEEPSEEK_API_KEY",
    },
    "owner-engineer": {
        "provider": "deepseek",
        "model": "deepseek-v4-pro",
        "tools": {"web", "terminal", "file", "code_execution", "skills", "todo", "memory", "session_search", "clarify", "kanban"},
        "secret": "DEEPSEEK_API_KEY",
    },
    "owner-vision": {
        "provider": "xiaomi",
        "model": "mimo-v2.5",
        "tools": {"web", "browser", "vision", "video", "skills", "todo", "memory", "session_search", "clarify", "kanban"},
        "secret": "XIAOMI_API_KEY",
    },
    "owner-operator": {
        "provider": "xiaomi",
        "model": "mimo-v2.5-pro",
        "tools": {"web", "browser", "vision", "skills", "todo", "memory", "session_search", "clarify", "cronjob", "computer_use", "kanban"},
        "secret": "XIAOMI_API_KEY",
    },
}

SECURITY_FLOORS = {
    "cryptography": "48.0.1",
    "python-multipart": "0.0.31",
    "starlette": "1.3.1",
    "pydantic-settings": "2.14.2",
    "pip": "26.1.2",
    "Pygments": "2.20.0",
    "click": "8.3.3",
    "httplib2": "0.32.0",
    "pillow": "12.3.0",
    "setuptools": "83.0.0",
}


def nested(config: dict, *keys: str):
    value = config
    for key in keys:
        if not isinstance(value, dict) or key not in value:
            return None
        value = value[key]
    return value


def env_has_value(path: Path, name: str) -> bool:
    if not path.exists():
        return False
    prefix = f"{name}="
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith(prefix):
            return bool(line[len(prefix) :].strip())
    return False


def check_profile(name: str, expected: dict) -> tuple[list[str], bool]:
    errors: list[str] = []
    root = PROFILES / name
    config_path = root / "config.yaml"
    if not config_path.exists():
        return [f"{name}: config.yaml is missing"], False

    config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    checks = {
        "provider": (nested(config, "model", "provider"), expected["provider"]),
        "model": (nested(config, "model", "default"), expected["model"]),
        "context length": (nested(config, "model", "context_length"), 1_000_000),
        "terminal backend": (nested(config, "terminal", "backend"), "docker"),
        "approval mode": (nested(config, "approvals", "mode"), "manual"),
        "cron approval": (nested(config, "approvals", "cron_mode"), "deny"),
        "memory write approval": (nested(config, "memory", "write_approval"), True),
        "skill write approval": (nested(config, "skills", "write_approval"), True),
        "secret redaction": (nested(config, "security", "redact_secrets"), True),
    }
    for label, (actual, wanted) in checks.items():
        if actual != wanted:
            errors.append(f"{name}: {label} is {actual!r}, expected {wanted!r}")

    actual_tools = set(nested(config, "platform_toolsets", "cli") or [])
    if actual_tools != expected["tools"]:
        errors.append(
            f"{name}: tool contract differs; actual={sorted(actual_tools)!r}"
        )

    if name == "owner-orchestrator":
        kanban_checks = {
            "auto_decompose": True,
            "auto_decompose_per_tick": 1,
            "orchestrator_profile": "owner-orchestrator",
            "default_assignee": "owner-fast-worker",
            "max_in_progress": 2,
            "max_in_progress_per_profile": 1,
            "failure_limit": 2,
        }
        for key, wanted in kanban_checks.items():
            actual = nested(config, "kanban", key)
            if actual != wanted:
                errors.append(
                    f"{name}: kanban.{key} is {actual!r}, expected {wanted!r}"
                )

        for auxiliary_name in (
            "kanban_decomposer",
            "triage_specifier",
            "profile_describer",
        ):
            actual = nested(config, "auxiliary", auxiliary_name, "model")
            if actual != "mimo-v2.5":
                errors.append(
                    f"{name}: auxiliary.{auxiliary_name}.model is "
                    f"{actual!r}, expected 'mimo-v2.5'"
                )

    if name in {"owner-fast-worker", "owner-engineer"}:
        actual = nested(config, "terminal", "docker_mount_cwd_to_workspace")
        if actual is not True:
            errors.append(
                f"{name}: Docker workspace mount is {actual!r}, expected True"
            )

    return errors, env_has_value(root / ".env", expected["secret"])


def check_kanban() -> list[str]:
    path = HERMES_HOME / "kanban.db"
    if not path.exists():
        return ["kanban.db is missing"]
    try:
        with sqlite3.connect(path) as connection:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
            if integrity != "ok":
                return [f"kanban.db integrity check returned {integrity!r}"]
    except sqlite3.Error as exc:
        return [f"kanban.db could not be opened: {exc}"]
    return []


def check_security_floors() -> list[str]:
    errors: list[str] = []
    for package, floor in SECURITY_FLOORS.items():
        try:
            installed = version(package)
        except PackageNotFoundError:
            errors.append(f"security package is missing: {package}")
            continue
        if Version(installed) < Version(floor):
            errors.append(
                f"{package} is {installed}, below the security floor {floor}"
            )
    return errors


def main() -> int:
    errors: list[str] = []
    missing_secrets: list[str] = []
    for name, expected in EXPECTED.items():
        profile_errors, has_secret = check_profile(name, expected)
        errors.extend(profile_errors)
        if not has_secret:
            missing_secrets.append(f"{name}:{expected['secret']}")

    errors.extend(check_kanban())
    errors.extend(check_security_floors())

    if errors:
        print("CONFIG CONTRACT: FAIL")
        for error in errors:
            print(f"  - {error}")
    else:
        print("CONFIG CONTRACT: PASS")

    if missing_secrets:
        print("PROVIDER KEYS: PENDING (values were not inspected or printed)")
        for item in missing_secrets:
            print(f"  - {item}")
    else:
        print("PROVIDER KEYS: CONFIGURED (values not printed)")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
