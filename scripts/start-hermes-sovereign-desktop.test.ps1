<#
.SYNOPSIS
    Deterministic contract tests for start-hermes-sovereign-desktop.ps1.

.DESCRIPTION
    Dot-sources the launcher (which defines its pure helpers WITHOUT launching anything)
    and drives them with injected path/port probes so the whole configuration contract is
    proven with zero disk/socket IO and no Electron. Proves: environment restoration on
    success AND failure, malformed/relative paths reject, source/data overlap rejects,
    protected gateway ports reject, occupied ports reject, non-distinct ports reject,
    missing adapter files reject, argv JSON round-trips (including spaces), and the feature
    stays opt-in (dot-sourcing sets no flag and launches nothing). No large framework:
    a tiny assert harness mirroring scripts/verify.ps1.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'start-hermes-sovereign-desktop.ps1')

$script:Passed = 0
$script:Failed = 0
$script:FailedNames = @()

function Assert-That {
    param([bool]$Condition, [Parameter(Mandatory)][string]$Name, [string]$Detail = '')
    if ($Condition) {
        $script:Passed++
        Write-Host "  PASS $Name"
    } else {
        $script:Failed++
        $script:FailedNames += $Name
        Write-Host "  FAIL $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "       $Detail" -ForegroundColor Red }
    }
}

function Assert-Reason {
    param([object]$Verdict, [string]$ExpectedReason, [string]$Name)
    $ok = (-not $Verdict.Ok) -and ($Verdict.Reason -eq $ExpectedReason)
    Assert-That $ok $Name "expected reason=$ExpectedReason actual Ok=$($Verdict.Ok) Reason=$($Verdict.Reason)"
}

$PathExistsAll = { param($p) $true }
$PortFree = { param($h, $p) $false }
$PortBusy = { param($h, $p) $true }

function New-BaseConfig {
    param([hashtable]$Overrides = @{})
    $base = @{
        NodePath       = 'C:\Program Files\nodejs\node.exe'
        SourceRoot     = 'C:\src\sovereign'
        DataDir        = 'C:\Users\x\AppData\Local\hermes\sovereign\product-data'
        AdapterEntry   = 'C:\repo\scripts\sovereign-product-host.mjs'
        AdapterCore    = 'C:\repo\electron\sovereign-product-host.cjs'
        AdapterRuntime = 'C:\repo\electron\sovereign-runtime.cjs'
        ProductPort    = 4312
        ApiPort        = 4310
        Host           = 'localhost'
        HealthPath     = '/__hermes/health'
        ArgsJson       = '["C:\\repo\\scripts\\sovereign-product-host.mjs","--source-root","C:\\src\\sovereign","--data-dir","C:\\Users\\x\\AppData\\Local\\hermes\\sovereign\\product-data","--api-host","127.0.0.1","--api-port","4310"]'
    }
    foreach ($key in $Overrides.Keys) { $base[$key] = $Overrides[$key] }
    return $base
}

Write-Host "`n== helpers defined on dot-source =="
Assert-That ([bool](Get-Command Test-SovereignLauncherConfig -ErrorAction SilentlyContinue)) 'helpers.validator.defined'
Assert-That ([bool](Get-Command Restore-EnvironmentSnapshot -ErrorAction SilentlyContinue)) 'helpers.envRestore.defined'
Assert-That ([bool](Get-Command Invoke-StartHermesSovereignDesktop -ErrorAction SilentlyContinue)) 'helpers.entry.defined'

Write-Host "`n== feature remains opt-in =="
# Dot-sourcing must not enable the flag or launch anything (the entry is guarded).
Assert-That ($null -eq [System.Environment]::GetEnvironmentVariable('HERMES_DESKTOP_SOVEREIGN', 'Process')) 'optIn.dotSourceSetsNoFlag'

Write-Host "`n== happy path validates =="
$ok = Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $PathExistsAll -PortProbe $PortFree
Assert-That ($ok.Ok -eq $true) 'valid.ok' "Reason=$($ok.Reason)"

Write-Host "`n== malformed / relative paths reject =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ SourceRoot = 'relative\src' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'SOURCE_ROOT_NOT_ABSOLUTE' 'reject.sourceRelative'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ SourceRoot = 'C:sovereign' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'SOURCE_ROOT_NOT_ABSOLUTE' 'reject.sourceDriveRelative'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ DataDir = '..\data' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'DATA_DIR_NOT_ABSOLUTE' 'reject.dataRelative'

