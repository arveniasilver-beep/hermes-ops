[CmdletBinding()]
param(
    [ValidatePattern('^[a-z0-9][a-z0-9_-]{0,63}$')]
    [string]$Profile = 'owner-orchestrator',
    [ValidateRange(5, 120)]
    [int]$ReadyTimeoutSeconds = 45,
    [switch]$UseInstalledRuntime,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ManagedHermesRoot = Join-Path $RepoRoot 'runtime\hermes-agent'
$InstalledHermesRoot = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent'
$ManagedHermesDesktop = Join-Path $ManagedHermesRoot 'apps\desktop\release\win-unpacked\Hermes.exe'
$InstalledHermesDesktop = Join-Path $InstalledHermesRoot 'apps\desktop\release\win-unpacked\Hermes.exe'
$HermesRoot = if (-not $UseInstalledRuntime -and (Test-Path -LiteralPath $ManagedHermesDesktop)) {
    $ManagedHermesRoot
} else {
    $InstalledHermesRoot
}
$HermesDesktop = Join-Path $HermesRoot 'apps\desktop\release\win-unpacked\Hermes.exe'
$HermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$InstalledPython = Join-Path $InstalledHermesRoot 'venv\Scripts\python.exe'
$KnownDesktopPaths = @($ManagedHermesDesktop, $InstalledHermesDesktop)
$DesktopData = Join-Path $env:APPDATA 'Hermes'
$ProfileConfig = Join-Path $DesktopData 'active-profile.json'
$GatewayInstaller = Join-Path $PSScriptRoot 'install-gateway-autostart.ps1'
$ComputerUseInstaller = Join-Path $PSScriptRoot 'install-user-autostart.ps1'
$ManagedLaunchAttempted = $HermesRoot -eq $ManagedHermesRoot

if (-not (Test-Path -LiteralPath $HermesDesktop)) {
    throw "Hermes desktop application is not installed at $HermesDesktop"
}

function Get-KnownMainDesktopProcess {
    @(Get-CimInstance Win32_Process -Filter "Name = 'Hermes.exe'" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -notmatch '--type=' -and
            $KnownDesktopPaths -contains [string]$_.ExecutablePath
        })
}

function Get-MainDesktopProcess {
    @(Get-KnownMainDesktopProcess | Where-Object {
        [string]::Equals(
            [string]$_.ExecutablePath,
            $HermesDesktop,
            [StringComparison]::OrdinalIgnoreCase
        )
    })
}

function Get-DesktopBackendProcess {
    $mainProcessIds = @(
        Get-MainDesktopProcess | ForEach-Object { [int]$_.ProcessId }
    )
    if ($mainProcessIds.Count -eq 0) { return @() }

    @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '^python\.exe$' -and
        $mainProcessIds -contains [int]$_.ParentProcessId -and
        $_.CommandLine -match 'hermes_cli\.main(?:\s+--profile\s+\S+)?\s+serve --host 127\.0\.0\.1 --port 0'
    })
}

function Set-DesktopLaunchEnvironment {
    param([Parameter(Mandatory)][string]$RuntimeRoot)

    $env:HERMES_HOME = $HermesHome
    $env:HERMES_DESKTOP_HERMES_ROOT = $RuntimeRoot
    if (Test-Path -LiteralPath $InstalledPython) {
        $env:HERMES_DESKTOP_PYTHON = $InstalledPython
    }
}

function Wait-DesktopReady {
    param([Parameter(Mandatory)][int]$TimeoutSeconds)

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 500
        $main = @(Get-MainDesktopProcess)
        $backend = @(Get-DesktopBackendProcess)
    } until (($main.Count -gt 0 -and $backend.Count -gt 0) -or (Get-Date) -ge $deadline)

    return $main.Count -gt 0 -and $backend.Count -gt 0
}

function Use-InstalledDesktopFallback {
    if (-not (Test-Path -LiteralPath $InstalledHermesDesktop)) {
        return $false
    }

    $script:HermesRoot = $InstalledHermesRoot
    $script:HermesDesktop = $InstalledHermesDesktop
    Set-DesktopLaunchEnvironment -RuntimeRoot $HermesRoot

    $existingInstalledProcesses = @(Get-MainDesktopProcess)
    if ($existingInstalledProcesses.Count -gt 0) {
        $shell = New-Object -ComObject WScript.Shell
        [void]$shell.AppActivate([int]$existingInstalledProcesses[0].ProcessId)
        return $true
    }

    Start-Process -FilePath $HermesDesktop -WorkingDirectory (Split-Path -Parent $HermesDesktop) -ErrorAction Stop
    return $true
}

