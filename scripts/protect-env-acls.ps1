[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
$hermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$paths = [Collections.Generic.List[string]]::new()

$globalEnv = Join-Path $hermesHome '.env'
if (Test-Path -LiteralPath $globalEnv) { $paths.Add($globalEnv) }

$profileRoot = Join-Path $hermesHome 'profiles'
if (Test-Path -LiteralPath $profileRoot) {
    Get-ChildItem -LiteralPath $profileRoot -Directory | ForEach-Object {
        $profileEnv = Join-Path $_.FullName '.env'
        if (Test-Path -LiteralPath $profileEnv) { $paths.Add($profileEnv) }
    }
}

foreach ($path in $paths) {
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
    [IO.File]::SetAccessControl($path, $security)
    Write-Host "Protected $path"
}
