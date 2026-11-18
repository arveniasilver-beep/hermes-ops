# Validation Record

## Phase 8 verified portable recovery

- Added a versioned SHA-256 manifest, structural configuration redaction,
  portable credential/transient exclusions, bounded ZIP inspection, dry-run
  impact reporting, automatic pre-import recovery backups, SQLite-safe copies,
  and atomic per-file restore. Unsafe paths, links, encryption, duplicate or
  case-colliding members, compression abuse, and digest mismatches fail before
  profile mutation.
- Added typed loopback list/inspect/backup/restore endpoints and a native
  **Maintenance** workflow with Verified, Legacy, Invalid, and credential-state
  badges; category and add/overwrite impact; folder reveal; disabled invalid
  restore; and explicit destructive confirmation.
- Five focused backend archive-security tests and three selected web API tests
  passed. The native Maintenance interaction test, Python compilation,
  TypeScript checking, and targeted ESLint also passed. The broad backup file
  finished with 142 passed, 3 skipped, 3 deselected, and only two pinned
  Windows-specific failures: a slash-sensitive assertion and a POSIX `0600`
  mode assertion. The separate extensionless-wrapper failure remains in the
  excluded upstream profile-restoration class; no Phase 8 regression was found.
- The exact packaged `resources/app.asar` ran in the trusted Electron runtime
  with an isolated Hermes home and user-data directory. UI Automation created a
  472-file portable archive, displayed **Verified** and **Credentials excluded**,
  showed 472 overwrites and zero additions, required the expected confirmation,
  created `pre-import-20260716-221214-14600.zip`, and restored 472 of 472 files
  in 1.5 seconds with no warning. No real profile was restored.
- A second source dry run reported `valid=true`, `verified=true`,
  `includes_credentials=false`, no warnings, and the same 472-file impact. ZIP
  inspection found the manifest and zero credential, lock, or `logs/` entries.
- Production packaging passed with stamp commit
  `9de9c25f620ff7f1ce0fd5457d596052d5159596`, branch `managed-phase8`, and build
  time `2026-07-16T22:05:31.470Z`. SHA-256 is
  `07CA913C4797FCF094A8A42295CE8A8F9F98E918B98DEA0F4BBBDA3102891A03` for
  `Hermes.exe` and
  `AFE75EA05432479A0C743F29AA1D704E8158DED38DA3BC98D857E11712E86E38` for
  `resources/app.asar`.
- The outer executable is `NotSigned` and Windows Application Control blocked
  the new hash. The policy was not weakened; the managed launcher fell back to
  the trusted installed runtime, which remained running. No provider call,
  purchase, paid service, credential change, or real-profile restore was made.
- `scripts/verify.ps1` passed the complete local non-model gate: release and
  five-profile contracts, configured-key presence without disclosure, shared
  spend enforcement (`$1.0527` committed across six stores), gateway, computer
  use, Docker 29.4.1 and sandbox smoke, agent-browser 0.26.0, Playwright
  Chromium, and Kanban diagnostics.
- The full Electron platform run stayed at its recorded Windows baseline: 304
  passed, 3 failed, and 2 skipped. The failures are the existing POSIX release
  path and `bash -n` checks invoked with Windows paths. The full renderer run
  passed 1,162 tests and retained 27 upstream timing, stale-mock, locale, and
  implementation-assertion failures across 13 files. The focused Phase 8
  renderer test passed independently.

## Phase 7 local browser takeover

- Added post-navigation classification for CAPTCHA, 2FA, sign-in, payment, and
  sensitive-confirmation screens. A Kanban `needs_input` block can now preserve
  the exact local agent-browser session under a profile-scoped, time-bounded
  lease. Public API data contains only challenge kind, expiry, target origin,
  and a loopback WebSocket; cookies, page/form contents, CDP URLs, socket paths,
  session keys, and full target URLs are not projected.
- Added observe-only JPEG streaming, explicit pointer/keyboard takeover,
  reconnect, zoom, fullscreen, and a dedicated sender-bound Electron window.
  Non-loopback streams, credentialed URLs, stale capabilities, and leases over
  one hour fail closed.
- The broad focused backend set passed 101 tests. Desktop lint and TypeScript
  checking passed; 17 targeted jsdom tests and 18 Electron window/session tests
  passed. The existing Starlette deprecation and inaccessible pytest-cache
  warnings remain non-product warnings.
- A real 1280-by-720 Chromium stream produced JPEG frames. WebSocket-only user
  input entered `human42` and clicked the verification control. Hermes then
  classified the live page as `captcha`, emitted a 20-minute takeover, kept the
  browser across worker exit, rejected resumed navigation before observation,
  and reattached successfully after a fresh snapshot showing `human42`.
  Snapshot completion removed the public capability.
- Production renderer build and unpacked Windows packaging passed. The package
  stamp pins upstream commit `9de9c25f620ff7f1ce0fd5457d596052d5159596`
  under `managed-phase7`. SHA-256 is
  `D558CEBFCD640A1F2393E0BD720DB5C3D80DB62322F6699A7DB0237A153E1CC5` for
  `Hermes.exe` and
  `6DF2FB4536992783BB6A8BCBB48ABFAEE3BAB382ACA356FA9C0C93F3FE023DF0` for
  `resources/app.asar`.
- The exact Phase 7 package launched with isolated user data and Hermes home,
  started its source-backed Python service on loopback, mounted Kanban and cron,
  and accepted the renderer WebSocket without a startup error. No provider
  request, paid service, real account, or user task was used.
- The final `scripts/verify.ps1` run passed every local non-model group: release
  and five-profile contracts, configured-key presence without disclosure,
  shared spend enforcement (`$1.0455` committed across six stores), gateway,
  computer use, Docker 29.4.1 and sandbox smoke, agent-browser 0.26.0,
  Playwright Chromium, and Kanban diagnostics. The managed Phase 7 executable
  remained running with a direct `owner-orchestrator` backend after validation.
- Native UI Automation then opened the exact packaged
  `#/command-center?section=tasks` route. The Tasks workspace, **Needs you**
  filter, task timeline, attempts, gateway-ready state, and five profile
  controls were exposed without overlap at 1920 by 1020. Evidence is in
  `runtime/hermes-agent/artifacts/phase7-native-operations.png`.

## Phase 6 durable human handoff

- Reused the canonical Kanban `needs_input` block instead of adding a parallel
  handoff store. Task summaries expose a derived **Needs you** flag; detail
  returns only a bounded, force-redacted current reason.
- Added a typed resolution endpoint with expected-block-kind compare-and-swap.
  The optional desktop-user comment, `unblocked`, and
  `human_handoff_resolved` events commit atomically with dependency-aware task
  readiness. Password, verification-code, token, payment, and secret-shaped
  notes fail before any mutation.
- Focused backend task-control and web API suites passed 26 tests. The block and
  unblock regression subset passed 28 tests with 292 deselected. The only
  warning was the existing Starlette deprecation warning.
- Targeted desktop jsdom suites passed 15 tests covering the encoded bridge
  request, Needs-you filtering, safe completion, sensitive-note rejection,
  persistent error display, budget-panel integration, and timeline refresh.
  TypeScript checking and targeted ESLint passed.
- Production renderer build and unpacked Windows packaging passed. The package
  stamp pins upstream commit `9de9c25f620ff7f1ce0fd5457d596052d5159596`
  under `managed-phase6`. SHA-256 is
  `65BEE3AF869E33EA4AD7FFAFC999AC0F703017B8DCC68D5B5C7ECF940C907D7A` for
  `Hermes.exe` and
  `6B5285F2002DE462513C23845D835473B4B49520B0C61F5A9F4FEDB3439B40D7` for
  `resources/app.asar`.
- The exact packaged archive ran against an isolated SQLite board through the
  trusted Electron runtime. Native and renderer automation verified wide and
  minimum window layouts, rejected `OTP 123456`, kept the readable error visible
  across background polling, then accepted `Signed in successfully` and showed
  Ready plus Commented, Unblocked, and Human Handoff Resolved history. No model,
  provider, real account, or user board was touched.
- Direct final-wrapper smoke and `scripts/start-hermes-desktop.ps1` both reached
  readiness from the managed Phase 6 path with a direct Python child. The binary
  remains `NotSigned`; fallback behavior stays enabled for future policy blocks
  or readiness failures.
- Isolated database inspection confirmed one `desktop-user` comment, `ready`
  status, no current run, and the expected final audit event payload. Evidence
  is in `runtime/hermes-agent/artifacts/phase6-handoff-wide.png`,
  `phase6-handoff-narrow.png`, `phase6-handoff-rejection-renderer.png`, and
  `phase6-handoff-resolved.png`.
- The final `scripts/verify.ps1` run passed all local non-model groups: release
  and profile contracts, configured-key presence without disclosure, the shared
  spend guard (`$1.0377` committed across six stores), gateway, computer use,
  Docker 29.4.1 and sandbox smoke, browser dependencies, and Kanban diagnostics.

## Phase 5 native scheduler

- Added profile-explicit cron list/create/update/pause/resume/trigger/delete and
  run-history clients, collision-safe backend lookup, configured delivery-target
  discovery, provider reconciliation, and a queued **Run now** endpoint.
- Added a structured schedule editor for daily, weekdays, weekly, monthly,
  hourly, interval, one-time, and custom schedules. All-profile creation selects
  an owner, while list keys, selection, mutations, and history use `profile:id`.
- The focused Python scheduler suite passed 79 tests. The existing web-server
  cron subset passed 6 tests with 352 deselected. Both runs emitted only the
  existing Starlette deprecation warning.
- Targeted jsdom tests passed 14 cases covering schedule compilation, every
  profile-preserving cron URL, active-profile loading, and owner-correct
  immediate execution. TypeScript checking, targeted ESLint, and Python bytecode
  compilation passed.
- Production renderer build and unpacked Windows packaging passed. The package
  stamp pins upstream commit `9de9c25f620ff7f1ce0fd5457d596052d5159596`
  under the local `managed-phase5` branch label. The unpacked executable SHA-256
  is `7613C283720CB136750A798EC3D90EA3B0550C825EAA9B39DB235D15215660C2`.
- Windows Application Control blocked the newly generated unsigned outer
  `Hermes.exe` with `0x800711C7`; the policy was not weakened. Visual acceptance
  therefore launched the exact packaged `resources/app.asar` with the already
  trusted installed Electron runtime. Signing the release wrapper remains a
  release requirement, not a scheduler-code failure.
- The managed launcher now catches a blocked start and also detects a managed
  process that never reaches desktop/backend readiness. Either case falls back
  to the preserved installed runtime without weakening Windows policy. A live
  repeat-launch check retained the same healthy installed process instead of
  restarting it.
- Native UI Automation inspected the Cron route, all eight frequency choices,
  the one-time date/time control, and configured desktop delivery. Wide and
  minimum supported window checks showed no overlap, clipping, or unusable
  controls. Evidence is in
  `runtime/hermes-agent/artifacts/phase5-cron-wide.png`,
  `runtime/hermes-agent/artifacts/phase5-cron-editor-wide.png`,
  `runtime/hermes-agent/artifacts/phase5-cron-frequency-menu.png`,
  `runtime/hermes-agent/artifacts/phase5-cron-once-wide.png`,
  `runtime/hermes-agent/artifacts/phase5-cron-once-narrow.png`, and
  `runtime/hermes-agent/artifacts/phase5-cron-narrow.png`.
- No cron job was saved, no model was invoked, no delivery was sent, and no
  spend policy was changed during visual acceptance.
- The final `scripts/verify.ps1` run passed every local non-model group: release
  and profile contracts, configured-key presence without disclosure, shared
  spend enforcement (`$1.0377` committed across six stores), gateway, computer
  use, Docker 29.4.1 and sandbox smoke, browser dependencies, and Kanban
  diagnostics.

## Phase 4 shared spend guard

- Added one atomic shared policy, calendar-month accounting across the default
  home and all five profiles, conservative charging for unknown model prices,
  and a transactional SQLite reservation ledger for concurrent requests.
- Interactive and autonomous provider calls now stop before network execution
  when denied. The provider retry/failover loop treats the denial as
  deterministic and returns it once. The Kanban dispatcher holds tasks in
  `ready` before claim, preserving state and history.
