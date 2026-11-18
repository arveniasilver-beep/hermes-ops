# ADR 0001: Native Desktop Is the Primary Product Surface

- Status: accepted
- Date: 2026-07-16

## Context

The initial installation used Hermes' loopback browser dashboard as the daily
entry point. The dashboard launches a PTY/TUI gateway and can retain detached
slash-worker sessions. During native UI validation, three stale dashboard
workers occupied the shared two-session lease limit and rejected a new desktop
chat. The browser surface also exposes more runtime mechanics than a normal
desktop user should need to manage.

The pinned Hermes release already ships a maintained Electron application with
React, TypeScript, streaming chat, tool timelines, file and project navigation,
artifacts, voice controls, profiles, settings, and an internal `hermes serve`
backend. Its shared client package is the stable adapter boundary requested by
the product specification.

## Decision

The official Hermes Electron application is the primary user interface.

- The desktop app launches a loopback-only `hermes serve` backend pinned to
  `owner-orchestrator`.
- The persistent gateway remains responsible for durable Kanban dispatch.
- `cua-driver` remains a current-user background capability.
- The browser dashboard is an explicit diagnostic tool and does not autostart.
- Desktop and Start Menu shortcuts invoke the managed launcher, which repairs
  missing prerequisites and restarts an unhealthy desktop backend.
- Provider keys remain in protected Hermes environment files and are never
  copied into this repository or shortcut arguments.

## Consequences

The daily workflow becomes a normal native application instead of a terminal
session embedded in a browser. Removing the dashboard from startup also removes
the observed session-slot leak and one unnecessary listener/process tree.

The desktop remains coupled to the pinned Hermes release. Upstream updates must
be followed by the managed security overlay and the validation suite before the
new build becomes the default. The dashboard stays available for diagnostics,
so this decision is reversible using the protected shortcut backup.

The pinned upstream `dashboard --stop` process discovery can match the native
`serve` backend. Operations therefore use `stop-dashboard-diagnostics.ps1`,
which only terminates descendants of the exact managed loopback dashboard
command line.
