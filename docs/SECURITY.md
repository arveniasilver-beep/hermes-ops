# Security

## Secret handling

- API keys live only in each of the five managed profiles' `.env` files under
  Local AppData.
- `configure-secrets.ps1` uses masked prompts and restricts each file ACL to
  the current Windows account and `SYSTEM`.
- The repository ignores `.env`, keys, tokens, databases, logs, and runtime state.
- Secret redaction and PII redaction are explicitly enabled in every profile.
- Desktop recovery backups exclude credential stores, private keys, OAuth data,
  logs, locks, and external memory paths; secret configuration values are
  structurally redacted. A full CLI backup may contain credentials and must be
  protected as secret material.
- Do not pass secrets as command-line arguments, Kanban text, prompts, or chat.

For stronger centralized rotation, Hermes also supports Bitwarden Secrets
Manager and 1Password. Those integrations are not enabled because adding a
new paid or third-party data path requires the user's explicit approval.

## Execution policy

- Dangerous commands use `approvals.mode: manual`.
- Headless cron jobs deny dangerous commands.
- Memory and skill writes require approval.
- Tool loops have warnings and hard-stop circuit breakers.
- The engineering shell uses Docker with four CPUs, 8 GB RAM, a persistent
  filesystem, and no forwarded provider secrets.
- The dashboard binds to `127.0.0.1`; no tunnel or public URL is configured.
- Live browser takeover also binds to loopback. Its desktop projection excludes
  cookies, form values, page text, CDP/session identifiers, socket paths, and
  full target URLs. The capability is profile-scoped, expires after 20 minutes
  by default, and is removed on cancel or successful post-user observation.
- Browser input is disabled until the user explicitly selects **Take control**.
  Dedicated windows retrieve the capability through sender-bound Electron IPC;
  non-loopback or overlong capabilities are rejected by both main and renderer.
- Messaging adapters are disabled. Unknown senders are not allowed, and an
  explicit sender allowlist is required before any adapter is enabled.

Docker reduces command blast radius but is not a security boundary against a
malicious container workload. The Windows computer-use process necessarily
runs with the logged-in user's UI authority, so confirmation gates remain the
primary protection for external side effects.

## Runtime dependency overlay

The upstream `v2026.7.7.2` lock predates several July 2026 OSV disclosures.
`scripts/apply-security-hotfix.ps1` raises affected packages to their first
fixed releases, applies the two required direct-pin metadata changes with
strict old/new version guards, runs `pip check`, tests imports, and reruns the
Hermes OSV audit. `patches/hermes-security-overlay.patch` records the minimal
vendor diff for review and rollback; the script is idempotent and stops for
review if upstream changes either pin. Run it again after every Hermes update
until the upstream lock carries equal or newer versions.

## Explicit approval required

- Purchases, payments, subscriptions, and financial transfers.
- Publication, sending messages, or changing production data.
- Deletion, account or credential changes, and permission changes.
- Uploading user data to a new external service.
- Adding a paid provider, public listener, tunnel, plugin, or MCP server.