- Seven spend-guard tests cover atomic validation, actual-over-estimate
  precedence, profile aggregation, unknown-price fallback, concurrent
  reservation exclusion, both enforcement modes, corrupt accounting, and
  unclaimed Kanban behavior. The focused backend integration set passed 17
  tests; Kanban/API regression files passed 37 tests.
- Desktop TypeScript checking and targeted ESLint passed. The native budget and
  durable task interaction tests both passed under jsdom.
- Production renderer build and unpacked Windows packaging passed. The package
  stamp pins upstream commit `9de9c25f620ff7f1ce0fd5457d596052d5159596`
  under the local `managed-phase4` branch label. The unpacked executable SHA-256
  is `C1BB3E466E9602E3941512721E828D9549CC3573287BE5964045DDB6DEB3511E`.
- The exact unpacked `Hermes.exe` was launched through the managed profile
  launcher and exercised with `cua-driver 0.8.2`. Operations navigated to the
  real `section=usage` route. UI Automation exposed 90 elements including the
  progress bar, limit and warning inputs, interactive/autonomous switches, and
  Save control.
- Live cross-profile accounting displayed `$1.04 / $10.00`, `$8.96` remaining,
  and two conservatively estimated unpriced records. Wide and minimum native
  window checks showed no overlapping or out-of-bounds controls; overflow
  remained vertically scrollable. Evidence is in
  `artifacts/phase4-native-budget.png` and
  `artifacts/phase4-native-budget-narrow.png`.
- No paid model call, task submission, or policy mutation was made during Phase
  4 acceptance.
- The final `scripts/verify.ps1` run passed every non-model group after Docker
  Desktop was started: configuration, provider-key presence, the shared $10
  spend guard (`$1.0377` committed across six profile stores), gateway,
  computer use, Docker 29.4.1, Python/Node sandbox smoke, browser dependencies,
  and Kanban diagnostics.

## Phase 3 durable task workspace

- Added durable `paused` and `cancelled` states, dependency-aware resume, run
  closure, and append-only operator events in SQLite.
- Added bounded/redacted task detail plus pause, resume, and cancel loopback API
  endpoints. Eight control tests cover schema migration, audit history, parent
  gates, terminal rejection, real local termination, and refusal when a worker
  remains alive.
- Focused backend acceptance passed: 22 Python database, API, validation, and
  pricing tests. The task panel interaction test, TypeScript check, and targeted
  lint also passed.
- A real loopback API and isolated SQLite home were exercised through the
  rendered task workspace as a user: resume, pause, confirmed cancel, terminal
  control removal, and exact `created -> paused -> resumed -> paused ->
  cancelled` event order all passed. No model/provider request was made.
- Visual checks passed at 720x900 and 1440x900 with no horizontal overflow,
  out-of-bounds controls, or mobile list/detail gap. Evidence is under
  `artifacts/phase3-user-test/`.
- Production renderer build and unpacked Windows packaging passed. The managed
  package is `runtime/hermes-agent/apps/desktop/release/win-unpacked/Hermes.exe`.
- The packaged Phase 3 window was subsequently launched in the interactive
  Windows host session before Phase 4. `cua-driver` verified the exact managed
  executable, `owner-orchestrator` backend, Tasks route, durable timeline, and
  attempts view without making a provider call.

## Completed locally

- Windows, CPU, RAM, disk, GPU, Docker, WSL, Python, Node, Git, and browser audit.
- Hermes Agent `0.18.2` installed from tag `v2026.7.7.2`.
- Python dependencies and baseline imports verified.
- Desktop Electron app built and shortcuts created.
- `agent-browser` and Playwright Chromium detected by `hermes doctor`.
- Five profile configs parsed at schema version 33.
- Tool contracts separated by role.
- Shared Kanban database initialized and integrity checked.
- Docker daemon detected.
- `cua-driver-rs 0.8.2` installed; UIAutomation and Windows Graphics Capture
  probes passed. Current-user autostart is used instead of elevated UAC access.
- Loopback-only dashboard built and verified over HTTP on `127.0.0.1:9119`,
  then demoted to an explicit diagnostic surface rather than an autostart UI.
- Official native Electron application selected as the primary product surface;
  its backend uses Hermes' supported loopback `serve` contract.
- Native UI live-chat test created a session, called Xiaomi `mimo-v2.5`,
  streamed `MASAUSTU_CALISIYOR`, and persisted the completed conversation.
- Dashboard PTY workers that occupied the `2/2` active-session lease limit were
  removed; only gateway and computer-use remain in Windows Startup.
- Managed launcher process detection is bound to the native executable's full
  path, so Windows' case-insensitive `hermes.exe`/`Hermes.exe` names cannot make
  desktop recovery terminate the persistent gateway.
- Gateway process starts without a messaging adapter and hosts the durable
  Kanban dispatcher; external messaging remains disabled.
- Hermes OSV audit findings from the upstream lock are remediated by a local,
  version-pinned runtime overlay and rechecked after installation.
- Aggregate routing report reads profile session stores and Kanban attempts
  without reading provider secrets.
- Synthetic SQLite unit test verifies token-price, cache, completion-rate, and
  retry aggregation, including clean database-handle closure on Windows.
- Hermes OSV scan covered 107 components with no known findings; npm reported
  zero production dependency vulnerabilities.
- Provider credentials configured through masked prompts; the contract check
  confirmed presence without printing key values.
- One live, tool-free API smoke call completed for every project profile:
  MiMo V2.5 router, DeepSeek V4 Flash worker, DeepSeek V4 Pro engineer, MiMo
  V2.5 vision, and MiMo V2.5 Pro operator.
- The running gateway claimed a ready card assigned to `owner-fast-worker` and
  completed it once, without retry, in 11 seconds.
- Native **Operations** navigation was verified in the packaged Electron app.
  Tasks showed live Kanban state; Usage showed live tokens and a nonzero MiMo
  estimate; System and Maintenance remained available through typed routes.
- The Operations API passed 26 focused tests covering bounded/redacted task
  projection, task creation validation, usage backfill, and Xiaomi pricing.
- Desktop type checking, targeted linting, formatting, Python compilation,
  production build, and unpacked Windows packaging all passed after the change.
- Live desktop checks covered a normal and 720-by-700 viewport with no
  horizontal overflow or task-control overlap. No paid live task was submitted
  during UI validation.

## Additional live validation

- Live Xiaomi `mimo-v2.5` image, audio, and video tests.
- Model-driven Docker, browser, and computer-use tool calls against disposable
  targets; the underlying local tools have already passed non-model checks.
- End-to-end Kanban handoffs for the engineer, vision, and operator profiles.
- Restart-resume test with the persistent gateway dispatcher.

Use `scripts/configure-secrets.ps1` to rotate credentials, then run
`scripts/verify.ps1`. Live tests must use small prompts and record usage without
writing key material to artifacts.

## Known upstream test baseline

The desktop TypeScript check passes. The pinned upstream source's broad test
commands are not fully green on this Windows checkout and were not changed to
hide that fact:

- `test:desktop:platforms`: 304 passed, 3 failed, 2 skipped. The failures are
  POSIX path/bash assertions executed with Windows paths.
- `test:ui` is now scoped to `src` so generated `build/` and `release/`
  `node-pty` tests are not imported. The broad source suite still has known
  upstream timing, locale, and implementation-assertion failures; the focused
  Phase 3 task workspace, Phase 4 budget panel, Phase 5 scheduler, and Phase 6
  handoff tests pass.

The product-specific PowerShell validation, focused phase suites, packaged
native acceptance, and native live-chat test remain the acceptance gate for
this vertical slice. The upstream suite debt is tracked as a release risk
rather than being represented as product completion.

A broad Kanban/Python run during Phase 3 produced 231 passes and 14 existing
Windows-specific failures involving POSIX wait status/zombie reaping, slash
normalization in Git worktree assertions, and environment-sensitive executable
resolution. The focused Phase 3 acceptance suite is green; these upstream
cross-platform failures were not hidden or rewritten as feature fixes.

## Sovereign execution acceptance, 17 July 2026

The isolated Sovereign product was accepted against
`http://127.0.0.1:4321` with its own data directory and model profiles. The
source rollback archive is
`backups/sovereign-agent-source-20260717-015654.zip`.

- Full workspace test run: 119 passed, 0 failed. This includes 92 control-plane
  tests, five Computer Worker tests, and the action-blocking takeover test.
- Full workspace TypeScript check passed for 11 projects.
- Full production build passed; the web build transformed 1,645 modules.
- Dedicated DeepSeek planning/chat and MiMo critic routes completed live calls
  and recorded token provenance without exposing provider secrets.
- A public `https://example.com/` task completed with title/main-message
  evidence and a verified `research-result.json` artifact.
- A real Windows `computer.inspect` task captured the current 1920x1080 desktop
  through CUA Driver with zero input actions, four evidence records, and three
  artifacts. The decoded PNG was visually inspected.
- The authenticated Computer page loaded the real desktop frame, changed from
  agent to human ownership with **Take over**, blocked the next agent action,
  and returned control with **Return to agent**.
- The System page reported Computer Worker as connected with Windows CUA, UI
  Automation, and Windows Graphics Capture. All DeepSeek/MiMo model roles were
  connected.
- Browser acceptance passed at 1280x720 and 390x844. The mobile run found an
  18-pixel navigation overflow; hiding the redundant mobile runtime badge fixed
  it, and the repeated measurement was `scrollWidth == clientWidth`.
- The global Refresh command now requests `/api/system`; a live server trace and
  the updated `Playwright + optional Skyvern` card verified the correction.
- MCP Bridge changed from an all-interface bind to `127.0.0.1:4319` by default;
  its authenticated contract test, typecheck, build, loopback listener check,
  and live upstream health probe all passed.

Not accepted as live capability: Agent-S/GUI-Owl visual planning, Browser Use,
live model-driven OpenHands code generation, persistent takeover ownership
across worker restart, and a signed native package containing the Sovereign UI.
Those remain explicit release work, not implied functionality.

## Handoff consistency audit, 18 July 2026

This audit rechecked the handoff against both source trees, local profile names,
the rollback archive, Git visibility, ports, and current test commands. It does
not replace the successful 17 July acceptance because the runtime was not
running and the current session could not reproduce the complete environment.

- Sovereign TypeScript check passed for all 11 participating workspace projects.
- `tests/test_routing_report.py` passed (`1 passed`).
- A new full `pnpm test` attempt did not complete cleanly. MCP Bridge failed with
  Windows `ENOBUFS`; a minimal Node loopback listen reproduced the same OS-level
  error. The MCP test also left its fixed `127.0.0.1:4601` process open after the
  early failure and required targeted process cleanup. This is now release work,
  not counted as a product pass.
- A production-build retry was blocked after the workspace permission profile
  changed: TypeScript could not read the external Sovereign source tree and
  returned `EPERM`. This is a session sandbox result, not a source compile error;
  the last completed build remains the 17 July acceptance.
- `verify_config.py` could not inspect profile-local `.env` files under the new
  read-only policy. No secret values were printed. The test result is therefore
  `not run`, not failed configuration.
- Docker daemon was stopped. No project listener was present on 4310-4319,
  4320-4321, 4601, or 8642-8644 after cleanup.
- Three profile directories exist: `sovereign-mimo`, `sovereign-deepseek`, and
  `sovereign-hermes`. The persisted Sovereign `.env` names only the DeepSeek
  8643 route; MiMo/Hermes lifecycle is not reproducible from a repository script.
- The source rollback ZIP opened successfully: 536 entries, 1,988,680 bytes,
  SHA-256 `31d0d84b6f0e9274d4041d3d98c59ac1c99148ff05b5a166eb7ddd7d8a5ede0a`.
  It contains build output and dependency directory entries, so it is a rollback
  snapshot rather than a clean source-release archive. No real `.env`, private
  key, credential, or token file name was found.
- HERMES had 6,303 untracked files. `backups/`, Sovereign audit data, gateway-log
  state, and runtime screenshots were added to `.gitignore`; 6,205 untracked
  source/control files remain for a deliberate baseline. No files were staged
  or committed. The repository has an unborn `master` branch and no valid
  `HEAD` revision.

Open findings and exact next actions are recorded in `docs/ROADMAP.md` and
`docs/AUDIT-2026-07-18.md`.

## P0-A source-control baseline, 19 July 2026

