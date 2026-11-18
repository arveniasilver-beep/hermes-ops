[CmdletBinding()]
param(
    [ValidatePattern('^[a-z0-9][a-z0-9_-]{0,63}$')]
    [string]$Profile = 'owner-orchestrator',
    [ValidateRange(1, 65535)]
    [int]$Port = 9119
)

$ErrorActionPreference = 'Stop'

$all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
$profilePattern = [Regex]::Escape($Profile)
$roots = @($all | Where-Object {
    $_.CommandLine -match "-p $profilePattern dashboard --host 127\.0\.0\.1 --port $Port(?:\s|$)"
})

if ($roots.Count -eq 0) {
    Write-Host "No managed diagnostic dashboard is running on 127.0.0.1:$Port."
    exit 0
}

$targets = [Collections.Generic.HashSet[int]]::new()
foreach ($root in $roots) { [void]$targets.Add([int]$root.ProcessId) }
do {
    $before = $targets.Count
    foreach ($process in $all) {
        if ($targets.Contains([int]$process.ParentProcessId)) {
            [void]$targets.Add([int]$process.ProcessId)
        }
    }
} while ($targets.Count -gt $before)

foreach ($process in @($all | Where-Object {
    $targets.Contains([int]$_.ProcessId)
} | Sort-Object CreationDate -Descending)) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Milliseconds 500
$remaining = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $targets.Contains([int]$_.ProcessId)
})
if ($remaining.Count -gt 0) {
    throw "Diagnostic dashboard process tree did not stop: $($remaining.ProcessId -join ', ')"
}

Write-Host "Stopped the managed diagnostic dashboard on 127.0.0.1:$Port."
