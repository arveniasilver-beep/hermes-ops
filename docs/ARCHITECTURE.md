# Architecture

## Decision

Hermes runs as a native Windows control plane with a Docker execution plane.
This hybrid is intentional: a fully containerized Hermes process cannot drive
the user's Windows desktop, while a fully local shell would give model-issued
commands the same filesystem authority as the logged-in user.

```text
Native Hermes desktop (primary)       Browser dashboard (diagnostics only)
              |                                     |
   loopback hermes serve                    loopback PTY/TUI gateway
              |                                     |
              +------------- owner-orchestrator ----+
      /          |          |          \
fast-worker  engineer    vision     operator
DS Flash      DS Pro     MiMo 2.5   MiMo Pro
      \          |          |          /
       Docker sandbox + browser + cua-driver
                    |
          Shared durable Kanban
```

## Control boundaries

- `owner-orchestrator` uses MiMo 2.5 for low-cost routing, simple work,
  synthesis, and final acceptance.
- `owner-fast-worker` is the default routine executor and receives Docker,
  file, code-execution, web, and semantic browser tools.
- `owner-engineer` receives the same technical execution boundary but is
  reserved for DeepSeek Pro architecture, security, diagnosis, and review.
- `owner-vision` receives multimodal and browser inspection, not host execution.
- `owner-operator` receives browser, computer-use, cron, and Kanban tools, not
  shell or code execution.
- Third-party plugins and MCP servers remain opt-in. No network listener is
  exposed beyond loopback.
- The native app is pinned to `owner-orchestrator` through Electron's supported
  `active-profile.json` contract. Its shared JSON-RPC/WebSocket client is the
  adapter boundary; the UI does not parse terminal output.
- The browser dashboard never autostarts. This avoids duplicate PTY/TUI process
  trees consuming active-session leases.
- Long work uses Hermes' shared SQLite Kanban board, atomic claims, profile
  workers, retries, heartbeats, and dependency links.
- The managed Phase 8 checkout under `runtime/hermes-agent` is the preferred
  source and packaged UI. It reuses the installed Python environment while
  keeping normal runtime data under `%LOCALAPPDATA%\hermes`.

## Native Operations workspace

- The Electron sidebar exposes **Operations** as a first-class product route.
- **Tasks** reads a bounded, redacted Kanban projection and creates only a
  title, active-profile assignee, and conservative defaults. Task body, result,
  workspace paths, claims, and failure excerpts are not returned to the UI.
- Task detail returns bounded, redacted event and run projections. The native
  two-pane workspace polls active tasks while visible and stops polling terminal
  tasks. Pause/cancel only commit after a local worker is confirmed stopped;
  resume re-evaluates parent dependencies. Cancellation preserves all history.
- A task blocked with `block_kind=needs_input` receives a derived **Needs you**
  projection and a redacted handoff reason. Completion uses a typed compare-and-
  swap endpoint. An optional non-sensitive comment, `unblocked` event, and
  `human_handoff_resolved` audit event commit in one SQLite transaction before
  the task returns to dependency-checked readiness. Passwords, one-time codes,
  tokens, payment details, and secret-shaped notes are rejected at the API
  boundary; the UI never asks Hermes to perform or store the private step.
- A local browser challenge may add a short-lived takeover projection to that
  same handoff. The desktop connects only to an agent-browser WebSocket on
  loopback, starts read-only, and sends input only after explicit user control.
  A dedicated Electron window receives its capability through sender-bound IPC
  and an opaque URL token. No cookie, page text, form value, CDP address,
  browser profile path, or full target URL crosses the API boundary.
- The blocked task owns a bounded browser lease. Cleanup preserves the browser
  only while that lease is valid. After the user resolves the handoff, the next
  worker reattaches to the same session but cannot navigate, click, or type until
  it has taken a fresh snapshot of the post-human page.
- **Usage** reads aggregate session records and reports provider tokens plus a
  managed current-price estimate. Missing historical estimates are recomputed
  in memory from canonical model pricing; source databases are not mutated.