- Pre-checks: the Sovereign write probe passed (no `EPERM`); the system-level
  `core.autocrlf=true` was neutralized with repo-local `false` plus a `* -text`
  `.gitattributes` in both repositories; `core.longpaths=true`; a global Git
  identity was present and used.
- HERMESAGENT: staged 6,212 files through an explicit pathspec allowlist (root
  documents, `docs/`, `patches/`, `scripts/`, `templates/`, `tests/`,
  `runtime/hermes-agent`). Forbidden-name and forbidden-directory scans over
  the staged list returned zero matches. A masked content scan found
  secret-shaped strings only in upstream placeholder/example/test files; all
  four `.env.example` matches are commented placeholder lines. Root commit
  `152bf9a98ccb5a48f6b1691fa2751ba197c5c219`, annotated tag
  `baseline-hermes-20260719`.
- Sovereign: hardened `.gitignore`, `git init -b master`, staged 220 files by
  explicit allowlist. `git check-ignore` proved exclusion of the real `.env`,
  generated `qa/` evidence, `data/` runtime state, the `{console.error(e.code)`
  leftover, `*.tsbuildinfo`, `node_modules/`, and `dist/`. Masked scans matched
  only `.env.example` (7/7 safe-patterned), `infra/compose.core.yml` (6/6
  dev-default-patterned), and `runtime-config.test.ts` (synthetic production
  preflight fixture constants; rotate before any future remote push). Root
  commit `9ca47c7622923b51eaab3fa504de4393153d8771`, annotated tag
  `baseline-sovereign-20260719`.
- Rollback artifacts (corrected after the Codex review on the same day): the
  canonical bundles are `backups/hermes-baseline-20260719-canonical.bundle`
  (SHA-256 `092501d07fef85a12fc6edc89dcd5b3a5fcf24accac2fa57fbab3abf81d762b1`)
  and `backups/sovereign-baseline-20260719-canonical.bundle` (SHA-256
  `bcedac1bfcee6afcc13cfdf8e283e95baacdfb76f5a2dcf9e42ffe73c849ca92`). Each
  carries only `HEAD`, `refs/heads/master`, and its own annotated baseline tag,
  and `git bundle verify` reports a complete history for both. The first
  HERMES bundle additionally carried an unexpected
  `refs/codex/turn-diffs/checkpoints/...` ref and both original bundles remain
  on disk uncorrected pending user-approved cleanup. Bundles carry tracked
  source/history only; excluded QA PNG evidence exists only on the local disk.
  The first-commit undo command is `git update-ref -d refs/heads/master` (the
  working tree is untouched).
- Not run in this slice: `pnpm test`, `pnpm typecheck`, `pnpm build` (deferred
  to P0-C), any service or model call, and any remote/push operation.

## P0-B Phase 1 gateway lifecycle service, 19 July 2026

- New `scripts/sovereign-gateway-service.ps1` (ADR 0010): per-user Scheduled
  Task architecture, `plan|install|status|start|stop|uninstall`, dry-run by
  default, mutations only behind `-Execute` plus ShouldProcess, loopback-only
  expectation, FOREIGN/NONLOOPBACK fail-closed, single process snapshot,
  launcher-child tree resolution, stale-PID comparison against the previous
  receipt, profile-scoped stop (never `--all`), redacted JSON receipts under
  the gitignored `runtime/sovereign-hermes-gateways/receipts/` directory.
- Parser check passed for the new service script, its test file, and the
  historical `sovereign-gateways.ps1` (0 syntax errors). PSScriptAnalyzer is
  not installed and was deliberately not added as a new dependency.
- `tests/test_sovereign_gateway_service.ps1`: **40/40 mock assertions passed**
  covering dry-run zero-side-effect, install/start idempotency, port-collision
  FOREIGN fail-closed (plan, refusal, and execute-throw), stale/recycled PID
  detection, launcher-child-grandchild tree membership, other-profile
  exclusion, secret redaction, receipt schema and file write, redaction of
  receipt content, profile-scoped stop, install-plan task definition, missing
  hermes.exe fail-closed, and the SGS-GUARD mutation gate.
- The first test run failed 1/40 and exposed a real Turkish-locale bug: .NET
  regex `IgnoreCase` folds case with the current culture, so uppercase
  `API_KEY` did not match `api` under tr-TR (dotted/dotless i). Fixed with
  `RegexOptions.CultureInvariant`; rerun 40/40.
- Safe live read-only measurement (no gateway mutation, local `/health` GET
  only): all three gateways `RUNNING`, loopback-only, `HTTP 200`, process
  trees of three PIDs each, zero stale PIDs, scheduled tasks not installed
  yet (expected). Redacted receipt:
  `runtime/sovereign-hermes-gateways/receipts/receipt-status-20260719-030303.json`
  (4,354 bytes; post-write secret-pattern scan clean).
- Not run in this phase: real `Register-ScheduledTask`/`Unregister-ScheduledTask`,
  real gateway start/stop, reboot acceptance, and any paid provider probe.
  Those remain Phase 2 work requiring explicit user approval.

## P0-B Phase 1 review fixes (r2), 19 July 2026

