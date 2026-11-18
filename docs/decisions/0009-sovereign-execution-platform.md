# ADR 0009: Sovereign Execution Platform

## Status

Accepted. The first local vertical slice is implemented and verified on 17 July
2026. This ADR supersedes claims that Hermes alone is the product runtime.

## Context

Hermes is a capable reasoning agent, but a professional Manus-like product also
needs durable task ownership, explicit policy, capability isolation, live work
visibility, human takeover, model routing, artifacts, and independent evidence.
Putting all authority inside one model process would turn the application into a
large chatbot with tools and would make recovery, approvals, and audits fragile.

Manus is used as a workflow reference, not as source code or a dependency. Its
official documentation confirms the product pattern we need: a visible working
browser, temporary human takeover, local authenticated browser sessions, an
isolated execution environment, and concrete output delivery.

## Decision

- Sovereign Control Plane owns tasks, plans, policy, approvals, events, artifacts,
  verification, budgets, and provider routing. No model owns authorization.
- Hermes remains a restricted reasoning worker for wide research and long-horizon
  synthesis. It is replaceable and receives only explicitly granted tools.
- Temporal is the production durable workflow engine. The local JSON runtime is a
  development fallback and must not be presented as equivalent crash recovery.
- DeepSeek and MiMo are routed by role through separate Hermes gateway profiles.
  Planning and execution receipts preserve model, token, evidence, and artifact
  provenance.
- Playwright is the deterministic browser executor. Browser Use is the preferred
  future visual/natural-language escalation because its core is MIT licensed.
  The existing Skyvern adapter stays optional and disabled by default because the
  project is AGPL-3.0 and enables basic telemetry by default.
- OpenHands Software Agent SDK and Agent Server remain the coding backend inside
  an isolated workspace. Their current SDK repository is MIT licensed.
- CUA Driver is the primary Windows host executor. It supplies UI Automation and
  Windows Graphics Capture without requiring the agent to steal the user's cursor.
  Agent-S is accepted only as an optional Apache-2.0 visual planner behind the
  strict Sovereign action schema; it does not bypass approvals or verification.
- The product exposes three user intents: ordinary Chat, durable Agent Task, and
  Project work. A task must show its plan, live events, approvals, evidence, and
  deliverables instead of returning only prose.
- The Computer surface shows the real Windows desktop through an authenticated
  control-plane proxy. Taking control suspends agent actions; returning control
  allows the next action to continue.

## Current Acceptance State

Implemented and user-tested in the isolated product runtime:

- DeepSeek planning/chat and MiMo review routes through dedicated profiles;
- a real public-web task with source evidence and a JSON deliverable;
- real 1920x1080 Windows desktop capture through CUA Driver;
- authenticated live desktop polling, explicit `Take over` and `Return to agent`;
- an action gate proving the agent blocks while the human owns control;
- read-only computer inspection with screenshots and SHA-256 evidence;
- fail-closed handling when host-screen sensitive-region redaction is requested.

Implemented as adapter contracts but not yet accepted against a live external
runtime:

- Agent-S and GUI-Owl visual planning;
- OpenHands model-driven code generation;
- Skyvern browser escalation.

Still pending:

- persisting computer takeover ownership across control-plane/worker restart;
- a live Agent-S visual-action acceptance run on a disposable test application;
- a Browser Use adapter and authenticated-session acceptance test;
- one signed native application that embeds the Sovereign UI and services;
- full production Temporal/PostgreSQL/NATS recovery acceptance for this merged
  product build.

## Security Consequences

- Read-only inspection can proceed automatically. Mouse, keyboard, external
  writes, publishing, payments, and other consequential actions remain approval
  gated.
- Computer control and frame endpoints bind to loopback workers and are exposed
  to the UI only through the authenticated control plane.
- The task-scoped MCP Bridge also binds to loopback by default. Container
  deployments must opt into a service-network bind address explicitly.
- Human takeover is an execution lock, not a cosmetic UI state.
- Credentials are never copied into model prompts, task events, or artifacts.
- Host desktop redaction is not claimed complete. Sensitive-region requests fail
  closed until physical redaction is implemented and verified.
- Live desktop transport currently uses two-second authenticated PNG polling,
  not a remote desktop protocol or a cloud relay.

## Rejected Alternatives

- **Hermes as the whole product:** rejected because reasoning, authorization,
  execution, recovery, and evidence need separate trust boundaries.
- **Skyvern as the default browser engine:** rejected because the license and
  telemetry posture add avoidable product obligations while Playwright and
  Browser Use cover the intended architecture.
- **Agent-S directly controlling Windows:** rejected because visual agents must
  produce bounded actions through policy, approval, and verifier layers.
- **Copying Manus UI or implementation:** rejected. Only documented workflow
  concepts are used.

## Primary Sources

- [Manus Cloud Browser](https://manus.im/docs/features/cloud-browser)
- [Manus Browser Operator](https://manus.im/docs/features/browser-operator)
- [Manus Desktop](https://manus.im/docs/features/desktop)
- [Temporal durable execution](https://docs.temporal.io/)
- [OpenHands Software Agent SDK](https://github.com/OpenHands/software-agent-sdk)
- [Browser Use](https://github.com/browser-use/browser-use)
- [Skyvern](https://github.com/Skyvern-AI/Skyvern)
- [Agent-S](https://github.com/simular-ai/Agent-S)
- [CUA documentation](https://cua.ai/docs)

## Rollback

The source snapshot before this product integration remains at
`backups/sovereign-agent-source-20260717-015654.zip`. Rolling back the UI or
worker does not remove Hermes profiles or user data. Stop the isolated Sovereign
services before restoring the snapshot; never overwrite active profile data.
