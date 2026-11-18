# Operations

## Daily entry points

Open **Hermes** from the desktop or Start Menu. The managed shortcut starts the
native application, pins it to `owner-orchestrator`, and repairs the gateway or
computer-use prerequisite if either is missing.

```powershell
.\scripts\start-hermes-desktop.ps1
owner-orchestrator
owner-fast-worker
owner-engineer
owner-vision
owner-operator
```

Install or repair the native shortcuts and background services with:

```powershell
.\scripts\install-desktop-primary.ps1
```

The desktop owns its own loopback `hermes serve` backend. It does not require
the browser dashboard.

The launcher prefers the managed Phase 8 package. If Windows Application
Control blocks an unsigned managed build or it fails readiness, the launcher
falls back to the previously installed Hermes runtime without changing the
security policy. To request that rollback explicitly without deleting anything:

```powershell
.\scripts\start-hermes-desktop.ps1 -UseInstalledRuntime
```

Start the diagnostic dashboard only when investigating a browser/TUI issue:

```powershell
owner-orchestrator dashboard --host 127.0.0.1 --port 9119
owner-orchestrator dashboard --status
.\scripts\stop-dashboard-diagnostics.ps1
```

The dashboard intentionally has no Startup shortcut. Opting back into dashboard
autostart is supported for diagnostics but is not the product default:

```powershell
.\scripts\install-dashboard-autostart.ps1
```

Do not run the dashboard and native UI continuously with a low
`max_concurrent_sessions` value. Detached dashboard workers share the same
active-session lease registry. Do not use upstream `dashboard --stop` in this
pinned release: its process discovery can select the native `serve` backend.

## Durable tasks

The normal desktop path is **Operations > Tasks**. Enter a concise title and
press the plus button; the task is assigned to the active profile and appears
on the live board. The persistent dispatcher can claim it immediately, so this
action may make paid provider calls. Select a task to inspect its durable event
timeline and run attempts. Active work can be paused or cancelled; paused work
can be resumed after dependency checks. Cancellation asks for confirmation and
preserves the task, events, and attempts. Use the Ready, Running, Paused,
Blocked, Done, and Cancelled filters to review state. **Needs you** isolates
blocked cards that require a private user action.

Pause and cancel are intentionally conservative. If a locally claimed worker
cannot be confirmed stopped, Hermes returns a conflict and leaves the durable
state unchanged. Command-line equivalents remain available:

Triage auto-decomposition is enabled for smart routing but capped at one task
per dispatcher tick. The low-cost MiMo router selects from profile descriptions;
unmatched work falls back to `owner-fast-worker`. For sensitive work, create a
non-triage task with an explicit assignee or inspect the dry run first:

```powershell
owner-orchestrator kanban create "Goal" --body "Acceptance criteria" --triage --idempotency-key "unique-key"
owner-orchestrator kanban list
owner-orchestrator kanban decompose TASK_ID
owner-orchestrator kanban dispatch --dry-run
```

The gateway contains the persistent dispatcher. Do not install or start it
as a Windows service; this installation uses a current-user Startup shortcut
because the upstream service installer targets systemd and launchd. The
gateway can run without a messaging platform and remains cost-idle while the
board is empty:

```powershell
.\scripts\install-gateway-autostart.ps1
owner-orchestrator gateway list
Remove-Item "$([Environment]::GetFolderPath('Startup'))\Hermes Gateway.lnk"
```

Messaging remains disabled. Configure an explicit sender allowlist before
enabling Telegram, Discord, or another external adapter.

## Scheduled work

Open **Cron** from the native status bar. **New cron** opens the structured
editor. Choose the owning profile, prompt, frequency, and delivery target. The
profile selector appears only in the all-profile view; otherwise a job belongs
to the active profile. Daily, weekdays, weekly, monthly, hourly, interval, and
one-time modes generate the underlying schedule. Use **Custom** only when an
existing Hermes cron expression or natural duration is required.

Select a job to inspect its owner, schedule, next run, last status, and bounded
run history. Editing, pausing, resuming, deleting, and **Run now** always target
that owning profile. An id collision across profiles is rejected unless the
profile is supplied. **Run now** acknowledges queueing immediately; execution
and delivery continue in the background.

Creating or immediately running a job may make a paid provider request. The
shared monthly spend guard applies before that request, including autonomous
enforcement and concurrent reservations. Headless cron approvals remain in
deny mode for dangerous commands. External delivery destinations appear only
after the corresponding adapter is configured for the selected profile; keep
sender allowlists enabled before turning on messaging.

## Routing and cost review

Open **Operations > Usage** for live session, API-call, token, estimated-cost,
and monthly budget controls. The default $10 USD calendar-month guard is shared
by every profile and applies to both interactive chat and autonomous tasks.
Changing the main switch or either mode switch takes effect before the next
provider request. The dispatcher leaves budget-held tasks in `ready`.