- **Usage** also owns one policy at the shared Hermes root. The monthly cap
  aggregates every profile, prefers actual cost over estimates, conservatively
  prices unknown routes, and applies separately configurable gates to chat and
  autonomous work. Short-lived SQLite reservations serialize concurrent model
  starts so parallel agents cannot each spend the same remaining balance.
- **System** and **Maintenance** reuse Hermes' typed JSON-RPC contracts for
  health, logs, updates, restart, and diagnostics.
- List limits, input lengths, assignee shape, and priority ranges are enforced
  at the local API boundary even though the service is loopback-only.

## Verified portable recovery

- **Maintenance** creates portable backups by default. Provider `.env` files,
  OAuth and authentication stores, SSH/private-key material, live runtime locks,
  logs, and external memory-provider paths are omitted. Secret-shaped YAML
  values are redacted structurally instead of by text replacement.
- Every new archive carries a versioned `hermes-backup-manifest.json` with the
  exact path, byte size, and SHA-256 digest of each archived file. Inspection
  rejects traversal, absolute and drive paths, duplicate/case-colliding entries,
  links, encrypted members, excessive expansion, and manifest mismatches before
  any restore action is available.
- The inspection projection reports verified, legacy, or invalid status;
  portable and credential flags; categories; compressed and expanded size; and
  new, overwrite, and external-file impact. Legacy ZIPs can pass bounded CRC
  checks but are never presented as SHA-256 verified.
- Restore requires explicit desktop confirmation, re-verifies the archive,
  creates a full `pre-import-*.zip`, and writes each file through a same-directory
  temporary replacement. SQLite files are copied through the SQLite backup API.
  The manifest itself is metadata and is never restored into the profile.

## Native scheduler

- The status bar exposes **Cron** as a first-class native route. Jobs are listed,
  created, edited, paused, resumed, triggered, deleted, and inspected through
  typed loopback endpoints rather than terminal-output parsing.
- Every job projection carries its owning profile. UI identity is the composite
  `profile:id`, and every mutation sends the profile explicitly. An ambiguous
  legacy id without a profile fails with HTTP 409 instead of mutating whichever
  profile happens to be searched first.
- Structured editor modes compile to Hermes-supported cron, duration, or ISO
  schedules. Custom syntax remains available without weakening the normal
  editor's validation and numeric bounds.
- Delivery choices are discovered from the selected profile's configured
  gateway adapters. Unconfigured external destinations are not presented as
  working options; local desktop delivery remains available.
- **Run now** queues an immediate, profile-scoped fire through FastAPI background
  work. The provider receives the correct `HERMES_HOME`, timezone cache, and
  post-mutation reconciliation. It still passes through the shared spend guard
  and existing headless approval policy before any provider request.

## Model routing

- Main conversation, simple work, and routing: Xiaomi `mimo-v2.5`.
- Routine implementation: DeepSeek `deepseek-v4-flash`.
- Expert engineering: DeepSeek `deepseek-v4-pro`.
- Image, audio, and video input: Xiaomi `mimo-v2.5`.
- Operator reasoning: Xiaomi `mimo-v2.5-pro`; visual evidence is delegated to
  the `mimo-v2.5` auxiliary vision slot.

The Pro model is not treated as multimodal. This follows Xiaomi's current
model contract and avoids silently sending unsupported media to it.

## Cost and reliability controls

- Triage auto-decomposition uses MiMo 2.5 and is capped at one task per tick.
- Unmatched work defaults to DeepSeek Flash, never a Pro profile.
- Board concurrency is two tasks globally and one task per profile.
- API retries and dispatcher failure retries are capped at two.
- Context compression begins at 35 percent of the one-million-token window.
- Tool-loop hard stops are enabled.
- A $10 USD monthly spend guard is enabled by default for interactive and
  autonomous model calls. The Kanban dispatcher leaves tasks ready when the cap
  is unavailable or exhausted; task state and history are not discarded.
- Pre-update backups, verified portable recovery, and filesystem checkpoints are
  enabled.
- Pro use is limited to diagnosis/planning and an optional critical review;
  routine execution is demoted after a safe plan exists.
