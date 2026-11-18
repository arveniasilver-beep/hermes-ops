# ADR 0011: Native Sovereign Service Supervisor (flag-gated spike)

- Status: accepted (first vertical slice implemented and verified)
- Date: 2026-07-20
- Relates to: ADR 0001 (native desktop primary), ADR 0009 (Sovereign execution
  platform), ADR 0010 (per-user gateway scheduled task)

## Context

The next P0 item is "one real desktop product": the Hermes Electron shell must be
able to host the Sovereign execution surface and own the lifecycle of the local
Sovereign services, without the two halves remaining separate processes a user
must start by hand. The charter forbids weakening auth, loopback, approval, or
evidence boundaries to make this easier, and forbids ever touching the persistent
8642-8644 gateway scheduled tasks.

A naive integration — spawn the control-plane from the renderer, or point a
`<webview>` at a remote origin, or bind a service on a routable address — would
violate those boundaries. We need a supervisor that is owned by the main process,
proves ownership before it ever signals a process, and fails closed on anything it
does not own.

## Decision

Add a **flag-gated, main-process-owned Sovereign service supervisor** plus a
first-class (but reversible) renderer route.

1. **Reversible feature flag.** The whole surface is off unless
   `HERMES_DESKTOP_SOVEREIGN=1`. With the flag unset the descriptor reports
   `enabled:false`; precisely: the renderer route and the IPC bridge stay
   REGISTERED but answer with the disabled descriptor / blocked status (start is
   refused as `DISABLED`), the nav entry is hidden, and no child process,
   listener, or network probe is ever created. Configuration is environment-only
   (`HERMES_DESKTOP_SOVEREIGN_CMD`/`_ARGS`/`_CWD`/`_PORT`/`_HEALTH_PATH`/
   `_SURFACE_URL`); no secret is read.

2. **Loopback only, reserved ports refused.** The config resolver rejects a
   non-loopback host and refuses ports 8642/8643/8644 (the persistent gateways)
   fail-closed. The supervisor therefore structurally cannot manage a gateway
   port: it is both a different port and — being started by someone else — a
   foreign process, which is refused twice over.