Write-Host "`n== source / data overlap rejects =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ DataDir = 'C:\src\sovereign\data' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'DATA_DIR_INSIDE_SOURCE' 'reject.dataInsideSource'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ DataDir = 'C:\src\sovereign' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'DATA_DIR_INSIDE_SOURCE' 'reject.dataEqualsSource'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ SourceRoot = 'C:\data\sub'; DataDir = 'C:\data' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'DATA_DIR_INSIDE_SOURCE' 'reject.sourceInsideData'

Write-Host "`n== protected gateway ports reject =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ProductPort = 8643 }) -PathExists $PathExistsAll -PortProbe $PortFree) 'PORT_RESERVED_GATEWAY' 'reject.productReserved'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ApiPort = 8642 }) -PathExists $PathExistsAll -PortProbe $PortFree) 'PORT_RESERVED_GATEWAY' 'reject.apiReserved'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ApiPort = 8644 }) -PathExists $PathExistsAll -PortProbe $PortFree) 'PORT_RESERVED_GATEWAY' 'reject.apiReserved8644'

Write-Host "`n== non-distinct ports reject =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ApiPort = 4312 }) -PathExists $PathExistsAll -PortProbe $PortFree) 'PORT_NOT_DISTINCT' 'reject.samePort'

Write-Host "`n== occupied ports reject =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $PathExistsAll -PortProbe $PortBusy) 'PORT_OCCUPIED' 'reject.occupied'

Write-Host "`n== missing adapter files reject =="
$entryMissing = { param($p) -not ([string]$p).EndsWith('sovereign-product-host.mjs') }
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $entryMissing -PortProbe $PortFree) 'ADAPTER_ENTRY_MISSING' 'reject.adapterEntryMissing'
$coreMissing = { param($p) -not ([string]$p).EndsWith('sovereign-product-host.cjs') }
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $coreMissing -PortProbe $PortFree) 'ADAPTER_CORE_MISSING' 'reject.adapterCoreMissing'
$runtimeMissing = { param($p) -not ([string]$p).EndsWith('sovereign-runtime.cjs') }
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $runtimeMissing -PortProbe $PortFree) 'ADAPTER_RUNTIME_MISSING' 'reject.adapterRuntimeMissing'

Write-Host "`n== missing source build artifacts reject =="
$noWebIndex = { param($p) -not ([string]$p).EndsWith('index.html') }
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $noWebIndex -PortProbe $PortFree) 'WEB_INDEX_MISSING' 'reject.webIndexMissing'
$noBootstrap = { param($p) -not ([string]$p).EndsWith('bootstrap.js') }
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig) -PathExists $noBootstrap -PortProbe $PortFree) 'CONTROL_PLANE_ENTRY_MISSING' 'reject.bootstrapMissing'

Write-Host "`n== health path must be private =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ HealthPath = '/health' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'HEALTH_PATH_NOT_PRIVATE' 'reject.healthNotPrivate'

Write-Host "`n== malformed argv JSON rejects =="
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ArgsJson = 'not-json' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'ARGS_INVALID' 'reject.argsMalformed'
Assert-Reason (Test-SovereignLauncherConfig -Config (New-BaseConfig @{ ArgsJson = '[1,2,3]' }) -PathExists $PathExistsAll -PortProbe $PortFree) 'ARGS_INVALID' 'reject.argsNotStrings'

Write-Host "`n== argv JSON round-trips (handles spaces) =="
$spEntry = 'C:\repo dir\scripts\sovereign-product-host.mjs'
$spSource = 'C:\Program Files\sovereign src'
$spData = 'C:\Users\x y\AppData\Local\hermes\data'
$argv = New-SovereignArgv -Entry $spEntry -SourceRoot $spSource -DataDir $spData -ApiPort 4310
$json = ConvertTo-SovereignArgsJson -Argv $argv
Assert-That ($json.StartsWith('[') -and $json.EndsWith(']')) 'argv.json.isArray' "json=$json"
# Assign to a variable first, THEN wrap with @(): Windows PowerShell 5.1's
# ConvertFrom-Json emits a top-level array as a single (non-enumerated) object, so
# @(inline-pipeline) would wrap it to one element. @($variable) preserves the count.
$parsed = $json | ConvertFrom-Json
$roundTrip = @($parsed)
Assert-That ($roundTrip.Count -eq 9) 'argv.json.count' "count=$($roundTrip.Count)"
Assert-That ($roundTrip[0] -eq $spEntry) 'argv.json.entryFirst' "argv0=$($roundTrip[0])"
Assert-That ($roundTrip[1] -eq '--source-root') 'argv.json.flagSource'
Assert-That ($roundTrip[2] -eq $spSource) 'argv.json.sourceHasSpaces' "value=$($roundTrip[2])"
Assert-That ($roundTrip[4] -eq $spData) 'argv.json.dataHasSpaces' "value=$($roundTrip[4])"
Assert-That ($roundTrip[8] -eq '4310') 'argv.json.apiPort'
# The spaced-argv config still validates end to end.
$spConfig = New-BaseConfig @{ SourceRoot = $spSource; DataDir = $spData; AdapterEntry = $spEntry; ArgsJson = $json }
Assert-That ((Test-SovereignLauncherConfig -Config $spConfig -PathExists $PathExistsAll -PortProbe $PortFree).Ok) 'argv.json.validConfig'

