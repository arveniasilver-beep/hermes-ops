[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Read-PlainSecret {
    param([Parameter(Mandatory)][string]$Prompt)

    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    if ([string]::IsNullOrWhiteSpace($plain)) {
        throw "$Prompt cannot be empty. No files were changed."
    }
    if ($plain.Contains("`r") -or $plain.Contains("`n")) {
        throw "$Prompt contains a newline. No files were changed."
    }
    return $plain
}

function Set-PrivateAcl {
    param([Parameter(Mandatory)][string]$Path)

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
    $security = [Security.AccessControl.FileSecurity]::new()
    $security.SetAccessRuleProtection($true, $false)
    $security.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
        $identity.User,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    ))
    $security.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
        $systemSid,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    ))
    [IO.File]::SetAccessControl($Path, $security)
}

function Set-EnvSecret {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        throw "Hermes profile directory does not exist: $directory"
    }

    $lines = [Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $Path) {
        foreach ($line in [IO.File]::ReadAllLines($Path)) { $lines.Add($line) }
    }

    $prefix = "$Name="
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith($prefix, [StringComparison]::Ordinal)) {
            $lines[$i] = $prefix + $Value
            $found = $true
        }
    }
    if (-not $found) { $lines.Add($prefix + $Value) }

    $tempPath = Join-Path $directory ([IO.Path]::GetRandomFileName())
    try {
        [IO.File]::WriteAllLines($tempPath, $lines, [Text.UTF8Encoding]::new($false))
        Set-PrivateAcl -Path $tempPath
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
        Set-PrivateAcl -Path $Path
    } finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }
    }
}

$xiaomi = Read-PlainSecret -Prompt 'Xiaomi MiMo API key'
$deepSeek = Read-PlainSecret -Prompt 'DeepSeek API key'

try {
    foreach ($profile in @('owner-orchestrator', 'owner-vision', 'owner-operator')) {
        $path = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\.env"
        Set-EnvSecret -Path $path -Name 'XIAOMI_API_KEY' -Value $xiaomi
    }
    foreach ($profile in @('owner-fast-worker', 'owner-engineer')) {
        $path = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\.env"
        Set-EnvSecret -Path $path -Name 'DEEPSEEK_API_KEY' -Value $deepSeek
    }
} finally {
    $xiaomi = $null
    $deepSeek = $null
    [GC]::Collect()
}

Write-Host 'Provider keys were written to profile-local .env files.'
Write-Host 'No key values were printed, logged, or added to this repository.'
