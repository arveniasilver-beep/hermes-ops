[CmdletBinding()]
param(
    [ValidatePattern('^[a-z0-9][a-z0-9_-]{0,63}$')]
    [string]$Profile = 'owner-orchestrator',
    [switch]$KeepDashboardAutostart,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StartScript = Join-Path $PSScriptRoot 'start-hermes-desktop.ps1'
$ManagedHermesDesktop = Join-Path $RepoRoot 'runtime\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe'
$InstalledHermesDesktop = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe'
$HermesDesktop = if (Test-Path -LiteralPath $ManagedHermesDesktop) {
    $ManagedHermesDesktop
} else {
    $InstalledHermesDesktop
}
$BackupRoot = Join-Path $env:LOCALAPPDATA "hermes\backups\desktop-primary-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$Startup = [Environment]::GetFolderPath('Startup')
$DashboardShortcut = Join-Path $Startup 'Hermes Dashboard.lnk'

foreach ($path in @($StartScript, $HermesDesktop)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required file is missing: $path" }
}

function Protect-BackupDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
    $security = [Security.AccessControl.DirectorySecurity]::new()
    $security.SetAccessRuleProtection($true, $false)
    foreach ($sid in @($identity, $systemSid)) {
        $security.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit',
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        ))
    }
    [IO.Directory]::SetAccessControl($Path, $security)
}

function Backup-FileIfPresent {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    if (Test-Path -LiteralPath $Path) {
        Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupRoot "$Label.lnk") -Force
    }
}

function Install-DesktopShortcut {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$BackupLabel
    )

    Backup-FileIfPresent -Path $Path -Label $BackupLabel
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = Join-Path $PSHOME 'powershell.exe'
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$StartScript`" -Profile `"$Profile`""
    $shortcut.WorkingDirectory = $RepoRoot
    $shortcut.WindowStyle = 7
    $shortcut.IconLocation = "$HermesDesktop,0"
    $shortcut.Description = 'Open the managed Hermes native desktop application'
    $shortcut.Save()
}

New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
Protect-BackupDirectory -Path $BackupRoot

$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Hermes.lnk'
$StartMenuShortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Hermes.lnk'
Install-DesktopShortcut -Path $DesktopShortcut -BackupLabel 'Desktop-Hermes'
Install-DesktopShortcut -Path $StartMenuShortcut -BackupLabel 'StartMenu-Hermes'

if (-not $KeepDashboardAutostart) {
    Backup-FileIfPresent -Path $DashboardShortcut -Label 'Startup-Hermes-Dashboard'
    if (Test-Path -LiteralPath $DashboardShortcut) {
        Remove-Item -LiteralPath $DashboardShortcut -Force
    }
    & (Join-Path $PSScriptRoot 'stop-dashboard-diagnostics.ps1') -Profile $Profile
}

& (Join-Path $PSScriptRoot 'install-gateway-autostart.ps1')
& (Join-Path $PSScriptRoot 'install-user-autostart.ps1')

if ($NoLaunch) {
    & $StartScript -Profile $Profile -NoLaunch
} else {
    & $StartScript -Profile $Profile
}

Write-Host "Installed managed desktop shortcut: $DesktopShortcut"
Write-Host "Installed managed Start Menu shortcut: $StartMenuShortcut"
Write-Host "Previous shortcuts backed up under: $BackupRoot"
if (-not $KeepDashboardAutostart) {
    Write-Host 'Dashboard autostart removed. It remains available as an explicit diagnostic command.'
}
