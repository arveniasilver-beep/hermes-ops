[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$HermesRoot = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent'
$HermesExe = Join-Path $HermesRoot 'venv\Scripts\hermes.exe'
$PythonExe = Join-Path $HermesRoot 'venv\Scripts\python.exe'
$CuaBin = Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin'
$Failures = 0

if (Test-Path -LiteralPath $CuaBin) {
    $env:Path = "$CuaBin;$env:Path"
}

function Invoke-Verification {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action
    )
    Write-Host "`n== $Name =="
    $exitCode = 0
    try {
        & $Action
        if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }
    } catch {
        $exitCode = 1
        Write-Warning "$Name failed: $($_.Exception.Message)"
    }
    if ($exitCode -ne 0) {
        $script:Failures++
        Write-Warning "$Name failed with exit code $exitCode"
    }
}

if (-not (Test-Path -LiteralPath $HermesExe)) {
    throw "Hermes executable not found: $HermesExe"
}

Invoke-Verification 'Hermes version' { & $HermesExe --version }
Invoke-Verification 'Native desktop product contract' {
    $desktopExe = Join-Path $HermesRoot 'apps\desktop\release\win-unpacked\Hermes.exe'
    $profileConfig = Join-Path $env:APPDATA 'Hermes\active-profile.json'
    $dashboardShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Hermes Dashboard.lnk'
    $desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Hermes.lnk'
    $startMenuShortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Hermes.lnk'

    foreach ($path in @($desktopExe, $profileConfig, $desktopShortcut, $startMenuShortcut)) {
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing desktop product file: $path" }
    }
    $profile = (Get-Content -LiteralPath $profileConfig -Raw -Encoding UTF8 | ConvertFrom-Json).profile
    if ($profile -ne 'owner-orchestrator') { throw "Unexpected desktop profile: $profile" }
    if (Test-Path -LiteralPath $dashboardShortcut) {
        throw "Dashboard must not autostart: $dashboardShortcut"
    }
    Write-Host "Native desktop: $desktopExe"
    Write-Host "Pinned profile: $profile"
    Write-Host 'Dashboard autostart: disabled'
}
Invoke-Verification 'Configuration contract' { & $PythonExe (Join-Path $PSScriptRoot 'verify_config.py') }
Invoke-Verification 'Shared spend guard' {
    $managedRuntime = Join-Path (Split-Path $PSScriptRoot -Parent) 'runtime\hermes-agent'
    $profileHome = Join-Path $env:LOCALAPPDATA 'hermes\profiles\owner-orchestrator'
    $previousHome = $env:HERMES_HOME
    $previousPythonPath = $env:PYTHONPATH
    try {
        $env:HERMES_HOME = $profileHome
        $env:PYTHONPATH = $managedRuntime
        $raw = & $PythonExe -c 'import json; from hermes_cli.spend_guard import get_budget_status; print(json.dumps(get_budget_status()))'
        if ($LASTEXITCODE -ne 0) { throw 'Spend guard status probe failed.' }
        $status = $raw | ConvertFrom-Json
        if (-not $status.enabled) { throw 'Shared spend guard is disabled.' }
        if (-not $status.enforce_interactive) { throw 'Interactive spend enforcement is disabled.' }
        if (-not $status.enforce_autonomous) { throw 'Autonomous spend enforcement is disabled.' }
        if (-not $status.accounting_complete) { throw 'Cross-profile spend accounting is incomplete.' }
        if ([double]$status.monthly_limit_usd -le 0) { throw 'Monthly spend limit is invalid.' }
        Write-Host ("Monthly limit: `${0:N2} USD" -f [double]$status.monthly_limit_usd)
        Write-Host ("Committed: `${0:N4} USD across {1} profile store(s)" -f [double]$status.committed_usd, [int]$status.profiles_scanned)
        Write-Host "Interactive enforcement: enabled"
        Write-Host "Autonomous enforcement: enabled"
    } finally {
        $env:HERMES_HOME = $previousHome
        $env:PYTHONPATH = $previousPythonPath
    }
}
Invoke-Verification 'Managed background services' {
    $gateway = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match 'owner-orchestrator gateway run'
    })
    $computerUse = @(Get-Process -Name 'cua-driver' -ErrorAction SilentlyContinue)
    if ($gateway.Count -eq 0) { throw 'Managed Hermes gateway is not running.' }
    if ($computerUse.Count -eq 0) { throw 'Managed computer-use driver is not running.' }
    Write-Host 'Gateway: running'
    Write-Host 'Computer use: running'
}
Invoke-Verification 'Docker daemon' { docker info --format 'Docker {{.ServerVersion}}' }
Invoke-Verification 'Docker sandbox smoke test' {
    docker run --rm --network none --cpus 1 --memory 512m --pids-limit 64 `
        --cap-drop ALL --security-opt no-new-privileges `
        nikolaik/python-nodejs:python3.11-nodejs20 `
        bash -lc 'python --version && node --version && test ! -e /run/docker.sock'
}
Invoke-Verification 'Browser dependencies' {
    $agentBrowser = Join-Path $HermesRoot 'node_modules\.bin\agent-browser.cmd'
    if (-not (Test-Path -LiteralPath $agentBrowser)) {
        $agentBrowserCommand = Get-Command agent-browser -ErrorAction SilentlyContinue
        if (-not $agentBrowserCommand) { throw 'agent-browser executable not found.' }
        $agentBrowser = $agentBrowserCommand.Source
    }
    & $agentBrowser --version
    if ($LASTEXITCODE -eq 0) {
        $chromium = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'ms-playwright') `
            -Directory -Filter 'chromium-*' -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($chromium) {
            Write-Host "Playwright Chromium: $($chromium.Name)"
        } else {
            cmd /c exit 1
        }
    }
}
Invoke-Verification 'Computer use status' { & $HermesExe -p owner-operator computer-use status }
Invoke-Verification 'Kanban database and diagnostics' {
    & $HermesExe -p owner-orchestrator kanban init | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Kanban database: initialized'
        & $HermesExe -p owner-orchestrator kanban diagnostics --json
    }
}

Write-Host "`n== Result =="
if ($Failures -eq 0) {
    Write-Host 'PASS: local non-model validation completed.'
    exit 0
}

Write-Warning "$Failures validation group(s) failed."
exit 1
