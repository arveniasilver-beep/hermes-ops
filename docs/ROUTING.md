# Model Routing

## Objective

Complete work safely and verifiably with the cheapest model that has a high
probability of success. A stronger model is not the default quality setting; it
is an escalation resource for specific uncertainty or risk.

## Levels

| Level | Default profile | Use |
|---|---|---|
| 1 | `owner-orchestrator` | Questions, short edits, small plans, simple research, basic visual or browser work |
| 2 | `owner-fast-worker` | Bounded text, data, web, documentation, tests, logs, and simple-to-medium code |
| 3 technical | `owner-engineer` | Architecture, security, complex diagnosis, critical review, algorithms, migration |
| 3 operations | `owner-operator` | Uncertain multi-step browser, computer-use, changing UI, multiple applications |
| Multimodal | `owner-vision` | Focused image, screenshot, document, audio, or video evidence |

Use one Pro profile at level 3. Dual-Pro review is limited to payments,
identity, authorization, major production migration/deployment, irreversible
changes, unresolved critical uncertainty, or an explicit user request. The
second Pro reviews risks and omissions; it does not repeat the whole task.

## Escalation

Escalate after two meaningfully different failed approaches, contradictory
evidence, an unexpected architecture boundary, new security or data-loss risk,
or inability to verify a critical result. API outages, rate limits, missing
credentials, network failures, and expired browser sessions are infrastructure
failures and do not justify a smarter model by themselves.

Once a Pro profile has produced a diagnosis, architecture, safe plan, test
strategy, rollback, or acceptance criteria, route mechanical implementation
back to `owner-fast-worker`.

## Implementation

Hermes 0.18.2 cannot select a different subagent model per `delegate_task`
call. Cross-model routing therefore uses the shared Kanban database: each task
has an explicit profile assignee, the gateway atomically claims it, and the
worker runs with that profile's model, tools, secrets, memory, and audit trail.

Triage decomposition is automatic but capped at one task per tick. Normal
fan-out is 2-6 tasks, global concurrency is two, per-profile concurrency is
one, and repeated worker failure blocks after two attempts.

## Measurement

Run `python scripts/routing_report.py --days 30`. It reports input, output,
cache tokens, API/tool calls, current-price estimates, Kanban completions, and
retries per profile. Treat estimates as a lower bound and reconcile them with
provider invoices. Task type, user corrections, and independent-verification
events are not native structured fields in Hermes 0.18.2 and must not be
invented from prose.