- All six Codex findings were implemented: FOREIGN_TASK ownership proof
  (dedicated `\Sovereign\` TaskPath + description marker + current-user
  principal + full action/trigger/RunLevel comparison; unproven tasks are
  fail-closed and never modified/deleted; same-name tasks under other paths
  are never touched), truthful v1.1 receipts (requestedExecute /
  whatIfRequested / appliedCount / declinedCount / failedCount /
  effectiveDryRun / outcome plus per-step results; error and fail-closed
  paths also write redacted receipts; filenames use UTC milliseconds plus a
  nonce), previous-receipt selection that only accepts the newest valid
  observation receipt carrying `treePids` and skips plan/corrupt files,
  token-level process identity honoring Windows quoting (exact `-p
  <profile>`/`--profile <profile>` pair plus adjacent `gateway run` tokens),
  a secretless health probe (no environment credential is read; an
  authenticated probe is explicitly deferred as a separate approval topic),
  and NONLOOPBACK handling documented as containment-stop on the proven
  exact-owned tree only (start remains fail-closed).
- Test suite: **70/70 mock assertions passed**, including execute-flow
  measurements with fake ShouldProcess and logging wrappers (mutation
  targets, execute-mode proof, declined/failed step records, zero-mutation
  proofs for foreign tasks and WhatIf).
- The expanded tests caught two additional real PowerShell 5.1 defects that
  were fixed: `@(command)` double-wrapping of a comma-returned array
  (Count=1, breaking the matcher) and an ArgumentException from `@()` over a
  `List[object]` step log (replaced with a plain array).
- Live read-only status with the fixed script (secretless probe): all three
  gateways `RUNNING`, loopback-only, `HTTP 200`, identical process trees to
  the earlier measurement, zero stale PIDs, schema 1.1 receipt
  `receipt-status-20260719-002335-460-38f7.json`, post-write secret scan
  clean. Parser: 0 errors.
- Still not run (Phase 2, user approval required): real task
  install/uninstall, real gateway start/stop, reboot acceptance, paid
  provider probes.

## P0-B Phase 2A live install and stop/start acceptance, 19 July 2026

- User approval was given for the whole of Phase 2; this slice deliberately
  executed only Phase 2A (no reboot, no provider/model call, no new
  listener, no remote/push, no secret read/print).
- Preflight (redacted receipts `receipt-status-20260719-093105-*` and
  `receipt-plan-20260719-093113-*`): all three gateways were found DOWN with
  the previous session-started PIDs reported as stale — live proof of the
  Phase 2 rationale (session processes did not survive). `\Sovereign\`
  contained 0 tasks, ports were free, no FOREIGN_TASK, so the fail-closed
  preconditions passed.
- The first real `install -Execute` failed safely (outcome=failed, 0
  mutations, receipts `receipt-install-...-7231ae2e/-6b20ae70`): scriptblocks
  bound with `GetNewClosure()` execute in a new dynamic module scope and
  cannot see script functions in a real `-File` run (mock runs did not
  reproduce this). Fixed by passing parameters explicitly via `-BodyArgs`
  without closures; parser 0 errors and the 71/71 suite stayed green.
- Real install then succeeded: 3/3 `register-task` applied
  (`receipt-install-20260719-093447-139-09837c2b.json`). Raw re-read of the
  created tasks confirmed every verified field: actionCount=1, exact
  exe/args/workdir, triggerCount=1, `MSFT_TaskLogonTrigger` enabled with
  trigger user `DESKTOP-IDOTAMK\MSI`, principal `MSI` Interactive/Limited,
  ownership marker present. A second `install -Execute` returned 3/3
  `skip (idempotent)` (`receipt-install-20260719-093504-681-49217969.json`),
  which also proves ownership+config verification passes on the real objects.
- Per-profile acceptance cycles ran sequentially (adapted to the DOWN
  pre-state: task-owned start -> RUNNING accept -> profile-scoped stop ->
  DOWN accept -> task-owned start -> RUNNING accept; the other routes were
  left untouched and later verified still RUNNING):
  - `sovereign-mimo`: start applied via exact `\Sovereign\` task; RUNNING,
    loopback-only, secretless health `HTTP 200`, tree 16736/21392/24512;
    stop applied -> tree gone, port 8642 closed, old PIDs correctly reported
    stale; second start -> new tree 7680/7796/18488, `HTTP 200`
    (receipts `...-045889d7`, `...-6fb1edf4`, `...-568720a0`, `...-25c31f0a`,
    `...-25bdd7fb`).
  - `sovereign-deepseek`: same cycle clean; trees 9876/4084/25580 then
    7916/16064/14056; port 8643 closed on stop; `HTTP 200` both starts
    (receipts `...-2180975b`, `...-0b986065`, `...-7d9e949b`, `...-5f380251`,
    `...-140142a8`, `...-8bb28f88`); `sovereign-mimo` verified still RUNNING
    afterwards.
  - `sovereign-hermes`: same cycle clean; trees 23904/13672/3960 then
    6176/12692/6012; port 8644 closed on stop; `HTTP 200`
    (receipts `...-943aa0e1`, `...-001495c8`, `...-f200ddaa`, `...-1e281948`,
    `...-a74b87e5`).
- Final state (`receipt-status-20260719-094739-700-b4d2e73c.json`): 3/3
  RUNNING, loopback-only listeners, secretless health `HTTP 200` on all
  routes, `taskOwned=True` and `taskConfigMatches=True` for all three,
  `\Sovereign\` task count 3/3, post-write secret-pattern scan clean. No
  `gateway stop --all` was ever used; no foreign process or task was touched.
- Rollback recorded: `-Action uninstall -Execute` removes only the three
  proven-owned tasks; a subsequent `start` would fall back to the deliberate
  `start-direct` path; the docs/code change is revertable via git.
- Explicitly NOT run in this slice (Phase 2B, after Codex review of this
  evidence): Windows reboot acceptance and the small paid provider probes.

## P0-B Phase 2A review fix: hidden launcher architecture (r4), 19 July 2026

- Codex's blocking finding (visible terminal windows from direct hermes.exe
  task actions) was reproduced and fixed. Two additional real defects were
  caught live and fixed: (1) dot-sourcing the service script inside the
  launcher re-ran its param block and clobbered `$GatewayProfile` to `all`
  (hermes was started with `-p all`, died, launcher exited 3 with a truthful
  failed receipt; fixed by copying params to private names before the
  dot-source plus a fail-closed guard that rejects any non-exact profile);
  (2) with Windows Terminal as the default terminal, even
  `powershell -WindowStyle Hidden` opened a visible WT tab for the wrapper,
  so the whole console chain now runs under `conhost.exe --headless`
  (task action and the hermes child). A named-mutex duplicate guard was
  replaced by a per-profile file lock (FileShare::None) because mutexes are
  reentrant on the same thread.
- New `scripts/sovereign-gateway-launch.ps1`: no secrets, file-lock duplicate
  suppression, read-only reuse of the lifecycle status logic
  (RUNNING=idempotent exit 0; FOREIGN/NONLOOPBACK/PARTIAL=fail-closed exit 2
  with zero process starts; DOWN=hidden start with stdout/stderr redirected
  under the gitignored `runtime/sovereign-hermes-gateways/logs/`, then a
  timeout-bounded RUNNING+loopback acceptance; on timeout only the
  token-proven own profile tree is cleaned, exit 3), and a redacted launcher
  receipt for every outcome.
- Test suite grew to **83/83** (launcher idempotent/fail-closed/hidden-start
  /timeout-cleanup/file-lock-duplicate/invalid-profile tests, conhost task
  action assertions, plus the environment-robust dispatcher WhatIf outcome).
- Live acceptance with the running gateways untouched during install:
  drift-recreate applied 6/6 (receipt `receipt-install-20260719-101553-*`),
  raw task fields re-read (Execute=`C:\WINDOWS\System32\conhost.exe`,
  Arguments=`--headless "<powershell>" ... -File "<launcher>"
  -GatewayProfile <exact>`, single action/trigger, principal
  MSI/Interactive/Limited), then per-profile consoleless cycles
  (stop -> task start): mimo, deepseek, hermes all reached
  RUNNING/loopback/HTTP 200 with fresh trees; every stop closed the port and
  pushed the old PIDs into live stale detection; the old visible consoles
  died naturally with their profiles' stops.
- Window evidence (process metadata only, no UI automation): baseline one
  WindowsTerminal window hosting the legacy visible gateway tabs; **zero new
  visible windows** appeared during any conhost-chain start (the earlier
  powershell-direct attempt had visibly flipped the WT tab title, proving the
  measurement detects regressions); after the last legacy profile stop the
  final visible gateway-related window count is **0**. Launcher wrappers
  exit after acceptance (0 remaining), latest launcher receipts
  outcome=ok/applied=2.
- Final: 3/3 RUNNING, loopback-only, HTTP 200, `\Sovereign\` tasks 3/3
  owned/config-matching, final status receipt secret-scan clean
  (`receipt-status-20260719-102241-272-6d73107e.json`).
- Boundaries kept: no reboot, no provider/model call, no new listener, no
  remote/push, no secret read/print. Reboot acceptance and paid provider
  probes remain Phase 2B.

## P0-B Phase 2A hardening (r5), 19 July 2026

- Codex's three r4-review findings were implemented as a narrow hardening
  slice without touching the three running routes or the task definitions:
  (1) every real start path now goes through one shared consoleless
  primitive (`Invoke-SgsStartHermesConsoleless`, conhost --headless +
  hidden + gitignored log redirection); the old visible
  `Start-Process hermes.exe` path was removed from the `start-direct`
  fallback and the launcher delegates to the same contract with no recursive
  launcher/task calls; (2) the hermes child command line is built with a
  Windows quoting helper whose output is proven by CommandLineToArgvW
  round-trips (spaced paths, trailing backslashes, embedded quotes all
  tokenize exactly; the current space-free path produces a byte-identical
  line, so no task drift); (3) unexpected launcher exceptions
  (status/lock/IO) can no longer escape: fail-closed exit 4, the file lock
  is released in `finally`, a single-attempt redacted `outcome=error`
  receipt is written, and a receipt-write failure causes no recursion and a
  nonzero exit 5.
- Test suite grew to **97/97**: source-level unification proofs (zero legacy
  direct-hermes starts, exactly one conhost start site, launcher has no
  process-start/Start-ScheduledTask of its own), a real `Invoke-SgsStartDirect`
  execution against a mocked primitive, quoting round-trip cases, and
  launcher exception tests (nonzero + zero starts + lock released +
  redacted error receipt + receipt-failure exit 5). Parser: 0 errors on all
  three files.
- Live read-only verification with everything untouched: `plan` reported
  3x `already-installed` (no drift-recreate), and `status` showed 3/3
  RUNNING, loopback-only, `HTTP 200`
  (`receipt-status-20260719-104013-014-d75ed6f3.json`).
- Boundaries kept again: no reboot, no provider/model call, no route
  stop/start, no remote/push, no secret read/print.

## P0-B Phase 1 second review fixes (r3), 19 July 2026

- All five findings from the second Codex review were implemented: the start
  ownership bypass is closed (start only launches an IdentityOwned AND
  ConfigMatches task through its exact TaskPath; a foreign or drifted task at
  the dedicated path makes start fail-closed with zero mutations; the direct
  `Start-Process` fallback applies only when no task exists at the dedicated
  path and is documented as deliberate; same-name tasks under other paths are
  never started), the recreate chain is dependency-gated (register runs only
  after an APPLIED unregister; declined/failed unregister skips register and
  records truthful step results), receipts aggregate truth from the step log
  (fail-closed > failed > declined > ok, explicit applied/declined/failed
  booleans, atomic `FileMode.CreateNew` writes that ignore `-WhatIf`, and
  `-Execute -NoReceipt` is refused as an audit bypass with a mandatory
  refusal receipt), task verification covers the full definition
  (single action, single enabled logon trigger, trigger-user SID, LogonType,
  RunLevel, and SID-canonical principal comparison where an untranslatable
  account or a same-username/different-SID principal fails closed; the
  register path now sets an explicit current-user Interactive Limited
  principal and an `-AtLogOn -User` trigger), and argument parsing uses the
  official Win32 `CommandLineToArgvW` (escaped quotes, backslash-before-quote,
  empty arguments, and decoy cases tested; non-Windows environments fail
  closed).
- Test suite: **71/71 assertions passed** — 64 mock-level plus 7 real
  dispatcher/parser proofs. The dispatcher-level proofs ran the actual script
  as a child process: `-Execute -WhatIf` produced a unique receipt file with
  `whatIfRequested=true`, `appliedCount=0`, `effectiveDryRun=true`, and the
  real `\Sovereign\` scheduled-task count was unchanged before/after (zero
  real mutations); `-Execute -NoReceipt` exited nonzero and still wrote the
  mandatory redacted refusal receipt.
- The harness work documented two more environment pitfalls: child processes
  inherit `SGS_NO_DISPATCH` (temporarily cleared around dispatcher tests) and
  native stderr redirection under `$ErrorActionPreference='Stop'` becomes a
  terminating NativeCommandError in Windows PowerShell 5.1.
- Live read-only status with the r3 script: all three gateways `RUNNING`,
  loopback-only, `HTTP 200`, identical process trees, zero stale PIDs,
  schema 1.2 receipt `receipt-status-20260719-004512-110-c4a841bb.json`,
  post-write secret scan clean. Parser: 0 errors; PSScriptAnalyzer was again
  deliberately not installed.
- Still not run (Phase 2, user approval required): real task
  install/uninstall, real gateway start/stop, reboot acceptance, paid
  provider probes.

## P0-B Phase 2B reboot acceptance (post-reboot evidence), 19 July 2026

- Read-only post-reboot measurement, source HEAD `82f908f` (Faz 2A accepted at
  `f2a2a19`, unchanged): LastBoot 2026-07-19 14:07:55 (Istanbul); 3/3
  `\Sovereign\` tasks LastRun 14:12:34, LastTaskResult 0, Ready, exact
  owned/config (single `conhost --headless` action, single enabled
  current-user logon trigger, MSI Interactive/Limited principal).
- 3/3 routes up: 8642 PID 17364, 8643 PID 17348, 8644 PID 17352; single
  `127.0.0.1` listener per port; `/health` `HTTP 200` on all three.
- Launcher wrapper artifacts: 0. `sky.list_apps` visible
  console/Terminal/PowerShell/Hermes window count: 0.
- Launcher receipt (14:13:34): outcome ok, applied 2 / failed 0,
  secret-pattern false. Status receipt
  `receipt-status-20260719-112433-839-2081c97c.json`: outcome ok, 3 gateways,
  secret-pattern false. Out log 1155 bytes, err log 0 bytes; all six logs
  scanned secret-pattern clean.
- Acceptance window 14:12:50 -> 14:13:34 (~44s), within the 90s bound.
- Full 1-14 checklist filled in `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md`
  section 9. Phase 2B reboot acceptance is now COMPLETE (TAM). Paid provider
  probe (section 7 of that document, MiMo 8642 + DeepSeek 8643) was NOT run
  in this pass — still `KANIT GEREKLI`, pending separate user approval and
  spend-guard scope.

## P0-B Phase 2B provider probe (live evidence), 19 July 2026 — COMPLETE

- Ran the section-7 contract with user approval: DeepSeek 8643 and MiMo
  8642 each got one live call (prompt: single short "answer OK only"
  message, max 8 output tokens, temperature 0, no sensitive context).
- First MiMo attempt failed application-side:
  `receipt-provider-probe-sovereign-mimo-20260719-123730-201-b5e7e235.json`
  — HTTP 200, latency 2242ms, attempts 1, prompt 254 / completion 8 /
  total 262 tokens, responseLength 0, expectedOk false, outcome `failed
  UNEXPECTED_RESPONSE_CONTENT`, secret pattern false. Root cause per
  Xiaomi's official docs: `mimo-v2.5` deep-thinking defaults to enabled,
  so the whole 8-token budget was consumed by reasoning instead of the
  expected short reply. Not retried — this is an application-level content
  mismatch, not a transient network failure, and the contract only retries
  transient errors.
- Fix applied in Claude Code r3, commit `a26091a`: added
  `thinking.type=disabled` to the MiMo request (DeepSeek already had
  thinking disabled). Regression: provider-probe suite 109/109, gateway
  service test suite 97/97, parser 0 errors.
- DeepSeek accepted:
  `receipt-provider-probe-sovereign-deepseek-20260719-124120-200-a2cb21ee.json`
  — HTTP 200, latency 1338ms, attempts 1, outcome exact OK, prompt 11 /
  completion 1 / total 12 tokens, responseLength 2, configured estimate
  $0.00000182, secret pattern false.
- MiMo accepted after the fix:
  `receipt-provider-probe-sovereign-mimo-20260719-124537-820-0c5f04fe.json`
  — HTTP 200, latency 2305ms, attempts 1, outcome exact OK, prompt 256 /
  completion 2 / total 258 tokens, responseLength 2, configured estimate
  $0.00003640, secret pattern false.
- Cost: accepted pair (DeepSeek + corrected MiMo) totals 270 tokens,
  configured estimate $0.00003822. All live spend this pass including the
  failed first MiMo attempt: 532 tokens, configured estimate $0.00007602.
  These are local configured-rate estimates (0.14 input / 0.28 output
  USD/M token), not an official current bill.
- No secrets, raw request/response bodies, or base URLs were logged in any
  receipt (secret-pattern scan false on all four probe receipts). No
  retries were triggered (each attempt above is a single call, not a
  retry of the prior one).
- 8644 (`sovereign-hermes`) scope unchanged: health-only, no paid
  inference call made or planned in this pass — still `KANIT GEREKLI`,
  but out of P0-B's provider-probe scope (contract only covers MiMo 8642 +
  DeepSeek 8643), so it does not block this phase's acceptance.
- Full detail in `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` section 10.
  **Phase 2B provider probe is now COMPLETE. P0-B is COMPLETE** (with the
  8644 health-only limitation explicitly carried forward, since 8644 was
  never in P0-B's provider-probe scope).

## MCP Bridge Windows ENOBUFS/teardown fix, 19 July 2026

Sovereign source commits `cf8c9e0` (initial deterministic test-listen + MCP
cleanup + fault injection) and `63fcc3b` (Node-official close ordering: close
once, then `closeIdle`/`closeAll`, plus an exact-order test) close the roadmap
item opened by the 18 July audit's `ENOBUFS` failure. Code scope is limited to
`workers/mcp-bridge/src/mcp.test.ts`, `test-listen.ts`, and
`test-listen.test.ts`; no other product code changed.

- Pre-fix reproduction in this session: the isolated target file passed 1/1
  and the full workspace passed 124/124. The failure was confirmed
  intermittent rather than always-reproducing, but the underlying source leak
  path (an early network failure left the fixed `127.0.0.1:4601` listener and
  its Node process running instead of tearing down) was proven and is what
  the fix addresses.
- Post-fix: the target MCP suite passed 11/11, the full workspace passed
  134/134, TypeScript checking passed clean for 11 of the 12 workspace
  projects reachable from this scope, and `pnpm build` passed clean (web
  build transformed 1,645 modules).
- Fault-injection coverage added by the fix: `port 0` `ENOBUFS` triggers a
  bounded deterministic fallback; `EADDRINUSE` advances to the next candidate
  port; a non-retryable error fails immediately; exhausting all candidates
  fails in a bounded way; a synchronous throw from a listener still cleans up;
  `close()` is idempotent; a `close()` error is handled; an early
  application-level error still cleans up listeners; and an exact
  close-ordering test enforces the Node-official sequence (close the primary
  listener once, then `closeIdle`, then `closeAll`).
- Codex-run stress evidence: the first normal-sandbox repeat loop returned
  0/20, caused by sandbox `EPERM`, not a product defect. A subsequent
  Codex-approved exact command batch under full access returned 19/20; the
  one failure's root-cause output was truncated by the capture method and
  showed no `ENOBUFS` evidence, so it is recorded as inconclusive rather than
  a reproduction. With failure output capture fixed, two further batches
  returned 40/40 and 60/60 — **100 consecutive passes with no failure**. This
  document does not claim the original `ENOBUFS` was ever reproduced again
  after the fix; it only claims the exact close-ordering/cleanup path is now
  deterministic under repeated stress.
- Final environment check: candidate ports `4601`, `4691`, `4692`, and `4693`
  had zero listeners, and zero leftover `tsx`/`node --test` processes remained
  from the repo. Sovereign `git status` was clean at `63fcc3b`.
- Environment note, not a test/build failure: in the default (non-full-access)
  sandbox profile, `typecheck` and `build` could not read `tsc` from the
  external Sovereign source tree and returned `EPERM`. Both passed cleanly on
  retry under full access. This mirrors the 18 July audit's sandbox-permission
  finding and is a session-sandbox characteristic, not a source or test
  defect.
- Not run in this slice: any service or provider/model call. This was a
  docs-only, test-and-typecheck-and-build-only verification pass against
  already-committed Sovereign code; no HERMES or Sovereign product code was
  changed by this session.

## Isolated runtime smoke E2E complete, 19 July 2026

Sovereign source commits `8d904a3`, `edf6393`, `5e07e02`, plus the
hygiene-only `.gitignore` commit `e314314` (this commit changed only the
Sovereign `.gitignore` line; no runtime behavior changed).

- Helper suite 21/21; full workspace 134/134; TypeScript checking passed
  clean for 11 of 12 workspace projects; `pnpm build` passed clean — web
  build transformed 1,645 modules, `index` 0.45 kB, CSS 106.25 kB, JS
  380.45 kB.
- A real isolated runtime smoke run executed and exited 0. Receipt:
  `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent\qa\isolated-runtime-smoke\receipt.json`,
  timestamped `2026-07-19T16:03:16.023Z`. The run used a unique temporary
  `DATA_DIR` and the port range 50171-50194.
- Incremental UI chat produced the partial token "İzole" and the final text
  "Izole runtime sohbeti canlı akış ile yanıt veriyor.", with 2 persisted
  turns. The model was a local deterministic mock,
  `deepseek-chat-isolated-smoke`; no paid call was made.
- A real Playwright `browser.inspect` run against `https://example.com`
  confirmed the "Example Domain" heading and produced 3 artifacts:
  `browser-run.json` at 837 bytes, SHA-256
  `1cde0be7baa2ebc7a61a69d78649094002cabe320c32c0395a32180101830112`, and a
  valid PNG at 1280x800, 10892 bytes.
- A real Windows CUA frame was captured at 431664 bytes, 1920x1080, and its
  proxied copy at 412141 bytes. The takeover sequence agent false -> human
  true -> agent false was verified; no active desktop mouse/keyboard input
  was accepted at any point.
- No console or request errors were observed; visual QA was clean. All
  cleanup passed — the temporary directory was deleted and the ports were
  closed. The `gateway-auth` and `gateway-stream` fault-injection runs exited
  1 only after cleanup completed, with no orphaned workers.
- Truthful limits: the model gateway is a local mock, not a packaged or
  signed single desktop product; no paid request was made; there is no
  active mouse/keyboard acceptance; takeover restart durability remains
  pending; port 8644 remains health-only; the live 8642-8644 gateways were
  untouched. The next step is a Hermes Electron or native shell plus
  Sovereign UI and Control Plane lifecycle integration, followed by takeover
  restart durability and safety-gated active input.
- Docs-only slice: no service/provider/model call was made and no HERMES or
  Sovereign product code was changed by this session.

## Native Sovereign service supervisor spike (2026-07-20)

First real vertical slice of the "one desktop product" P0 item: a flag-gated,
main-process-owned supervisor that can discover/start, health-check, expose
status, and gracefully stop only a loopback Sovereign service it can prove it
owns, plus a reversible first-class renderer route. Detail in ADR 0011.

- Main-process unit/contract suites (`node --test`, wired into
  `npm run test:desktop:platforms`): `electron/sovereign-config.test.cjs`,
  `electron/sovereign-supervisor.test.cjs`, `electron/sovereign-ipc.test.cjs`,
  `electron/sovereign-runtime.test.cjs` — **44/44 pass**. They cover: disabled/
  misconfigured/not-configured start guards; reserved-gateway-port refusal
  (8642/8643/8644); non-loopback host refusal; token- and child-handle ownership
  proofs; readiness timeout with child cleanup; child-exit-before-ready; foreign
  collision fail-close (no spawn, no kill); idempotent adopt; graceful stop;
  forced tree-kill escalation; `PORT_NOT_RELEASED` honesty; refusal to touch a
  foreign/blocked port on stop; `disposeSync` quit teardown; and secret-free
  status/argv/stdio.
- Renderer suites (`vitest`, jsdom): `src/app/sovereign/index.test.tsx`,
  `src/store/sovereign.test.ts`, `src/app/routes.test.ts` — **16/16 pass**.
  They cover the flag-gated nav/route wiring and every honest surface state
  (disabled, reserved-port fail-closed, foreign-port fail-closed, ready-but-
  auth-pending, and the ready+surface embed), including asserting the embedded
  `<webview>` carries `webpreferences="contextIsolation=yes,nodeIntegration=no,
  sandbox=yes"` and an isolated `persist:sovereign` partition.
- Deterministic isolated acceptance harness
  (`node scripts/sovereign-supervisor-accept.mjs`, exit 0, **16/16 checks**, no
  paid provider/model call): the REAL supervisor drove a real fake-service child
  process — Scenario A started it (pid live) → owned via token proof → healthy →
  `reach()` 200 → stopped → port released AND pid dead (no orphan); Scenario B put
  a foreign listener on the port and confirmed start returned `blocked
  FOREIGN_PORT` and the foreign process was untouched by both start and stop;
  Scenario C confirmed reserved port 8643 was refused before any spawn. A repeat
  run left **0 lingering `fake-sovereign-service` processes** (verified via
  `Get-CimInstance Win32_Process`). Receipts are printed to stdout only (not
  committed).
- `npx tsc -p . --noEmit` for the desktop app passes clean (exit 0).
- Pre-existing, unrelated: the wider `vitest run src` suite has ~25 failures on
  this Turkish-locale Windows machine (number formatting like `5,000` vs `5.000`,
  and product drift such as `explicit_only`). Proven pre-existing by stashing the
  slice and re-running the same 13 files (25 failures at baseline). None of the
  failing files are touched by this slice. `electron/update-relaunch.test.cjs` has
  one pre-existing Linux-path assertion that cannot pass on Windows; the
  main.cjs-reading `windows-child-process.test.cjs` passes 5/5 with the edits.
- Truthful limits: the authenticated Sovereign product surface is intentionally
  NOT wired — auth is not bypassed (no `AUTH_MODE=disabled` in the product path);
  the route shows an honest "authenticated surface pending" state naming the next
  contract (bootstrap/login → `sovereign_session` cookie, then `_SURFACE_URL`).
  Cross-desktop-restart ownership adoption is designed (token handshake) but not
  persisted; a full Electron GUI E2E of the route was not run (jsdom + isolated
  supervisor acceptance stand in). The live 8642-8644 gateways/tasks were not
  touched. No Sovereign-repo code was changed; the Sovereign control-plane
  bootstrap/auth contract was only read for the design.

## Native Sovereign supervisor hardening (Codex review-fix), 2026-07-20

A tightly-scoped security/reliability review of the uncommitted native Sovereign
slice was implemented tests-first. Only the HERMES desktop app changed; the
Sovereign repo was untouched, the flag stays default-off, and no provider/model
call or paid spend occurred. Nine fixes (detail in ADR 0011's hardening addendum):
crypto 192-bit ownership token with token-only proof (health OK + `/health`
ownerToken or ready-file token+exact-port) and honest `OWNERSHIP_UNPROVEN`; a
race-free FIFO queue for start/stop/reach; raw-BYTE bounding of the health fetch
with fail-closed abort (no truncated parse); a conservative child-env allowlist so
ambient provider keys never reach the child; injected IPC sender-trust
(`UNTRUSTED_SENDER`) gated on a live BrowserWindow-owned top/main frame on the
exact renderer location; POSIX-safe teardown (Windows tree kill + SIGKILL direct
child) with synchronous ready-file deletion; credentialed-surface-URL rejection
plus a fail-closed `persist:sovereign` subresource egress filter; and a renderer
that embeds only when ready+healthy+`owned`+surfaceUrl with Stop gated on a new
`controllable` status.

Exact results on this machine (isolated, no paid calls):

- Focused Sovereign `node --test`: **85 tests, 85 pass, 0 fail, 0 skip**
  (`sovereign-config` 13, `sovereign-supervisor` 28, `sovereign-ipc` 12,
  `sovereign-runtime` 18, `sovereign-webview-security` 14). Pre-fix these five
  files were 56 tests; +29 new. (Correction, r3 2026-07-20: this entry
  originally recorded the per-file breakdown as 16/28/13/18/17 — impossible, it
  sums to 92 — the re-measured per-file reality for the 85 total is 13/28/12/18/14.)
- Renderer (`vitest` jsdom): `src/app/sovereign/index.test.tsx` +
  `src/store/sovereign.test.ts` + `src/app/routes.test.ts` = **18 tests, 18 pass**
  (pre-fix 16; +2 negative unowned-embed / controllable-Stop tests).
- `test:sovereign:accept` run **twice**: exit 0 both times, **23/23 checks** each,
  including new scenario D (a real healthy-but-silent child fails
  `OWNERSHIP_UNPROVEN` and is cleaned up with no orphan) and a `controllable`
  check. `Get-CimInstance Win32_Process` after the runs: **0** lingering
  `fake-sovereign-service` processes.
- Targeted ESLint on all touched electron/renderer/store/test files: **0 errors,
  0 warnings** (the pre-existing untracked slice files carried import/curly/
  jsx-prop/padding violations; fixed per the repo's own rules; no rule disabled).
  The two `.mjs` acceptance scripts are outside `eslint src/ electron/` and only
  "fail" `no-undef` because the flat config has no `.mjs` globals block — a
  pre-existing condition identical for the prior script, not touched.
- `npm run typecheck` (`tsc -p . --noEmit`): clean (exit 0).
- `git -c core.whitespace=cr-at-eol diff --check`: clean; `electron/main.cjs` stays
  LF with no reformat churn (only the localized authorizer addition).
- Full `npm run test:desktop:platforms`: **394 tests, 391 pass, 1 fail, 2
  skipped**. The **1** failure is the pre-existing, unrelated
  `resolveUnpackedRelease returns the dir for a binary UNDER release/<plat>-unpacked`
  Linux-path assertion in `update-relaunch.test.cjs` (not touched, not hidden). NB:
  the review brief cited "3 pre-existing update-relaunch failures"; the measured
  reality on this checkout is **1** (matching ADR 0011's "one pre-existing Linux-
  path assertion"). Reported exactly as observed, not adjusted to the brief.
- Read-only safety: 8642/8643/8644 still single 127.0.0.1 listeners with PIDs
  17364/17348/17352 (unchanged from the recorded post-reboot state); 4310-4321 all
  free; the three `\Sovereign\` gateway scheduled tasks still `Ready` (untouched).

Honest limits (unchanged): authenticated surface still pending (auth not bypassed);
the stock control-plane does not yet echo the token, so it cannot be *owned* until
it does (start would fail `OWNERSHIP_UNPROVEN` — the safe direction); cross-restart
ownership adoption not persisted; no packaged Electron GUI E2E; no active input; no
full Manus product. The user's AgentOS repo/temporary clone is optional comparison/
reference only — not copied/imported/merged/added as a dependency/modified; the
inspected snapshot had no top-level LICENSE and defaulted to a different
Claude-centric stack, so no code was imported. Open-source/Manus research remains
planned, not cancelled.

## Native Sovereign supervisor r3 follow-up (Codex review corrections), 2026-07-20

A second, smaller Codex review pass on the same uncommitted slice fixed six
residual issues (stale-ownership lifecycle, renderer honesty, sender-predicate
extraction, egress tightening, truthful docs — detail in ADR 0011's r3 section).
Same boundaries: HERMES desktop only, Sovereign repo untouched, flag default-off,
no provider/model call or paid spend, nothing committed.

Code changes: `sovereign-supervisor.cjs` (adoption requires the live spawned
handle; spawn-time exit watcher reconciles a post-READY exit to `FAILED`/
`CHILD_EXIT` with ownership/pid/proof cleared; expected STOPPING exit untouched;
`childAlive()` re-check before publishing ownership), new Electron-free
`sovereign-ipc-trust.cjs` (sender predicate with empty-file-URL-hostname
requirement and `fileURLToPath`+normalize comparison) wired from `main.cjs`,
`sovereign-webview-security.cjs` (in-page schemes narrowed to `data:`/`blob:`/
`about:`; `devtools:`/`chrome:`/`chrome-extension:`/unknown denied),
`src/app/sovereign/index.tsx` (dedicated fail-closed ownership-lost panel for
`ready+healthy+unowned` — no embed, Stop disabled; Start allowed only for the
stale unowned+uncontrollable ready; truthful FIFO stop comment), plus corrected
comments in `sovereign-config.cjs`/`sovereign-runtime.cjs`/`main.cjs` and this
documentation set.

Exact results on this machine (isolated, no paid calls):

- Focused Sovereign `node --test`: **108 tests, 108 pass, 0 fail, 0 skip** —
  `sovereign-config` 13, `sovereign-supervisor` 32 (+4 lifecycle tests),
  `sovereign-ipc` 12, `sovereign-ipc-trust` 19 (new suite, added to
  `test:desktop:platforms`), `sovereign-runtime` 18, `sovereign-webview-security`
  14. The r2 baseline was re-measured before the changes as **85 = 13/28/12/18/14**
  (the previously recorded 16/28/13/18/17 breakdown was a mis-recording).
- Renderer (`vitest`, jsdom): `src/app/sovereign/index.test.tsx` 10 +
  `src/store/sovereign.test.ts` 4 + `src/app/routes.test.ts` 5 = **19 tests, 19
  pass** (pre-r3 18; the unowned-ready test now asserts the ownership-lost panel,
  Start enabled and Stop disabled; +1 owned-READY Start-disabled test).
- Targeted ESLint on all touched electron/renderer/test files: **0 errors, 0
  warnings**. `npx tsc -p . --noEmit`: clean (exit 0).
- `test:sovereign:accept` run **twice**: exit 0 both times, **23/23 checks** each;
  `Get-CimInstance Win32_Process` after the runs: **0** lingering
  `fake-sovereign-service` processes.
- `git -c core.whitespace=cr-at-eol diff --check`: clean (main.cjs edit stays
  localized: one require plus the predicate block replaced by the tested helper).
- Read-only safety: 8642/8643/8644 still single 127.0.0.1 listeners with PIDs
  17364/17348/17352 (unchanged); 4310-4321 all free; the three `\Sovereign\`
  gateway scheduled tasks still `Ready` (untouched).
- Deliberately NOT run in this pass (per the r3 brief): the full
  `test:desktop:platforms` suite — Codex runs it independently.

Final-gate environmental note (reported exactly as observed): after all of the
above was measured green, an end-of-session re-verification found
`sovereign-runtime` at **12/18** — the 6 failures are all `listen ENOBUFS` thrown
by the test's OWN ephemeral HTTP fixture server before any assertion runs. At
that moment an unrelated host process (`ArkSignerManagement`, PID 23048) held
**15,771 Bound TCP sockets** (15,913 total TCP rows host-wide; TIME_WAIT was
only 2), and an independent probe — `net.createServer().listen(0,'127.0.0.1')`
in a fresh node process — also failed `ENOBUFS`, proving NO process on the host
could bind a new loopback listener at that point. The five socket-free Sovereign
suites still passed at the final gate (13+32+12+19+14 = **90/90**), and
`sovereign-runtime` had passed **18/18 twice earlier in the same session**
(r2-baseline measurement and the 108-total run), before the host degraded; the
acceptance harness had likewise already passed twice with real listeners. r3
changed only a comment in `sovereign-runtime.cjs`, so this is a host condition,
not a product/test regression (ENOBUFS has prior history on this machine — see
the 19 July MCP-bridge ENOBUFS notes). The foreign process was NOT touched
(read-only inspection only). Before Codex's independent full-suite run, the host
condition needs clearing (close/restart ArkSignerManagement or reboot), then
`node --test electron/sovereign-runtime.test.cjs` should be re-run to reconfirm
18/18.

Honest limits: unchanged from the hardening entry above (authenticated surface
pending, stock control-plane token echo pending, no cross-restart ownership
persistence, no packaged GUI E2E, no active input; AgentOS optional/no-import and
MiMo+DeepSeek-only routing decisions unchanged).

## Native Sovereign supervisor r4 hardening (Opus 5 / Max), 2026-07-25

Scope: HERMES desktop only. Sovereign repo untouched, flag still default-off, no
provider/model call, no external network, no reboot, no scheduled-task mutation,
no remote/push, no secret read/write/print, no commit. The three protected
gateway listeners were never stopped, restarted or reconfigured.

### Environment correction (supersedes the r3 end-of-session caveat)

The r3 section recorded a final-gate `listen ENOBUFS` condition: an unrelated
host process (`ArkSignerManagement`) had exhausted the dynamic port pool, so
`net.createServer().listen(0, '127.0.0.1')` failed host-wide and the six
real-HTTP fixtures in `sovereign-runtime` could not bind (12/18 at that moment,
after passing 18/18 twice earlier the same session).

That condition was **external and transient**. After a Windows reboot, dynamic
`listen(0)` works again and `sovereign-runtime` passes **18/18 unchanged, on
standard ephemeral ports**. Therefore:

- The previously-proposed deterministic 4310-4321 fixed-test-port patch was
  **deliberately NOT applied**. Standard ephemeral ports are the correct
  behavior and cannot collide with the product's fixed 4310-4321 range.
- Any earlier wording implying that fixed test ports, an ArkSigner
  restart, or a reboot are an ongoing REQUIREMENT for the focused suites is
  corrected here: they are not. The ENOBUFS episode stands only as external
  environment evidence, not as a product or test defect.

### Code changes in this pass (three, all HERMES desktop)

1. **Supervisor total exception safety** (`electron/sovereign-supervisor.cjs`)
   was already implemented in the working tree when this pass began (stable
   `INTERNAL_REASONS`, `failClosed`, `safeKillOwned`, `safeRemoveReadyFile`,
   redacted `errText`, throw-proof logger, per-op total-safety wrappers). This
   pass added the missing **fault-injection proof** rather than re-writing it,
   and corrected one stale test that still expected the pre-hardening contract
   (a rejected promise) instead of a fail-closed FAILED status.
2. **Honest queued Stop UX** (`src/app/sovereign/index.tsx`): the shared `busy`
   flag no longer gates Stop. Gating is per-operation now — a duplicate of the
   SAME operation is blocked, but while a Start is pending and
   `status.controllable` is true, Stop can be requested. A new
   `sovereign-stop-queued` panel states the truth (FIFO-serialized teardown
   behind the bounded start, not an immediate cancellation). A failed config
   read now renders a dedicated `sovereign-config-error` fail-closed panel with
   Retry instead of masquerading as "integration disabled"; status/mutation
   failures render a compact `sovereign-bridge-error` panel naming which call
   failed (fixed vocabulary) with a Retry. No stack, no raw error text, no path
   or secret reaches the UI.
3. **Webview egress protocol-family pinning**
   (`electron/sovereign-webview-security.cjs`): the filter previously compared
   host+port only, so an `http` surface also admitted `https`/`wss` on the same
   authority. Egress is now pinned to the surface's own family — an `http`
   surface may use `http`+`ws` only, an `https` surface `https`+`wss` only —
   with the opposite family denied even on the exact configured authority, and
   an unknown surface scheme denying all network egress. `data:`/`blob:`/
   `about:` in-page allowance, permission/download/navigation denial and the
   attach lockdown are unchanged. Comments and tests were updated to match the
   real behavior.

### Measured evidence (this machine, isolated, no paid calls)

- Focused Sovereign `node --test` suites: **115/115 pass, 0 fail** —
  `sovereign-config` 13, `sovereign-supervisor` **38** (32 + 6 new
  fault-injection), `sovereign-ipc` 12, `sovereign-ipc-trust` 19,
  `sovereign-runtime` **18/18 on standard ephemeral ports**,
  `sovereign-webview-security` **15** (14 + 1 new https-family test).
- New supervisor fault-injection tests prove: a pre-spawn probe rejection ends
  FAILED/`START_INTERNAL_ERROR` with **0 spawns, 0 kills, 0 foreign signals**
  and no STARTING residue; a post-spawn `readReadyFile` throw tears down the
  exact spawned child, removes the token-bearing ready-file and ends
  FAILED/`READINESS_INTERNAL_ERROR` with owned/controllable/pid cleared; a
  throwing `removeReadyFile` is best-effort and never fails a proven start; a
  stop release-probe rejection ends FAILED/`STOP_INTERNAL_ERROR` (never a
  claimed IDLE) with stale child/ownership dropped; throwing
  `killChild`/`forceKillTree` cleanup dependencies cannot wedge stop (release
  still proven => IDLE); and the FIFO queue recovers after a post-spawn fault
  (next start succeeds on a fresh child). Every asserted reason is a stable
  constant with no raw error text.
- Renderer (`vitest`, jsdom): **22/22 pass** — `src/app/sovereign/index.test.tsx`
  **13** (10 + 3 new: queued-Stop-during-pending-Start, config-error panel +
  Retry recovery, bridge-error panel + Retry with no raw error text),
  `src/store/sovereign.test.ts` 4, `src/app/routes.test.ts` 5.
- Acceptance harness (`test:sovereign:accept`) run **twice**: exit 0 both times,
  **23/23 checks** both times, **0** lingering `fake-sovereign-service`
  processes.
- Targeted ESLint on every touched file: **0 errors, 0 warnings**.
  `tsc -p . --noEmit` clean. `git -c core.whitespace=cr-at-eol diff --check`
  clean.
- Full `npm run test:desktop:platforms`: **424 tests, 421 pass, 1 fail, 2
  skipped**. The single failure is the pre-existing, unrelated
  `resolveUnpackedRelease … release/<plat>-unpacked` Linux-path assertion in
  `electron/update-relaunch.test.cjs` — a file this slice does not touch. Not
  hidden, not modified.
- Full `npm run build`: success (`tsc -b` + vite production bundle,
  `assert-dist-built` OK). The only warning is the pre-existing chunk-size
  advisory on the main bundle.
- Final read-only host state: **4310-4321 completely free (0 listeners)**;
  protected gateways unchanged on 127.0.0.1 — **8642 PID 11692, 8643 PID 17636,
  8644 PID 8680**; the three `\Sovereign\` scheduled tasks `Ready` with
  `LastTaskResult=0`; **0** real `fake-sovereign-service` node processes (the
  single CIM match was the measuring PowerShell process's own command line —
  self-match, excluded).

### Honest limits (unchanged)

Authenticated Sovereign surface still pending (auth not bypassed);
cross-desktop-restart ownership adoption not persisted (a survivor is treated as
foreign — the safe direction); no packaged Electron GUI E2E; no active
mouse/keyboard. The supervisor exception-safety code predates this pass — this
pass supplied its fault-injection proof, the queued-Stop UX and the egress
family pin.

## Native Sovereign r4 review-fix (Codex r4 findings), 2026-07-25

Three defects found by Codex's independent r4 review were reproduced, fixed with
the narrowest safe change, and each fix is now guarded by a test that was PROVEN
to fail against the unfixed code (fix temporarily reverted, suite re-run,
restored). Same boundaries: no commit, no network/provider call, no reboot, no
scheduled-task or process mutation, protected 8642-8644 untouched.

1. **Queued-Stop panel was bound to the wrong condition.** It read
   `stopIsQueued = canStop && startPending`, so the notice appeared *before* the
   user asked for a teardown and then vanished the moment Stop was clicked
   (`canStop` goes false while the stop mutation is pending) — the exact inverse
   of the truth it claimed to state. The r4 test asserted the panel before the
   click, so it passed for the wrong reason. Fixed to
   `stopIsQueued = stopPending && startPending` (an ACTUAL request still in
   flight behind a pending Start). The test is now faithful: panel absent before
   the click, present while BOTH promises are pending, then the Start settles
   first, the queued Stop settles second and its `idle` status wins the surface.
   Reverting the one-line condition fails that test.
2. **A missing preload bridge was rendered as "Integration disabled".**
   `sovereignBridge()?.getConfig()` returned `null` for an absent bridge, which
   made `enabled` false and fell through to the friendly disabled panel — an
   unknown state presented as a decided one. Config, status and all three
   mutations now go through `requireSovereignBridge()` / `requireBridgeResult()`
   and raise a stable, constant `SOVEREIGN_BRIDGE_UNAVAILABLE` error (never
   rendered) so the fail-closed error state handles them. Two tests cover it: a
   completely absent `window.hermesDesktop` and a bridge that answers with
   nothing; both assert the config-error panel, the ABSENCE of the disabled
   panel, and that the sentinel string never reaches the DOM. The first also
   proves Retry recovers once the bridge appears.
3. **A throwing `clearTimeout` could strand `waitForChildExit` forever.** In
   `finish()`, `clearTimeoutFn(timer)` ran before `resolve(value)`; a hostile or
   broken injected clock therefore threw past the resolve and left the promise
   pending, so `killOwned` -> `doStop` never settled and the FIFO queue wedged —
   contradicting the module's "every injected dependency is hostile" contract.
   Cancelling the timer is hygiene (the timer is unref'd and `settled` already
   makes it a no-op), so it is now best-effort inside a try/catch and resolution
   always happens. `setTimeoutFn` throwing is also handled: rather than entering
   an unbounded wait, the helper reports "did not exit" so teardown escalates
   immediately. Three tests cover the exit path, the timeout path (stubborn
   child, force escalation targeted only at our own pid) and the throwing
   `setTimeout` path; each uses a race deadline so a regression fails fast
   instead of hanging the suite. With the guard reverted, the two clearTimeout
   tests fail (0 pass / 2 fail) and pass again once restored.

### Measured evidence (supersedes the counts in the r4 section above)

- Focused Sovereign `node --test`: **118/118 pass, 0 fail** — `sovereign-config`
  13, `sovereign-supervisor` **41** (38 + 3 timer-fault), `sovereign-ipc` 12,
  `sovereign-ipc-trust` 19, `sovereign-runtime` 18 (standard ephemeral ports),
  `sovereign-webview-security` 15.
- Renderer (`vitest`, jsdom): **24/24 pass** — `src/app/sovereign/index.test.tsx`
  **15** (13 + 2 missing/empty-bridge; the queued-Stop test was rewritten, not
  added), `src/store/sovereign.test.ts` 4, `src/app/routes.test.ts` 5.
- Regression-guard proof: with the three fixes reverted, the renderer suite goes
  **3 failed / 12 passed** and the supervisor timer tests **0 pass / 2 fail**;
  restored, both are green again.
- `test:sovereign:accept` run twice: exit 0 both times, **23/23 checks** both
  times, **0** lingering `fake-sovereign-service` processes.
- Targeted ESLint on every touched file: **0 errors, 0 warnings**.
  `tsc -p . --noEmit` clean. `git -c core.whitespace=cr-at-eol diff --check`
  clean.
- Full `npm run test:desktop:platforms`: **427 tests, 424 pass, 1 fail, 2
  skipped** — the single failure remains the pre-existing, unrelated
  `resolveUnpackedRelease … release/<plat>-unpacked` Linux-path assertion in
  `electron/update-relaunch.test.cjs`, untouched by this slice.
- Full `npm run build`: success (`assert-dist-built` OK; only the pre-existing
  chunk-size advisory).
- Final read-only host state: **4310-4321 free (0 listeners)**; protected
  gateways unchanged on 127.0.0.1 — **8642 PID 11692, 8643 PID 17636, 8644 PID
  8680**; three `\Sovereign\` tasks `Ready` with `LastTaskResult=0`; **0** real
  `fake-sovereign-service` node processes.

## Native Sovereign r4 review-fix #2 (Codex second r4 review), 2026-07-25

Two contracts were re-examined at Codex's request. Both objections were CORRECT
and are fixed with the narrowest safe change; each fix is guarded by a test
proven to fail against the unfixed code (fix temporarily reverted, suite re-run,
restored). No commit, no network/provider call, no protected 8642-8644 / task /
process mutation.

1. **`handle.once` (and `timer.unref`) could still orphan the spawned child.**
   The earlier note — "it rejects, `safeKillOwned` swallows it, so there is no
   hang" — was not good enough, and Codex was right to reject it. Tracing the
   path: `waitForChildExit` rejects -> the `await` inside `killOwned` throws
   BEFORE the escalation block -> `forceKillTree(pid)` and the SIGKILL fallback
   never run -> `safeKillOwned` swallows the rejection -> `doStop` clears
   `child`/`ownership`. A stubborn child we spawned therefore stays ALIVE while
   the supervisor drops its only handle: exactly the "never leaks the child we
   spawned" clause of the total-exception-safety contract. Both `timer.unref()`
   and `handle.once('exit', …)` are now best-effort: `unref` failure is
   swallowed (it is an optimization, not correctness) and a throwing `once`
   resolves the wait as "did not exit" (`finish(false)`), so the caller escalates
   immediately. Three tests cover it: a hostile `once` during teardown still
   force-kills **only our own pid** and ends IDLE with no stale
   ownership/handle and a recovered queue; a throwing `unref` with a stubborn
   child still reaches `forceKillTree` + SIGKILL; and a hostile handle while a
   FOREIGN process holds the port kills only our pid, never signals the
   occupant, and honestly reports `PORT_NOT_RELEASED` instead of a clean IDLE.
2. **The IPC error contract dressed failures as successes.** `start`/`stop`
   returned `{ ...getStatus(), error }` and `reach` returned
   `{ ok:false, status:0, error }`. The renderer's `requireBridgeResult` only
   rejected null/undefined, so those payloads RESOLVED: `mutation.isError` /
   `statusQuery.isError` stayed false, no fail-closed panel opened, and the
   message text (paths survive `safeMessage`, which only strips 24+ char token
   runs) landed in the query cache. Additionally `config`/`status` had no
   try/catch at all, so a throwing `publicConfig()`/`getStatus()` crossed the
   IPC boundary raw. Now every one of the five channels — config and status
   included — catches, logs the redacted detail MAIN-SIDE ONLY, and rejects with
   the single constant `SOVEREIGN_OPERATION_FAILED`. Sender trust still runs
   first, so an untrusted sender keeps getting exactly `UNTRUSTED_SENDER` and
   the supervisor is never reached. As defense in depth the renderer also
   refuses any payload carrying a truthy `error` field (it never reaches
   `applyStatus`, the cache or the DOM) and routes it to the existing
   fail-closed panel.

### Measured evidence (supersedes the counts in the r4 review-fix section above)

- Focused Sovereign `node --test`: **123/123 pass, 0 fail** — `sovereign-config`
  13, `sovereign-supervisor` **44** (41 + 3 hostile-handle/unref),
  `sovereign-ipc` **14** (12 + 2 net: the two tests that encoded the old
  `{ error }` contract were REWRITTEN, and config/status raw-exception plus
  trust-precedence tests were added), `sovereign-ipc-trust` 19,
  `sovereign-runtime` 18, `sovereign-webview-security` 15.
- Renderer (`vitest`, jsdom): **27/27 pass** — `src/app/sovereign/index.test.tsx`
  **18** (15 + 3: error-carrying status payload, error-carrying reach payload,
  constant IPC failure signal — each asserting the raw path/message and the
  sentinel never reach the DOM), `src/store/sovereign.test.ts` 4,
  `src/app/routes.test.ts` 5.
- Regression-guard proof: with the `once`/`unref` guards reverted the two
  hostile-handle tests fail (**0 pass / 2 fail**) and pass again once restored.
  The IPC contract change is proven by the rewritten tests themselves (the old
  assertions asserted the very shape that hid the failure).
- Targeted ESLint on every touched file: **0 errors, 0 warnings**.
  `tsc -p . --noEmit` clean. `git -c core.whitespace=cr-at-eol diff --check`
  clean.
- Full `test:desktop:platforms`, `npm run build` and the acceptance harness were
  deliberately NOT re-run in this pass (Codex runs the single final sweep). The
  last measured values remain 427/424 pass/1 pre-existing unrelated fail/2
  skipped, a successful build, and 23/23 acceptance twice with 0 orphans.

## Sovereign visible navigation row + corrected final sweep, 2026-07-25

Codex's final GUI review found a real discoverability gap: with
`HERMES_DESKTOP_SOVEREIGN=1` the `/sovereign` screen was reachable ONLY through
the command palette, and Windows UI automation could not drive Ctrl+K reliably.
A flag-gated native control-plane screen should not be palette-only regardless.

### Change (narrowest idiomatic)

The primary sidebar navigation array moved out of the 1,000-line sidebar
component into a pure `src/app/chat/sidebar/nav-items.tsx` module, and the
Sovereign row is appended there from the SHARED descriptor state:

- The row uses the existing `SidebarNavItem` shape, the existing row markup,
  tooltip/label path (`sidebar.nav.<id>` with the item's own `label` as the
  locale fallback) and the `Shield` icon already used by the Sovereign view.
- It is placed directly after Capabilities, so it sits with the other
  control-plane rows (Operations / Capabilities) rather than below the content
  rows.
- It is offered ONLY when the descriptor has loaded AND reports `enabled`.
  While loading, when the flag is off, when the preload bridge is missing, or
  when the config load failed (the store records the last two as
  `{ loaded: true, config: null }`), the row is absent — the shell never
  advertises a dead route.
- Discovery reuses the existing `@/store/sovereign` load, whose `loadStarted`
  guard makes it idempotent, so the sidebar and the command palette cannot
  double-fetch or race. The command palette's own flag gate is untouched.
- The row is a plain route row with NO `action`, so the sidebar's single generic
  click path (`action ? …special… : navigate(route)`) can only navigate to
  `SOVEREIGN_ROUTE`; opening the screen never starts or probes the supervised
  service. Lifecycle stays behind the view's own Start/Probe/Stop controls.
- Active-state highlighting matches the other rows
  (`currentView === 'sovereign'`), `SidebarNavId` gained `'sovereign'`, and
  `en.sidebar.nav.sovereign = 'Sovereign'` was added (other locales inherit
  through the existing merge-over-`en` mechanism, exactly as they already do for
  the `command-center` row they never translated).

### Test boundary (chosen deliberately, stated honestly)

`src/app/chat/sidebar/index.tsx` is a very large component wired to a dozen
stores and the shadcn sidebar context; rendering it would be brittle, and the
directory's own convention is pure unit tests (`order.test.ts`,
`session-actions-menu.test.ts`). The new tests therefore sit on the extracted
pure module plus the real route table:
`src/app/chat/sidebar/nav-items.test.tsx` — **9 tests**: hidden while not
loaded (including a stale/optimistic config), hidden when the flag is off,
hidden when the bridge is missing / the load failed, base navigation unchanged
in every hidden case, visible when enabled, exact placement order
(`new-session, command-center, skills, sovereign, messaging, artifacts`), the
shared base array is never mutated, click contract (`route === SOVEREIGN_ROUTE`,
no `action`, and `appViewForPath(SOVEREIGN_ROUTE) === 'sovereign'`), and the
Shield icon / fallback label. No snapshots. The live click-through in the real
Electron window was then verified independently by Codex — see the live GUI
section below; the earlier "remains unproven / is Codex's next step" framing no
longer applies.

Regression-guard proof: with the visibility gate forced open, 4 of the 9 tests
fail; restored, 9/9 pass.

### Measured evidence

- New/changed files: `src/app/chat/sidebar/nav-items.tsx` (new),
  `src/app/chat/sidebar/nav-items.test.tsx` (new),
  `src/app/chat/sidebar/index.tsx` (nav array extracted, store+memo+effect
  wired, sovereign active state), `src/app/types.ts` (`SidebarNavId` +
  `'sovereign'`), `src/i18n/en.ts` (one label).
- Renderer (`vitest`, jsdom) for the six touched files: **51/51 pass, 6 files**
  — `chat/sidebar/nav-items` 9, `chat/sidebar/order`, `chat/sidebar/
  session-actions-menu`, `app/sovereign/index` 18, `store/sovereign` 4,
  `app/routes` 5. (Count correction: an earlier revision of this section
  claimed "87/87 across 7 files". That number came from passing the
  `src/app/chat/sidebar` DIRECTORY to vitest, which pulled in a seventh file
  outside the six named here. The honest figure for the named command is
  51/51; the 87 claim is withdrawn, not merely restated.)
- Flake note, reported rather than hidden: one run of that six-file command
  under heavy machine load failed a single unrelated assertion in
  `app/sovereign/index.test.tsx` ("renders the honest disabled panel when the
  flag is off", 6.2 s — a React Testing Library find timeout in a run whose
  environment setup alone took 61 s). The same file passes 18/18 in isolation
  and the six-file command passed 51/51 twice consecutively afterwards. It is
  recorded as a load-induced timing flake, not a product defect.
- Focused Sovereign `node --test`: **123/123 pass** (unchanged by this slice:
  config 13, supervisor 44, ipc 14, ipc-trust 19, runtime 18, webview 15).
- Targeted ESLint on every touched file: **0 errors, 0 warnings**.
  `tsc -p . --noEmit` clean. `git -c core.whitespace=cr-at-eol diff --check`
  clean.

### Append-correction: the FINAL full-platform sweep numbers

Codex's independent sweep supersedes this session's earlier report. The correct
final numbers are **432 total, 427 pass, 3 fail, 2 skipped**, not the
427/424/1/2 recorded in the r4 sections above (that run predated the tests added
afterwards and reported a single failure). All THREE failures are unrelated,
pre-existing Windows/POSIX portability cases in
`electron/update-relaunch.test.cjs` — `resolveUnpackedRelease` asserting a POSIX
path under Windows semantics, plus two `/bin/bash` temp-path conversion cases —
in a file this slice never touched. Codex's sweep also recorded: acceptance
twice 23/23 with zero orphans, targeted ESLint/tsc/diff-check clean, and a
successful `npm run build` (only dirty-stamp, CSS-optimizer and large-chunk
warnings). Earlier counts are left in place above and corrected here rather than
rewritten.

### LIVE Electron GUI verification (Codex, independent), 2026-07-26

This supersedes every earlier statement in this document that the real click and
lifecycle path was still unproven. Verified in the REAL built renderer with the
actual main/preload IPC — not jsdom, not a harness:

- The new flag-gated sidebar row was **visibly present after Capabilities**, and
  a real mouse click navigated to `/sovereign`.
- Initial state: `idle`, `127.0.0.1:4310`, healthy no, owned no, PID `—`; Start
  enabled, Stop disabled.
- **Start**: `ready`, healthy yes, owned yes (proof `token`), PID **28356**;
  port 4310 was held by the exact node process running
  `scripts/fake-sovereign-service.mjs`. The authenticated-surface-pending panel
  was shown — auth was NOT bypassed.
- **Probe**: stayed ready/healthy/owned with the same PID, no error.
- **Stop**: returned `idle`, healthy no, owned no, PID `—`; port 4310 released;
  `fake-sovereign-service` process count zero.
- The test Electron window was then closed: Electron PID 10700 gone, port 4310
  free, no fake service process left behind.
- Protected gateways unchanged throughout: **8642 PID 11692, 8643 PID 17636,
  8644 PID 8680**; all three `\Sovereign\` scheduled tasks `Ready` with
  `LastTaskResult = 0`.

Consequently the ADR/roadmap "no packaged Electron GUI E2E" limit now applies
only to a PACKAGED/signed build: the flag-gated route, its visible entry point
and the full Start -> Probe -> Stop lifecycle are proven in the real desktop
app. Cross-session ownership adoption and the authenticated product surface
remain deliberately unproven/pending.

### Diff hygiene correction, 2026-07-26

Codex's review also caught accidental line-ending churn: `src/app/types.ts`
showed **168 insertions / 161 deletions** for a one-member `SidebarNavId`
change, because a scripted edit rewrote the CRLF file as LF. The file was
restored from `HEAD` and the minimal change re-applied byte-safely with CRLF
preserved: the diff is now **8 insertions / 1 deletion** and the file still
carries 168 CR bytes. The other four nav-slice files were inspected and are
clean: `src/i18n/en.ts` 1 insertion, `src/app/chat/sidebar/index.tsx` 45 lines
across 4 focused hunks (import rewire, extracted nav array, store/memo/effect,
nav render + active state), and the two new `nav-items` files have no prior
version to churn. `git -c core.whitespace=cr-at-eol diff --check` is clean.

## 2026-07-26 Sovereign product host adapter (authenticated surface, auth NOT bypassed)

Native P0 vertical slice: a HERMES-owned foreground product host adapter that
becomes the single supervisor child, serves the stock Sovereign web build on the
loopback product port, reverse-proxies the API/stream prefixes to a directly
spawned control-plane on a separate loopback API port, and echoes the ownership
token only when both halves are live. The external Sovereign repo was NOT
modified (clean at `e314314`); no `main.cjs`/renderer change (the integration is
env/config-driven through the existing supervisor). No paid provider/model call,
no Docker mutation, no write to external Sovereign user data, no commit. Details
in ADR 0011 (2026-07-26 section).

Files added: `electron/sovereign-product-host.cjs` (pure, Electron-free core),
`electron/sovereign-product-host.test.cjs` (25 unit tests),
`scripts/sovereign-product-host.mjs` (ESM adapter entry / supervisor child),
`scripts/sovereign-product-accept.mjs` (real acceptance harness). Modified:
`package.json` (wired the new test file into `test:desktop:platforms`; added the
`test:sovereign:product` script).

De-risking probe (before building the adapter): the stock control-plane
`node dist/bootstrap.js` starts headless in dev/JSON mode with a temp DATA_DIR,
an ephemeral `CONTROL_PLANE_PORT`, and a minimal env (no `NODE_ENV`, no
DB/NATS/Temporal/provider/`AUTH_MODE`): `GET /health` 200; `GET /api/auth/status`
`setupRequired=true`; `POST /api/auth/bootstrap` 201 + `set-cookie
sovereign_session=…; Path=/; HttpOnly; SameSite=Strict; Max-Age=2592000` (no
`Secure` flag — correct for http loopback); `GET /api/auth/session` with the
cookie authenticated; second bootstrap 409; identity.json written under the temp
DATA_DIR. Child and temp dir cleaned up, 0 orphans.

Measured evidence (this machine, isolated, no paid calls):

- Focused product-host unit (`node --test electron/sovereign-product-host.test.cjs`):
  **25/25 pass**. Covers config validation/projection (token/host/port/reserved-
  port/private-health-path/source-root/web-index/control-plane-entry/data-dir-
  inside-source/api-host/api-port fail-closed reasons, plus a full valid
  projection that never leaks the token); static serving (existing asset MIME +
  immutable cache + nosniff; index no-store; root always the SPA shell; SPA
  fallback only for `text/html` navigations; missing asset 404; traversal denied
  and never reads outside root; no directory listing; HEAD; 405; MIME map);
  hop-by-hop stripping incl. `connection`-listed tokens with cookies preserved;
  host pinning; health token gating (503+no token before ready, 200+token when
  ready, HEAD, 405); router precedence (health > private-404 > proxy > static)
  and malformed-encoding → 400; ready-file atomicity (temp+rename, exact payload,
  unlink+rethrow on rename failure); and reverse proxy against REAL loopback
  servers (method/body/cookie forwarding + upstream status + `set-cookie`; SSE
  streamed incrementally with a ~150 ms open gap proving no buffering; upstream
  refusal → 502; client disconnect aborts the upstream and clears in-flight).
- Full focused Sovereign `node --test`: **148/148 pass** — `sovereign-config` 13,
  `sovereign-supervisor` 44, `sovereign-ipc` 14, `sovereign-ipc-trust` 19,
  `sovereign-runtime` 18, `sovereign-webview-security` 15, `sovereign-product-host`
  25. (The existing 123 are unchanged by this slice.)
- Acceptance harness (`test:sovereign:product`) against the real Sovereign source
  root: **50/50 checks, exit 0 on two consecutive runs, 0 control-plane orphans**
  (`Get-CimInstance` sweep = 0). Phases, all through the product origin:
  - first cycle: ownership (private-health `ownerToken` echo + ready-file
    `{token, product port}`), a separate ephemeral API port, `GET /` 200 text/html
    `no-store`, hashed `/assets/*` 200 `immutable`, encoded traversal 404,
    `/__hermes/internal` 404; `setupRequired` fresh → `POST /api/auth/bootstrap`
    201 + `sovereign_session` cookie with `HttpOnly`+`SameSite=Strict`+`Path=/` →
    `GET /api/auth/session` authenticated;
  - restart cycle on the SAME disposable DATA_DIR: `setupRequired=false` →
    bootstrap refused **409** → `POST /api/auth/login` **200** + cookie →
    authenticated session (honest persisted-identity/session semantics, nothing
    re-provisioned, auth never weakened);
  - supervised phase driving the REAL `createSovereignSupervisor` +
    `resolveSovereignConfig` (production code path): `start` → `ready`,
    `owned=true`, ownership proof `token`, `healthy=true`, live pid,
    `surfaceUrl` set, no token leak in status; the supervised adapter served
    `GET /` 200 and proxied `GET /api/auth/status` 200; `reach` 200; `stop` →
    `idle`/not owned; product port + API port free, control-plane pid dead, clean
    teardown;
  - every stop verified with a bounded graceful-then-force wait (models the
    supervisor teardown). Passwords, cookies and tokens were held only in memory
    and never printed (only presence, cookie attributes and status codes).
- Teardown timing was directly observed (throwaway probe, then removed): after a
  SIGTERM that hard-terminates the adapter on Windows, at +1 ms the control-plane
  is still closing (both ports briefly listening); by ~+510 ms the control-plane
  is dead and both ports are free. The harness's bounded wait reflects this real,
  guaranteed-within-a-window cleanup; both acceptance cycles reported
  `cleanTeardown = graceful` (no force escalation was needed).
- Full `npm run test:desktop:platforms`: **457 tests, 454 pass, 1 fail, 2
  skipped** (432 prior baseline + 25 new). The single failure is the pre-existing,
  unrelated `resolveUnpackedRelease … release/<plat>-unpacked` Linux-path
  assertion in `electron/update-relaunch.test.cjs`, untouched by this slice.
- In-scope ESLint on `electron/sovereign-product-host.cjs` +
  `electron/sovereign-product-host.test.cjs`: **0 errors / 0 warnings**. The two
  `scripts/*.mjs` follow the existing unlinted-harness convention: the project
  lint scope is `eslint src/ electron/`, and the prior harnesses
  (`fake-sovereign-service.mjs`, `sovereign-supervisor-accept.mjs`) produce the
  identical `.mjs` `no-undef` output (12 problems) because the flat config has no
  `**/*.mjs` node-globals block. `tsc -p . --noEmit` clean;
  `git -c core.whitespace=cr-at-eol diff --check` clean (package.json); the new
  files are LF.
- Read-only host state: **4310-4321 free (0 listeners), 0 adapter/control-plane
  orphans**; protected gateways unchanged (127.0.0.1 — **8642 PID 11692, 8643 PID
  17636, 8644 PID 8680**); three `\Sovereign\` tasks `Ready` / `LastTaskResult=0`.

Honest limits (this is a local JSON slice, not the whole product): no
worker/Temporal/PostgreSQL/NATS/provider/computer execution is proven; the dev
auth-encryption secret is a fixed local constant when `AUTH_ENCRYPTION_SECRET` is
unset (correct for a local-first surface, not a production posture); WebAuthn/MFA
step-up was not exercised (may require the canonical `localhost:<productPort>`
origin); the ephemeral API-port pick has a negligible loopback TOCTOU window that
fails closed; cross-desktop-restart ownership adoption is still not persisted; and
a packaged/signed Electron GUI E2E, durable takeover and active-input approval E2E
remain pending.
