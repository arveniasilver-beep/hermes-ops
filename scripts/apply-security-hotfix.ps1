[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$HermesRoot = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent'
$HermesExe = Join-Path $HermesRoot 'venv\Scripts\hermes.exe'
$PythonExe = Join-Path $HermesRoot 'venv\Scripts\python.exe'
$UvExe = Join-Path $env:LOCALAPPDATA 'hermes\bin\uv.exe'
$PyprojectPath = Join-Path $HermesRoot 'pyproject.toml'
$startup = [Environment]::GetFolderPath('Startup')

foreach ($path in @($HermesExe, $PythonExe, $UvExe, $PyprojectPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required executable missing: $path" }
}

$packages = @(
    'cryptography==48.0.1',
    'python-multipart==0.0.31',
    'starlette==1.3.1',
    'pydantic-settings==2.14.2',
    'pip==26.1.2',
    'Pygments==2.20.0',
    'click==8.3.3',
    'httplib2==0.32.0',
    'pillow==12.3.0',
    'setuptools==83.0.0'
)

$dashboardWasRunning = [bool](Get-NetTCPConnection -LocalPort 9119 -State Listen -ErrorAction SilentlyContinue)
$gatewayWasRunning = [bool](Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(python|hermes)\.exe$' -and
    $_.CommandLine -match 'owner-orchestrator gateway run'
})

$targets = Get-CimInstance Win32_Process | Where-Object {
    $_.ProcessId -ne $PID -and
    $_.Name -match '^(powershell|python|hermes)\.exe$' -and
    ($_.CommandLine -match 'dashboard --port 9119' -or
     $_.CommandLine -match 'owner-orchestrator gateway run')
}
foreach ($target in $targets) {
    Stop-Process -Id $target.ProcessId -Force -ErrorAction SilentlyContinue
}
if ($targets) { Start-Sleep -Seconds 2 }

$completed = $false
try {
    $metadata = [IO.File]::ReadAllText($PyprojectPath)
    $pinUpdates = @(
        @{
            Name = 'cryptography'
            LegacyPattern = '(?m)^([ \t]*)"cryptography==46\.0\.7",[^\r\n]*'
            FixedPattern = '(?m)^[ \t]*"cryptography==48\.0\.1",'
            Replacement = '$1"cryptography==48.0.1",  # GHSA-537c-gmf6-5ccf'
        },
        @{
            Name = 'Pillow'
            LegacyPattern = '(?m)^([ \t]*)"Pillow==12\.2\.0",[ \t]*'
            FixedPattern = '(?m)^[ \t]*"Pillow==12\.3\.0",'
            Replacement = '$1"Pillow==12.3.0",'
        }
    )

    $metadataChanged = $false
    foreach ($pin in $pinUpdates) {
        if ([regex]::IsMatch($metadata, $pin.FixedPattern)) { continue }
        if (-not [regex]::IsMatch($metadata, $pin.LegacyPattern)) {
            throw "Hermes dependency pin for $($pin.Name) changed upstream; review before applying the overlay."
        }
        $metadata = [regex]::Replace($metadata, $pin.LegacyPattern, $pin.Replacement, 1)
        $metadataChanged = $true
    }
    if ($metadataChanged) {
        [IO.File]::WriteAllText($PyprojectPath, $metadata, [Text.UTF8Encoding]::new($false))
    }

    & $UvExe pip install --python $PythonExe @packages
    if ($LASTEXITCODE -ne 0) { throw 'Security package installation failed.' }

    & $UvExe pip install --python $PythonExe --no-deps --editable $HermesRoot
    if ($LASTEXITCODE -ne 0) { throw 'Could not refresh Hermes editable package metadata.' }

    & $PythonExe -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'pip check found an incompatible dependency.' }

    & $PythonExe -c 'import cryptography, fastapi, starlette, multipart, pydantic_settings, PIL'
    if ($LASTEXITCODE -ne 0) { throw 'Security overlay import test failed.' }
    Write-Host 'Security overlay imports: OK'

    & $HermesExe -p owner-orchestrator security audit --fail-on high
    if ($LASTEXITCODE -ne 0) { throw 'OSV audit still contains a high-severity finding.' }
    $completed = $true
} finally {
    if ($dashboardWasRunning) {
        $shortcut = Join-Path $startup 'Hermes Dashboard.lnk'
        if (Test-Path -LiteralPath $shortcut) { Start-Process -FilePath $shortcut }
    }
    if ($gatewayWasRunning) {
        $shortcut = Join-Path $startup 'Hermes Gateway.lnk'
        if (Test-Path -LiteralPath $shortcut) { Start-Process -FilePath $shortcut }
    }
}

if (-not $completed) { throw 'Hermes runtime security overlay did not complete.' }

Write-Host 'Hermes runtime security overlay applied and verified.'
Write-Host 'Re-run this script after a Hermes update until the upstream lock includes these fixes.'
