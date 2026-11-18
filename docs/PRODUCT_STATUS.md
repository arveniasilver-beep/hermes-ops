# Product Status

## Working vertical slice

The primary product is the native Hermes desktop application. The current
installation provides a real end-to-end path from the desktop composer through
the profile-pinned local backend to Xiaomi or DeepSeek and back as a streamed
answer. It also includes:

- five isolated model profiles and cost-aware durable routing;
- native conversations, session history, files, projects, artifacts, voice,
  settings, profile switching, tool progress, and approval surfaces;
- a native Operations workspace with bounded task creation/listing, filters,
  durable task timelines and run attempts, verified pause/resume/cancel
  controls, cross-profile monthly spend enforcement, usage and estimated cost,
  system health, logs, and maintenance;
- a native, profile-aware scheduler with structured daily, weekday, weekly,
  monthly, hourly, interval, one-time, and custom schedules; configured delivery
  targets; run history; pause/resume; edit/delete; and guarded immediate runs;
- durable **Needs you** handoffs for CAPTCHA, 2FA, sign-in, and explicit user
  checks, with redacted reasons, sensitive-note rejection, atomic resumption,
  append-only audit history, automatic browser-challenge classification, a
  local live view, explicit pointer/keyboard takeover, a dedicated window, and
  snapshot-gated reconnection to the same browser;
- loopback-only services, protected provider keys, secret redaction, manual
  approvals, checkpoints, and a Docker execution boundary;
- persistent Kanban dispatch, browser automation, and current-user Windows
  computer use;
- local validation, routing/cost reporting, verified portable backups, archive
  inspection, impact preview, and confirmed atomic recovery.

The managed launcher prefers the Phase 8 package under `runtime/hermes-agent`
and automatically falls back to the upstream installation when that package is
absent, blocked by Windows Application Control, or fails its readiness check.
`-UseInstalledRuntime` provides an explicit rollback path.

The exact Phase 8 packaged application archive passed isolated native startup,
portable-backup creation, archive inspection, confirmation, automatic
pre-import backup, and a 472-file zero-warning restore. Windows Application
Control blocks the newly generated unsigned outer executable, so the managed
launcher safely retains the trusted installed runtime fallback and the policy
was not weakened. Phase 8 is not claimed as a signed release.

## Deliberately not claimed complete

The broader product specification is a roadmap, not a completed-feature claim.
The following still require dedicated product work and acceptance tests:

- provider invoice import and reconciliation of local estimates with invoices;
- remote/cloud-browser relay and arbitrary Windows desktop takeover. Phase 7
  deliberately implements local agent-browser Chromium only;
- project-level export/import and encrypted memory controls;
- signed Phase 8 installer/update release automation that reapplies the security
  overlay and preserves the managed launcher contract;
- full accessibility, localization, offline, failure-injection, and upgrade tests;
- semantic multi-model routing directly inside one live chat turn. Cross-model
  routing currently uses explicit profiles and durable Kanban assignees.

These items are kept visible so the platform is not presented as finished when
only the first production-shaped vertical slice is verified.

## Sovereign execution platform track

The broader Manus-like execution product now has a separate working local build
at `Documents/Codex/2026-07-10/n/work/sovereign-agent`. Hermes is a restricted
reasoning worker inside that architecture rather than the authority for the whole
application. The isolated build has verified DeepSeek/MiMo routing, a real web
research deliverable, real Windows desktop capture through CUA Driver, and an
authenticated live computer view with an action-blocking human takeover gate.

This does not change the Phase 8 Hermes desktop claim above: arbitrary Windows
takeover is implemented in the Sovereign web product, not yet packaged inside the
signed native Hermes application. The merge and open-source decisions are tracked
in [ADR 0009](decisions/0009-sovereign-execution-platform.md).
