[CmdletBinding()]
param(
    [switch]$InstallComputerUse,
    [switch]$PullDockerImage
)

$ErrorActionPreference = 'Stop'

$HermesRoot = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent'
$HermesExe = Join-Path $HermesRoot 'venv\Scripts\hermes.exe'
$AgentBrowser = Join-Path $HermesRoot 'node_modules\.bin\agent-browser.cmd'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DockerImage = 'nikolaik/python-nodejs:python3.11-nodejs20'
$CuaBin = Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin'

if (Test-Path -LiteralPath $CuaBin) {
    $env:Path = "$CuaBin;$env:Path"
}

if (-not (Test-Path -LiteralPath $HermesExe)) {
    throw "Hermes is not installed at $HermesExe"
}

if (-not (Test-Path -LiteralPath $AgentBrowser)) {
    Push-Location $HermesRoot
    try {
        npm install
        if ($LASTEXITCODE -ne 0) { throw 'Could not install Hermes browser dependencies.' }
    } finally {
        Pop-Location
    }
}

$ProfileBin = Join-Path $HOME '.local\bin'
New-Item -ItemType Directory -Path $ProfileBin -Force | Out-Null

$profiles = [ordered]@{
    'owner-orchestrator' = 'Default low-cost MiMo router. Handles simple work, classifies risk and complexity, routes durable tasks, synthesizes evidence, and owns final acceptance. It must prefer the cheapest profile that can reliably finish the task.'
    'owner-fast-worker' = 'Default economical DeepSeek Flash worker for clear, bounded, reversible, and verifiable text, data, research, documentation, routine browser, test, and simple-to-medium coding tasks in Docker.'
    'owner-engineer' = 'DeepSeek V4 Pro technical expert reserved for architecture, security, complex diagnosis, critical review, difficult algorithms, and high-impact engineering decisions. Routine implementation belongs to owner-fast-worker.'
    'owner-vision' = 'Analyzes images, screenshots, video, audio, documents, and other multimodal inputs; returns structured observations and evidence for other profiles.'
    'owner-operator' = 'MiMo Pro agent expert reserved for complex multi-step browser and Windows desktop operations, changing interfaces, multiple applications, and high-uncertainty tool workflows. Routine semantic browser work belongs to cheaper profiles.'
}

$common = [ordered]@{
    'model.context_length' = '1000000'
    'agent.api_max_retries' = '2'
    'compression.enabled' = 'true'
    'compression.threshold' = '0.35'
    'compression.target_ratio' = '0.15'
    'approvals.mode' = 'manual'
    'approvals.timeout' = '120'
    'approvals.cron_mode' = 'deny'
    'approvals.mcp_reload_confirm' = 'true'
    'approvals.destructive_slash_confirm' = 'true'
    'memory.memory_enabled' = 'true'
    'memory.write_approval' = 'true'
    'skills.write_approval' = 'true'
    'privacy.redact_pii' = 'true'
    'security.redact_secrets' = 'true'
    'security.tirith_enabled' = 'true'
    'security.tirith_fail_open' = 'true'
    'checkpoints.enabled' = 'true'
    'checkpoints.max_snapshots' = '20'
    'tool_loop_guardrails.warnings_enabled' = 'true'
    'tool_loop_guardrails.hard_stop_enabled' = 'true'
    'max_concurrent_sessions' = '2'
    'terminal.backend' = 'docker'
    'terminal.cwd' = '/workspace'
    'terminal.home_mode' = 'profile'
    'terminal.timeout' = '300'
    'terminal.lifetime_seconds' = '900'
    'terminal.docker_image' = $DockerImage
    'terminal.docker_mount_cwd_to_workspace' = 'false'
    'terminal.container_cpu' = '4'
    'terminal.container_memory' = '8192'
    'terminal.container_disk' = '51200'
    'terminal.container_persistent' = 'true'
    'browser.user_takeover_enabled' = 'true'
    'browser.user_takeover_timeout' = '1200'
    'updates.pre_update_backup' = 'true'
    'updates.backup_keep' = '5'
    'display.compact' = 'true'
    'display.show_reasoning' = 'false'
    'display.tool_progress' = 'new'
}

$roleConfig = @{
    'owner-orchestrator' = [ordered]@{
        'model.provider' = 'xiaomi'
        'model.default' = 'mimo-v2.5'
        'agent.max_turns' = '50'
        'auxiliary.kanban_decomposer.provider' = 'xiaomi'
        'auxiliary.kanban_decomposer.model' = 'mimo-v2.5'
        'auxiliary.triage_specifier.provider' = 'xiaomi'
        'auxiliary.triage_specifier.model' = 'mimo-v2.5'
        'auxiliary.profile_describer.provider' = 'xiaomi'
        'auxiliary.profile_describer.model' = 'mimo-v2.5'
        'kanban.auto_decompose' = 'true'
        'kanban.auto_decompose_per_tick' = '1'
        'kanban.auto_promote_children' = 'true'
        'kanban.orchestrator_profile' = 'owner-orchestrator'
        'kanban.default_assignee' = 'owner-fast-worker'
        'kanban.max_in_progress' = '2'
        'kanban.max_in_progress_per_profile' = '1'
        'kanban.failure_limit' = '2'
        'kanban.auto_subscribe_on_create' = 'true'
    }
    'owner-fast-worker' = [ordered]@{
        'model.provider' = 'deepseek'
        'model.default' = 'deepseek-v4-flash'
        'agent.max_turns' = '50'
        'terminal.docker_mount_cwd_to_workspace' = 'true'
    }
    'owner-engineer' = [ordered]@{
        'model.provider' = 'deepseek'
        'model.default' = 'deepseek-v4-pro'
        'agent.max_turns' = '40'
        'terminal.docker_mount_cwd_to_workspace' = 'true'
    }
    'owner-vision' = [ordered]@{
        'model.provider' = 'xiaomi'
        'model.default' = 'mimo-v2.5'
        'agent.max_turns' = '40'
        'auxiliary.vision.provider' = 'xiaomi'
        'auxiliary.vision.model' = 'mimo-v2.5'
        'auxiliary.vision.timeout' = '90'
        'auxiliary.vision.download_timeout' = '60'
    }
    'owner-operator' = [ordered]@{
        'model.provider' = 'xiaomi'
        'model.default' = 'mimo-v2.5-pro'
        'agent.max_turns' = '50'
        'auxiliary.vision.provider' = 'xiaomi'
        'auxiliary.vision.model' = 'mimo-v2.5'
        'auxiliary.vision.timeout' = '90'
    }
}

