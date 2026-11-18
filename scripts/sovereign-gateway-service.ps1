<#
.SYNOPSIS
  Sovereign dedicated gateway lifecycle servisi (P0-B Faz 1, review-fix r3).
  MiMo 8642 / DeepSeek 8643 / restricted Hermes 8644 icin idempotent
  plan | install | status | start | stop | uninstall arayuzu.

.DESCRIPTION
  Mimari: per-user Windows Scheduled Task, dedicated `\Sovereign\` TaskPath,
  Description ownership marker ve SID-canonical principal kaniti. ADR 0010.

  Guvenlik kurallari (r3):
   - Varsayilan mod DRY-RUN'dir. Gercek mutasyon yalniz -Execute + ShouldProcess.
   - Secret degeri okunmaz/yazilmaz; health probe SECRETSIZ'dir.
   - Task sahipligi: TaskPath + marker + SID-canonical principal (identity) ve
     tek action/tek trigger/enabled/trigger-user/LogonType/RunLevel/exe/args/
     workdir tam alan dogrulamasi (config). Kanitsiz task FOREIGN_TASK
     fail-closed'dur: silinmez, degistirilmez, BASLATILMAZ.
   - START yalniz IdentityOwned VE ConfigMatches task'i baslatir. Bizim path'te
     foreign/drift task varken start fail-closed'dur. Task hic yoksa dogrudan
     Start-Process fallback'i BILINCLI davranistir (ADR 0010) ve receipt'te
     `start-direct` olarak etiketlenir. Farkli path'teki ayni isimli task asla
     baslatilmaz.
   - Recreate zinciri bagimlidir: register yalniz unregister adimi APPLIED ise
     calisir; decline/hata register'i atlatir ve receipt gercegi yazar.
   - Receipt toplam sonucu step log'dan turetilir (fail-closed > failed >
     declined > ok). Receipt yazimi .NET FileMode.CreateNew ile atomiktir ve
     -WhatIf'ten etkilenmez (audit kaydi mutasyon degildir). `-Execute` ile
     `-NoReceipt` audit bypass'i olarak REDDEDILIR ve refusal receipt yazilir.
   - Arg parsing resmi Win32 CommandLineToArgvW iledir; Windows disi ortamda
     acik fail-closed.
   - `gateway stop --all` ASLA kullanilmaz; stop profil kapsamlidir.

.NOTES
  Faz 1 kapsami: kod + mock/dispatcher testleri + read-only status. Gercek
  install/uninstall/start/stop ve reboot kabulu ayri onayli Faz 2 isidir.
  Test modu: $env:SGS_NO_DISPATCH='1' iken dosya yalniz fonksiyonlari yukler.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [ValidateSet('plan', 'install', 'status', 'start', 'stop', 'uninstall')]
  [string]$Action = 'status',

  [ValidateSet('all', 'sovereign-mimo', 'sovereign-deepseek', 'sovereign-hermes')]
  [string]$GatewayProfile = 'all',

  [switch]$Execute,
  [switch]$NoHealth,
  [switch]$NoReceipt,
  [string]$ReceiptDirectory
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- sabitler

$script:SgsGateways = [ordered]@{
  'sovereign-mimo'     = 8642
  'sovereign-deepseek' = 8643
  'sovereign-hermes'   = 8644
}
$script:SgsRepoRoot    = Split-Path -Parent $PSScriptRoot
$script:SgsHermesExe   = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
# r4: task action'lari hermes.exe'yi dogrudan calistirmaz (Interactive
# principal gorunur konsol acar). Canli olcum ayrica gosterdi ki Windows
# Terminal default-terminal iken powershell -WindowStyle Hidden bile GORUNUR
# WT tab'i acabiliyor; bu yuzden konsol zinciri legacy `conhost --headless`
# uzerinden kurulur (tab/pencere hic olusmaz).
$script:SgsPowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$script:SgsConhostExe    = Join-Path $env:SystemRoot 'System32\conhost.exe'
$script:SgsLauncherPath  = Join-Path $PSScriptRoot 'sovereign-gateway-launch.ps1'
$script:SgsRuntimeDir  = Join-Path $script:SgsRepoRoot 'runtime\sovereign-hermes-gateways'
$script:SgsTaskPath    = '\Sovereign\'
$script:SgsTaskPrefix  = 'Sovereign Gateway '
$script:SgsMarker      = 'sovereign-gateway-service:managed:v1'
$script:SgsSchema      = '1.2'
$script:SgsExecuteMode = $false
$script:SgsStepLog     = @()
$script:SgsShouldProcess = { param($Target, $Operation) $true }
$script:SgsArgvTypeLoaded = $false

function Get-SgsProfileList {
  param([string]$Scope)
  if ($Scope -eq 'all') { return @($script:SgsGateways.Keys) }
  return @($Scope)
}

# ------------------------------------------------- kimlik (SID-canonical)

function Get-SgsCurrentIdentity {
  $wi = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  [pscustomobject]@{ Name = [string]$wi.Name; Sid = [string]$wi.User.Value }
}

function ConvertTo-SgsSid {
  # Hesap adini canonical SID'e cevirir; cevrilemeyen hesap $null doner
  # (sahiplik kaniti BASARISIZ sayilir - fail-closed).
  param([string]$Account)
  if (-not $Account) { return $null }
  if ($Account -match '^S-1-') { return $Account }
  try {
    $nt = New-Object System.Security.Principal.NTAccount($Account)
    return [string]$nt.Translate([System.Security.Principal.SecurityIdentifier]).Value
  } catch { return $null }
}

# ------------------------------------------------- dis dunya wrapper'lari

function Get-SgsProcessTable {
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(hermes|python|pythonw)\.exe$' } |
    ForEach-Object {
      [pscustomobject]@{
        ProcessId       = [int]$_.ProcessId
        ParentProcessId = [int]$_.ParentProcessId
        Name            = [string]$_.Name
        CommandLine     = [string]$_.CommandLine
      }
    }
}

function Get-SgsListeners {
  param([int]$Port)
  Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
}

function Invoke-SgsHealthProbe {
  # SECRETSIZ probe: hicbir env/credential okunmaz.
  param([int]$Port)
  try {
    $r = Invoke-WebRequest -Uri ('http://127.0.0.1:{0}/health' -f $Port) `
      -TimeoutSec 4 -UseBasicParsing
    return ('HTTP {0}' -f [int]$r.StatusCode)
  } catch {
    if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) {
      try { return ('HTTP {0}' -f [int]$_.Exception.Response.StatusCode) } catch { }
    }
    return 'no-response'
  }
}

