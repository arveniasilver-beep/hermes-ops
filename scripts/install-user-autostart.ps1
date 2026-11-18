[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Driver = Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin\cua-driver.exe'

if (-not (Test-Path -LiteralPath $Driver)) {
    throw "cua-driver is not installed at $Driver"
}

$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Hermes Cua Driver.lnk'
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
$escapedDriver = $Driver.Replace("'", "''")

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShellExe
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -Command & '$escapedDriver' serve"
$shortcut.WorkingDirectory = Split-Path -Parent $Driver
$shortcut.WindowStyle = 7
$shortcut.Description = 'Start Hermes computer-use driver for the current user'
$shortcut.Save()

$running = Get-Process -Name 'cua-driver' -ErrorAction SilentlyContinue
if (-not $running) {
    Start-Process -FilePath $Driver -ArgumentList 'serve' -WindowStyle Hidden
}

Write-Host "Installed current-user autostart shortcut: $shortcutPath"
Write-Host 'This intentionally does not grant access to elevated administrator windows.'

