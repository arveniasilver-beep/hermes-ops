# ADR 0003: Durable native task control

## Status

Accepted and implemented on 2026-07-16.

## Context

The first Operations task view exposed a bounded task list, but it did not show
the history of an execution or provide truthful operator controls. A desktop
button must not claim that a running worker was paused or cancelled while the
process is still alive, and task history must survive an operator stop.

## Decision

- SQLite remains the source of truth for task status, events, and run attempts.
- `paused` and `cancelled` are durable terminal-for-dispatch statuses.
- Pause and cancel terminate a locally owned worker first. The database state
  changes only after liveness verification; an unconfirmed termination leaves
  the task unchanged and returns a conflict.
- Resume rechecks parent dependencies and returns the task to `todo` or `ready`.
- The loopback API exposes bounded task detail plus pause, resume, and cancel
  commands. Projections omit prompts, results, paths, claim tokens, PIDs, raw
  errors, and free-form event metadata.
- The native Operations task workspace shows the event timeline and run attempts.
  It polls every two seconds only while the window is visible and the selected
  task is non-terminal. Cancellation requires confirmation and preserves history.
- The managed workspace build is the preferred desktop runtime. The previously
  installed Hermes tree remains an explicit launcher fallback.

## Consequences

Operator intent is auditable across restarts and task state cannot falsely move
past a live local worker. Remote-worker pause remains conservative: if Hermes
cannot prove ownership and termination, it refuses the transition. The API is
poll-based for now; a future event stream can replace polling without changing
the durable database contract.