function Get-SgsScheduledTaskInfoList {
  # Ayni isimli TUM task'lari (her path'te) tam alan kumesiyle dondurur.
  param([string]$TaskName)
  $found = @(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
  $out = @()
  foreach ($task in $found) {
    $actions = @($task.Actions)
    $triggers = @($task.Triggers)
    $exe = ''; $arguments = ''; $workdir = ''
    if ($actions.Count -gt 0) {
      $a0 = $actions[0]
      if ($a0.PSObject.Properties['Execute'])          { $exe = [string]$a0.Execute }
      if ($a0.PSObject.Properties['Arguments'])        { $arguments = [string]$a0.Arguments }
      if ($a0.PSObject.Properties['WorkingDirectory']) { $workdir = [string]$a0.WorkingDirectory }
    }
    $triggerClass = ''; $triggerEnabled = $false; $triggerUserId = ''
    if ($triggers.Count -gt 0) {
      $t0 = $triggers[0]
      try { $triggerClass = [string]$t0.CimClass.CimClassName } catch { $triggerClass = '' }
      if ($t0.PSObject.Properties['Enabled'] -and $null -ne $t0.Enabled) { $triggerEnabled = [bool]$t0.Enabled }
      if ($t0.PSObject.Properties['UserId']) { $triggerUserId = [string]$t0.UserId }
    }
    $runLevel = ''; $userId = ''; $logonType = ''
    if ($task.PSObject.Properties['Principal'] -and $task.Principal) {
      if ($task.Principal.PSObject.Properties['RunLevel'])  { $runLevel = [string]$task.Principal.RunLevel }
      if ($task.Principal.PSObject.Properties['UserId'])    { $userId = [string]$task.Principal.UserId }
      if ($task.Principal.PSObject.Properties['LogonType']) { $logonType = [string]$task.Principal.LogonType }
    }
    $out += [pscustomobject]@{
      TaskName         = [string]$task.TaskName
      TaskPath         = [string]$task.TaskPath
      State            = [string]$task.State
      Description      = [string]$task.Description
      Execute          = $exe
      Arguments        = $arguments
      WorkingDirectory = $workdir
      ActionCount      = [int]$actions.Count
      TriggerCount     = [int]$triggers.Count
      TriggerClass     = $triggerClass
      TriggerEnabled   = $triggerEnabled
      TriggerUserId    = $triggerUserId
      RunLevel         = $runLevel
      LogonType        = $logonType
      UserId           = $userId
    }
  }
  return @($out)
}

function Test-SgsPath {
  param([string]$Path)
  Test-Path -LiteralPath $Path
}

function Get-SgsReceiptFiles {
  param([string]$Directory)
  if (-not (Test-Path -LiteralPath $Directory)) { return @() }
  @(Get-ChildItem -LiteralPath $Directory -Filter 'receipt-*.json' -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending)
}

function Get-SgsPreviousReceipt {
  param([string]$Directory)
  foreach ($f in (Get-SgsReceiptFiles -Directory $Directory)) {
    $obj = $null
    try { $obj = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json } catch { continue }
    if ($null -eq $obj) { continue }
    if (-not $obj.PSObject.Properties['schemaVersion']) { continue }
    if (@('1.0', '1.1', '1.2') -notcontains [string]$obj.schemaVersion) { continue }
    if (-not $obj.PSObject.Properties['gateways']) { continue }
    $hasObservation = $false
    foreach ($g in @($obj.gateways)) {
      if ($g.PSObject.Properties['treePids']) { $hasObservation = $true; break }
    }
    if (-not $hasObservation) { continue }
    return $obj
  }
  return $null
}

# --- mutasyon wrapper'lari (Faz 2'de canli kabul; Faz 1'de yalniz guard) ---

function Assert-SgsExecuteMode {
  param([string]$Operation)
  if (-not $script:SgsExecuteMode) {
    throw ('SGS-GUARD: "{0}" mutasyonu execute modu disinda cagrilamaz.' -f $Operation)
  }
}

function Invoke-SgsRegisterTask {
  param($Definition)
  Assert-SgsExecuteMode -Operation 'register-task'
  $identity = Get-SgsCurrentIdentity
  $action = New-ScheduledTaskAction -Execute $Definition.ExePath `
    -Argument $Definition.Arguments -WorkingDirectory $Definition.WorkingDirectory
  # Explicit current-user principal + current-user logon trigger (r3).
  $principal = New-ScheduledTaskPrincipal -UserId $identity.Name `
    -LogonType Interactive -RunLevel Limited
  $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero)
  Register-ScheduledTask -TaskName $Definition.TaskName -TaskPath $Definition.TaskPath `
    -Action $action -Trigger $trigger -Settings $settings -Principal $principal `
    -Description $Definition.Description | Out-Null
}

function Invoke-SgsUnregisterTask {
  param([string]$TaskName, [string]$TaskPath)
  Assert-SgsExecuteMode -Operation 'unregister-task'
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false | Out-Null
}

function Invoke-SgsStartOwnedTask {
  # Yalniz sahipligi+config'i KANITLANMIS task icin cagrilir; exact TaskPath.
  param([string]$TaskName, [string]$TaskPath)
  Assert-SgsExecuteMode -Operation 'start-owned-task'
  Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
}

