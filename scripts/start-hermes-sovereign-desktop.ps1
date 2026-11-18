<#
.SYNOPSIS
    Launch the Hermes desktop with the Sovereign PRODUCT HOST integration enabled
    for that one child invocation only.

.DESCRIPTION
    This is a thin, reversible wrapper around scripts/start-hermes-desktop.ps1. It
    computes and validates the product-host launch contract (source root, a durable
    Hermes-owned DATA_DIR OUTSIDE the source tree, system Node, the packaged-or-source
    adapter entry, distinct loopback ports, the private health path and the JSON argv),
    sets the HERMES_DESKTOP_SOVEREIGN_* environment ONLY for the nested launcher (which
    launches Electron in-process so Start-Process inherits it), then restores the caller
    environment EXACTLY in a finally block — on success or failure.

    Security posture (fail-closed, never "best effort"):
      * The whole Sovereign surface stays OFF by default. Nothing here runs unless the
        operator invokes this wrapper; merely dot-sourcing it (for tests) sets no env
        and launches nothing.
      * The persistent gateway ports 8642/8643/8644 are refused for BOTH the product and
        the internal API port, so this path can never manage a gateway.
      * DATA_DIR must resolve OUTSIDE the Sovereign source tree, so identity/session JSON
        is never written into the repo.
      * No secret is read, stored or printed. Only non-secret paths/ports are echoed. The
        ownership token is generated at runtime inside Electron and never touched here.

    The product host imports the stock control-plane IN-PROCESS, so ONE supervisor-owned
    Node pid owns both the product listener (4312) and the internal API listener (4310).

    The product ORIGIN is localhost (http://localhost:4312/) so the WebAuthn canonical
    origin (RP id "localhost") matches the isolated webview; the internal control-plane
    API stays on 127.0.0.1:4310. See docs/decisions/0011-native-sovereign-service-supervisor.md.

.NOTES
    Dot-source this file to unit-test its pure helpers without launching anything
    (scripts/start-hermes-sovereign-desktop.test.ps1 does exactly that). The launch body
    runs only when the script is invoked directly, never when dot-sourced.
#>
[CmdletBinding()]
param(
    # Absolute path to the stock Sovereign source (contains apps/web/dist +
    # apps/control-plane/dist). Defaults to the external checkout; accepts an override.
    [string]$SourceRoot = 'C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent',

    # Absolute Hermes-owned DATA_DIR for the control-plane JSON stores. Defaults to a
    # durable path under HERMES_HOME (never inside SourceRoot).
    [string]$DataDir,

    # Forwarded verbatim to start-hermes-desktop.ps1.
    [ValidatePattern('^[a-z0-9][a-z0-9_-]{0,63}$')]
    [string]$Profile = 'owner-orchestrator',
    [ValidateRange(5, 120)]
    [int]$ReadyTimeoutSeconds = 45,
    [switch]$UseInstalledRuntime,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'

# The three persistent gateway ports the desktop must never manage or collide with.
$SovereignReservedGatewayPorts = @(8642, 8643, 8644)

# --------------------------------------------------------------------------------------
# Pure, dependency-injectable helpers (defined on dot-source; exercised by the test).
# --------------------------------------------------------------------------------------

function New-SovereignVerdict {
    param([bool]$Ok, [string]$Reason)
    return [pscustomobject]@{ Ok = $Ok; Reason = $Reason }
}

# A fully-qualified Windows path only: a drive-absolute (C:\...) or UNC (\\server\...)
# path. Rejects relative, bare-rooted (\foo) and drive-relative (C:foo) forms so a
# launch can never resolve against an accidental working directory.
function Test-AbsoluteWindowsPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return [bool]([regex]::IsMatch($Path, '^(?:[A-Za-z]:\\|\\\\[^\\])'))
}

function Test-SovereignLoopbackHost {
    param([string]$TargetHost)
    $h = ([string]$TargetHost).Trim().ToLowerInvariant()
    return @('127.0.0.1', 'localhost', '::1') -contains $h
}

# True when $Child is exactly $Parent or lives strictly under it (separator boundary,
# case-insensitive), using lexical full-path normalization so neither path needs to
# exist. Used to keep DATA_DIR out of the source tree (either direction).
function Test-PathContains {
    param([string]$Parent, [string]$Child)
    if ([string]::IsNullOrWhiteSpace($Parent) -or [string]::IsNullOrWhiteSpace($Child)) { return $false }
    try {
        $p = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\', '/')
        $c = [System.IO.Path]::GetFullPath($Child).TrimEnd('\', '/')
    } catch {
        return $false
    }
    if ([string]::Equals($c, $p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    return $c.StartsWith($p + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

# Real loopback TCP probe (default injected PortProbe). True iff something is accepting
# connections on host:port right now. A refused/timed-out connect => free.
function Test-SovereignPortListening {
    param([string]$TargetHost, [int]$Port, [int]$TimeoutMs = 400)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($TargetHost, $Port, $null, $null)
        $completed = $async.AsyncWaitHandle.WaitOne($TimeoutMs)
        if ($completed -and $client.Connected) { return $true }
        return $false
    } catch {
        return $false
    } finally {
        try { $client.Close() } catch { }
    }
}

# Resolve the system Node executable to an absolute path and confirm the version
# satisfies the desktop engines range (^20.19.0 || >=22.12.0). Dependency-injected so
# the test can drive it deterministically.
function Resolve-SystemNodePath {
    param(
        [scriptblock]$CommandLookup = { Get-Command node -CommandType Application -ErrorAction SilentlyContinue },
        [scriptblock]$VersionProbe = { param($exe) & $exe --version 2>$null }
    )
    $cmd = & $CommandLookup | Select-Object -First 1
    if (-not $cmd) { return [pscustomobject]@{ Ok = $false; Path = $null; Version = $null; Reason = 'NODE_NOT_FOUND' } }
    $path = if ($cmd.Source) { [string]$cmd.Source } elseif ($cmd.Path) { [string]$cmd.Path } else { [string]$cmd }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
        return [pscustomobject]@{ Ok = $false; Path = $null; Version = $null; Reason = 'NODE_NOT_FOUND' }
    }
    $raw = (& $VersionProbe $path | Select-Object -First 1)
    $version = ([string]$raw).Trim()
    $match = [regex]::Match($version, '^v?(\d+)\.(\d+)\.(\d+)')
    if (-not $match.Success) {
        return [pscustomobject]@{ Ok = $false; Path = $path; Version = $version; Reason = 'NODE_VERSION_UNKNOWN' }
    }
    $major = [int]$match.Groups[1].Value
    $minor = [int]$match.Groups[2].Value
    $supported = $false
    if ($major -eq 20 -and $minor -ge 19) { $supported = $true }
    elseif ($major -eq 22 -and $minor -ge 12) { $supported = $true }
    elseif ($major -ge 23) { $supported = $true }
    if (-not $supported) {
        return [pscustomobject]@{ Ok = $false; Path = $path; Version = $version; Reason = 'NODE_UNSUPPORTED' }
    }
    return [pscustomobject]@{ Ok = $true; Path = $path; Version = $version; Reason = $null }
}

# Resolve the product-host adapter trio, preferring the PACKAGED resources path (an
# unpacked, external-Node-readable resources dir) and falling back to the in-tree source
# adapter for development. The relative import scripts/*.mjs -> ../electron/*.cjs is
# preserved by construction in both layouts. Dependency-injected existence check.
function Get-SovereignAdapterPaths {
    param(
        [Parameter(Mandatory)][string]$DesktopRoot,
        [scriptblock]$PathExists = { param($p) Test-Path -LiteralPath $p }
    )
    $packagedRoot = Join-Path $DesktopRoot 'release\win-unpacked\resources\sovereign-product-host'
    $candidates = @(
        [pscustomobject]@{ Origin = 'packaged'; Scripts = (Join-Path $packagedRoot 'scripts'); Electron = (Join-Path $packagedRoot 'electron') },
        [pscustomobject]@{ Origin = 'source'; Scripts = (Join-Path $DesktopRoot 'scripts'); Electron = (Join-Path $DesktopRoot 'electron') }
    )
    foreach ($candidate in $candidates) {
        $entry = Join-Path $candidate.Scripts 'sovereign-product-host.mjs'
        $core = Join-Path $candidate.Electron 'sovereign-product-host.cjs'
        $runtime = Join-Path $candidate.Electron 'sovereign-runtime.cjs'
        if ((& $PathExists $entry) -and (& $PathExists $core) -and (& $PathExists $runtime)) {
            return [pscustomobject]@{ Ok = $true; Origin = $candidate.Origin; Entry = $entry; Core = $core; Runtime = $runtime; Reason = $null }
        }
    }
    return [pscustomobject]@{ Ok = $false; Origin = $null; Entry = $null; Core = $null; Runtime = $null; Reason = 'ADAPTER_FILES_MISSING' }
}

# Build the adapter argv (argv[0] is the entry the supervisor hands to Node). Non-secret
# paths/ports only.
function New-SovereignArgv {
    param(
        [Parameter(Mandatory)][string]$Entry,
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$DataDir,
        [Parameter(Mandatory)][int]$ApiPort,
        [string]$ApiHost = '127.0.0.1'
    )
    return @(
        $Entry,
        '--source-root', $SourceRoot,
        '--data-dir', $DataDir,
        '--api-host', $ApiHost,
        '--api-port', [string]$ApiPort
    )
}

# Serialize argv as a JSON array of strings (the ONLY form HERMES_DESKTOP_SOVEREIGN_ARGS
# accepts). Each element is converted independently so the result is always a JSON array
# (PowerShell's whole-pipeline ConvertTo-Json collapses a single-element array to a
# scalar) with backslashes/quotes/spaces escaped correctly for Node's JSON.parse.
function ConvertTo-SovereignArgsJson {
    param([Parameter(Mandatory)][string[]]$Argv)
    $parts = foreach ($item in $Argv) { ($item | ConvertTo-Json -Compress) }
    return '[' + ($parts -join ',') + ']'
}

# The single fail-closed validation gate. Every existence check goes through $PathExists
# and every occupancy check through $PortProbe, so the whole contract is deterministically
# testable with zero disk/socket IO. Returns { Ok, Reason }.
function Test-SovereignLauncherConfig {
    param(
        [Parameter(Mandatory)][hashtable]$Config,
        [scriptblock]$PathExists = { param($p) Test-Path -LiteralPath $p },
        [scriptblock]$PortProbe = { param($h, $p) Test-SovereignPortListening -TargetHost $h -Port $p }
    )
    $reserved = @(8642, 8643, 8644)

    # System Node.
    if ([string]::IsNullOrWhiteSpace($Config.NodePath)) { return (New-SovereignVerdict $false 'NODE_NOT_FOUND') }
    if (-not [bool](& $PathExists $Config.NodePath)) { return (New-SovereignVerdict $false 'NODE_NOT_FOUND') }

    # Source root: absolute + present + build artifacts contained.
    if (-not (Test-AbsoluteWindowsPath $Config.SourceRoot)) { return (New-SovereignVerdict $false 'SOURCE_ROOT_NOT_ABSOLUTE') }
    if (-not [bool](& $PathExists $Config.SourceRoot)) { return (New-SovereignVerdict $false 'SOURCE_ROOT_MISSING') }
    $webIndex = Join-Path $Config.SourceRoot 'apps\web\dist\index.html'
    if (-not [bool](& $PathExists $webIndex)) { return (New-SovereignVerdict $false 'WEB_INDEX_MISSING') }
    $controlPlaneEntry = Join-Path $Config.SourceRoot 'apps\control-plane\dist\bootstrap.js'
    if (-not [bool](& $PathExists $controlPlaneEntry)) { return (New-SovereignVerdict $false 'CONTROL_PLANE_ENTRY_MISSING') }

    # Data dir: absolute + separated from the source tree (either containment direction).
    if (-not (Test-AbsoluteWindowsPath $Config.DataDir)) { return (New-SovereignVerdict $false 'DATA_DIR_NOT_ABSOLUTE') }
    if ((Test-PathContains $Config.SourceRoot $Config.DataDir) -or (Test-PathContains $Config.DataDir $Config.SourceRoot)) {
        return (New-SovereignVerdict $false 'DATA_DIR_INSIDE_SOURCE')
    }

    # Adapter files (preserve the scripts/*.mjs -> ../electron/*.cjs import relationship).
    if (-not [bool](& $PathExists $Config.AdapterEntry)) { return (New-SovereignVerdict $false 'ADAPTER_ENTRY_MISSING') }
    if (-not [bool](& $PathExists $Config.AdapterCore)) { return (New-SovereignVerdict $false 'ADAPTER_CORE_MISSING') }
    if (-not [bool](& $PathExists $Config.AdapterRuntime)) { return (New-SovereignVerdict $false 'ADAPTER_RUNTIME_MISSING') }

    # Ports: valid range, not a reserved gateway, distinct, loopback host.
    foreach ($portKey in @('ProductPort', 'ApiPort')) {
        $p = [int]$Config[$portKey]
        if ($p -lt 1 -or $p -gt 65535) { return (New-SovereignVerdict $false 'PORT_INVALID') }
        if ($reserved -contains $p) { return (New-SovereignVerdict $false 'PORT_RESERVED_GATEWAY') }
    }
    if ([int]$Config.ProductPort -eq [int]$Config.ApiPort) { return (New-SovereignVerdict $false 'PORT_NOT_DISTINCT') }
    if (-not (Test-SovereignLoopbackHost $Config.Host)) { return (New-SovereignVerdict $false 'HOST_NOT_LOOPBACK') }

    # Occupancy: neither the product nor the API port may be in use (probe both families).
    foreach ($p in @([int]$Config.ProductPort, [int]$Config.ApiPort)) {
        if ([bool](& $PortProbe '127.0.0.1' $p) -or [bool](& $PortProbe '::1' $p)) {
            return (New-SovereignVerdict $false 'PORT_OCCUPIED')
        }
    }

    # Health path must live in the adapter-private namespace (un-proxyable token echo).
    if (-not ($Config.HealthPath -eq '/__hermes' -or ([string]$Config.HealthPath).StartsWith('/__hermes/'))) {
        return (New-SovereignVerdict $false 'HEALTH_PATH_NOT_PRIVATE')
    }

    # Argv JSON must round-trip to a non-empty array of strings.
    try {
        $parsed = $Config.ArgsJson | ConvertFrom-Json
    } catch {
        return (New-SovereignVerdict $false 'ARGS_INVALID')
    }
    $array = @($parsed)
    if ($array.Count -lt 1) { return (New-SovereignVerdict $false 'ARGS_INVALID') }
    foreach ($item in $array) {
        if ($item -isnot [string]) { return (New-SovereignVerdict $false 'ARGS_INVALID') }
    }

    return (New-SovereignVerdict $true $null)
}

# Snapshot every process-scope environment variable so it can be restored byte-for-byte.
function Get-EnvironmentSnapshot {
    $snapshot = @{}
    foreach ($entry in [System.Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
        $snapshot[[string]$entry.Key] = [string]$entry.Value
    }
    return $snapshot
}

# Restore the process environment to EXACTLY a prior snapshot: drop any variable added
# since (including whatever the nested launcher set), then reset every snapshot variable
# to its captured value. Idempotent; safe to call from finally on any code path.
function Restore-EnvironmentSnapshot {
    param([Parameter(Mandatory)][hashtable]$Snapshot)
    foreach ($entry in [System.Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
        $name = [string]$entry.Key
        if (-not $Snapshot.ContainsKey($name)) {
            [System.Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }
    foreach ($name in $Snapshot.Keys) {
        [System.Environment]::SetEnvironmentVariable([string]$name, [string]$Snapshot[$name], 'Process')
    }
}

# --------------------------------------------------------------------------------------
# Launch entry (runs only when the script is invoked directly, never on dot-source).
# --------------------------------------------------------------------------------------

function Invoke-StartHermesSovereignDesktop {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [string]$DataDir,
        [string]$Profile = 'owner-orchestrator',
        [int]$ReadyTimeoutSeconds = 45,
        [switch]$UseInstalledRuntime,
        [switch]$NoLaunch,
        [string]$ScriptRoot = $PSScriptRoot
    )

    # Fixed, non-secret product-host contract.
    $productPort = 4312
    $apiPort = 4310
    $productHost = 'localhost'
    $healthPath = '/__hermes/health'

    $repoRoot = Split-Path -Parent $ScriptRoot
    $desktopRoot = Join-Path $repoRoot 'runtime\hermes-agent\apps\desktop'
    $innerLauncher = Join-Path $ScriptRoot 'start-hermes-desktop.ps1'
    if (-not (Test-Path -LiteralPath $innerLauncher)) {
        throw "Inner launcher not found: $innerLauncher"
    }

    # Durable DATA_DIR under HERMES_HOME (never inside the source tree).
    if ([string]::IsNullOrWhiteSpace($DataDir)) {
        $hermesHome = if (-not [string]::IsNullOrWhiteSpace($env:HERMES_HOME)) { $env:HERMES_HOME } else { Join-Path $env:LOCALAPPDATA 'hermes' }
        $DataDir = Join-Path $hermesHome 'sovereign\product-data'
    }

    $node = Resolve-SystemNodePath
    if (-not $node.Ok) { throw "System Node is unavailable or unsupported ($($node.Reason)). Install Node ^20.19 || >=22.12 and retry." }

    $adapter = Get-SovereignAdapterPaths -DesktopRoot $desktopRoot
    if (-not $adapter.Ok) { throw "Sovereign product-host adapter files not found under $desktopRoot ($($adapter.Reason))." }

    $argv = New-SovereignArgv -Entry $adapter.Entry -SourceRoot $SourceRoot -DataDir $DataDir -ApiPort $apiPort -ApiHost '127.0.0.1'
    $argsJson = ConvertTo-SovereignArgsJson -Argv $argv

    $config = @{
        NodePath       = $node.Path
        SourceRoot     = $SourceRoot
        DataDir        = $DataDir
        AdapterEntry   = $adapter.Entry
        AdapterCore    = $adapter.Core
        AdapterRuntime = $adapter.Runtime
        ProductPort    = $productPort
        ApiPort        = $apiPort
        Host           = $productHost
        HealthPath     = $healthPath
        ArgsJson       = $argsJson
    }
    $verdict = Test-SovereignLauncherConfig -Config $config
    if (-not $verdict.Ok) { throw "Sovereign launcher configuration refused: $($verdict.Reason)" }

    # Create the Hermes-owned data dir safely (idempotent; outside the source tree).
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

    $surfaceUrl = "http://${productHost}:$productPort/"
    $productEnv = [ordered]@{
        HERMES_DESKTOP_SOVEREIGN             = '1'
        HERMES_DESKTOP_SOVEREIGN_CMD         = $node.Path
        HERMES_DESKTOP_SOVEREIGN_ARGS        = $argsJson
        HERMES_DESKTOP_SOVEREIGN_CWD         = $DataDir
        HERMES_DESKTOP_SOVEREIGN_HOST        = $productHost
        HERMES_DESKTOP_SOVEREIGN_PORT        = [string]$productPort
        HERMES_DESKTOP_SOVEREIGN_HEALTH_PATH = $healthPath
        HERMES_DESKTOP_SOVEREIGN_SURFACE_URL = $surfaceUrl
    }

    # Non-secret summary only; never dump environment values.
    Write-Host 'Hermes Sovereign product-host launcher'
    Write-Host "  Source root : $SourceRoot"
    Write-Host "  Data dir    : $DataDir"
    Write-Host "  Node        : $($node.Path) ($($node.Version))"
    Write-Host "  Adapter     : $($adapter.Entry) [$($adapter.Origin)]"
    Write-Host "  Product     : $surfaceUrl (internal API 127.0.0.1:$apiPort)"
    Write-Host "  Health      : $healthPath"

    $snapshot = Get-EnvironmentSnapshot
    try {
        foreach ($name in $productEnv.Keys) {
            [System.Environment]::SetEnvironmentVariable([string]$name, [string]$productEnv[$name], 'Process')
        }

        $innerParams = @{ Profile = $Profile; ReadyTimeoutSeconds = $ReadyTimeoutSeconds }
        if ($UseInstalledRuntime) { $innerParams['UseInstalledRuntime'] = $true }
        if ($NoLaunch) { $innerParams['NoLaunch'] = $true }

        & $innerLauncher @innerParams
    } finally {
        # Preserve the caller environment EXACTLY, even if the nested launcher threw.
        Restore-EnvironmentSnapshot -Snapshot $snapshot
    }
}

# Guard: dot-sourcing (for tests) defines the helpers and returns without launching.
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-StartHermesSovereignDesktop `
        -SourceRoot $SourceRoot `
        -DataDir $DataDir `
        -Profile $Profile `
        -ReadyTimeoutSeconds $ReadyTimeoutSeconds `
        -UseInstalledRuntime:$UseInstalledRuntime `
        -NoLaunch:$NoLaunch
}