These figures use the same managed pricing contract as the local report. A
recorded actual charge takes precedence over an estimate. Routes without a
known price receive a conservative reserve and are marked in the UI; they are
never counted as free. Figures remain estimates rather than provider invoices.

The policy is stored at `%LOCALAPPDATA%\hermes\spend-policy.json`. Active
request reservations are stored in `spend-guard.db` and expire automatically.
To restore documented defaults, stop Hermes and remove only the policy file.
To bypass the managed guard temporarily without changing data, use the main
switch in Usage or start the preserved runtime with `-UseInstalledRuntime`.

Use `owner-orchestrator` for normal entry. Invoke a specialist directly only
when the task is already classified:

```powershell
owner-fast-worker       # routine, bounded, verifiable execution
owner-engineer          # architecture/security/complex diagnosis only
owner-vision            # focused multimodal evidence
owner-operator          # complex browser/Windows multi-tool work only
```

The local report recomputes session cost using the managed pricing snapshot and
combines it with Kanban attempts, completions, and retries:

```powershell
python .\scripts\routing_report.py --days 30
python .\scripts\routing_report.py --days 7 --json
```

These are lower-bound estimates, not provider invoices. Hermes 0.18.2 does not
natively record task type, independent-verification status, or user-correction
events, and auxiliary calls or provider retries may be absent from `state.db`.

## Health and recovery

```powershell
.\scripts\verify.ps1
owner-orchestrator logs errors
owner-orchestrator kanban diagnostics
owner-orchestrator kanban runs TASK_ID
owner-orchestrator computer-use doctor
```

Computer-use starts from the current user's Startup folder. It can automate
normal user applications but intentionally cannot cross into elevated
administrator windows. Reapply or remove that startup entry with:

```powershell
.\scripts\install-user-autostart.ps1
Remove-Item "$([Environment]::GetFolderPath('Startup'))\Hermes Cua Driver.lnk"
```

Create the normal recovery backup from **Operations > Maintenance**. Select
**Create portable backup**, then inspect the new archive. Proceed only when it
shows **Verified** and **Credentials excluded** and the add/overwrite counts are
expected. Archives are stored under the active profile's `backups` directory.

**Restore** is intentionally a separate, confirmed action. Hermes verifies every
manifest digest again, rejects unsafe ZIP paths and link entries, creates a
timestamped `pre-import-*.zip` recovery backup, then replaces each file
atomically. SQLite stores use SQLite's backup API. Stop autonomous work first
and restart Hermes after the restore finishes. A failed archive check performs
no mutation.

The managed source CLI supports the same inspection path. Set the target profile
explicitly so a dry run cannot be mistaken for another Hermes home:

```powershell
$env:HERMES_HOME = "$env:LOCALAPPDATA\hermes\profiles\owner-orchestrator"
Push-Location .\runtime\hermes-agent
python -c "from hermes_cli.main import main; main()" backup --portable
python -c "from hermes_cli.main import main; main()" import "C:\path\backup.zip" --dry-run
Pop-Location
```

The dry run prints integrity, credential, category, size, and restore-impact
data without writing anything. Run the same import command without `--dry-run`
only after reviewing that output. Full CLI backups may contain credentials and
must be treated as secrets; the desktop creation flow always requests portable
mode.

Back up before updates or major policy changes:

```powershell
owner-orchestrator backup
owner-orchestrator update
.\scripts\apply-security-hotfix.ps1
```

The profile contract can be reapplied without touching secrets:

```powershell
.\scripts\bootstrap.ps1
```

## Human handoff

CAPTCHA, 2FA, one-time codes, account recovery, and explicit human checks are
never bypassed. When a worker blocks with `needs_input`, open **Operations >
Tasks > Needs you** and select the card. Read the redacted reason. If **Live
browser** is present, wait for **Connected**, select **Take control**, and
complete the step in that exact local page. **Open in new window**, zoom, and
fullscreen are available for difficult pages. Return to **View** before handing
control back. If no live surface is shown, complete the private step in the real
browser or application.

Never paste a password, one-time code, recovery key, token, card number, or
payment detail into Hermes. The note is optional and accepts only non-sensitive
completion context such as `Signed in successfully`. Press **Step completed**
after the external step is finished. Hermes atomically records the optional
note, unblocks the card, appends the handoff audit event, and rechecks parent
dependencies before returning it to work. A stale or non-handoff card returns a
conflict instead of being resumed accidentally.

The local takeover lease lasts 20 minutes by default and never more than one
hour. Do not expose its loopback WebSocket through a proxy or firewall rule.
After **Step completed**, the next worker reuses the same browser but is forced
to take a fresh snapshot before any navigation, click, or typing action. Cancel
the card to discard the preserved browser immediately.