$allToolsets = @(
    'web', 'browser', 'terminal', 'file', 'code_execution', 'vision', 'video',
    'image_gen', 'video_gen', 'x_search', 'tts', 'skills', 'todo', 'memory',
    'context_engine', 'session_search', 'clarify', 'delegation', 'cronjob',
    'homeassistant', 'spotify', 'yuanbao', 'computer_use'
)

$enabledToolsets = @{
    # Kanban is injected by Hermes' bundled plugin and is not accepted as a
    # manual `hermes tools` name, so it is intentionally absent here.
    'owner-orchestrator' = @('web', 'browser', 'vision', 'skills', 'todo', 'memory', 'session_search', 'clarify')
    'owner-fast-worker' = @('web', 'browser', 'terminal', 'file', 'code_execution', 'skills', 'todo', 'memory', 'session_search', 'clarify')
    'owner-engineer' = @('web', 'terminal', 'file', 'code_execution', 'skills', 'todo', 'memory', 'session_search', 'clarify')
    'owner-vision' = @('web', 'browser', 'vision', 'video', 'skills', 'todo', 'memory', 'session_search', 'clarify')
    'owner-operator' = @('web', 'browser', 'vision', 'skills', 'todo', 'memory', 'session_search', 'clarify', 'cronjob', 'computer_use')
}

function Invoke-Hermes {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        & $HermesExe @Arguments
        if ($LASTEXITCODE -eq 0) { return }

        if ($attempt -lt $maxAttempts) {
            Write-Warning "Hermes command failed (attempt $attempt/$maxAttempts); retrying: hermes $($Arguments -join ' ')"
            Start-Sleep -Milliseconds (300 * $attempt)
        }
    }

    throw "Hermes command failed after $maxAttempts attempts: hermes $($Arguments -join ' ')"
}

foreach ($profile in $profiles.Keys) {
    & $HermesExe profile show $profile *> $null
    if ($LASTEXITCODE -ne 0) {
        Invoke-Hermes @('profile', 'create', $profile, '--description', $profiles[$profile])
    } else {
        Invoke-Hermes @('profile', 'describe', $profile, '--text', $profiles[$profile])
    }

    foreach ($entry in $common.GetEnumerator()) {
        Invoke-Hermes @('-p', $profile, 'config', 'set', $entry.Key, [string]$entry.Value)
    }
    foreach ($entry in $roleConfig[$profile].GetEnumerator()) {
        Invoke-Hermes @('-p', $profile, 'config', 'set', $entry.Key, [string]$entry.Value)
    }

    Invoke-Hermes (@('-p', $profile, 'tools', 'disable') + $allToolsets)
    Invoke-Hermes (@('-p', $profile, 'tools', 'enable') + $enabledToolsets[$profile])

    $soulTemplate = Join-Path $RepoRoot "templates\souls\$profile.md"
    $soulTarget = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\SOUL.md"
    Copy-Item -LiteralPath $soulTemplate -Destination $soulTarget -Force
    $wrapperTemplate = Join-Path $RepoRoot "templates\wrappers\$profile.bat"
    $wrapperTarget = Join-Path $ProfileBin "$profile.bat"
    Copy-Item -LiteralPath $wrapperTemplate -Destination $wrapperTarget -Force
    Write-Host "Configured $profile"
}

Invoke-Hermes @('profile', 'use', 'owner-orchestrator')
Invoke-Hermes @('-p', 'owner-orchestrator', 'kanban', 'init')
& (Join-Path $PSScriptRoot 'protect-env-acls.ps1')

if ($PullDockerImage) {
    $installedImages = @(docker image ls --format '{{.Repository}}:{{.Tag}}')
    if ($installedImages -notcontains $DockerImage) {
        docker pull $DockerImage
        if ($LASTEXITCODE -ne 0) { throw "Could not pull $DockerImage" }
    }
}

if ($InstallComputerUse) {
    Invoke-Hermes @('-p', 'owner-operator', 'computer-use', 'install')
    & (Join-Path $PSScriptRoot 'install-user-autostart.ps1')
}

Write-Host 'Hermes profile contract applied. API keys were not read or changed.'
Write-Host 'Run install-desktop-primary.ps1 to install the managed native desktop entry point.'
Write-Host 'The browser dashboard is a diagnostic surface and should not autostart.'
Write-Host 'Run install-gateway-autostart.ps1 to keep the Kanban dispatcher available after logon.'