function ConvertTo-SgsQuotedArg {
  # Windows (CommandLineToArgvW) kurallarina gore TEK argumani quote'lar:
  # backslash-oncesi-quote ciftleme ve kapanis oncesi backslash ciftleme dahil.
  # Round-trip kaniti testlerde CommandLineToArgvW ile dogrulanir.
  param([string]$Arg)
  if ($null -eq $Arg -or $Arg -eq '') { return '""' }
  if ($Arg -notmatch '[\s"]') { return $Arg }
  $out = '"'
  $backslashes = 0
  foreach ($ch in $Arg.ToCharArray()) {
    if ($ch -eq '\') { $backslashes++; continue }
    if ($ch -eq '"') {
      $out += ('\' * (2 * $backslashes + 1)) + '"'
      $backslashes = 0
      continue
    }
    $out += ('\' * $backslashes) + $ch
    $backslashes = 0
  }
  $out += ('\' * (2 * $backslashes)) + '"'
  return $out
}

function ConvertTo-SgsCommandLine {
  param([string[]]$Tokens)
  return (@($Tokens | ForEach-Object { ConvertTo-SgsQuotedArg -Arg $_ }) -join ' ')
}

function Get-SgsHermesChildArguments {
  # conhost --headless altinda hermes cocugunun arguman satiri; her token
  # Windows quoting helper'iyla exact ayrisacak sekilde uretilir.
  param([string]$HermesExe, [string]$ProfileName)
  ConvertTo-SgsCommandLine -Tokens @('--headless', $HermesExe, '-p', $ProfileName, 'gateway', 'run')
}

function Invoke-SgsStartHermesConsoleless {
  # TEK ortak konsolsuz child-start contract'i (r5): conhost --headless +
  # hidden + gitignore'lu logs yonlendirmesi. Hem servis start-direct'i hem
  # launcher bunu kullanir; recursive launcher/task cagrisi YOKTUR. Guard'siz
  # primitive'dir; cagiranlar kendi fail-closed/onay katmanindan sorumludur.
  param([string]$ProfileName, [string]$OutLog = '', [string]$ErrLog = '')
  $logDir = Join-Path $script:SgsRuntimeDir 'logs'
  [void][System.IO.Directory]::CreateDirectory($logDir)
  if (-not $OutLog) {
    $stamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
    $OutLog = Join-Path $logDir ('{0}-launch-{1}.out.log' -f $ProfileName, $stamp)
    $ErrLog = Join-Path $logDir ('{0}-launch-{1}.err.log' -f $ProfileName, $stamp)
  }
  $childArgs = Get-SgsHermesChildArguments -HermesExe $script:SgsHermesExe -ProfileName $ProfileName
  Start-Process -FilePath $script:SgsConhostExe `
    -ArgumentList $childArgs `
    -WorkingDirectory $script:SgsRepoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError  $ErrLog | Out-Null
}

function Invoke-SgsStartDirect {
  # Bilincli fallback (ADR 0010): dedicated path'te task HIC yoksa dogrudan
  # process baslatilir. Task varsa (owned/foreign fark etmez) bu yol
  # KULLANILMAZ. r5: ayni konsolsuz ortak contract'i kullanir; eski gorunur
  # Start-Process hermes.exe yolu kaldirildi.
  param([string]$ProfileName)
  Assert-SgsExecuteMode -Operation 'start-direct'
  Invoke-SgsStartHermesConsoleless -ProfileName $ProfileName
}

function Invoke-SgsGracefulStop {
  param([string]$ProfileName)
  Assert-SgsExecuteMode -Operation 'graceful-stop'
  # Profil kapsamli graceful stop. ASLA `gateway stop --all` kullanilmaz.
  & $script:SgsHermesExe -p $ProfileName gateway stop 2>$null | Out-Null
}

function Invoke-SgsStopProcess {
  param([int]$TargetPid)
  Assert-SgsExecuteMode -Operation 'stop-process'
  Stop-Process -Id $TargetPid -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------- adim kaydi ve onay kapisi

function Reset-SgsStepLog {
  $script:SgsStepLog = @()
}

function Add-SgsStepResult {
  param([string]$ProfileName, [string]$Operation, [string]$Target,
        [string]$Status, [string]$Detail = '')
  $script:SgsStepLog += [pscustomobject]@{
    profile   = $ProfileName
    operation = $Operation
    target    = $Target
    status    = $Status   # applied | declined | failed | refused | skipped
    detail    = $Detail
  }
}

function Invoke-SgsExecuteStep {
  # Not: Body'ler GetNewClosure ile BAGLANMAZ - closure yeni dinamik modul
  # scope'u yaratir ve gercek -File kosusunda script fonksiyonlarini goremez
  # (canli Faz 2A'da yakalandi). Parametreler BodyArgs ile acikca gecilir.
  param([string]$ProfileName, [string]$Operation, [string]$Target,
        [scriptblock]$Body, [object[]]$BodyArgs = @())
  $approved = & $script:SgsShouldProcess $Target $Operation
  if (-not $approved) {
    Add-SgsStepResult -ProfileName $ProfileName -Operation $Operation -Target $Target -Status 'declined'
    return $false
  }
  $script:SgsExecuteMode = $true
  try {
    & $Body @BodyArgs
    Add-SgsStepResult -ProfileName $ProfileName -Operation $Operation -Target $Target -Status 'applied'
    return $true
  } catch {
    Add-SgsStepResult -ProfileName $ProfileName -Operation $Operation -Target $Target `
      -Status 'failed' -Detail (Protect-SgsText -Text ([string]$_.Exception.Message))
    return $false
  } finally {
    $script:SgsExecuteMode = $false
  }
}

# ---------------------------- resmi Win32 arg parser (CommandLineToArgvW)

function Initialize-SgsArgvType {
  if ($script:SgsArgvTypeLoaded) { return }
  if ($env:OS -ne 'Windows_NT') {
    throw 'SGS-FAILCLOSED: arg parser yalniz Windows CommandLineToArgvW ile calisir; baska ortamda bilincli olarak bloklanir.'
  }
  if (-not ('SgsNative.Argv' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace SgsNative {
  public static class Argv {
    [DllImport("shell32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr CommandLineToArgvW(string lpCmdLine, out int pNumArgs);
    [DllImport("kernel32.dll")]
    public static extern IntPtr LocalFree(IntPtr hMem);
  }
}
'@
  }
  $script:SgsArgvTypeLoaded = $true
}

function ConvertTo-SgsArgTokens {
  # Resmi Windows quoting semantigi: CommandLineToArgvW. Ev yapimi parser
  # backslash-before-quote kurallarini tasimadigi icin r3'te kaldirildi.
  param([string]$CommandLine)
  if ($null -eq $CommandLine) { return @() }
  if ($CommandLine.Trim().Length -eq 0) { return @() }
  Initialize-SgsArgvType
  $count = 0
  $ptr = [SgsNative.Argv]::CommandLineToArgvW($CommandLine, [ref]$count)
  if ($ptr -eq [IntPtr]::Zero) {
    throw 'SGS-FAILCLOSED: CommandLineToArgvW basarisiz oldu.'
  }
  try {
    $tokens = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $count; $i++) {
      $strPtr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($ptr, $i * [IntPtr]::Size)
      [void]$tokens.Add([System.Runtime.InteropServices.Marshal]::PtrToStringUni($strPtr))
    }
    return $tokens.ToArray()
  } finally {
    [void][SgsNative.Argv]::LocalFree($ptr)
  }
}

function Test-SgsGatewayCommand {
  param([string]$CommandLine, [string]$ProfileName)
  $tokens = @(ConvertTo-SgsArgTokens -CommandLine $CommandLine)
  if ($tokens.Count -lt 4) { return $false }
  $profileOk = $false
  for ($i = 0; $i -lt ($tokens.Count - 1); $i++) {
    if ((($tokens[$i] -ceq '-p') -or ($tokens[$i] -ceq '--profile')) -and
        ($tokens[$i + 1] -ceq $ProfileName)) { $profileOk = $true; break }
  }
  if (-not $profileOk) { return $false }
  for ($i = 0; $i -lt ($tokens.Count - 1); $i++) {
    if (($tokens[$i] -ceq 'gateway') -and ($tokens[$i + 1] -ceq 'run')) { return $true }
  }
  return $false
}

# ------------------------------------------------------- saf mantik katmani

function Resolve-SgsTree {
  param($Table, [string]$ProfileName)
  $rows = @($Table)
  $launchers = @($rows | Where-Object {
      Test-SgsGatewayCommand -CommandLine $_.CommandLine -ProfileName $ProfileName
    })
  $allPids = New-Object System.Collections.Generic.List[int]
  foreach ($l in $launchers) { [void]$allPids.Add([int]$l.ProcessId) }
  $frontier = @($launchers | ForEach-Object { [int]$_.ProcessId })
  $children = @()
  while ($frontier.Count -gt 0) {
    $next = @()
    foreach ($row in $rows) {
      if ($frontier -contains [int]$row.ParentProcessId -and
          -not ($allPids -contains [int]$row.ProcessId)) {
        [void]$allPids.Add([int]$row.ProcessId)
        $children += $row
        $next += [int]$row.ProcessId
      }
    }
    $frontier = $next
  }
  [pscustomobject]@{
    Launchers = $launchers
    Children  = @($children)
    AllPids   = $allPids.ToArray()
  }
}

function Get-SgsPortState {
  param([int]$Port, [int[]]$TreePids)
  $listeners = @(Get-SgsListeners -Port $Port)
  $ownerPids = @($listeners | ForEach-Object { [int]$_.OwningProcess } | Sort-Object -Unique)
  $loopbackOnly = $true
  foreach ($l in $listeners) {
    if (([string]$l.LocalAddress) -ne '127.0.0.1' -and ([string]$l.LocalAddress) -ne '::1') {
      $loopbackOnly = $false
    }
  }
  $foreignPids = @($ownerPids | Where-Object { -not ($TreePids -contains $_) })
  [pscustomobject]@{
    Listening    = ($listeners.Count -gt 0)
    LoopbackOnly = $loopbackOnly
    OwnerPids    = $ownerPids
    ForeignPids  = $foreignPids
    OwnedByTree  = (($listeners.Count -gt 0) -and ($foreignPids.Count -eq 0))
  }
}

function Get-SgsStalePids {
  param($PreviousReceipt, [string]$ProfileName, [int[]]$CurrentTreePids)
  if (-not $PreviousReceipt) { return @() }
  $stale = @()
  $prevGateways = @()
  if ($PreviousReceipt.PSObject.Properties['gateways']) {
    $prevGateways = @($PreviousReceipt.gateways)
  }
  foreach ($g in $prevGateways) {
    if ([string]$g.profile -ne $ProfileName) { continue }
    $prevPids = @()
    if ($g.PSObject.Properties['treePids'] -and $g.treePids) { $prevPids = @($g.treePids) }
    foreach ($prevPid in $prevPids) {
      if (-not ($CurrentTreePids -contains [int]$prevPid)) { $stale += [int]$prevPid }
    }
  }
  return @($stale | Sort-Object -Unique)
}

function Test-SgsTaskOwnership {
  # IdentityOwned: TaskPath + marker + SID-canonical current-user principal.
  # ConfigMatches: exe/args/workdir + TEK action + TEK trigger + trigger enabled
  # + trigger-user SID + LogonType + RunLevel + logon trigger sinifi.
  param($TaskInfo, $Definition)
  $identity = Get-SgsCurrentIdentity

  $idReasons = @()
  if (([string]$TaskInfo.TaskPath) -ne $Definition.TaskPath) { $idReasons += 'task-path' }
  $desc = [string]$TaskInfo.Description
  if (-not ($desc -like ('*' + $script:SgsMarker + '*'))) { $idReasons += 'marker' }
  $principalSid = ConvertTo-SgsSid -Account ([string]$TaskInfo.UserId)
  if (-not $principalSid -or $principalSid -ne $identity.Sid) { $idReasons += 'principal-sid' }

  $cfgReasons = @()
  if ((([string]$TaskInfo.Execute).Trim('"')) -ne $Definition.ExePath) { $cfgReasons += 'exe' }
  if (([string]$TaskInfo.Arguments) -ne $Definition.Arguments) { $cfgReasons += 'args' }
  if (([string]$TaskInfo.WorkingDirectory) -ne $Definition.WorkingDirectory) { $cfgReasons += 'workdir' }
  if ([int]$TaskInfo.ActionCount -ne 1) { $cfgReasons += 'action-count' }
  if ([int]$TaskInfo.TriggerCount -ne 1) { $cfgReasons += 'trigger-count' }
  if (([string]$TaskInfo.TriggerClass) -notmatch 'LogonTrigger') { $cfgReasons += 'trigger-class' }
  if (-not [bool]$TaskInfo.TriggerEnabled) { $cfgReasons += 'trigger-disabled' }
  $triggerSid = ConvertTo-SgsSid -Account ([string]$TaskInfo.TriggerUserId)
  if (-not $triggerSid -or $triggerSid -ne $identity.Sid) { $cfgReasons += 'trigger-user' }
  if (@('Interactive', 'InteractiveToken') -notcontains ([string]$TaskInfo.LogonType)) { $cfgReasons += 'logon-type' }
  if (([string]$TaskInfo.RunLevel) -ne 'Limited') { $cfgReasons += 'runlevel' }

  [pscustomobject]@{
    IdentityOwned   = ($idReasons.Count -eq 0)
    ConfigMatches   = ($cfgReasons.Count -eq 0)
    IdentityReasons = @($idReasons)
    ConfigReasons   = @($cfgReasons)
  }
}

function Get-SgsGatewayStatus {
  param([string]$ProfileName, $Table, $PreviousReceipt, [switch]$SkipHealth)
  $port = [int]$script:SgsGateways[$ProfileName]
  $tree = Resolve-SgsTree -Table $Table -ProfileName $ProfileName
  $portState = Get-SgsPortState -Port $port -TreePids $tree.AllPids
  $stale = Get-SgsStalePids -PreviousReceipt $PreviousReceipt -ProfileName $ProfileName `
    -CurrentTreePids $tree.AllPids
  $taskName = $script:SgsTaskPrefix + $ProfileName
  $def = Get-SgsTaskDefinition -ProfileName $ProfileName
  $tasks = @(Get-SgsScheduledTaskInfoList -TaskName $taskName)
  $ourTask = $null
  $foreignSameNamePaths = @()
  foreach ($t in $tasks) {
    if ([string]$t.TaskPath -eq $script:SgsTaskPath) { $ourTask = $t }
    else { $foreignSameNamePaths += [string]$t.TaskPath }
  }
  $taskInstalled = $false; $taskState = '-'; $taskOwned = $false; $taskConfigMatches = $false
  if ($ourTask) {
    $taskInstalled = $true
    $taskState = [string]$ourTask.State
    $own = Test-SgsTaskOwnership -TaskInfo $ourTask -Definition $def
    $taskOwned = [bool]$own.IdentityOwned
    $taskConfigMatches = [bool]$own.ConfigMatches
  }

  $state = 'DOWN'
  $failClosed = $false
  if ($portState.Listening -and (-not $portState.OwnedByTree)) {
    $state = 'FOREIGN'; $failClosed = $true
  } elseif ($portState.Listening -and (-not $portState.LoopbackOnly)) {
    $state = 'NONLOOPBACK'; $failClosed = $true
  } elseif ($portState.Listening -and $portState.OwnedByTree -and $tree.Launchers.Count -gt 0) {
    $state = 'RUNNING'
  } elseif ($tree.Launchers.Count -gt 0 -and (-not $portState.Listening)) {
    $state = 'PARTIAL_NO_LISTENER'
  }

  $health = '-'
  if ($state -eq 'RUNNING' -and (-not $SkipHealth)) {
    $health = Invoke-SgsHealthProbe -Port $port
  }

  [pscustomobject]@{
    profile              = $ProfileName
    port                 = $port
    state                = $state
    failClosed           = $failClosed
    listener             = $portState.Listening
    loopbackOnly         = $portState.LoopbackOnly
    ownerPids            = @($portState.OwnerPids)
    foreignPids          = @($portState.ForeignPids)
    launcherPids         = @($tree.Launchers | ForEach-Object { [int]$_.ProcessId })
    treePids             = @($tree.AllPids)
    stalePids            = @($stale)
    health               = $health
    taskName             = $taskName
    taskPath             = $script:SgsTaskPath
    taskInstalled        = $taskInstalled
    taskOwned            = $taskOwned
    taskConfigMatches    = $taskConfigMatches
    taskState            = $taskState
    foreignSameNamePaths = @($foreignSameNamePaths)
  }
}

function Get-SgsTaskDefinition {
  param([string]$ProfileName)
  # r4 launcher mimarisi: Execute `conhost.exe`; arguments `--headless` +
  # canonical powershell + gizli launcher (exact/quoted path, exact profil).
  # Secret tasimaz. conhost --headless, WT default-terminal tab'ini engeller.
  $launcherArgs = ('--headless "{0}" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{1}" -GatewayProfile {2}' -f $script:SgsPowerShellExe, $script:SgsLauncherPath, $ProfileName)
  [pscustomobject]@{
    TaskName         = $script:SgsTaskPrefix + $ProfileName
    TaskPath         = $script:SgsTaskPath
    ExePath          = $script:SgsConhostExe
    Arguments        = $launcherArgs
    PowerShellPath   = $script:SgsPowerShellExe
    LauncherPath     = $script:SgsLauncherPath
    HermesExePath    = $script:SgsHermesExe
    WorkingDirectory = $script:SgsRepoRoot
    Trigger          = 'AtLogOn'
    RunLevel         = 'Limited'
    LogonType        = 'Interactive'
    RunsAs           = 'current-user'
    Description      = ('{0} profile={1} port={2} loopback-only launcher=v2' -f $script:SgsMarker, $ProfileName, [int]$script:SgsGateways[$ProfileName])
    Port             = [int]$script:SgsGateways[$ProfileName]
    Loopback         = $true
  }
}

function Get-SgsInstallPlan {
  param([string]$ProfileName)
  $def = Get-SgsTaskDefinition -ProfileName $ProfileName
  $tasks = @(Get-SgsScheduledTaskInfoList -TaskName $def.TaskName)
  $ourTask = $null
  $foreignSameNamePaths = @()
  foreach ($t in $tasks) {
    if ([string]$t.TaskPath -eq $def.TaskPath) { $ourTask = $t }
    else { $foreignSameNamePaths += [string]$t.TaskPath }
  }
  $planAction = 'create'
  $ownership = $null
  if ($ourTask) {
    $ownership = Test-SgsTaskOwnership -TaskInfo $ourTask -Definition $def
    if (-not $ownership.IdentityOwned) {
      $planAction = 'blocked-foreign-task'
    } elseif ($ownership.ConfigMatches) {
      $planAction = 'already-installed'
    } else {
      $planAction = 'recreate-differs'
    }
  }
  if ($planAction -ne 'blocked-foreign-task') {
    foreach ($req in @($def.ExePath, $def.PowerShellPath, $def.LauncherPath, $def.HermesExePath)) {
      if (-not (Test-SgsPath -Path $req)) { $planAction = 'blocked-missing-exe'; break }
    }
  }
  [pscustomobject]@{
    profile              = $ProfileName
    definition           = $def
    existing             = $ourTask
    ownership            = $ownership
    foreignSameNamePaths = @($foreignSameNamePaths)
    planAction           = $planAction
  }
}

# ----------------------------------------------------------- redaction

function Protect-SgsText {
  param([string]$Text)
  if ($null -eq $Text) { return $Text }
  $opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor `
          [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
  $out = $Text
  $out = [regex]::Replace($out, '(bearer\s+)[A-Za-z0-9\-\._~\+/=]{8,}', '$1<REDACTED>', $opts)
  $out = [regex]::Replace($out, '((api[_-]?key|apikey|secret|token|password|passwd|authorization|credential)["'']?\s*[:=]\s*["'']?)[^\s",;''\\]{6,}', '$1<REDACTED>', $opts)
  $out = [regex]::Replace($out, '[A-Za-z0-9_\-]{40,}', '<REDACTED-LONGRUN>')
  return $out
}

# ----------------------------------------------------------- receipt v1.2

function Get-SgsAggregateOutcome {
  # Toplam sonuc step log'dan turetilir; fail-closed en yuksek onceliktir.
  param([string]$BaseOutcome, $StepResults)
  $applied = @(@($StepResults) | Where-Object { $_.status -eq 'applied' }).Count
  $declined = @(@($StepResults) | Where-Object { $_.status -eq 'declined' }).Count
  $failed = @(@($StepResults) | Where-Object { $_.status -eq 'failed' }).Count
  if ($BaseOutcome -eq 'fail-closed' -or $BaseOutcome -eq 'error') { return $BaseOutcome }
  if ($failed -gt 0) { return 'failed' }
  if ($applied -eq 0 -and $declined -gt 0) { return 'declined' }
  return 'ok'
}

function New-SgsReceipt {
  param(
    [string]$ActionName,
    [bool]$RequestedExecute,
    [bool]$WhatIfRequested = $false,
    $GatewayResults = @(),
    $PlannedSteps = @(),
    $StepResults = @(),
    [string]$Outcome = 'ok',
    [string]$ErrorMessage = '',
    [string]$Directory,
    [switch]$SkipWrite
  )
  $applied = @(@($StepResults) | Where-Object { $_.status -eq 'applied' }).Count
  $declined = @(@($StepResults) | Where-Object { $_.status -eq 'declined' }).Count
  $failed = @(@($StepResults) | Where-Object { $_.status -eq 'failed' }).Count
  $finalOutcome = Get-SgsAggregateOutcome -BaseOutcome $Outcome -StepResults $StepResults
  $observation = $false
  foreach ($g in @($GatewayResults)) {
    if ($g.PSObject.Properties['treePids']) { $observation = $true; break }
  }
  $receipt = [ordered]@{
    schemaVersion    = $script:SgsSchema
    tool             = 'sovereign-gateway-service'
    action           = $ActionName
    requestedExecute = $RequestedExecute
    whatIfRequested  = $WhatIfRequested
    applied          = ($applied -gt 0)
    declined         = ($declined -gt 0)
    failed           = ($failed -gt 0)
    appliedCount     = $applied
    declinedCount    = $declined
    failedCount      = $failed
    effectiveDryRun  = ($applied -eq 0)
    outcome          = $finalOutcome
    errorMessage     = (Protect-SgsText -Text $ErrorMessage)
    observation      = $observation
    timestampUtc     = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    gateways         = @($GatewayResults)
    plannedSteps     = @($PlannedSteps)
    stepResults      = @($StepResults)
  }
  $json = ($receipt | ConvertTo-Json -Depth 8)
  $json = Protect-SgsText -Text $json
  $path = $null
  if (-not $SkipWrite) {
    if (-not $Directory) { $Directory = Join-Path $script:SgsRuntimeDir 'receipts' }
    # Audit kaydi hedef mutasyon DEGILDIR: .NET IO kullanilir ki -WhatIf
    # altinda da yazilsin; FileMode.CreateNew atomik benzersizlik saglar.
    [void][System.IO.Directory]::CreateDirectory($Directory)
    $utf8 = New-Object System.Text.UTF8Encoding($true)
    $bytes = $utf8.GetBytes($json)
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
      $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
      $nonce = [guid]::NewGuid().ToString('N').Substring(0, 8)
      $candidate = Join-Path $Directory ('receipt-{0}-{1}-{2}.json' -f $ActionName, $stamp, $nonce)
      try {
        $fs = [System.IO.File]::Open($candidate, [System.IO.FileMode]::CreateNew,
          [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Dispose() }
        $path = $candidate
        break
      } catch [System.IO.IOException] { continue }
    }
    if (-not $path) { throw 'SGS: receipt dosyasi 16 denemede olusturulamadi.' }
  }
  [pscustomobject]@{ Json = $json; Path = $path }
}

# ----------------------------------------------------------- aksiyonlar

function Invoke-SgsStatusAction {
  param([string]$Scope, [switch]$SkipHealth, $PreviousReceipt)
  $table = @(Get-SgsProcessTable)
  $results = @()
  foreach ($p in (Get-SgsProfileList -Scope $Scope)) {
    $results += Get-SgsGatewayStatus -ProfileName $p -Table $table `
      -PreviousReceipt $PreviousReceipt -SkipHealth:$SkipHealth
  }
  return @($results)
}

function Invoke-SgsPlanAction {
  param([string]$Scope)
  $plans = @()
  foreach ($p in (Get-SgsProfileList -Scope $Scope)) {
    $plans += Get-SgsInstallPlan -ProfileName $p
  }
  return @($plans)
}

function Invoke-SgsInstallAction {
  param([string]$Scope, [switch]$DoExecute)
  $plans = Invoke-SgsPlanAction -Scope $Scope
  $steps = @()
  $failClosed = $false
  foreach ($plan in $plans) {
    switch ($plan.planAction) {
      'create'             { $steps += ('register-task: {0}{1}' -f $plan.definition.TaskPath, $plan.definition.TaskName) }
      'recreate-differs'   { $steps += ('unregister-task (owned, drift): {0}{1}' -f $plan.definition.TaskPath, $plan.definition.TaskName)
                             $steps += ('register-task (yalniz unregister APPLIED ise): {0}{1}' -f $plan.definition.TaskPath, $plan.definition.TaskName) }
      'already-installed'  { $steps += ('skip (idempotent): {0}{1}' -f $plan.definition.TaskPath, $plan.definition.TaskName) }
      'blocked-foreign-task' {
        $reasonText = ''
        if ($plan.ownership) { $reasonText = ($plan.ownership.IdentityReasons -join ',') }
        $steps += ('REFUSE fail-closed (FOREIGN_TASK sahiplik kanitsiz: {0}): {1}{2}' -f $reasonText, $plan.definition.TaskPath, $plan.definition.TaskName)
        $failClosed = $true
      }
      'blocked-missing-exe' { $steps += ('BLOKE: hermes.exe bulunamadi - {0}' -f $plan.definition.ExePath); $failClosed = $true }
    }
    if ($plan.foreignSameNamePaths.Count -gt 0) {
      $steps += ('bilgi: ayni isimli yabanci task path(ler)ine dokunulmaz: {0}' -f ($plan.foreignSameNamePaths -join ' '))
    }
  }
  if ($DoExecute) {
    foreach ($plan in $plans) {
      $target = ($plan.definition.TaskPath + $plan.definition.TaskName)
      if ($plan.planAction -eq 'blocked-foreign-task' -or $plan.planAction -eq 'blocked-missing-exe') {
        Add-SgsStepResult -ProfileName $plan.profile -Operation 'install' -Target $target `
          -Status 'refused' -Detail $plan.planAction
        continue
      }
      if ($plan.planAction -eq 'already-installed') {
        Add-SgsStepResult -ProfileName $plan.profile -Operation 'install' -Target $target `
          -Status 'skipped' -Detail 'idempotent'
        continue
      }
      if ($plan.planAction -eq 'recreate-differs') {
        $unregOk = Invoke-SgsExecuteStep -ProfileName $plan.profile -Operation 'unregister-task' `
          -Target $target `
          -Body { param($tn, $tp) Invoke-SgsUnregisterTask -TaskName $tn -TaskPath $tp } `
          -BodyArgs @($plan.definition.TaskName, $plan.definition.TaskPath)
        if (-not $unregOk) {
          # r3: register, unregister APPLIED olmadan calismaz.
          Add-SgsStepResult -ProfileName $plan.profile -Operation 'register-task' -Target $target `
            -Status 'skipped' -Detail 'unregister applied olmadi (declined/failed); register atlandi'
          continue
        }
      }
      [void](Invoke-SgsExecuteStep -ProfileName $plan.profile -Operation 'register-task' `
        -Target $target -Body { param($d) Invoke-SgsRegisterTask -Definition $d } `
        -BodyArgs @(, $plan.definition))
    }
  }
  [pscustomobject]@{ Plans = $plans; Steps = @($steps); FailClosed = $failClosed }
}

function Invoke-SgsStartAction {
  param([string]$Scope, [switch]$DoExecute, $PreviousReceipt)
  $statusList = Invoke-SgsStatusAction -Scope $Scope -SkipHealth -PreviousReceipt $PreviousReceipt
  $steps = @()
  $failClosed = $false
  $startModes = @{}
  foreach ($s in $statusList) {
    switch ($s.state) {
      'RUNNING'             { $steps += ('skip (calisiyor): {0}' -f $s.profile) }
      'FOREIGN'             { $steps += ('REFUSE fail-closed (yabanci port sahibi pid={0}): {1}' -f (($s.foreignPids -join ',')), $s.profile); $failClosed = $true }
      'NONLOOPBACK'         { $steps += ('REFUSE fail-closed (loopback disi listener): {0}' -f $s.profile); $failClosed = $true }
      'PARTIAL_NO_LISTENER' { $steps += ('REFUSE fail-closed (listener''siz mevcut surec; once stop incele): {0}' -f $s.profile); $failClosed = $true }
      'DOWN' {
        # r3 START SAHIPLIK KURALI: bizim path'te task varsa yalniz
        # IdentityOwned VE ConfigMatches ise baslatilir; aksi fail-closed.
        # Task hic yoksa bilincli dogrudan-baslatma fallback'i kullanilir.
        # Farkli path'teki ayni isimli task ASLA baslatilmaz.
        if ($s.taskInstalled) {
          if ($s.taskOwned -and $s.taskConfigMatches) {
            $steps += ('start-task (exact-owned {0}{1}): {2}' -f $s.taskPath, $s.taskName, $s.profile)
            $startModes[$s.profile] = 'task'
          } else {
            $steps += ('REFUSE fail-closed (dedicated path''te FOREIGN/drift task; start bypass engellendi): {0}' -f $s.profile)
            $failClosed = $true
          }
        } else {
          $steps += ('start-direct (bilincli fallback, task kurulu degil): {0}' -f $s.profile)
          $startModes[$s.profile] = 'direct'
        }
      }
    }
  }
  if ($DoExecute) {
    if ($failClosed) { throw 'SGS-FAILCLOSED: fail-closed durumlar var; start reddedildi.' }
    foreach ($s in $statusList) {
      if ($s.state -ne 'DOWN') { continue }
      if (-not $startModes.ContainsKey($s.profile)) { continue }
      if ($startModes[$s.profile] -eq 'task') {
        [void](Invoke-SgsExecuteStep -ProfileName $s.profile -Operation 'start-owned-task' `
          -Target ($s.taskPath + $s.taskName) `
          -Body { param($tn, $tp) Invoke-SgsStartOwnedTask -TaskName $tn -TaskPath $tp } `
          -BodyArgs @($s.taskName, $s.taskPath))
      } else {
        [void](Invoke-SgsExecuteStep -ProfileName $s.profile -Operation 'start-direct' `
          -Target $s.profile -Body { param($p) Invoke-SgsStartDirect -ProfileName $p } `
          -BodyArgs @(, $s.profile))
      }
    }
  }
  [pscustomobject]@{ Status = @($statusList); Steps = @($steps); FailClosed = $failClosed }
}

function Invoke-SgsStopAction {
  param([string]$Scope, [switch]$DoExecute, $PreviousReceipt)
  $statusList = Invoke-SgsStatusAction -Scope $Scope -SkipHealth -PreviousReceipt $PreviousReceipt
  $steps = @()
  $failClosed = $false
  foreach ($s in $statusList) {
    if ($s.state -eq 'FOREIGN') {
      $steps += ('REFUSE fail-closed (yabanci surec durdurulamaz, pid={0}): {1}' -f (($s.foreignPids -join ',')), $s.profile)
      $failClosed = $true
      continue
    }
    if ($s.treePids.Count -eq 0) {
      $steps += ('skip (surec yok): {0}' -f $s.profile)
      continue
    }
    if ($s.state -eq 'NONLOOPBACK') {
      $steps += ('containment-stop (nonloopback, exact-owned tree): {0}' -f $s.profile)
    } else {
      $steps += ('graceful-stop (profil kapsamli): {0}' -f $s.profile)
    }
    foreach ($treePid in $s.treePids) {
      $steps += ('force-stop-if-survives: {0} pid={1}' -f $s.profile, $treePid)
    }
  }
  if ($DoExecute) {
    foreach ($s in $statusList) {
      if ($s.state -eq 'FOREIGN') {
        Add-SgsStepResult -ProfileName $s.profile -Operation 'stop' -Target $s.profile `
          -Status 'refused' -Detail 'FOREIGN port sahibi'
        continue
      }
      if ($s.treePids.Count -eq 0) {
        Add-SgsStepResult -ProfileName $s.profile -Operation 'stop' -Target $s.profile `
          -Status 'skipped' -Detail 'surec yok'
        continue
      }
      $stopKind = 'graceful-stop'
      if ($s.state -eq 'NONLOOPBACK') { $stopKind = 'containment-stop' }
      $ok = Invoke-SgsExecuteStep -ProfileName $s.profile -Operation $stopKind `
        -Target $s.profile -Body { param($p) Invoke-SgsGracefulStop -ProfileName $p } `
        -BodyArgs @(, $s.profile)
      if ($ok) {
        Start-Sleep -Seconds 3
        $freshTable = @(Get-SgsProcessTable)
        $freshTree = Resolve-SgsTree -Table $freshTable -ProfileName $s.profile
        foreach ($survivorPid in $freshTree.AllPids) {
          [void](Invoke-SgsExecuteStep -ProfileName $s.profile -Operation 'force-stop' `
            -Target ('{0} pid={1}' -f $s.profile, $survivorPid) `
            -Body { param($stopPid) Invoke-SgsStopProcess -TargetPid $stopPid } `
            -BodyArgs @(, $survivorPid))
        }
      }
    }
  }
  [pscustomobject]@{ Status = @($statusList); Steps = @($steps); FailClosed = $failClosed }
}

function Invoke-SgsUninstallAction {
  param([string]$Scope, [switch]$DoExecute)
  $steps = @()
  $targets = @()
  $failClosed = $false
  foreach ($p in (Get-SgsProfileList -Scope $Scope)) {
    $def = Get-SgsTaskDefinition -ProfileName $p
    $tasks = @(Get-SgsScheduledTaskInfoList -TaskName $def.TaskName)
    $ourTask = $null
    $foreignPaths = @()
    foreach ($t in $tasks) {
      if ([string]$t.TaskPath -eq $def.TaskPath) { $ourTask = $t }
      else { $foreignPaths += [string]$t.TaskPath }
    }
    if ($foreignPaths.Count -gt 0) {
      $steps += ('bilgi: ayni isimli yabanci task path(ler)ine dokunulmaz: {0}' -f ($foreignPaths -join ' '))
    }
    if (-not $ourTask) {
      $steps += ('skip (kurulu degil): {0}{1}' -f $def.TaskPath, $def.TaskName)
      continue
    }
    $own = Test-SgsTaskOwnership -TaskInfo $ourTask -Definition $def
    if (-not $own.IdentityOwned) {
      $steps += ('REFUSE fail-closed (FOREIGN_TASK sahiplik kanitsiz: {0}): {1}{2}' -f (($own.IdentityReasons -join ',')), $def.TaskPath, $def.TaskName)
      $failClosed = $true
      continue
    }
    $steps += ('unregister-task (owned): {0}{1}' -f $def.TaskPath, $def.TaskName)
    $targets += [pscustomobject]@{ Profile = $p; TaskName = $def.TaskName; TaskPath = $def.TaskPath }
  }
  if ($DoExecute) {
    foreach ($t in $targets) {
      [void](Invoke-SgsExecuteStep -ProfileName $t.Profile -Operation 'unregister-task' `
        -Target ($t.TaskPath + $t.TaskName) `
        -Body { param($tn, $tp) Invoke-SgsUnregisterTask -TaskName $tn -TaskPath $tp } `
        -BodyArgs @($t.TaskName, $t.TaskPath))
    }
  }
  [pscustomobject]@{ Steps = @($steps); FailClosed = $failClosed }
}

# ----------------------------------------------------------- dispatcher

if ($env:SGS_NO_DISPATCH -eq '1') { return }

$script:SgsShouldProcess = { param($Target, $Operation) $PSCmdlet.ShouldProcess($Target, $Operation) }
$whatIfRequested = $false
if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = [bool]$PSBoundParameters['WhatIf'] }
elseif (Test-Path variable:WhatIfPreference) { $whatIfRequested = [bool]$WhatIfPreference }

Reset-SgsStepLog
$receiptDir = $ReceiptDirectory
if (-not $receiptDir) { $receiptDir = Join-Path $script:SgsRuntimeDir 'receipts' }

# r3: -Execute + -NoReceipt audit bypass'idir; reddedilir ve refusal receipt
# ZORLA yazilir (SkipWrite yok sayilir).
if ($Execute -and $NoReceipt) {
  $refusal = New-SgsReceipt -ActionName $Action -RequestedExecute $true `
    -WhatIfRequested $whatIfRequested `
    -PlannedSteps @('REFUSE fail-closed: -Execute ile -NoReceipt audit bypass olarak reddedildi') `
    -Outcome 'fail-closed' -Directory $receiptDir
  Write-Host ('refusal receipt: {0}' -f $refusal.Path) -ForegroundColor Yellow
  throw 'SGS-FAILCLOSED: -Execute ile -NoReceipt birlikte kullanilamaz (audit kaydi zorunlu).'
}

$prev = Get-SgsPreviousReceipt -Directory $receiptDir

$gatewayResults = @()
$plannedSteps = @()
$outcome = 'ok'
$errorMessage = ''

try {
  switch ($Action) {
    'status' {
      $gatewayResults = Invoke-SgsStatusAction -Scope $GatewayProfile -SkipHealth:$NoHealth -PreviousReceipt $prev
      foreach ($g in $gatewayResults) { if ($g.failClosed) { $outcome = 'fail-closed' } }
    }
    'plan' {
      $plans = Invoke-SgsPlanAction -Scope $GatewayProfile
      $plannedSteps = @($plans | ForEach-Object { '{0}: {1}' -f $_.profile, $_.planAction })
      $gatewayResults = @($plans | ForEach-Object { $_.definition })
      foreach ($p in $plans) { if ($p.planAction -like 'blocked-*') { $outcome = 'fail-closed' } }
    }
    'install' {
      $r = Invoke-SgsInstallAction -Scope $GatewayProfile -DoExecute:$Execute
      $plannedSteps = $r.Steps
      $gatewayResults = @($r.Plans | ForEach-Object { $_.definition })
      if ($r.FailClosed) { $outcome = 'fail-closed' }
    }
    'start' {
      $r = Invoke-SgsStartAction -Scope $GatewayProfile -DoExecute:$Execute -PreviousReceipt $prev
      $plannedSteps = $r.Steps
      $gatewayResults = $r.Status
      if ($r.FailClosed) { $outcome = 'fail-closed' }
    }
    'stop' {
      $r = Invoke-SgsStopAction -Scope $GatewayProfile -DoExecute:$Execute -PreviousReceipt $prev
      $plannedSteps = $r.Steps
      $gatewayResults = $r.Status
      if ($r.FailClosed) { $outcome = 'fail-closed' }
    }
    'uninstall' {
      $r = Invoke-SgsUninstallAction -Scope $GatewayProfile -DoExecute:$Execute
      $plannedSteps = $r.Steps
      if ($r.FailClosed) { $outcome = 'fail-closed' }
    }
  }
} catch {
  $errorMessage = [string]$_.Exception.Message
  if ($errorMessage -match 'SGS-FAILCLOSED') { $outcome = 'fail-closed' } else { $outcome = 'error' }
  $errReceipt = New-SgsReceipt -ActionName $Action -RequestedExecute ([bool]$Execute) `
    -WhatIfRequested $whatIfRequested -GatewayResults $gatewayResults `
    -PlannedSteps $plannedSteps -StepResults @($script:SgsStepLog) `
    -Outcome $outcome -ErrorMessage $errorMessage -Directory $receiptDir -SkipWrite:$NoReceipt
  if ($errReceipt.Path) { Write-Host ('hata receipt: {0}' -f $errReceipt.Path) -ForegroundColor Yellow }
  throw
}

$receipt = New-SgsReceipt -ActionName $Action -RequestedExecute ([bool]$Execute) `
  -WhatIfRequested $whatIfRequested -GatewayResults $gatewayResults `
  -PlannedSteps $plannedSteps -StepResults @($script:SgsStepLog) `
  -Outcome $outcome -Directory $receiptDir -SkipWrite:$NoReceipt

$finalOutcome = Get-SgsAggregateOutcome -BaseOutcome $outcome -StepResults @($script:SgsStepLog)
Write-Host ('== sovereign-gateway-service :: {0} (execute={1} whatIf={2} outcome={3}) ==' -f $Action, [bool]$Execute, $whatIfRequested, $finalOutcome) -ForegroundColor Cyan
foreach ($g in $gatewayResults) {
  if ($g.PSObject.Properties['state']) {
    '{0,-20} port {1}  {2,-20} listener={3,-5} loopback={4,-5} health={5,-10} tree={6} stale={7} task={8}/owned={9}/cfg={10}' -f `
      $g.profile, $g.port, $g.state, $g.listener, $g.loopbackOnly, $g.health, `
      (($g.treePids -join ',')), (($g.stalePids -join ',')), $g.taskState, $g.taskOwned, $g.taskConfigMatches | Write-Host
  } else {
    '{0,-44} port {1}  task="{2}{3}" trigger={4} runlevel={5}' -f `
      $g.Arguments, $g.Port, $g.TaskPath, $g.TaskName, $g.Trigger, $g.RunLevel | Write-Host
  }
}
foreach ($s in $plannedSteps) { Write-Host ('  step: {0}' -f $s) }
foreach ($sr in @($script:SgsStepLog)) {
  Write-Host ('  sonuc: [{0}] {1} {2} -> {3}' -f $sr.status, $sr.operation, $sr.target, $sr.detail)
}
if ($receipt.Path) { Write-Host ('receipt: {0}' -f $receipt.Path) -ForegroundColor DarkGray }
if (-not $Execute -and $Action -ne 'status' -and $Action -ne 'plan') {
  Write-Host 'DRY-RUN: hicbir mutasyon yapilmadi. Gercek uygulama icin -Execute (ve onay) gerekir.' -ForegroundColor Yellow
}