3. **Proven ownership, never assumed.** Ownership is proven by a TOKEN ECHO, never
   inferred from a live child handle alone. The default ownership token is
   generated with the crypto RNG (24 bytes = 192 bits). A start becomes owned only
   when the service both (a) reports health OK and (b) proves the token — an exact
   `/health` `ownerToken` match, OR a ready-file whose token matches AND whose port
   equals the configured port. A healthy-but-silent child that never echoes the
   token fails `OWNERSHIP_UNPROVEN` and is cleaned up (no ownership exposed). Tokens
   ride in the child environment, never argv; they are redacted from logs and never
   appear in `getStatus()` or the renderer. (Superseded the earlier "live child
   handle OR token" rule — see the 2026-07-20 hardening addendum.)

4. **Fail closed on collision.** If the configured port is already occupied by a
   process that does not prove the token, the supervisor goes `blocked` and never
   signals, kills, or otherwise touches it. `stop()` likewise refuses to touch
   anything unowned.

5. **Bounded lifecycle.** Readiness, graceful stop, force-kill escalation, and
   post-stop port-release verification are all time-boxed. Force escalation does
   BOTH the Windows tree kill (`taskkill /T /F`) AND a SIGKILL of the still-live
   direct child, so a stubborn child is never left behind on POSIX (where the tree
   kill is a no-op) or Windows. `disposeSync()` (Electron `before-quit`) has the
   same guarantee and deletes the ephemeral ready-file synchronously. Child stdio
   is discarded so a chatty/secret-shaped service can neither deadlock a pipe nor
   leak into a log. The child is spawned with a MINIMAL environment (a conservative
   OS/runtime allowlist overlaid with the supervisor's own token/port env), so it
   never inherits Hermes's ambient provider keys. `windowsHide` prevents console
   flashes. Start/stop/reach are serialized through a race-free FIFO queue so
   concurrent callers cannot overlap or double-spawn.

6. **Renderer isolation preserved.** The route reaches the surface through the
   existing preload bridge (`window.hermesDesktop.sovereign.*`) with no new
   `nodeIntegration` and no weakening of `contextIsolation`/sandbox/navigation.
   When ready+healthy AND `status.owned` (proven ownership) AND a loopback surface
   URL is configured, the surface is embedded via an imperatively-created
   `<webview>` (contextIsolation on, nodeIntegration off, sandbox on, isolated
   `persist:sovereign` partition), mirroring the existing preview-pane pattern. The
   IPC channels only trust a live BrowserWindow-owned top/main frame on the exact
   Hermes renderer location (webview guests/subframes/foreign contents are denied
   with a constant `UNTRUSTED_SENDER`), and the `persist:sovereign` session runs a
   fail-closed subresource egress filter that confines all network requests to the
   configured surface authority.

7. **Auth is not bypassed.** The stock control-plane API requires a
   `sovereign_session` cookie (via `POST /api/auth/bootstrap` first-run owner or
   `/api/auth/login`). This slice does NOT wire that bootstrap and does NOT use
   the `AUTH_MODE=disabled` dev bypass in the product path. When a service is
   reachable but no authenticated surface is wired, the route shows an honest
   "authenticated surface pending" state that names the exact next contract.

## Consequences

- The desktop can now discover/start/health-check/stop a loopback Sovereign
  service it can prove it owns, entirely behind a reversible flag, with the
  persistent gateways provably untouchable by this path.
- Ownership across a desktop restart (adopting a still-running owned instance
  after the app itself restarts) is designed for (token handshake) but not yet
  persisted; today a cross-session survivor is treated as foreign — the safe
  direction. The next contract is a persisted ownership record.
- The authenticated product surface is deferred behind an honest blocked state.
  The next contract is an ephemeral session bootstrap (bootstrap/login →
  `sovereign_session` cookie) plus a `_SURFACE_URL` to embed the real UI.
- The stock control-plane does not yet echo the ownership token on `/health` and
  does not yet write the token+port ready-file. Until it does, a supervised stock
  control-plane cannot be *owned* by this supervisor: start fails
  `OWNERSHIP_UNPROVEN` (by design — ownership is never inferred from a live child
  handle alone). Teaching the control-plane to echo `SOVEREIGN_SUPERVISOR_TOKEN` on
  `/health` (or write the ready-file) is now a prerequisite for owning it, not just
  a cross-session nicety. This is the honest, safe direction: no spoofable
  ownership. The cooperating fake service in the acceptance harness proves the full
  owned lifecycle end-to-end today.

## Rejected alternatives

- **Spawn from the renderer / `AUTH_MODE=disabled` in the product path** —
  rejected: violates the charter (weakening auth, moving process ownership out of
  the trusted main process).
- **Kill-by-port to reclaim a busy port** — rejected: it could kill a foreign or
  gateway process. Collisions fail closed instead.
- **Embed a remote/off-box surface URL** — rejected: the surface URL is validated
  loopback-only.

## Verification

Original slice (2026-07-20): 44/44 main-process unit tests, 16/16 renderer, 16/16
acceptance harness checks, typecheck clean. Superseded by the hardening addendum
counts below.

## 2026-07-20 hardening (Codex review-fix package)

A tightly-scoped security/reliability review hardened the slice. Nine code changes
plus tests-first, no Sovereign-repo change, flag still default-off:

1. **Ownership never inferred from a live child handle.** Default token is now
   crypto (192-bit). Readiness requires health OK PLUS a token proof (exact
   `/health` ownerToken, OR a ready-file whose token AND port match). Health-OK
   without proof fails `OWNERSHIP_UNPROVEN` and cleans up only the child this
   supervisor spawned. The `'child'` ownership proof type was removed. A ready-file
   token with a wrong/missing port proves nothing.
2. **Race-free FIFO queue** replaces the `inFlight` start/stop pattern; start/stop/
   reach are serialized. Deterministic deferred-promise tests prove FIFO ordering,
   duplicate-start idempotence (one spawn), and queue recovery after a rejection.
3. **`fetchSovereignHealth` bounds RAW BYTES** (not JS chars): >64 KiB aborts and
   fails closed, never parsing a truncated prefix; buffers are decoded once. Real
   HTTP tests: in-bound, exact-limit, one-byte-over, single oversized chunk,
   multibyte UTF-8, and a byte-over/char-under case.
4. **`makeSovereignSpawn` no longer inherits the ambient env.** A conservative,
   cross-platform OS/runtime allowlist (`buildSovereignChildEnv`) is overlaid with
   only supervisor-generated env. Tests prove ambient ANTHROPIC/OPENAI/DEEPSEEK/
   MIMO keys, generic `*_API_KEY`/`*_TOKEN`/`*_SECRET`, and unrelated vars do not
   reach the child while OS vars + supervisor token/port do. Docs corrected: JSON
   launch args are shell-safe structured argv, but operators must not put secrets
   there.
5. **IPC sender trust.** `registerSovereignIpc` takes an injected authorizer and
   fails closed on all five channels before any config/supervisor call, rejecting
   with a constant secret-free `UNTRUSTED_SENDER`. `main.cjs` passes a predicate
   requiring a live BrowserWindow-owned top/main frame on the exact Hermes renderer
   location (dev-server origin in dev, packaged index file when packaged; secondary
   windows' query/hash may vary). Guests/subframes/foreign contents are denied.
6. **Teardown never leaves a stubborn child on POSIX:** force the Windows tree then
   SIGKILL the still-live direct child; `disposeSync` does the same and deletes the
   ready-file synchronously.
7. **Surface/config hardening:** surface URLs with userinfo credentials are
   rejected; a fail-closed `persist:sovereign` subresource egress filter confines
   network requests to the configured authority (same-origin http/https/ws/wss
   allowed, in-page schemes allowed, everything else cancelled). Residual risk
   documented: an off-box CDN subresource would be blocked (deliberate for a
   local-first surface).
8. **Renderer** embeds only when ready+healthy+`owned`+surfaceUrl; Stop reflects a
   new `controllable` status (a live spawned child), not a stale ready state.
   Negative UI tests cover ready+healthy-but-unowned (no embed, Stop disabled).
9. ESLint clean (zero errors/warnings) on all touched electron/renderer/store/test
   files; no unrelated EOL churn (`git -c core.whitespace=cr-at-eol diff --check`
   clean; main.cjs stays LF).

Evidence (this machine, isolated, no paid calls):

- Focused Sovereign `node --test` suites: **85/85** (`sovereign-config` 13,
  `sovereign-supervisor` 28, `sovereign-ipc` 12, `sovereign-runtime` 18,
  `sovereign-webview-security` 14 — per-file counts corrected in the r3
  follow-up below; an earlier revision mis-recorded the breakdown as
  16/28/13/18/17, which sums to 92 and was never the measured reality).
- Renderer (`vitest`, jsdom): `sovereign` view + `store/sovereign` + `routes` =
  **18/18** (adds negative unowned/embed + controllable-Stop tests).
- Acceptance harness (`test:sovereign:accept`) run twice: **23/23 checks**, exit 0
  both times, scenario D proving a real healthy-but-silent child fails
  `OWNERSHIP_UNPROVEN` with no orphan; 0 lingering `fake-sovereign-service`
  processes (`Get-CimInstance Win32_Process`).
- `tsc -p . --noEmit` clean.
- Full `test:desktop:platforms`: **394 tests, 391 pass, 1 fail, 2 skipped**. The
  single failure is the pre-existing, unrelated `resolveUnpackedRelease … release/
  <plat>-unpacked` Linux-path assertion in `update-relaunch.test.cjs` (a file this
  slice does not touch), not modified to hide it.
- Live 8642/8643/8644 gateways unchanged (127.0.0.1 listeners, PIDs 17364/17348/
  17352); 4310-4321 free; `\Sovereign\` tasks untouched (read-only checks).

Honest limits unchanged: authenticated Sovereign surface still pending (auth not
bypassed), cross-desktop-restart ownership adoption not persisted (a survivor is
treated as foreign — the safe direction), no packaged Electron GUI E2E, no active
mouse/keyboard, Manus product not complete. The user's AgentOS repo/temporary clone
is optional comparison/reference only: not copied, imported, merged, added as a
dependency, or modified; the inspected snapshot had no top-level LICENSE and
defaulted to a different Claude-centric stack, so no code was imported. Open-source/
Manus research remains planned, not cancelled.

## 2026-07-20 r3 follow-up (Codex review corrections)

A second, smaller Codex review pass on the uncommitted hardening slice fixed six
residual issues. Same boundaries: HERMES desktop only, Sovereign repo untouched,
flag default-off, no provider/model call, no commit.

1. **Adoption requires the live spawned handle.** `doStart`'s occupied-port
   adoption path re-adopts ONLY when the existing token proof also still holds
   the same live spawned child (`childAlive()`). A listener that echoes our
   token while the spawned handle is already dead (e.g. an orphaned grandchild)
   is fail-closed `FOREIGN_PORT` — never owned or controllable; the stale
   ownership/handle is dropped so status cannot keep claiming them.
2. **Post-READY child exit reconciles immediately.** The child's exit/error is
   watched from spawn time (handle-scoped, so a stale watcher cannot touch a
   newer spawn). An unexpected exit after READY flips the status atomically to
   `FAILED`/`CHILD_EXIT` with healthy/owned/controllable false and
   ownership/pid/proof cleared. The expected exit during STOPPING stays owned by
   `doStop` (no misclassification), and ownership is published only after a
   final `childAlive()` re-check, closing the narrow readiness-to-listener race
   (a token proof landing in the same poll the child dies fails `CHILD_EXIT`,
   never READY). FIFO serialization and token-only proof are unchanged.
3. **Renderer honesty for stale ready.** `state=ready, healthy=true,
   owned=false` no longer shows the auth-pending panel (which says the service
   is owned): a dedicated fail-closed "Ownership lost or unproven" panel renders
   instead — no embed, Stop disabled. Start is allowed exactly when that stale
   ready is unowned AND uncontrollable so the next supervised start can
   reconcile the port (e.g. to `FOREIGN_PORT`); a truly owned READY stays
   non-startable. Stop during STARTING is documented truthfully: the request is
   FIFO-serialized behind the bounded start operation (a queued teardown, not an
   immediate cancellation).
4. **Sender predicate extracted and hardened.** The security-critical
   trusted-sender predicate moved from `main.cjs` into Electron-free
   `electron/sovereign-ipc-trust.cjs` (injected `fromWebContents`, renderer URL
   settings, platform) with its own `node --test` suite wired into
   `test:desktop:platforms`. Packaged trust now requires an EMPTY file-URL
   hostname (`file://evil-host/<same path>` is rejected) and compares paths via
   `fileURLToPath` + `path.normalize` (encoded `/` fails closed) instead of
   decode-only string compare; only query/hash may vary for secondary windows.
   `main.cjs` wires the tested helper (localized change, no EOL churn).
5. **In-page egress schemes tightened.** The `persist:sovereign` subresource
   filter now allows only `data:`, `blob:`, `about:` as non-egress in-page
   schemes; `devtools:`, `chrome:`, `chrome-extension:` and every unknown scheme
   are denied fail-closed. Same-authority http/https/ws/wss behavior unchanged.
6. **Truthful comments/docs.** Flag-off wording now states precisely that the
   route/IPC bridge stay registered but answer disabled/blocked while no
   process/listener/network is created; the runtime ready-file comment no longer
   mentions a live-child fallback (token proof is the only proof); and the
   measured per-file test counts replaced the impossible earlier breakdown (see
   corrected hardening evidence above).

Evidence (this machine, isolated, no paid calls, measured 2026-07-20):

- Focused Sovereign `node --test` suites: **108/108** — `sovereign-config` 13,
  `sovereign-supervisor` 32 (+4 lifecycle: post-READY exit, expected-stop exit,
  dead-handle token echo, died-mid-probe publish guard), `sovereign-ipc` 12,
  `sovereign-ipc-trust` 19 (new), `sovereign-runtime` 18,
  `sovereign-webview-security` 14. (r2 baseline re-measured as 85 = 13/28/12/18/14.)
- Renderer (`vitest`, jsdom): **19/19** — `src/app/sovereign/index.test.tsx` 10
  (ownership-lost panel + Start gating added), `src/store/sovereign.test.ts` 4,
  `src/app/routes.test.ts` 5.
- Targeted ESLint on all touched files: 0 errors, 0 warnings. `tsc -p . --noEmit`
  clean. `git -c core.whitespace=cr-at-eol diff --check` clean.
- `test:sovereign:accept` run twice: exit 0, **23/23 checks** both times; 0
  lingering `fake-sovereign-service` processes.
- Read-only: 8642/8643/8644 unchanged (127.0.0.1, PIDs 17364/17348/17352);
  4310-4321 free; three `\Sovereign\` tasks `Ready`. Full
  `test:desktop:platforms` was deliberately NOT run in this pass (Codex runs it
  independently).
- Final-gate environmental caveat: at end of session the host stopped accepting
  ANY new loopback listener (`listen ENOBUFS`; an unrelated process,
  ArkSignerManagement PID 23048, held 15,771 Bound TCP sockets; a bare
  `net.createServer().listen(0,'127.0.0.1')` probe in a fresh node also failed),
  so `sovereign-runtime`'s six real-HTTP fixture tests could no longer bind —
  12/18 at that moment, after passing 18/18 twice earlier in the session. The
  five socket-free suites stayed 90/90 at the final gate. Host condition, not a
  regression (r3 only touched a comment in that file); re-run runtime after the
  host clears. Detail in `docs/VALIDATION.md` r3 section.

## 2026-07-25 r4 hardening (Opus 5 / Max)

A third review-fix pass on the still-uncommitted slice. Same boundaries: HERMES
desktop only, Sovereign repo untouched, flag default-off, no provider/model call,
no reboot, no scheduled-task mutation, no commit.

1. **Supervisor total exception safety, now proven.** The exception-safety
   implementation (stable `INTERNAL_REASONS`, `failClosed`, `safeKillOwned`,
   `safeRemoveReadyFile`, redacted `errText`, throw-proof logger, per-op safety
   wrappers) was already in the tree; this pass added the fault-injection proof
   and fixed one stale test that still expected the pre-hardening contract (a
   rejected promise) rather than a fail-closed FAILED status. Proven now: a
   pre-spawn probe rejection spawns nothing and signals nothing; a post-spawn
   ready-file throw removes the token-bearing ready-file and tears down ONLY the
   exact spawned child; a best-effort `removeReadyFile` failure never fails a
   proven start; a stop release-probe rejection never claims IDLE; throwing
   kill/force-kill dependencies cannot wedge stop; and the FIFO queue always
   recovers. No transient STARTING/STOPPING residue, no stale ownership/pid/
   proof, no raw error text in any reason.
2. **Honest queued Stop UX.** The renderer's shared `busy` flag no longer gates
   Stop — that contradicted the supervisor's `controllable` contract, which
   stays true through STARTING precisely so a teardown can be requested. Gating
   is per-operation (a duplicate of the same operation is still blocked), and a
   `sovereign-stop-queued` panel states the truth: FIFO-serialized teardown
   behind the bounded start, not an immediate cancellation. Fail-closed error
   surfaces were added: a failed config read renders its own panel with Retry
   (it is NO LONGER mistakable for "integration disabled" — unknown is not off),
   and status/mutation failures render a compact panel naming which call failed
   from a fixed vocabulary, with Retry. No stack, raw message, path or secret
   reaches the UI.
3. **Webview egress protocol-family pinning.** The subresource filter compared
   host+port only, so an `http` surface also admitted `https`/`wss` on the same
   authority (a silent, never-validated TLS channel). Egress is now pinned to
   the surface's own protocol family: `http` surface => `http`+`ws` only,
   `https` surface => `https`+`wss` only, opposite family denied even on the
   exact authority, unknown surface scheme => no network egress at all. The
   minimal in-page allowance (`data:`/`blob:`/`about:`), permission/download/
   navigation denial and the attach lockdown are unchanged. Comments and tests
   were rewritten to match the real behavior.

Environment correction: the r3 end-of-session `listen ENOBUFS` condition was
external and transient (an unrelated `ArkSignerManagement` process had exhausted
the dynamic port pool). After a reboot, dynamic `listen(0)` works and
`sovereign-runtime` passes 18/18 on standard ephemeral ports. The proposed
deterministic 4310-4321 fixed-test-port patch was deliberately NOT applied;
fixed test ports / an ArkSigner restart / a reboot are NOT ongoing requirements
for these suites.

Evidence (this machine, isolated, no paid calls, measured 2026-07-25):

- Focused Sovereign `node --test`: **115/115** — `sovereign-config` 13,
  `sovereign-supervisor` 38 (+6 fault-injection), `sovereign-ipc` 12,
  `sovereign-ipc-trust` 19, `sovereign-runtime` 18 (standard ephemeral ports),
  `sovereign-webview-security` 15 (+1 https-family pin).
- Renderer (`vitest`, jsdom): **22/22** — sovereign view 13 (+3), store 4,
  routes 5.
- `test:sovereign:accept` twice: exit 0, **23/23** both runs, 0 lingering
  `fake-sovereign-service` processes.
- Targeted ESLint 0 errors / 0 warnings; `tsc -p . --noEmit` clean;
  `git -c core.whitespace=cr-at-eol diff --check` clean.
- Full `test:desktop:platforms`: **424 tests, 421 pass, 1 fail, 2 skipped** —
  the one failure is the pre-existing unrelated `resolveUnpackedRelease`
  Linux-path assertion in `update-relaunch.test.cjs` (untouched by this slice).
- Full `npm run build`: success; only the pre-existing chunk-size advisory.
- Read-only: 4310-4321 free; protected gateways unchanged (127.0.0.1, 8642 PID
  11692, 8643 PID 17636, 8644 PID 8680); three `\Sovereign\` tasks `Ready`,
  `LastTaskResult=0`.

Honest limits unchanged: authenticated surface still pending (auth not
bypassed), cross-restart ownership adoption not persisted, no packaged Electron
GUI E2E.

## 2026-07-25 r4 review-fix (Codex r4 findings)

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

### Measured evidence (supersedes the r4 counts above)

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

## 2026-07-25 r4 review-fix #2 (Codex second r4 review)

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

### Measured evidence (supersedes the r4 review-fix counts above)

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

## 2026-07-25 visible navigation row (Codex final GUI review)

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
Electron window was then verified independently by Codex (see the live GUI
section below); the earlier "still unproven" framing no longer applies.

Regression-guard proof: with the visibility gate forced open, 4 of the 9 tests
fail; restored, 9/9 pass.

### Measured evidence

- New/changed files: `src/app/chat/sidebar/nav-items.tsx` (new),
  `src/app/chat/sidebar/nav-items.test.tsx` (new),
  `src/app/chat/sidebar/index.tsx` (nav array extracted, store+memo+effect
  wired, sovereign active state), `src/app/types.ts` (`SidebarNavId` +
  `'sovereign'`), `src/i18n/en.ts` (one label).
- Renderer (`vitest`, jsdom) for the six touched files: **51/51 pass, 6 files**
  (`nav-items` 9, `order`, `session-actions-menu`, `app/sovereign/index` 18,
  `store/sovereign` 4, `app/routes` 5). Count correction: an earlier revision
  claimed "87/87 across 7 files" — that came from passing the
  `src/app/chat/sidebar` DIRECTORY to vitest, which pulled in a seventh file
  outside the six named. The 87 figure is withdrawn.
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

## 2026-07-26 LIVE Electron GUI verification (Codex, independent)

This section supersedes every earlier "no packaged Electron GUI E2E / real click
and lifecycle still unproven" caveat in the sections above, for the UNPACKAGED
development build. Verified in the real built renderer with the actual
main/preload IPC:

- The flag-gated sidebar row was visibly present after Capabilities, and a real
  mouse click navigated to `/sovereign`.
- Initial: `idle`, `127.0.0.1:4310`, healthy no, owned no, PID `—`; Start
  enabled, Stop disabled.
- **Start**: `ready`, healthy yes, owned yes (proof `token`), PID **28356**;
  port 4310 held by the exact node process running
  `scripts/fake-sovereign-service.mjs`; the authenticated-surface-pending panel
  was shown and auth was NOT bypassed.
- **Probe**: stayed ready/healthy/owned, same PID, no error.
- **Stop**: `idle`, healthy no, owned no, PID `—`; 4310 released; zero
  `fake-sovereign-service` processes.
- Window closed: Electron PID 10700 gone, 4310 free, no fake process.
- Protected gateways unchanged throughout: 8642 PID 11692, 8643 PID 17636,
  8644 PID 8680; three `\Sovereign\` tasks `Ready`, `LastTaskResult = 0`.

What this does NOT prove, and remains honestly pending: a PACKAGED/signed
Electron build, cross-desktop-restart ownership adoption, and the authenticated
Sovereign product surface (auth is still not bypassed).

Diff hygiene correction from the same review: `src/app/types.ts` had shown
168 insertions / 161 deletions for a one-member union change because a scripted
edit rewrote the CRLF file as LF. It was restored from `HEAD` and the minimal
change re-applied byte-safely; the diff is now 8 insertions / 1 deletion with
CRLF preserved. The other four nav-slice files carry no accidental EOL churn.

## 2026-07-26 Product host adapter — authenticated surface (auth NOT bypassed)

The spike above left one honest gap: the stock control-plane neither echoes the
ownership token nor serves its own web build, so it could never be *owned* by the
supervisor and never presented an authenticated surface. Only a cooperating fake
service proved the owned lifecycle. This slice closes that gap WITHOUT modifying
the Sovereign repo (still clean at `e314314`) and WITHOUT any `main.cjs`/renderer
change — the integration is purely env/config-driven through the existing
supervisor.

### Decision: a HERMES-owned foreground product host adapter

A small Node adapter (`electron/sovereign-product-host.cjs` pure core +
`scripts/sovereign-product-host.mjs` executable entry) becomes the single
supervisor child and wraps the stock control-plane:

```
supervisor ──spawns──▶ product-host adapter  ──spawns──▶ control-plane (dist/bootstrap.js)
                       · serves apps/web/dist on the product port (loopback)
                       · reverse-proxies /api,/health,/livez,/readyz to the
                         control-plane on a SEPARATE loopback API port
                       · echoes the ownership token on a PRIVATE health path
                         (/__hermes/health) ONLY when the web host AND the
                         upstream API are both live
                       · writes the supervisor ready-file atomically (temp+rename)
```

Because the control-plane is a GRANDCHILD, the supervisor's existing Windows tree
kill (`taskkill /T` on the adapter pid) and `disposeSync` reap it, and the
supervisor's ownership/readiness/teardown machinery works unchanged. The adapter
is what makes a real, stock control-plane *ownable*: the supervisor's readiness
contract (health 2xx + exact `ownerToken` echo, OR ready-file token+port) is met
by the adapter, not by the control-plane.

Design specifics (all fail-closed, all dependency-injected/unit-tested):

1. **Auth is NOT bypassed, and no secret crosses Hermes.** The control-plane
   still requires a `sovereign_session` cookie. Bootstrap/login happen inside the
   isolated `persist:sovereign` `<webview>` pointed at the product origin
   (`_SURFACE_URL`). The adapter only shuttles opaque HTTP bytes between the
   webview and the loopback control-plane; no password/session/recovery/MFA value
   ever reaches Hermes preload/IPC/argv/logs/receipts. `AUTH_MODE=disabled` is
   never used.
2. **Private, un-proxyable health path.** The supervisor health path must live in
   the reserved `/__hermes/` namespace (config fails closed as
   `HEALTH_PATH_NOT_PRIVATE` otherwise). The token echo is therefore structurally
   un-proxyable and un-servable from disk; the router serves the exact health path
   and 404s every other `/__hermes/*` request without disclosure. The token
   appears only in that loopback body, never in a log or `getStatus()`.
3. **Deliberate control-plane env (local JSON slice).** The grandchild env is a
   conservative OS/runtime allowlist (reused from `sovereign-runtime.cjs`)
   overlaid with ONLY `CONTROL_PLANE_HOST`, `CONTROL_PLANE_PORT`, `DATA_DIR`
   (+`ELECTRON_RUN_AS_NODE` when the adapter itself runs under Electron). Notably
   ABSENT: `NODE_ENV=production`, `DATABASE_URL`, `AUTH_DATABASE_URL`, `NATS_URL`,
   `WORKFLOW_RUNTIME`, `MODEL_GATEWAY_URL`, `AUTH_MODE`, and every
   `*_API_KEY/*_TOKEN/*_SECRET`. Result: JSON stores + `NoopEventBus` + local
   `TaskEngine` with auth ENABLED. The supervisor token is not allowlisted, so it
   never reaches the control-plane. `.env` is never read.
4. **Explicit, validated source-root and Hermes-owned DATA_DIR.** Both are passed
   as adapter argv (non-secret paths; no user's absolute path is hardcoded in
   runtime code). The config fails closed if `apps/web/dist/index.html` or
   `apps/control-plane/dist/bootstrap.js` is missing, if the host/api-host is not
   loopback, if the product/api port is invalid/reserved/colliding, or if the
   DATA_DIR would land inside the source tree (`DATA_DIR_INSIDE_SOURCE` — this is
   what prevents writing identity/session JSON into the repo's own `data/`, the
   control-plane's default). The API port is a separate loopback port, ephemeral
   by default.
5. **Proxy semantics.** Streams request+response with no buffering (SSE
   `text/event-stream`, used by `/api/notifications/stream`, flows immediately);
   preserves status/headers/`set-cookie`; strips hop-by-hop on BOTH directions
   (plus `connection`-listed tokens); forwards cookies/bodies; pins the upstream
   `Host` to the loopback authority; the proxy target is a fixed validated
   loopback host:port, never client-influenced (no SSRF — a guest controls only
   the path). Bounds only the connect/first-response (never the streaming body,
   so long-lived SSE is not killed); aborts the upstream on client disconnect;
   fails closed (`502`/`504`) on upstream refusal/timeout.
6. **Static serving.** Path containment via `path.resolve` + a `root+sep` prefix
   check (traversal, encoded `..`, absolute/drive escapes all denied); correct
   MIME with an octet-stream fallback (never text/html for a stray file); SPA
   fallback ONLY for `Accept: text/html` navigations and the root, so a missing
   asset 404s (no silent HTML, no file/dir disclosure); no directory listing;
   `index`/auth HTML is `no-store`, hashed `/assets/*` immutable; `nosniff` +
   `no-referrer`. The Electron `persist:sovereign` egress filter remains the real
   network boundary (unchanged).
7. **Teardown / no orphan.** POSIX: the adapter's `SIGTERM` handler gracefully
   stops the control-plane, aborts in-flight proxy work, removes the ready-file,
   exits. Windows: the OS/tree cleanup reaps the grandchild and frees both sockets
   within a bounded window (observed sub-second), belt-and-braced by the
   supervisor's `forceKillTree`/`disposeSync`. Upstream death after ready flips
   `/__hermes/health` to 503 immediately AND exits the adapter nonzero, so the
   supervisor reconciles `CHILD_EXIT`. Startup failure leaves no child/listener/
   ready-file. The adapter never kills by port and only ever signals a process it
   spawned.

### Documented launch (secret-free, reversible, off by default)

```
HERMES_DESKTOP_SOVEREIGN=1
HERMES_DESKTOP_SOVEREIGN_CMD=<node executable>
HERMES_DESKTOP_SOVEREIGN_ARGS=["<abs>/scripts/sovereign-product-host.mjs","--source-root","<abs Sovereign source>","--data-dir","<abs Hermes-owned data dir>","--api-port","0"]
HERMES_DESKTOP_SOVEREIGN_PORT=4312
HERMES_DESKTOP_SOVEREIGN_HEALTH_PATH=/__hermes/health
HERMES_DESKTOP_SOVEREIGN_SURFACE_URL=http://127.0.0.1:4312/
```

The renderer (unchanged) already embeds the surface when
ready+healthy+`owned`+surfaceUrl, so this launch surfaces the real Sovereign login
inside the isolated webview.

### Verification (this machine, isolated, no paid calls, 2026-07-26)

- De-risking probe of the stock control-plane headless in dev/JSON mode:
  `/health` 200; `POST /api/auth/bootstrap` 201 + `set-cookie
  sovereign_session=…; Path=/; HttpOnly; SameSite=Strict; Max-Age=2592000` (no
  `Secure` — correct for http loopback); `GET /api/auth/session` authenticated;
  second bootstrap 409; identity.json under the temp DATA_DIR. No orphan.
- Focused product-host unit (`node --test`): **25/25** (config validation/
  projection; static traversal/SPA/root/MIME/cache; hop-by-hop stripping; health
  token gating; router precedence + private-namespace non-disclosure; ready-file
  atomicity; and reverse proxy cookie/body/SSE-streaming/upstream-502/
  client-disconnect against REAL loopback servers).
- Full focused Sovereign `node --test`: **148/148** — config 13, supervisor 44,
  ipc 14, ipc-trust 19, runtime 18, webview 15, product-host 25.
- Acceptance harness (`test:sovereign:product`) against the REAL source: **50/50,
  exit 0 both of two consecutive runs, 0 control-plane orphans.** Proves, through
  the product origin: ownership (token echo + ready-file token+port), a separate
  API port, index (no-store) + hashed asset (immutable) served, traversal
  contained, `/__hermes/*` 404; auth `setupRequired` fresh → bootstrap 201 +
  hardened `sovereign_session` cookie → authenticated session; RESTART on the SAME
  DATA_DIR → `setupRequired` false + bootstrap refused **409** + login **200** +
  authenticated session; and a SUPERVISED phase driving the REAL
  `createSovereignSupervisor` → `ready`/`owned`(proof `token`)/`healthy`/pid, no
  token leak, surface index 200 + `/api/auth/status` proxied 200, `reach` 200,
  `stop` idle → both ports free + control-plane pid dead + clean teardown.
- Full `test:desktop:platforms`: **457 tests, 454 pass, 1 fail, 2 skipped** — the
  one failure is the pre-existing, unrelated `resolveUnpackedRelease … release/
  <plat>-unpacked` assertion in `update-relaunch.test.cjs` (untouched here).
- In-scope ESLint (`electron/sovereign-product-host*.cjs`): **0 errors/0
  warnings**. The two `scripts/*.mjs` follow the established unlinted-harness
  convention (the existing `fake-sovereign-service.mjs` /
  `sovereign-supervisor-accept.mjs` show the identical `.mjs` `no-undef` pattern;
  the project lint scope is `src/ electron/`). `tsc -p . --noEmit` clean;
  `git -c core.whitespace=cr-at-eol diff --check` clean; new files are LF.
- Read-only host: **4310-4321 free, 0 orphans**; protected gateways unchanged
  (127.0.0.1 — 8642 PID 11692, 8643 PID 17636, 8644 PID 8680); three `\Sovereign\`
  tasks `Ready`/`LastTaskResult=0`.

### Honest limits (unchanged or newly precise)

- This is a **local JSON slice**. It does NOT prove worker/Temporal/PostgreSQL/
  NATS/provider/computer execution — those are deliberately absent so auth
  bootstrap/login works offline. `/readyz` may report the model gateway/workers
  unready; the adapter gates readiness on `/livez` (liveness), which is the honest
  signal for "the API is up and serving auth".
- The dev auth-encryption secret is a fixed local constant when
  `AUTH_ENCRYPTION_SECRET` is unset. That is correct for a local-first slice (it
  keeps sessions valid across restart) but is NOT a production posture.
- WebAuthn / MFA step-up was not exercised; it may require the canonical
  `localhost:<productPort>` origin and matching control-plane WebAuthn config
  (out of scope for this password-bootstrap slice).
- The ephemeral API-port pick (`listen(0)` then hand to the child) has a
  negligible loopback TOCTOU window; a lost race makes the child fail to bind and
  the adapter tears down + exits nonzero (fail-closed), so the supervisor
  reconciles it as `CHILD_EXIT`.
- Cross-desktop-restart ownership adoption is still not persisted (a survivor is
  treated as foreign — the safe direction). Packaged/signed Electron GUI E2E,
  durable takeover, and active-input approval E2E remain pending.

## Rollback

Unset `HERMES_DESKTOP_SOVEREIGN` (default) to make the entire surface inert.
Deleting `electron/sovereign-*.cjs` (including `sovereign-product-host.cjs`),
`electron/sovereign-product-host.test.cjs`,
`scripts/sovereign-product-host.mjs`, `scripts/sovereign-product-accept.mjs`,
`src/app/sovereign/`, `src/store/sovereign.ts`, the Sovereign row in
`src/app/chat/sidebar/nav-items.tsx`, and reverting the small hooks in
`main.cjs`, `preload.cjs`, `routes.ts`, `desktop-controller.tsx`,
`command-palette/index.tsx`, `global.d.ts`, `icons.ts`, plus the two
`package.json` script entries, removes it entirely. No user data or gateway task
is involved; the external Sovereign repo is untouched.

## 2026-07-26 Product-host launcher, packaging + in-process acceptance correction (Opus 5 / Max)

A narrow P0 integration slice on top of the product-host adapter. HERMES desktop
only; external Sovereign repo untouched (`e314314`); flag default-off; no commit;
protected 8642-8644 untouched.

1. **Architecture correction (in-process, NOT grandchild).** The adapter imports
   the stock control-plane IN-PROCESS (`await import(bootstrap.js)`), so ONE
   supervisor-owned Node pid owns BOTH the product listener and the internal API
   listener. The "grandchild spawn" wording in the 2026-07-26 product-host section
   above is SUPERSEDED for the running code (working code + new test evidence win):
   `bootstrap.js` is a pure in-process import and the control-plane dist has no
   `child_process`/`fork`/`spawn`/`worker_threads`. The adapter's only child is
   Windows' benign `conhost.exe` console host, reaped with the adapter.
2. **Root launcher** `scripts/start-hermes-sovereign-desktop.ps1` wraps
   `start-hermes-desktop.ps1`, configuring the product-host env for that ONE child
   invocation and restoring the caller environment EXACTLY in finally (full env
   snapshot) on success or failure. Fail-closed validation before launch: source
   containment/build artifacts, DATA_DIR separation (durable under HERMES_HOME,
   outside the source tree), distinct allowed loopback ports, reserved gateway
   ports, occupied ports, adapter files, and JSON argv. System Node resolves to an
   absolute path with a version gate (^20.19 || >=22.12). Product origin is
   `http://localhost:4312/` (WebAuthn canonical RP id `localhost`), internal API
   127.0.0.1:4310, private health `/__hermes/health`. No token/cookie/password/API
   key is printed. Packaged resources path preferred; in-tree source adapter is the
   dev fallback.
3. **Packaging.** Minimal `extraResources` copy the adapter trio
   (`scripts/sovereign-product-host.mjs` + `electron/sovereign-product-host.cjs` +
   `electron/sovereign-runtime.cjs`) into an unpacked, external-Node-readable
   `resources/sovereign-product-host/{scripts,electron}/` tree that preserves the
   `scripts/*.mjs -> ../electron/*.cjs` import relationship. No external Sovereign
   source or DATA_DIR is placed in the package.
4. **Scripts.** `package.json` gains `test:sovereign:product:unit` (product-host
   unit) and `test:sovereign:product:accept` (real acceptance); the product-host
   unit stays in `test:desktop:platforms`. CRLF preserved (no EOL churn).
5. **Acceptance harness rewrite** (`scripts/sovereign-product-accept.mjs`): matches
   the in-process architecture; asserts the SOLE adapter pid owns both ports
   (`sole.pidOwnsBothPorts`) with no node grandchild (`sole.noNodeGrandchild`,
   conhost excluded); the orphan sweep now looks for a `sovereign-product-host.mjs`
   node process; auth requests carry the canonical `Origin: http://localhost:<port>`
   over a 127.0.0.1 transport; the default source root is auto-discovered when
   present and skipped honestly when absent.
6. **Launcher contract test** `scripts/start-hermes-sovereign-desktop.test.ps1`
   dot-sources the launcher and drives its pure helpers with injected path/port
   probes (no Pester, no UI launch): env restoration on success and failure,
   malformed/relative reject, source/data overlap reject, reserved/occupied/
   non-distinct ports reject, missing adapter/build-artifact reject, argv JSON
   round-trip with spaces, and feature-opt-in.

### Measured evidence (this machine, isolated, no paid calls, 2026-07-26)

- product-host unit `node --test`: **42/42**.
- Launcher contract test: **43/43**, exit 0 (twice).
- Real product acceptance `test:sovereign:product` (stock external Sovereign,
  auto-discovered): **53/53, exit 0 both of two runs, orphan sweep 0** — first +
  restart cycles (static + auth bootstrap 201 -> hardened `sovereign_session`
  cookie -> authenticated session; restart on the SAME DATA_DIR: setupRequired
  false + bootstrap 409 + login 200 + session) and a supervised phase (real
  `createSovereignSupervisor` owned/token/healthy, surface 200 + `/api/auth/status`
  proxied 200 + reach 200, stop -> both ports free + sole pid dead + no node
  grandchild).
- Focused Sovereign `node --test`: **165/165** (config 13, supervisor 44, ipc 14,
  ipc-trust 19, runtime 18, webview 15, product-host 42).
- `tsc -p . --noEmit` clean; `package.json` CRLF preserved (0 lone-LF); new .ps1/
  .mjs are LF; `git -c core.whitespace=cr-at-eol diff --check` clean.
- Read-only host: 4310-4319 free (0 listeners); protected gateways unchanged
  (127.0.0.1 — 8642 PID 11692, 8643 PID 17636, 8644 PID 8680); 0 lingering adapter
  node processes; external Sovereign `e314314` clean.

### Honest limits (new/precise)

- A packaged electron-builder pack was NOT run: the `extraResources` configuration
  is added but no package was produced, and packaged/signed Electron GUI E2E remains
  unproven. Not claimed.
- The launcher's localhost bind/probe path was NOT exercised end-to-end here (the
  contract is structurally validated; the acceptance harness uses a 127.0.0.1
  transport with the canonical localhost Origin). Verifying the real GUI launch on
  localhost:4312 remains pending.
- The local-JSON-slice limits (no worker/Temporal/Postgres/NATS/provider/computer
  execution) are unchanged. No commit.
