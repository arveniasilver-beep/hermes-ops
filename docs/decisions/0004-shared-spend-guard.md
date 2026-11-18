# ADR 0004: Shared Spend Guard

## Status

Accepted and implemented in Phase 4.

## Context

Hermes can run interactive chats, scheduled work, and parallel Kanban workers
through several isolated profiles. Per-profile usage displays do not prevent a
profile switch or concurrent workers from exceeding the user's intended total.
Some newly released provider routes can also appear before the local canonical
pricing snapshot knows their exact price.

## Decision

- Store one versioned `spend-policy.json` at the shared Hermes root.
- Enable a $10 USD calendar-month cap by default for interactive and autonomous
  model calls. Keep both enforcement modes independently configurable.
- Aggregate `state.db` session costs across the default home and every named
  profile. Prefer a recorded actual charge; otherwise use the recorded estimate
  or the canonical pricing registry.
- Never classify an unknown route as free. Apply the greater of a conservative
  premium token estimate or the configured per-request reserve and report the
  count as inexact accounting.
- Fail closed when a session database or policy is unreadable.
- Insert a short-lived reservation into shared `spend-guard.db` before each
  provider request and release it after the request. The transaction includes
  active reservations when deciding whether the new request fits.
- Stop budget denials before provider retry/failover. Hold autonomous tasks in
  `ready` before claim so changing the policy or entering a new month makes them
  eligible without reconstructing task state.

## Consequences

The displayed estimate and the enforcement decision now share one accounting
contract. Parallel agents cannot independently consume the same remaining
budget, unknown models remain usable under a conservative allowance, and
operators can change the policy in the native Usage panel. Provider invoices
remain the authority for final billing and require a later reconciliation
feature.

## Rollback

Use `scripts/start-hermes-desktop.ps1 -UseInstalledRuntime` to run the preserved
upstream installation. In the managed build, disabling the main Usage-panel
switch preserves accounting but bypasses both gates. Removing
`%LOCALAPPDATA%\hermes\spend-policy.json` restores the documented defaults;
`spend-guard.db` contains only expiring reservations and can be removed while no
Hermes process is running.
