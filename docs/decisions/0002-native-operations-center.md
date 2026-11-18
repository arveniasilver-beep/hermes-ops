# ADR 0002: Extend the Native Command Center for Operations

- Status: accepted
- Date: 2026-07-16

## Context

Hermes Desktop already contained a Command Center for sessions, gateway status,
logs, usage analytics, and maintenance. It was reachable through secondary
commands but absent from the main sidebar, so the installed product appeared to
be only a chat window. Kanban task data was available in Hermes' shared database
but had no bounded native desktop API.

## Decision

The existing Command Center is the native operations surface.

- A visible `Operations` sidebar entry opens its task section directly.
- The task section reads the shared Kanban database and supports quick task
  creation for the active profile.
- Task list responses are capped at 200 rows and omit prompt bodies, results,
  workspace paths, claim tokens, and failure excerpts.
- Usage displays estimated and actual USD totals from Hermes session analytics.
- Gateway health, logs, restart, update, diagnostics, backup, and maintenance
  remain in their existing sections rather than being duplicated.
- The browser dashboard remains a diagnostic fallback, not a second daily UI.

## Consequences

The primary desktop now exposes chat, delegated work, cost, health, and
maintenance in one product surface. Kanban execution remains owned by the
persistent gateway, while the desktop API is a narrow presentation adapter.

The first task view is intentionally operational rather than a full board
editor. Task mutation beyond creation can be added later behind explicit,
tested endpoints without exposing sensitive task content or broad database
access.