function Stop-UnhealthyDesktop {
    param([Parameter(Mandatory)][object[]]$Processes)

    foreach ($item in $Processes) {
        $process = Get-Process -Id $item.ProcessId -ErrorAction SilentlyContinue
        if ($process) { [void]$process.CloseMainWindow() }
    }

    Start-Sleep -Seconds 3
    foreach ($item in $Processes) {
        Stop-Process -Id $item.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match 'owner-orchestrator gateway run'
})) {
    & $GatewayInstaller
}

if (-not (Get-Process -Name 'cua-driver' -ErrorAction SilentlyContinue)) {
    & $ComputerUseInstaller
}

New-Item -ItemType Directory -Path $DesktopData -Force | Out-Null
$previousProfile = $null
if (Test-Path -LiteralPath $ProfileConfig) {
    try {
        $previousProfile = (Get-Content -LiteralPath $ProfileConfig -Raw -Encoding UTF8 | ConvertFrom-Json).profile
    } catch {
        $previousProfile = $null
    }
}

$payload = @{ profile = $Profile } | ConvertTo-Json
$temporaryConfig = "$ProfileConfig.$PID.tmp"
[IO.File]::WriteAllText($temporaryConfig, $payload, [Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $temporaryConfig -Destination $ProfileConfig -Force

if ($NoLaunch) {
    Write-Host "Hermes desktop profile pinned to $Profile. Runtime: $HermesRoot. Launch skipped."
    exit 0
}

$knownMainProcesses = @(Get-KnownMainDesktopProcess)
$otherRuntimeProcesses = @($knownMainProcesses | Where-Object {
    -not [string]::Equals(
        [string]$_.ExecutablePath,
        $HermesDesktop,
        [StringComparison]::OrdinalIgnoreCase
    )
})
$deferredRuntimeProcesses = @()
if ($otherRuntimeProcesses.Count -gt 0) {
    if ($ManagedLaunchAttempted) {
        $deferredRuntimeProcesses = $otherRuntimeProcesses
        Write-Host 'Keeping the installed Hermes open until the managed runtime is confirmed ready.'
    } else {
        Write-Host 'Stopping the previous Hermes desktop runtime before switching versions.'
        Stop-UnhealthyDesktop -Processes $otherRuntimeProcesses
    }
}

$mainProcesses = @(Get-MainDesktopProcess)
$backendProcesses = @(Get-DesktopBackendProcess)
$profileChanged = $previousProfile -ne $Profile

if ($mainProcesses.Count -gt 0 -and ($backendProcesses.Count -eq 0 -or $profileChanged)) {
    Write-Host 'Restarting Hermes desktop to apply a healthy, profile-pinned backend.'
    Stop-UnhealthyDesktop -Processes $mainProcesses
    $mainProcesses = @()
}

if ($mainProcesses.Count -eq 0) {
    Set-DesktopLaunchEnvironment -RuntimeRoot $HermesRoot
    try {
        Start-Process -FilePath $HermesDesktop -WorkingDirectory (Split-Path -Parent $HermesDesktop) -ErrorAction Stop
    } catch {
        if (-not $ManagedLaunchAttempted) { throw }
        Write-Warning 'The managed desktop was blocked or could not start. Falling back to the preserved installed runtime.'
        if (-not (Use-InstalledDesktopFallback)) { throw }
    }
} else {
    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.AppActivate([int]$mainProcesses[0].ProcessId)
}

$desktopReady = Wait-DesktopReady -TimeoutSeconds $ReadyTimeoutSeconds
if (-not $desktopReady -and $ManagedLaunchAttempted -and $HermesRoot -eq $ManagedHermesRoot) {
    $failedManagedProcesses = @(Get-MainDesktopProcess)
    if ($failedManagedProcesses.Count -gt 0) {
        Stop-UnhealthyDesktop -Processes $failedManagedProcesses
    }
    Write-Warning 'The managed desktop did not become ready. Falling back to the preserved installed runtime.'
    if (Use-InstalledDesktopFallback) {
        $desktopReady = Wait-DesktopReady -TimeoutSeconds $ReadyTimeoutSeconds
    }
}

if (-not $desktopReady) {
    throw "Hermes desktop did not become ready within $ReadyTimeoutSeconds seconds."
}

if ($HermesRoot -eq $ManagedHermesRoot -and $deferredRuntimeProcesses.Count -gt 0) {
    Write-Host 'Managed runtime is ready; closing the previous installed desktop.'
    Stop-UnhealthyDesktop -Processes $deferredRuntimeProcesses
}

Write-Host "Hermes desktop ready. Profile: $Profile"
Write-Host "Runtime: $HermesRoot"
Write-Host 'Primary UI: native Electron application'
Write-Host 'Browser dashboard: diagnostics only, not started'
