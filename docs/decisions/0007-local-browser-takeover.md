# ADR 0007: Local Browser Takeover

## Status

Accepted and implemented in Phase 7.

## Context

The durable `needs_input` transition from Phase 6 preserves task state, but a
user could not see or control the exact local Chromium page that blocked the
worker. Opening a separate browser loses in-page state and can make sign-in,
CAPTCHA, or 2FA impossible to complete. Exposing CDP endpoints, cookies, page
text, form values, or browser profile paths to the desktop API would create a
larger secret and local-code-execution boundary than the feature requires.

## Decision

- Classify CAPTCHA, 2FA, sign-in, payment, and sensitive-confirmation screens
  from the post-navigation title, URL, and compact accessibility snapshot.
- Reuse agent-browser's loopback JPEG/input WebSocket. Do not introduce a
  hosted browser, relay, or new paid service.
- Create a profile-scoped, task-keyed handoff record only when managed takeover
  is enabled and the worker is attached to a Kanban task. The public projection
  contains only challenge kind, expiry, target origin, and
  `ws://127.0.0.1:<port>`.
- Activate the browser lease only when the task actually commits a
  `needs_input` block. Leases expire after 20 minutes by default and can never
  exceed one hour. Normal inactivity, orphan, and process-exit cleanup preserve
  an active lease; cancel, expiry, completion, and forced cleanup remove it.
- Start the desktop surface in observe-only mode. Keyboard and pointer events
  are sent only after the user explicitly selects **Take control**. The renderer
  rejects non-loopback stream URLs.
- Open an optional dedicated Electron window through validated IPC. Its URL
  carries only a random token; the main process binds capability retrieval to
  that child renderer's `webContents` identity.
- On resolution, reattach the next worker to the same browser. Block navigation,
  click, and typing until a fresh `browser_snapshot` succeeds, then remove the
  handoff record and return normal control to the agent.

## Consequences

The person can complete a private browser step without giving the password,
one-time code, card data, cookie, or page contents to Hermes. The task and local
browser survive worker replacement, and the resumed agent must reason from the
actual post-human screen instead of assuming success. This adds a short-lived
local capability file and browser process, both bounded by profile and expiry.

This decision covers local agent-browser Chromium only. It does not claim a
remote browser relay, cloud-browser takeover, arbitrary Windows desktop
takeover, or bypass of any human verification mechanism.

## Rollback

Set `browser.user_takeover_enabled: false` for every profile or use
`scripts/start-hermes-desktop.ps1 -UseInstalledRuntime`. Existing durable
handoffs continue to work through the Phase 6 note flow. For a source rollback
while Hermes is stopped, restore the changed files from
`backups/phase7-pre-browser-takeover-20260716-231943`.
