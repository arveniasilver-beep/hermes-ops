# ADR 0008: Verified Portable Recovery

## Status

Accepted and implemented in Phase 8.

## Context

The upstream backup command produced useful ZIP files, but the desktop could
not distinguish a portable recovery archive from one containing credentials,
prove every member's content before restore, preview which files would change,
or provide an automatic rollback point. Restoring a malformed, hostile, stale,
or partially written archive directly into a live profile risks secret leakage,
path escape, state corruption, and an unrecoverable partial import.

## Decision

- Keep full backup available for controlled local administration, but make the
  desktop request portable mode. Portable mode omits API/OAuth/authentication
  stores, SSH and private-key material, profile-home credential trees, external
  memory paths, runtime locks, and logs. Parse YAML and clear secret-shaped
  values structurally.
- Add a reserved, versioned manifest containing archive mode, credential and
  omission metadata, and the exact path, byte size, and SHA-256 digest of every
  data member. Validate the generated portable archive before reporting success.
- Inspect before restore. Reject absolute, drive, traversal, duplicate,
  case-colliding, link, encrypted, oversized, over-expanded, CRC-invalid, or
  manifest-mismatched archives. Report categories and new/overwrite/external
  impact without mutation. Treat bounded legacy archives as legacy, not verified.
- Re-run inspection at restore time. Create a full timestamped pre-import backup
  first, then restore through same-directory temporary files and atomic replace.
  Use SQLite's online backup API for SQLite stores and never extract the manifest
  into the profile.
- Expose list, inspect, create, and restore through typed loopback endpoints.
  Require a valid inspection and an explicit desktop confirmation containing the
  overwrite/add impact before restore can start.

## Consequences

Portable archives can be moved between installations without carrying provider
credentials or transient runtime state, and corruption or ZIP path abuse is
detected before profile changes. Restore has a local rollback archive and avoids
half-written ordinary files. Full backups remain intentionally sensitive. An
archive without the new manifest remains usable only as visibly legacy data and
does not receive a verified badge.

The feature restores profile data, not the Hermes codebase. The application must
be restarted after import. Project-level selective export/import and encrypted
memory management remain separate roadmap work.

## Rollback

Use `scripts/start-hermes-desktop.ps1 -UseInstalledRuntime` to bypass the managed
Phase 8 package without deleting data. For a source rollback while Hermes is
stopped, restore only the changed files from
`backups/phase8-pre-verified-backup-20260717-003124`. The preserved Phase 7
package is under
`runtime/hermes-agent/apps/desktop/release/win-unpacked-phase7-20260717-005231`.