Write-Host "`n== absolute-path helper =="
Assert-That (Test-AbsoluteWindowsPath 'C:\a\b') 'abs.drive'
Assert-That (Test-AbsoluteWindowsPath '\\server\share\x') 'abs.unc'
Assert-That (-not (Test-AbsoluteWindowsPath 'a\b')) 'abs.relativeRejected'
Assert-That (-not (Test-AbsoluteWindowsPath 'C:rel')) 'abs.driveRelativeRejected'
Assert-That (-not (Test-AbsoluteWindowsPath '\rooted')) 'abs.bareRootedRejected'

Write-Host "`n== environment restoration on success =="
[System.Environment]::SetEnvironmentVariable('TEST_SOV_MOD', 'orig', 'Process')
[System.Environment]::SetEnvironmentVariable('TEST_SOV_DEL', 'exists', 'Process')
[System.Environment]::SetEnvironmentVariable('TEST_SOV_ADD', $null, 'Process')
$snap = Get-EnvironmentSnapshot
[System.Environment]::SetEnvironmentVariable('TEST_SOV_MOD', 'changed', 'Process')
[System.Environment]::SetEnvironmentVariable('TEST_SOV_DEL', $null, 'Process')
[System.Environment]::SetEnvironmentVariable('TEST_SOV_ADD', 'added', 'Process')
Restore-EnvironmentSnapshot -Snapshot $snap
Assert-That ([System.Environment]::GetEnvironmentVariable('TEST_SOV_MOD', 'Process') -eq 'orig') 'env.success.modifiedRestored'
Assert-That ([System.Environment]::GetEnvironmentVariable('TEST_SOV_DEL', 'Process') -eq 'exists') 'env.success.deletedRestored'
Assert-That ($null -eq [System.Environment]::GetEnvironmentVariable('TEST_SOV_ADD', 'Process')) 'env.success.addedRemoved'
foreach ($n in 'TEST_SOV_MOD', 'TEST_SOV_DEL', 'TEST_SOV_ADD') { [System.Environment]::SetEnvironmentVariable($n, $null, 'Process') }

Write-Host "`n== environment restoration on failure (try/finally) =="
[System.Environment]::SetEnvironmentVariable('TEST_SOV_FAIL', 'before', 'Process')
$snap2 = Get-EnvironmentSnapshot
$threw = $false
try {
    [System.Environment]::SetEnvironmentVariable('TEST_SOV_FAIL', 'during', 'Process')
    [System.Environment]::SetEnvironmentVariable('TEST_SOV_FAIL_ADD', 'x', 'Process')
    throw 'simulated launcher failure'
} catch {
    $threw = $true
} finally {
    Restore-EnvironmentSnapshot -Snapshot $snap2
}
Assert-That $threw 'env.failure.threw'
Assert-That ([System.Environment]::GetEnvironmentVariable('TEST_SOV_FAIL', 'Process') -eq 'before') 'env.failure.modifiedRestored'
Assert-That ($null -eq [System.Environment]::GetEnvironmentVariable('TEST_SOV_FAIL_ADD', 'Process')) 'env.failure.addedRemoved'
[System.Environment]::SetEnvironmentVariable('TEST_SOV_FAIL', $null, 'Process')

Write-Host "`n== Result =="
Write-Host "passed=$script:Passed failed=$script:Failed"
if ($script:Failed -gt 0) {
    Write-Host "FAILURES: $($script:FailedNames -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host 'PASS: launcher configuration contract verified.'
exit 0
