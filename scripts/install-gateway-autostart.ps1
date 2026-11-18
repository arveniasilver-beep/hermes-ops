[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$HermesExe = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$CuaBin = Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin'

if (-not (Test-Path -LiteralPath $HermesExe)) {
    throw "Hermes is not installed at $HermesExe"
}

$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Hermes Gateway.lnk'
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
$escapedHermes = $HermesExe.Replace("'", "''")
$escapedCua = $CuaBin.Replace("'", "''")
$command = "`$env:Path='$escapedCua;'+`$env:Path; & '$escapedHermes' -p owner-orchestrator gateway run"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShellExe
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -Command `"$command`""
$shortcut.WorkingDirectory = Split-Path -Parent $PSScriptRoot
$shortcut.WindowStyle = 7
$shortcut.Description = 'Start the Hermes gateway and durable Kanban dispatcher'
$shortcut.Save()

$alreadyRunning = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(python|hermes)\.exe$' -and
    $_.CommandLine -match 'owner-orchestrator gateway run'
}
if (-not $alreadyRunning) {
    Start-Process -FilePath $shortcutPath
}

Write-Host "Installed gateway autostart shortcut: $shortcutPath"
Write-Host 'The dispatcher is cost-idle while the board is empty.'

