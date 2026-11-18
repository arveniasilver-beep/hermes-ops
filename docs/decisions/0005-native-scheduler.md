# ADR 0005: Profile-Safe Native Scheduler

## Status

Accepted and implemented in Phase 5.

## Context

Hermes already had cron persistence and provider execution, but the desktop
surface treated jobs as globally unique ids, showed hard-coded delivery choices,
and lacked an explicit immediate-run contract. With isolated model profiles,
the same job id can legally exist in more than one profile. A mutation based on
search order could therefore inspect or change the wrong user's job.

## Decision

- Treat `profile:id` as the native UI identity and send the owner profile on
  every read and mutation.
- Reject ambiguous profile-less lookup with HTTP 409. Preserve profile
  inference only when exactly one matching job exists.
- Compile normal schedules through a structured editor while retaining a
  bounded custom field for existing cron expressions and natural durations.
- Discover delivery targets from the selected profile's gateway configuration;
  keep local desktop delivery available and disable missing external adapters.
- Queue immediate execution through a dedicated 202 endpoint. Install the
  profile's Hermes home and timezone context for the whole fire operation and
  reconcile the scheduler provider after persistent changes.
- Reuse the existing headless approval policy and shared spend guard. A schedule
  is never an exemption from command safety or budget enforcement.

## Consequences

Operators can manage scheduled work without the terminal, all-profile views can
show colliding ids safely, and editor choices map to backend-supported schedule
formats. Immediate runs return quickly while the work continues in the local
backend. External delivery is honest about configuration. Provider execution is
still asynchronous, so final success belongs in run history rather than the 202
response.

## Rollback

Use `scripts/start-hermes-desktop.ps1 -UseInstalledRuntime` to run the preserved
upstream installation. Phase 5 does not migrate or rewrite existing cron job
files; the managed UI can be removed without deleting schedules. Restore from
`backups/phase5-pre-scheduler-20260716-211531` only while Hermes is stopped if a
source-level rollback is required.
