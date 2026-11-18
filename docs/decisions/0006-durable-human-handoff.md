# ADR 0006: Durable Human Handoff

## Status

Accepted and implemented in Phase 6.

## Context

Autonomous work can reach CAPTCHA, 2FA, account recovery, sign-in, payment, or
an explicit human confirmation. Hermes must stop without bypassing the check,
exposing a secret, losing task history, or resuming the wrong blocked state.
The Kanban worker already had a durable `needs_input` block, so a second handoff
store or transient chat-only prompt would create conflicting sources of truth.

## Decision

- Treat a currently blocked `needs_input` task as the canonical handoff state.
- Project only a bounded, force-redacted reason to the desktop and derive the
  **Needs you** list flag from current task status plus block kind.
- Let the user complete the private action outside Hermes. Accept only an
  optional, non-sensitive completion note; reject passwords, verification
  codes, tokens, payment details, and secret-shaped text at the API boundary.
- Resume through an expected-block-kind compare-and-swap. Commit the optional
  comment, `unblocked`, and `human_handoff_resolved` events in the same SQLite
  write transaction, then reuse normal dependency-aware readiness checks.
- Preserve the original block kind and recurrence history for loop detection.
  A resolved task is not considered **Needs you** unless it is currently
  blocked again.

## Consequences

The handoff survives desktop, gateway, and worker restarts; it is visible in a
dedicated filter and leaves an append-only audit trail. A stale click cannot
resume an unrelated blocked state. Hermes deliberately does not receive or
store the secret used in the external step.

This phase does not claim automatic CAPTCHA detection, live browser takeover,
or reconnection to an interrupted browser session. Those remain separate
product work built on this durable state transition.

## Rollback

Use `scripts/start-hermes-desktop.ps1 -UseInstalledRuntime` to run the preserved
upstream installation without deleting task data. Phase 6 adds no destructive
schema migration; older code ignores the additional audit kind. For a source
rollback while Hermes is stopped, restore only the changed files from
`backups/phase6-pre-human-handoff-20260716-222124`.
