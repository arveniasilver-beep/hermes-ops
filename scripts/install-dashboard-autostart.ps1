[CmdletBinding()]
param(
    [int]$Port = 9119
)

$ErrorActionPreference = 'Stop'
$HermesExe = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$CuaBin = Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin'

if (-not (Test-Path -LiteralPath $HermesExe)) {
    throw "Hermes is not installed at $HermesExe"
}

$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Hermes Dashboard.lnk'
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
$escapedHermes = $HermesExe.Replace("'", "''")
$escapedCua = $CuaBin.Replace("'", "''")
$command = "`$env:Path='$escapedCua;'+`$env:Path; & '$escapedHermes' -p owner-orchestrator dashboard --host 127.0.0.1 --port $Port --no-open --skip-build"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShellExe
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -Command `"$command`""
$shortcut.WorkingDirectory = Split-Path -Parent $PSScriptRoot
$shortcut.WindowStyle = 7
$shortcut.Description = 'Start the loopback-only Hermes dashboard'
$shortcut.Save()

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $listener) {
    Start-Process -FilePath $shortcutPath
}

Write-Host "Installed dashboard autostart shortcut: $shortcutPath"
Write-Host "Dashboard URL: http://127.0.0.1:$Port"

