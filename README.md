> **Upstream notice.** This project runs on the upstream
> [NousResearch Hermes Agent](https://github.com/NousResearch/hermes-agent)
> (MIT License, Copyright (c) 2025 Nous Research). Hermes Agent itself is **not
> included in this repository**: the operating copy is expected at
> `runtime/hermes-agent`, pinned to Hermes Agent `v0.18.2` / tag `v2026.7.7.2`,
> and that directory, our local modifications inside it, and all local runtime
> data are excluded. Everything here is our own work: `scripts/`, `templates/`,
> `tests/`, `patches/` (our security overlay for the upstream code), `tools/`,
> and `docs/` (including the architecture decisions in `docs/decisions/`).
> Absolute `C:\...` paths below describe the original Windows workstation.

# Hermes Personal Agent

## Project handoff and current truth

Claude or another technical lead must start with [`CLAUDE.md`](CLAUDE.md), then
read the complete
[`docs/CLAUDE-CODE-MASTER-HANDOFF.md`](docs/CLAUDE-CODE-MASTER-HANDOFF.md),
[`docs/PROJECT_MEMORY.md`](docs/PROJECT_MEMORY.md), and
[`docs/ROADMAP.md`](docs/ROADMAP.md). The broader Sovereign execution decision is
recorded in
[`docs/decisions/0009-sovereign-execution-platform.md`](docs/decisions/0009-sovereign-execution-platform.md).
The native Phase 8 surface and the Sovereign execution build are not yet one
signed desktop product; do not infer current runtime health from historical
acceptance records.

When moving the project to another Claude Code workspace or machine, follow
[`docs/CLAUDE-CODE-TRANSFER-CHECKLIST.md`](docs/CLAUDE-CODE-TRANSFER-CHECKLIST.md)
so the separate Sovereign source tree is not omitted and local credentials are
not copied.

This repository is the reproducible control package and managed development
runtime for Owner's local Hermes Agent installation. The current Phase 8 source
and package live at:

```text
C:\Users\MSI\Documents\HERMESAGENT\runtime\hermes-agent
```

The upstream installation remains available as the launcher fallback at:

```text
C:\Users\MSI\AppData\Local\hermes\hermes-agent
```

The installed release is pinned to Hermes Agent `v0.18.2` / tag
`v2026.7.7.2`. The architecture uses five isolated profiles and defaults to
the cheapest model that can reliably complete the task:

| Profile | Provider and model | Responsibility |
|---|---|---|
| `owner-orchestrator` | Xiaomi `mimo-v2.5` | Low-cost router, simple work, synthesis, final verification |
| `owner-fast-worker` | DeepSeek `deepseek-v4-flash` | Default routine text, data, web, test, and code execution |
| `owner-engineer` | DeepSeek `deepseek-v4-pro` | Expert architecture, security, diagnosis, and critical review |
| `owner-vision` | Xiaomi `mimo-v2.5` | Image, screenshot, audio, and video analysis |
| `owner-operator` | Xiaomi `mimo-v2.5-pro` | Complex browser, Windows UI, and multi-tool agent operations |

The native Hermes Electron application is the primary product surface. The
browser dashboard is retained only for explicit diagnostics and does not run at
Windows startup. Its **Operations** workspace exposes the live task board,
durable event and run history, pause/resume/cancel controls, enforceable monthly
spend limits, usage estimates, system health, logs, and maintenance without
leaving the desktop app. The native **Cron** route adds profile-safe recurring
and one-time work, configured delivery targets, run history, lifecycle controls,
and guarded immediate execution. Tasks that require a person now surface a
durable **Needs you** handoff with a redacted reason, a non-sensitive note, and
an audited return to the ready queue. Local Chromium challenges can also expose
the exact live page in observe-only mode, accept explicit user takeover, pop
into a dedicated window, and reconnect the worker after a mandatory fresh
snapshot. The
Windows host runs the control plane and UI automation.
Engineering shell commands run in a persistent Docker sandbox. Long work is
stored in Hermes' shared SQLite Kanban board instead of being kept only in chat
context. Triage auto-decomposition is limited to one task per dispatcher tick,
with two tasks globally and one task per profile allowed in progress.

See [`docs/ROUTING.md`](docs/ROUTING.md) for escalation rules. Direct Hermes
delegation cannot select a different model per child call in this release, so
cross-model routing deliberately uses durable Kanban assignees.

## First secure activation

API keys are intentionally not stored in this repository and must never be
pasted into chat. Enter them through the masked terminal prompts:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\configure-secrets.ps1
.\scripts\verify.ps1
```

Install the managed native entry point, then open **Hermes** from the desktop or
Start Menu:

```powershell
.\scripts\install-desktop-primary.ps1
```

The current Phase 8 wrapper is unsigned. The final package and managed launcher
start successfully on this host; the preserved installed runtime remains the
automatic fallback if Windows Application Control blocks a future hash or the
managed app fails readiness. Code signing is still required for a distributable
release.

For durable work, open **Operations > Tasks**, enter a concise task title, and
press the plus button. Select a task to inspect its timeline and attempts or to
pause, resume, or cancel it. Cancellation preserves the audit history. New
tasks are assigned to the active profile and may make paid provider calls when
the persistent dispatcher claims them. Use **Operations > Usage** for token and
estimated-cost totals and to set the shared monthly limit. The default $10 USD
guard covers every profile, interactive chat, and autonomous work. Unknown
provider prices are charged a conservative reserve instead of being treated as
free. Open **Cron** from the status bar to create or inspect scheduled work;
scheduled and immediate runs remain subject to the autonomous spend guard and
headless approval policy. If a card shows **Needs you**, use the local live
browser when it is available, select **Take control**, complete CAPTCHA, 2FA,
sign-in, or another private step, return to **View**, and press **Step
completed**. Never paste the secret into Hermes. When no live browser is
available, complete the step in the real app and optionally add a non-sensitive
note. Use **System** for health and logs.

Use **Operations > Maintenance** to create a verified portable recovery backup.
Desktop backups exclude API keys, OAuth credentials, authentication stores,
runtime locks, and logs; secret-shaped configuration values are redacted. Select
an archive and press **Inspect** to verify its SHA-256 manifest and review the
number of files that would be added or overwritten. **Restore** requires an
explicit confirmation and creates a separate pre-import recovery backup before
writing any file. Restart Hermes after a restore.

For command-line work, `owner-orchestrator` remains available. Any diagnostic
dashboard must remain bound to `127.0.0.1`. See
[`docs/OPERATIONS.md`](docs/OPERATIONS.md) for daily commands and
[`docs/SECURITY.md`](docs/SECURITY.md) for the approval boundary.

Review aggregate model use, current-price estimates, and Kanban outcomes with:

```powershell
python .\scripts\routing_report.py --days 30
```

## Reapply the managed contract

`bootstrap.ps1` is idempotent. It creates missing profiles and reapplies the
model, tool, Docker, memory, approval, backup, and Kanban policy without
touching API keys.

```powershell
.\scripts\bootstrap.ps1
```

See [`docs/PRODUCT_STATUS.md`](docs/PRODUCT_STATUS.md) for the verified product
surface and the remaining roadmap. The native-interface decision is recorded in
[`docs/decisions/0001-native-desktop-primary.md`](docs/decisions/0001-native-desktop-primary.md),
and the Operations workspace contract is recorded in
[`docs/decisions/0002-native-operations-center.md`](docs/decisions/0002-native-operations-center.md).
Durable task control is recorded in
[`docs/decisions/0003-durable-task-control.md`](docs/decisions/0003-durable-task-control.md),
and shared spend enforcement in
[`docs/decisions/0004-shared-spend-guard.md`](docs/decisions/0004-shared-spend-guard.md).
The profile-safe native scheduler is recorded in
[`docs/decisions/0005-native-scheduler.md`](docs/decisions/0005-native-scheduler.md).
The durable human-handoff boundary is recorded in
[`docs/decisions/0006-durable-human-handoff.md`](docs/decisions/0006-durable-human-handoff.md).
Local live-browser takeover and resume is recorded in
[`docs/decisions/0007-local-browser-takeover.md`](docs/decisions/0007-local-browser-takeover.md).
Verified portable recovery is recorded in
[`docs/decisions/0008-verified-portable-recovery.md`](docs/decisions/0008-verified-portable-recovery.md).
The decision to keep Sovereign Control Plane as the execution authority and
Hermes as a restricted worker is recorded in
[`docs/decisions/0009-sovereign-execution-platform.md`](docs/decisions/0009-sovereign-execution-platform.md).
