<#
  sovereign-gateway-service.ps1 icin mock + dispatcher testleri (r3).
  Mock katmani gercek sistemle konusmaz; Q grubu gercek dispatcher'i -WhatIf
  altinda calistirir ve 0 gercek mutasyonu Get-ScheduledTask ile kanitlar.
  Cikis kodu = basarisiz test sayisi.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$env:SGS_NO_DISPATCH = '1'
$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-gateway-service.ps1'
. $scriptPath

$script:TestCount = 0
$script:TestFails = 0
function Assert-True {
  param([bool]$Condition, [string]$Name)
  $script:TestCount++
  if ($Condition) { Write-Host ("PASS: {0}" -f $Name) }
  else { $script:TestFails++; Write-Host ("FAIL: {0}" -f $Name) -ForegroundColor Red }
}

# ---- test kimligi (SID-canonical mocklar) ------------------------------
$script:TestIdentity = [pscustomobject]@{ Name = 'TESTDOM\tester'; Sid = 'S-1-5-21-1111-1001' }
function Get-SgsCurrentIdentity { return $script:TestIdentity }
function ConvertTo-SgsSid {
  param([string]$Account)
  switch -Exact ($Account) {
    'TESTDOM\tester' { return 'S-1-5-21-1111-1001' }
    'tester'         { return 'S-1-5-21-1111-1001' }
    'S-1-5-21-1111-1001' { return 'S-1-5-21-1111-1001' }
    'OTHERDOM\tester' { return 'S-1-5-21-9999-7777' }
    default { return $null }
  }
}

function New-Row {
  param([int]$RowPid, [int]$RowPpid, [string]$Name, [string]$Cmd)
  [pscustomobject]@{ ProcessId = $RowPid; ParentProcessId = $RowPpid; Name = $Name; CommandLine = $Cmd }
}
function New-Listener {
  param([int]$OwnerPid, [string]$Addr = '127.0.0.1')
  [pscustomobject]@{ OwningProcess = $OwnerPid; LocalAddress = $Addr }
}
function New-TaskInfo {
  param(
    [string]$ProfileName,
    [string]$TaskPath = '\Sovereign\',
    [bool]$WithMarker = $true,
    [string]$Arguments = '',
    [string]$UserId = 'TESTDOM\tester',
    [string]$TriggerClass = 'MSFT_TaskLogonTrigger',
    [bool]$TriggerEnabled = $true,
    [string]$TriggerUserId = 'TESTDOM\tester',
    [int]$ActionCount = 1,
    [int]$TriggerCount = 1,
    [string]$LogonType = 'Interactive',
    [string]$RunLevel = 'Limited',
    [string]$Execute = '',
    [string]$WorkDir = ''
  )
  if (-not $Execute) { $Execute = $script:SgsConhostExe }
  if (-not $WorkDir) { $WorkDir = $script:SgsRepoRoot }
  if (-not $Arguments) { $Arguments = (Get-SgsTaskDefinition -ProfileName $ProfileName).Arguments }
  $desc = 'baska bir aracin gorevi'
  if ($WithMarker) { $desc = ('{0} profile={1}' -f $script:SgsMarker, $ProfileName) }
  [pscustomobject]@{
    TaskName = ('Sovereign Gateway {0}' -f $ProfileName); TaskPath = $TaskPath
    State = 'Ready'; Description = $desc; Execute = $Execute; Arguments = $Arguments
    WorkingDirectory = $WorkDir; ActionCount = $ActionCount; TriggerCount = $TriggerCount
    TriggerClass = $TriggerClass; TriggerEnabled = $TriggerEnabled; TriggerUserId = $TriggerUserId
    RunLevel = $RunLevel; LogonType = $LogonType; UserId = $UserId
  }
}

# ---- ortak "firlatan" mock kurulumu (dry-run guvenligi) ----------------
$script:MutationCalls = 0
function Invoke-SgsRegisterTask   { param($Definition) $script:MutationCalls++; throw 'MUTASYON: register' }
function Invoke-SgsUnregisterTask { param([string]$TaskName, [string]$TaskPath) $script:MutationCalls++; throw 'MUTASYON: unregister' }
function Invoke-SgsStartOwnedTask { param([string]$TaskName, [string]$TaskPath) $script:MutationCalls++; throw 'MUTASYON: starttask' }
function Invoke-SgsStartDirect    { param([string]$ProfileName) $script:MutationCalls++; throw 'MUTASYON: startdirect' }
function Invoke-SgsGracefulStop   { param([string]$ProfileName) $script:MutationCalls++; throw 'MUTASYON: gstop' }
function Invoke-SgsStopProcess    { param([int]$TargetPid) $script:MutationCalls++; throw 'MUTASYON: kill' }
function Invoke-SgsHealthProbe    { param([int]$Port) return 'HTTP 200' }
function Test-SgsPath             { param([string]$Path) return $true }
function Get-SgsScheduledTaskInfoList { param([string]$TaskName) return @() }
function Get-SgsListeners         { param([int]$Port) return @() }
function Get-SgsProcessTable      { return @() }

# ======================= A: dry-run yan etkisizligi =====================
$script:MutationCalls = 0
Reset-SgsStepLog
$rInstall = Invoke-SgsInstallAction -Scope 'all'
$rStart = Invoke-SgsStartAction -Scope 'all'
$rStop = Invoke-SgsStopAction -Scope 'all'
$rUninst = Invoke-SgsUninstallAction -Scope 'all'
Assert-True ($script:MutationCalls -eq 0) 'A1 dry-run: mutasyon wrapper cagrisi 0'
Assert-True (@($rInstall.Steps | Where-Object { $_ -match 'register-task' }).Count -eq 3) 'A2 dry-run: install 3 register adimi planlar'
Assert-True (@($script:SgsStepLog).Count -eq 0) 'A3 dry-run: step log bos'
Assert-True ((($rStart.Steps -join ';') -match 'start-direct \(bilincli fallback')) 'A4 dry-run: task yokken start-direct fallback planlanir'

# ======================= B: idempotency =================================
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') { return @(New-TaskInfo -ProfileName 'sovereign-mimo') }
  return @()
}
$plan = Get-SgsInstallPlan -ProfileName 'sovereign-mimo'
Assert-True ($plan.planAction -eq 'already-installed') 'B1 idempotent install: owned + tam config skip'
function Get-SgsProcessTable {
  @((New-Row -RowPid 100 -RowPpid 1 -Name 'hermes.exe' -Cmd 'hermes.exe -p sovereign-mimo gateway run'))
}
function Get-SgsListeners { param([int]$Port) if ($Port -eq 8642) { @(New-Listener -OwnerPid 100) } else { @() } }
$rStart2 = Invoke-SgsStartAction -Scope 'sovereign-mimo'
Assert-True (($rStart2.Steps -join ';') -match 'skip \(calisiyor\): sovereign-mimo') 'B2 idempotent start: calisan gateway skip'

# ======================= C: yabanci port sahibi =========================
function Get-SgsScheduledTaskInfoList { param([string]$TaskName) return @() }
function Get-SgsProcessTable { @() }
function Get-SgsListeners { param([int]$Port) if ($Port -eq 8642) { @(New-Listener -OwnerPid 999) } else { @() } }
$st3 = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $null
Assert-True ($st3[0].state -eq 'FOREIGN' -and $st3[0].failClosed) 'C1 collision: FOREIGN + failClosed'
$thrown = $false
try { Invoke-SgsStartAction -Scope 'sovereign-mimo' -DoExecute | Out-Null } catch { $thrown = ($_ -match 'SGS-FAILCLOSED') }
Assert-True $thrown 'C2 collision: execute SGS-FAILCLOSED throw'
$rStop3 = Invoke-SgsStopAction -Scope 'sovereign-mimo'
Assert-True (($rStop3.Steps -join ';') -match 'REFUSE fail-closed \(yabanci surec durdurulamaz') 'C3 collision: stop yabanci sureci hedeflemez'

# ======================= D: stale PID ===================================
function Get-SgsListeners { param([int]$Port) @() }
function Get-SgsProcessTable {
  @((New-Row -RowPid 500 -RowPpid 1 -Name 'python.exe' -Cmd 'python.exe baska-is'))
}
$prevReceipt = [pscustomobject]@{
  gateways = @([pscustomobject]@{ profile = 'sovereign-mimo'; treePids = @(4242, 500) })
}
$st4 = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $prevReceipt
Assert-True (($st4[0].stalePids -contains 4242) -and ($st4[0].stalePids -contains 500)) 'D1 stale: olu + geri donusmus PID stale'
function Get-SgsProcessTable {
  @((New-Row -RowPid 500 -RowPpid 1 -Name 'hermes.exe' -Cmd 'hermes.exe -p sovereign-mimo gateway run'))
}
$prevReceipt2 = [pscustomobject]@{
  gateways = @([pscustomobject]@{ profile = 'sovereign-mimo'; treePids = @(500) })
}
$st4b = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $prevReceipt2
Assert-True ($st4b[0].stalePids.Count -eq 0) 'D2 stale: agacta yasayan PID stale degil'

# ======================= E: process agaci ===============================
function Get-SgsProcessTable {
  @(
    (New-Row -RowPid 100 -RowPpid 1   -Name 'hermes.exe' -Cmd 'hermes.exe -p sovereign-mimo gateway run'),
    (New-Row -RowPid 101 -RowPpid 100 -Name 'python.exe' -Cmd 'python.exe -m hermes_gateway'),
    (New-Row -RowPid 102 -RowPpid 101 -Name 'python.exe' -Cmd 'python.exe worker-child'),
    (New-Row -RowPid 300 -RowPpid 1   -Name 'python.exe' -Cmd 'python.exe -p owner-orchestrator gateway run')
  )
}
function Get-SgsListeners { param([int]$Port) if ($Port -eq 8642) { @(New-Listener -OwnerPid 101) } else { @() } }
$st5 = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $null
Assert-True ($st5[0].state -eq 'RUNNING') 'E1 tree: cocuk listener sahibi RUNNING'
Assert-True (($st5[0].treePids -contains 101) -and ($st5[0].treePids -contains 102) -and (-not ($st5[0].treePids -contains 300))) 'E2 tree: cocuk/torun dahil, baska profil haric'

# ======================= F: redaction ===================================
$dirty = 'Authorization: Bearer abcdef1234567890ABCDEFxyz mimo API_KEY=supersecretvalue123456789 token: gizli-deger-abcdefgh'
$clean = Protect-SgsText -Text $dirty
Assert-True ((-not ($clean -match 'abcdef1234567890')) -and (-not ($clean -match 'supersecretvalue')) -and (-not ($clean -match 'gizli-deger'))) 'F1 redaction: bearer/API_KEY/token maskelendi (tr locale dahil)'

# ======================= G: receipt v1.2 gercegi ========================
$tmpDir = Join-Path $env:TEMP ('sgs-test-' + [guid]::NewGuid().ToString('N'))
$rec = New-SgsReceipt -ActionName 'status' -RequestedExecute $false -WhatIfRequested $false `
  -GatewayResults $st5 -PlannedSteps @('ornek: Bearer abcd1234efgh5678') -StepResults @() -Directory $tmpDir
$parsed = $rec.Json | ConvertFrom-Json
Assert-True ($parsed.schemaVersion -eq '1.2') 'G1 receipt: schemaVersion 1.2'
Assert-True ($parsed.requestedExecute -eq $false -and $parsed.effectiveDryRun -eq $true -and $parsed.outcome -eq 'ok') 'G2 receipt: temel alanlar'
Assert-True ($parsed.applied -eq $false -and $parsed.declined -eq $false -and $parsed.failed -eq $false) 'G3 receipt: acik boolean alanlar'
Assert-True ((Test-Path -LiteralPath $rec.Path) -and (-not ($rec.Json -match 'abcd1234efgh5678'))) 'G4 receipt: dosya + redaction'
$declSteps = @([pscustomobject]@{ profile='x'; operation='register-task'; target='t'; status='declined'; detail='' })
$recD = New-SgsReceipt -ActionName 'install' -RequestedExecute $true -StepResults $declSteps -Directory $tmpDir
Assert-True (($recD.Json | ConvertFrom-Json).outcome -eq 'declined') 'G5 agregat: yalniz declined => outcome=declined'
$failSteps = @([pscustomobject]@{ profile='x'; operation='register-task'; target='t'; status='failed'; detail='hata' })
$recF = New-SgsReceipt -ActionName 'install' -RequestedExecute $true -StepResults $failSteps -Directory $tmpDir
Assert-True (($recF.Json | ConvertFrom-Json).outcome -eq 'failed') 'G6 agregat: failed step => outcome=failed'
$recFC = New-SgsReceipt -ActionName 'install' -RequestedExecute $true -StepResults $failSteps -Outcome 'fail-closed' -Directory $tmpDir
Assert-True (($recFC.Json | ConvertFrom-Json).outcome -eq 'fail-closed') 'G7 agregat: fail-closed onceligi korunur'
$recA = New-SgsReceipt -ActionName 'status' -RequestedExecute $false -GatewayResults @() -Directory $tmpDir
$recB = New-SgsReceipt -ActionName 'status' -RequestedExecute $false -GatewayResults @() -Directory $tmpDir
Assert-True ($recA.Path -ne $recB.Path) 'G8 receipt: atomik benzersiz dosya adi'
$recErr = New-SgsReceipt -ActionName 'start' -RequestedExecute $true -GatewayResults @() `
  -Outcome 'error' -ErrorMessage 'patladi: API_KEY=sizmamasi-gereken-deger-123' -Directory $tmpDir
Assert-True ((($recErr.Json | ConvertFrom-Json).outcome -eq 'error') -and (-not ($recErr.Json -match 'sizmamasi-gereken'))) 'G9 hata receipt: outcome=error + redacted'

# ======================= H: profil kapsamli stop plani ==================
$rStop8 = Invoke-SgsStopAction -Scope 'all'
$joined8 = $rStop8.Steps -join ';'
Assert-True (($joined8 -match 'graceful-stop \(profil kapsamli\): sovereign-mimo') -and (-not ($joined8 -match '300')) -and (-not ($joined8 -match '--all')) -and ($joined8 -match 'pid=101')) 'H1 stop: profil kapsam + --all yasak + agac uyeleri'

# ======================= I: install plan tanimi =========================
$def9 = Get-SgsTaskDefinition -ProfileName 'sovereign-deepseek'
Assert-True ($def9.TaskName -eq 'Sovereign Gateway sovereign-deepseek' -and $def9.TaskPath -eq '\Sovereign\' -and $def9.Description -like ('*' + $script:SgsMarker + '*')) 'I1 plan: ad + TaskPath + marker'
Assert-True ($def9.ExePath -eq $script:SgsConhostExe -and $def9.Port -eq 8643 -and $def9.RunLevel -eq 'Limited' -and $def9.LogonType -eq 'Interactive') 'I2 plan: conhost --headless exe + port/runlevel/logontype'
Assert-True (($def9.Arguments -match '^--headless "[^"]*powershell\.exe" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File ') -and ($def9.Arguments -match '"[^"]*sovereign-gateway-launch\.ps1"') -and ($def9.Arguments -match '-GatewayProfile sovereign-deepseek$')) 'I2b plan: headless launcher argumanlari exact/quoted ve secret icermez'
Assert-True ($def9.LauncherPath -like '*sovereign-gateway-launch.ps1' -and $def9.HermesExePath -eq $script:SgsHermesExe) 'I2c plan: launcher/hermes yol alanlari'
function Test-SgsPath { param([string]$Path) return $false }
$plan9 = Get-SgsInstallPlan -ProfileName 'sovereign-deepseek'
Assert-True ($plan9.planAction -eq 'blocked-missing-exe') 'I3 plan: eksik exe BLOKE'
function Test-SgsPath { param([string]$Path) return $true }

# ======================= J: FOREIGN_TASK sahipligi ======================
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -WithMarker $false)
  }
  return @()
}
$planJ1 = Get-SgsInstallPlan -ProfileName 'sovereign-mimo'
Assert-True ($planJ1.planAction -eq 'blocked-foreign-task') 'J1 foreign task: marker yok -> blocked'
$script:MutationCalls = 0
Reset-SgsStepLog
$script:SgsShouldProcess = { param($Target, $Operation) $true }
$rJ1 = Invoke-SgsInstallAction -Scope 'sovereign-mimo' -DoExecute
Assert-True ($script:MutationCalls -eq 0 -and $rJ1.FailClosed) 'J2 foreign task: install execute 0 mutasyon + FailClosed'
Reset-SgsStepLog
$rJ1u = Invoke-SgsUninstallAction -Scope 'sovereign-mimo' -DoExecute
Assert-True ($script:MutationCalls -eq 0 -and $rJ1u.FailClosed) 'J3 foreign task: uninstall execute 0 mutasyon'
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -TaskPath '\' -WithMarker $false)
  }
  return @()
}
$planJ4 = Get-SgsInstallPlan -ProfileName 'sovereign-mimo'
Reset-SgsStepLog
$rJ4u = Invoke-SgsUninstallAction -Scope 'sovereign-mimo' -DoExecute
Assert-True ($planJ4.planAction -eq 'create' -and ($planJ4.foreignSameNamePaths -contains '\') -and $script:MutationCalls -eq 0 -and (($rJ4u.Steps -join ';') -match 'dokunulmaz')) 'J4 foreign path: create + dokunulmaz + 0 mutasyon'

# ======================= R: recreate adim bagimliligi ===================
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -Arguments '-p sovereign-mimo gateway run --eski')
  }
  return @()
}
$script:WrapperLog = @()
function Invoke-SgsRegisterTask   { param($Definition) $script:WrapperLog += ('register:' + $Definition.TaskPath + $Definition.TaskName) }
function Invoke-SgsUnregisterTask { param([string]$TaskName, [string]$TaskPath) $script:WrapperLog += ('unregister:' + $TaskPath + $TaskName) }
# R1: kuyruklu ShouldProcess - unregister DECLINED => register 0.
$script:SpQueue = @($false, $true); $script:SpIdx = 0
$script:SgsShouldProcess = {
  param($Target, $Operation)
  $v = $true
  if ($script:SpIdx -lt $script:SpQueue.Count) { $v = [bool]$script:SpQueue[$script:SpIdx] }
  $script:SpIdx++
  return $v
}
Reset-SgsStepLog
$rR1 = Invoke-SgsInstallAction -Scope 'sovereign-mimo' -DoExecute
$regSkip = @($script:SgsStepLog | Where-Object { $_.operation -eq 'register-task' -and $_.status -eq 'skipped' })
Assert-True ($script:WrapperLog.Count -eq 0) 'R1 recreate: unregister declined => register 0 wrapper'
Assert-True ($regSkip.Count -eq 1 -and ($regSkip[0].detail -match 'unregister applied olmadi')) 'R2 recreate: register skipped gercegi step logda'
# R3: unregister wrapper HATA => register 0.
$script:SgsShouldProcess = { param($Target, $Operation) $true }
function Invoke-SgsUnregisterTask { param([string]$TaskName, [string]$TaskPath) throw 'unregister patladi' }
$script:WrapperLog = @()
Reset-SgsStepLog
$rR3 = Invoke-SgsInstallAction -Scope 'sovereign-mimo' -DoExecute
$failedUnreg = @($script:SgsStepLog | Where-Object { $_.operation -eq 'unregister-task' -and $_.status -eq 'failed' })
$skippedReg = @($script:SgsStepLog | Where-Object { $_.operation -eq 'register-task' -and $_.status -eq 'skipped' })
Assert-True ($script:WrapperLog.Count -eq 0 -and $failedUnreg.Count -eq 1 -and $skippedReg.Count -eq 1) 'R3 recreate: unregister failed => register atlandi + gercek step sonuclari'
# R4: her ikisi onayli => unregister sonra register, dogru hedef.
function Invoke-SgsUnregisterTask { param([string]$TaskName, [string]$TaskPath) $script:WrapperLog += ('unregister:' + $TaskPath + $TaskName) }
$script:WrapperLog = @()
Reset-SgsStepLog
$rR4 = Invoke-SgsInstallAction -Scope 'sovereign-mimo' -DoExecute
Assert-True (($script:WrapperLog -join ';') -eq 'unregister:\Sovereign\Sovereign Gateway sovereign-mimo;register:\Sovereign\Sovereign Gateway sovereign-mimo') 'R4 recreate: applied zincir dogru sira/hedef'

# ======================= S: start sahiplik kurali =======================
function Get-SgsProcessTable { @() }
function Get-SgsListeners { param([int]$Port) @() }
$script:WrapperLog = @()
function Invoke-SgsStartOwnedTask { param([string]$TaskName, [string]$TaskPath) $script:WrapperLog += ('starttask:' + $TaskPath + $TaskName) }
function Invoke-SgsStartDirect    { param([string]$ProfileName) $script:WrapperLog += ('startdirect:' + $ProfileName) }
$script:SgsShouldProcess = { param($Target, $Operation) $true }
# S1: bizim path'te marker-yok task + DOWN + execute => fail-closed, 0 start.
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -WithMarker $false)
  }
  return @()
}
$thrownS1 = $false
try { Invoke-SgsStartAction -Scope 'sovereign-mimo' -DoExecute | Out-Null } catch { $thrownS1 = ($_ -match 'SGS-FAILCLOSED') }
Assert-True ($thrownS1 -and $script:WrapperLog.Count -eq 0) 'S1 start: FOREIGN_TASK bypass engellendi (0 start wrapper)'
$rS1p = Invoke-SgsStartAction -Scope 'sovereign-mimo'
Assert-True (($rS1p.Steps -join ';') -match 'start bypass engellendi') 'S2 start: plan REFUSE gerekcesi acik'
# S3: owned ama drift => yine fail-closed, 0 start.
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -Arguments '-p sovereign-mimo gateway run --eski')
  }
  return @()
}
$thrownS3 = $false
try { Invoke-SgsStartAction -Scope 'sovereign-mimo' -DoExecute | Out-Null } catch { $thrownS3 = ($_ -match 'SGS-FAILCLOSED') }
Assert-True ($thrownS3 -and $script:WrapperLog.Count -eq 0) 'S3 start: owned-drift 0 start (once install/recreate gerek)'
# S4: exact-owned + config => yalniz exact TaskPath ile start-task.
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo')
  }
  return @()
}
$script:WrapperLog = @()
Reset-SgsStepLog
$rS4 = Invoke-SgsStartAction -Scope 'sovereign-mimo' -DoExecute
Assert-True (($script:WrapperLog -join ';') -eq 'starttask:\Sovereign\Sovereign Gateway sovereign-mimo') 'S4 start: exact-owned task exact TaskPath ile baslatildi'
# S5: task hic yok => bilincli start-direct fallback; farkli path'teki task baslatilmaz.
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -TaskPath '\')
  }
  return @()
}
$script:WrapperLog = @()
Reset-SgsStepLog
$rS5 = Invoke-SgsStartAction -Scope 'sovereign-mimo' -DoExecute
Assert-True (($script:WrapperLog -join ';') -eq 'startdirect:sovereign-mimo') 'S5 start: farkli path task ASLA baslatilmaz; direct fallback kullanilir'

# ======================= T: task tam alan dogrulama =====================
$defT = Get-SgsTaskDefinition -ProfileName 'sovereign-mimo'
$ownT1 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -ActionCount 2) -Definition $defT
Assert-True ($ownT1.IdentityOwned -and (-not $ownT1.ConfigMatches) -and ($ownT1.ConfigReasons -contains 'action-count')) 'T1 tanim: ikinci action drift (ConfigMatches=false)'
$ownT2 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -TriggerUserId 'OTHERDOM\tester') -Definition $defT
Assert-True ((-not $ownT2.ConfigMatches) -and ($ownT2.ConfigReasons -contains 'trigger-user')) 'T2 tanim: baska trigger user drift'
$ownT3 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -UserId 'OTHERDOM\tester') -Definition $defT
Assert-True (-not $ownT3.IdentityOwned) 'T3 tanim: ayni kullanici adi farkli domain/SID => FOREIGN (EndsWith yetmez)'
$ownT4 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -TriggerEnabled $false) -Definition $defT
Assert-True ((-not $ownT4.ConfigMatches) -and ($ownT4.ConfigReasons -contains 'trigger-disabled')) 'T4 tanim: disabled trigger drift'
$ownT5 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -LogonType 'Password') -Definition $defT
Assert-True ((-not $ownT5.ConfigMatches) -and ($ownT5.ConfigReasons -contains 'logon-type')) 'T5 tanim: LogonType farki drift'
$ownT6 = Test-SgsTaskOwnership -TaskInfo (New-TaskInfo -ProfileName 'sovereign-mimo' -UserId 'bilinmeyen-hesap') -Definition $defT
Assert-True (-not $ownT6.IdentityOwned) 'T6 tanim: SID cevrilemeyen principal fail-closed'
# T7: drift task start'i da bloklar (S3 ile ayni kural status uzerinden).
function Get-SgsScheduledTaskInfoList {
  param([string]$TaskName)
  if ($TaskName -eq 'Sovereign Gateway sovereign-mimo') {
    return @(New-TaskInfo -ProfileName 'sovereign-mimo' -ActionCount 2)
  }
  return @()
}
$stT = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $null
Assert-True ($stT[0].taskOwned -and (-not $stT[0].taskConfigMatches)) 'T7 tanim: status taskOwned/taskConfigMatches ayrimi'

# ======================= K: ShouldProcess/WhatIf fonksiyon seviyesi =====
function Get-SgsScheduledTaskInfoList { param([string]$TaskName) return @() }
$script:WrapperLog = @()
$script:SgsShouldProcess = { param($Target, $Operation) $false }
Reset-SgsStepLog
$rK = Invoke-SgsInstallAction -Scope 'all' -DoExecute
$recK = New-SgsReceipt -ActionName 'install' -RequestedExecute $true -WhatIfRequested $true `
  -PlannedSteps $rK.Steps -StepResults @($script:SgsStepLog) -Directory $tmpDir
$parsedK = $recK.Json | ConvertFrom-Json
Assert-True ($script:WrapperLog.Count -eq 0 -and $parsedK.declinedCount -eq 3 -and $parsedK.appliedCount -eq 0 -and $parsedK.effectiveDryRun -eq $true -and $parsedK.outcome -eq 'declined') 'K1 whatif(fn): 0 mutasyon + declined agregat'
$script:SgsShouldProcess = { param($Target, $Operation) $true }

# ======================= L: previous-receipt secimi =====================
$lDir = Join-Path $env:TEMP ('sgs-prev-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $lDir | Out-Null
$statusReceipt = New-SgsReceipt -ActionName 'status' -RequestedExecute $false -GatewayResults $st5 -Directory $lDir
Start-Sleep -Milliseconds 60
$planReceipt = New-SgsReceipt -ActionName 'plan' -RequestedExecute $false `
  -GatewayResults @((Get-SgsTaskDefinition -ProfileName 'sovereign-mimo')) -Directory $lDir
Start-Sleep -Milliseconds 60
Set-Content -LiteralPath (Join-Path $lDir 'receipt-status-99999999-999999-999-zzzzzzzz.json') -Value '{bozuk json' -Encoding UTF8
$prevSel = Get-SgsPreviousReceipt -Directory $lDir
Assert-True ($null -ne $prevSel -and $prevSel.action -eq 'status' -and ($null -ne @($prevSel.gateways)[0].treePids)) 'L1 secim: bozuk/plan atlanir, gecerli gozlem secilir'

# ======================= M: token-level kimlik (decoy) ==================
Assert-True (Test-SgsGatewayCommand -CommandLine '"C:\Program Files\Hermes\hermes.exe" -p sovereign-mimo gateway run' -ProfileName 'sovereign-mimo') 'M1 token: quoted exe launcher taninir'
Assert-True (-not (Test-SgsGatewayCommand -CommandLine 'python.exe "C:\data\sovereign-mimo gateway run\tool.py"' -ProfileName 'sovereign-mimo')) 'M2 token: quoted decoy path launcher DEGIL'
Assert-True (-not (Test-SgsGatewayCommand -CommandLine 'python.exe -c "print(''sovereign-mimo gateway run'')"' -ProfileName 'sovereign-mimo')) 'M3 token: -c decoy launcher DEGIL'
Assert-True (-not (Test-SgsGatewayCommand -CommandLine 'hermes.exe -p sovereign-mimo gateway run' -ProfileName 'sovereign-hermes')) 'M4 token: farkli profil eslesmez'
Assert-True (Test-SgsGatewayCommand -CommandLine 'hermes.exe --profile sovereign-hermes gateway run' -ProfileName 'sovereign-hermes') 'M5 token: --profile taninir'
function Get-SgsProcessTable {
  @((New-Row -RowPid 700 -RowPpid 1 -Name 'python.exe' -Cmd 'python.exe "C:\data\sovereign-mimo gateway run\tool.py"'))
}
function Get-SgsListeners { param([int]$Port) if ($Port -eq 8642) { @(New-Listener -OwnerPid 700) } else { @() } }
$stM = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $null
Assert-True ($stM[0].state -eq 'FOREIGN') 'M6 token: decoy port sahibi FOREIGN'

# ======================= P: resmi CommandLineToArgvW semantigi ==========
$p1 = @(ConvertTo-SgsArgTokens -CommandLine 'x.exe "a b" c')
Assert-True ($p1.Count -eq 3 -and $p1[1] -ceq 'a b' -and $p1[2] -ceq 'c') 'P1 argv: quoted bosluk tek token'
$p2 = @(ConvertTo-SgsArgTokens -CommandLine 'x.exe a\"b c')
Assert-True ($p2.Count -eq 3 -and $p2[1] -ceq 'a"b') 'P2 argv: escaped quote literal'
$p3 = @(ConvertTo-SgsArgTokens -CommandLine 'x.exe "C:\dir\\" tail')
Assert-True ($p3.Count -eq 3 -and $p3[1] -ceq 'C:\dir\' -and $p3[2] -ceq 'tail') 'P3 argv: backslash-before-quote kurali'
$p4 = @(ConvertTo-SgsArgTokens -CommandLine 'x.exe "" -p sovereign-mimo gateway run')
Assert-True (($p4 -ccontains '') -and (Test-SgsGatewayCommand -CommandLine 'x.exe "" -p sovereign-mimo gateway run' -ProfileName 'sovereign-mimo')) 'P4 argv: bos arguman + matcher etkilenmez'
Assert-True (-not (Test-SgsGatewayCommand -CommandLine 'x.exe -p sovereign-mimo\" gateway run' -ProfileName 'sovereign-mimo')) 'P5 argv: escaped-quote decoy profili eslesmez'
$p6 = @(ConvertTo-SgsArgTokens -CommandLine '   ')
Assert-True ($p6.Count -eq 0) 'P6 argv: bos komut satiri bos dizi'

# ======================= O: NONLOOPBACK containment =====================
function Get-SgsScheduledTaskInfoList { param([string]$TaskName) return @() }
function Get-SgsProcessTable {
  @(
    (New-Row -RowPid 100 -RowPpid 1   -Name 'hermes.exe' -Cmd 'hermes.exe -p sovereign-mimo gateway run'),
    (New-Row -RowPid 101 -RowPpid 100 -Name 'python.exe' -Cmd 'python.exe -m hermes_gateway')
  )
}
function Get-SgsListeners { param([int]$Port) if ($Port -eq 8642) { @(New-Listener -OwnerPid 101 -Addr '0.0.0.0') } else { @() } }
$stO = Invoke-SgsStatusAction -Scope 'sovereign-mimo' -SkipHealth -PreviousReceipt $null
Assert-True ($stO[0].state -eq 'NONLOOPBACK' -and $stO[0].failClosed) 'O1 nonloopback: durum + failClosed'
$rStopO = Invoke-SgsStopAction -Scope 'sovereign-mimo'
Assert-True (($rStopO.Steps -join ';') -match 'containment-stop \(nonloopback, exact-owned tree\)') 'O2 nonloopback: containment etiketi'
$script:WrapperLog = @()
function Invoke-SgsGracefulStop { param([string]$ProfileName) $script:WrapperLog += ('gstop:' + $ProfileName + ':mode=' + $script:SgsExecuteMode) }
function Invoke-SgsStopProcess  { param([int]$TargetPid) $script:WrapperLog += ('kill:' + $TargetPid + ':mode=' + $script:SgsExecuteMode) }
Reset-SgsStepLog
$rStopOx = Invoke-SgsStopAction -Scope 'sovereign-mimo' -DoExecute
$logO = $script:WrapperLog -join ';'
Assert-True (($logO -match 'gstop:sovereign-mimo:mode=True') -and ($logO -match 'kill:100:mode=True') -and ($logO -match 'kill:101:mode=True') -and (-not ($logO -match 'kill:(300|700|999)'))) 'O3 nonloopback execute: yalniz exact-owned tree'

# ======================= SGL: hidden launcher testleri ==================
$env:SGL_NO_DISPATCH = '1'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-gateway-launch.ps1')
# Launcher receipt'leri temp'e gitsin diye runtime dizinini gecici tasi.
$sglRoot = Join-Path $env:TEMP ('sgs-sgl-' + [guid]::NewGuid().ToString('N'))
$prevRuntimeDir = $script:SgsRuntimeDir
$script:SgsRuntimeDir = $sglRoot
$script:SglLogDir = Join-Path $sglRoot 'logs'
New-Item -ItemType Directory -Force -Path $sglRoot | Out-Null
function New-SglStatus {
  param([string]$State, [bool]$Loopback = $true, [bool]$FailClosed = $false)
  [pscustomobject]@{ profile='sovereign-mimo'; port=8642; state=$State; failClosed=$FailClosed;
    listener=($State -eq 'RUNNING'); loopbackOnly=$Loopback; ownerPids=@(); foreignPids=@();
    launcherPids=@(); treePids=@(); stalePids=@(); health='-'; taskName='x'; taskPath='\Sovereign\';
    taskInstalled=$true; taskOwned=$true; taskConfigMatches=$true; taskState='Ready'; foreignSameNamePaths=@() }
}
$script:SglQueue = @(); $script:SglQIdx = 0
function Get-SglProfileStatus { param([string]$ProfileName)
  $item = $script:SglQueue[[Math]::Min($script:SglQIdx, $script:SglQueue.Count - 1)]
  $script:SglQIdx++
  return $item }
$script:SglStartLog = @()
function Invoke-SglStartHermesHidden { param([string]$ProfileName, [string]$OutLog, [string]$ErrLog)
  $script:SglStartLog += ('start:' + $ProfileName + ':' + $OutLog) }
$script:SglCleanupLog = @()
function Invoke-SglStopProfileTree { param([string]$ProfileName)
  $script:SglCleanupLog += ('cleanup:' + $ProfileName); return @(111) }
# SGL1: RUNNING => idempotent exit 0, 0 start.
$script:SglQueue = @((New-SglStatus 'RUNNING')); $script:SglQIdx = 0; $script:SglStartLog = @()
$rc1 = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 3 -PollSeconds 0
Assert-True ($rc1 -eq 0 -and $script:SglStartLog.Count -eq 0) 'SGL1 launcher: RUNNING idempotent exit 0, 0 start'
# SGL2: FOREIGN/NONLOOPBACK/PARTIAL => fail-closed exit 2, 0 start.
foreach ($bad in @('FOREIGN','NONLOOPBACK','PARTIAL_NO_LISTENER')) {
  $script:SglQueue = @((New-SglStatus $bad -FailClosed $true)); $script:SglQIdx = 0; $script:SglStartLog = @()
  $rcB = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 3 -PollSeconds 0
  Assert-True ($rcB -eq 2 -and $script:SglStartLog.Count -eq 0) ('SGL2 launcher: ' + $bad + ' fail-closed exit 2, 0 start')
}
# SGL3: DOWN -> hidden start -> RUNNING kabul, exit 0; log yolu dogru.
$script:SglQueue = @((New-SglStatus 'DOWN'), (New-SglStatus 'RUNNING'), (New-SglStatus 'RUNNING')); $script:SglQIdx = 0; $script:SglStartLog = @()
$rc3 = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 6 -PollSeconds 0
Assert-True ($rc3 -eq 0 -and $script:SglStartLog.Count -eq 1 -and ($script:SglStartLog[0] -like ('start:sovereign-mimo:' + $script:SglLogDir + '*'))) 'SGL3 launcher: DOWN hidden-start + RUNNING kabul + log hedefi'
# SGL4: DOWN -> hic RUNNING olmaz => timeout exit 3 + yalniz kendi agac temizligi.
$script:SglQueue = @((New-SglStatus 'DOWN'), (New-SglStatus 'DOWN'), (New-SglStatus 'DOWN')); $script:SglQIdx = 0; $script:SglStartLog = @(); $script:SglCleanupLog = @()
$rc4 = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 1 -PollSeconds 0
Assert-True ($rc4 -eq 3 -and $script:SglCleanupLog.Count -eq 1) 'SGL4 launcher: timeout exit 3 + profil-agaci temizligi'
# SGL5: dosya kilidi duplicate => exit 0, 0 start.
$lockDir5 = Join-Path $sglRoot 'locks'
New-Item -ItemType Directory -Force -Path $lockDir5 | Out-Null
$dupLock = [System.IO.File]::Open((Join-Path $lockDir5 'sovereign-mimo.lock'),
  [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
$script:SglQueue = @((New-SglStatus 'DOWN')); $script:SglQIdx = 0; $script:SglStartLog = @()
$rc5 = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 3 -PollSeconds 0
$dupLock.Dispose()
Assert-True ($rc5 -eq 0 -and $script:SglStartLog.Count -eq 0) 'SGL5 launcher: dosya kilidi duplicate-suppressed, 0 start'
# SGL8: param-clobber savunmasi - 'all' veya gecersiz profil fail-closed.
$script:SglStartLog = @()
$rc8 = Invoke-SglMain -ProfileName 'all' -TimeoutSeconds 3 -PollSeconds 0
Assert-True ($rc8 -eq 2 -and $script:SglStartLog.Count -eq 0) 'SGL8 launcher: gecersiz/all profil fail-closed exit 2, 0 start'
# SGL6: launcher receipt yazildi, action=launcher, redaction filtresinden gecti.
$sglReceipts = @(Get-ChildItem -LiteralPath (Join-Path $sglRoot 'receipts') -Filter 'receipt-launcher-*.json' -File)
Assert-True ($sglReceipts.Count -ge 5) 'SGL6 launcher: her kosuda receipt uretildi'
$sglParsed = Get-Content -LiteralPath $sglReceipts[0].FullName -Raw | ConvertFrom-Json
Assert-True ($sglParsed.action -eq 'launcher' -and $sglParsed.schemaVersion -eq '1.2') 'SGL7 launcher: receipt action/schema dogru'
$script:SgsRuntimeDir = $prevRuntimeDir
Remove-Item -LiteralPath $sglRoot -Recurse -Force -ErrorAction SilentlyContinue

# ============== SU: konsolsuz ortak start contract'i (r5) ===============
$svcSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-gateway-service.ps1') -Raw
$lchSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-gateway-launch.ps1') -Raw
Assert-True (([regex]::Matches($svcSource, 'Start-Process\s+-FilePath\s+\$script:SgsHermesExe')).Count -eq 0) 'SU1 kaynak: eski dogrudan hermes Start-Process yolu kalmadi'
Assert-True (([regex]::Matches($svcSource, 'Start-Process\s+-FilePath\s+\$script:SgsConhostExe')).Count -eq 1) 'SU2 kaynak: konsolsuz start tek ortak primitive icinde'
Assert-True (-not ($lchSource -match 'Start-Process')) 'SU3 kaynak: launcher process baslatmayi yalniz ortak wrapper uzerinden yapar'
Assert-True (-not ($lchSource -match 'Start-ScheduledTask')) 'SU4 kaynak: launcher recursive task cagrisi yapmaz'
# SU5: gercek Invoke-SgsStartDirect ortak primitive'i hedefler (AST'den geri yukle).
$sdDef = ([System.Management.Automation.Language.Parser]::ParseFile((Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-gateway-service.ps1'), [ref]$null, [ref]$null)).
  FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-SgsStartDirect' }, $true)[0]
Invoke-Expression $sdDef.Extent.Text
$script:SuLog = @()
function Invoke-SgsStartHermesConsoleless { param([string]$ProfileName, [string]$OutLog = '', [string]$ErrLog = '')
  $script:SuLog += ('consoleless:' + $ProfileName) }
$script:SgsExecuteMode = $true
Invoke-SgsStartDirect -ProfileName 'sovereign-mimo'
$script:SgsExecuteMode = $false
Assert-True (($script:SuLog -join ';') -eq 'consoleless:sovereign-mimo') 'SU5 start-direct: ortak konsolsuz primitive cagrildi'

# ============== QT: Windows quoting round-trip (r5) =====================
$qt1 = Get-SgsHermesChildArguments -HermesExe 'C:\Fake Dir\her mes.exe' -ProfileName 'sovereign-mimo'
$qt1t = @(ConvertTo-SgsArgTokens -CommandLine ('x.exe ' + $qt1))
Assert-True ($qt1t.Count -eq 7 -and $qt1t[1] -ceq '--headless' -and $qt1t[2] -ceq 'C:\Fake Dir\her mes.exe' -and $qt1t[3] -ceq '-p' -and $qt1t[4] -ceq 'sovereign-mimo' -and $qt1t[5] -ceq 'gateway' -and $qt1t[6] -ceq 'run') 'QT1 quoting: bosluklu hermes yolu exact round-trip'
$qt2 = Get-SgsHermesChildArguments -HermesExe 'C:\weird\pa th\' -ProfileName 'sovereign-hermes'
$qt2t = @(ConvertTo-SgsArgTokens -CommandLine ('x.exe ' + $qt2))
Assert-True ($qt2t[2] -ceq 'C:\weird\pa th\') 'QT2 quoting: sondaki backslash + bosluk exact'
$qt3raw = 'a"b c\'
$qt3t = @(ConvertTo-SgsArgTokens -CommandLine ('x.exe ' + (ConvertTo-SgsQuotedArg -Arg $qt3raw)))
Assert-True ($qt3t.Count -eq 2 -and $qt3t[1] -ceq $qt3raw) 'QT3 quoting: gomulu tirnak/backslash exact'
$qt4 = Get-SgsHermesChildArguments -HermesExe $script:SgsHermesExe -ProfileName 'sovereign-mimo'
Assert-True ($qt4 -ceq ('--headless {0} -p sovereign-mimo gateway run' -f $script:SgsHermesExe)) 'QT4 quoting: boslukssuz gercek yol degismedi (regresyon korumasi)'

# ============== SGLX: launcher exception sertligi (r5) ==================
$sglxRoot = Join-Path $env:TEMP ('sgs-sglx-' + [guid]::NewGuid().ToString('N'))
$prevRuntimeDir2 = $script:SgsRuntimeDir
$script:SgsRuntimeDir = $sglxRoot
New-Item -ItemType Directory -Force -Path $sglxRoot | Out-Null
$script:SglStartLog = @()
function Invoke-SglStartHermesHidden { param([string]$ProfileName, [string]$OutLog, [string]$ErrLog)
  $script:SglStartLog += ('start:' + $ProfileName) }
function Get-SglProfileStatus { param([string]$ProfileName)
  throw 'status patladi API_KEY=gizli-xyz-123456789 detay' }
$rcX = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 3 -PollSeconds 0
Assert-True ($rcX -eq 4 -and $script:SglStartLog.Count -eq 0) 'SGLX1 exception: nonzero fail-closed + 0 start'
$lockProbe = $null
try {
  $lockProbe = [System.IO.File]::Open((Join-Path (Join-Path $sglxRoot 'locks') 'sovereign-mimo.lock'),
    [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
} catch { $lockProbe = $null }
Assert-True ($null -ne $lockProbe) 'SGLX2 exception: dosya kilidi kesin birakildi'
if ($lockProbe) { $lockProbe.Dispose() }
$xr = @(Get-ChildItem -LiteralPath (Join-Path $sglxRoot 'receipts') -Filter 'receipt-launcher-*.json' -File | Sort-Object LastWriteTime -Descending)
$xj = Get-Content -LiteralPath $xr[0].FullName -Raw
Assert-True (($xj | ConvertFrom-Json).outcome -eq 'error') 'SGLX3 exception: outcome=error receipt yazildi'
Assert-True (-not ($xj -match 'gizli-xyz')) 'SGLX4 exception: receipt errorMessage redacted'
# SGLX5: receipt yazimi da patlarsa recursion yok, exit nonzero.
function Get-SglProfileStatus { param([string]$ProfileName) return (New-SglStatus 'RUNNING') }
function New-SgsReceipt { throw 'receipt disk dolu' }
$rcX2 = Invoke-SglMain -ProfileName 'sovereign-mimo' -TimeoutSeconds 3 -PollSeconds 0
Assert-True ($rcX2 -eq 5) 'SGLX5 receipt-fail: tek deneme, recursion yok, exit=5'
$script:SgsRuntimeDir = $prevRuntimeDir2
Remove-Item -LiteralPath $sglxRoot -Recurse -Force -ErrorAction SilentlyContinue

# ======================= Q: gercek dispatcher (WhatIf/NoReceipt) ========
$qDir = Join-Path $env:TEMP ('sgs-q-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $qDir | Out-Null
$sovBefore = @(Get-ScheduledTask -TaskPath '\Sovereign\' -ErrorAction SilentlyContinue).Count
# Child process env'i miras alir: dispatch'in calismasi icin bayragi gecici kapat.
$env:SGS_NO_DISPATCH = '0'
# PS 5.1 tuzagi: EAP=Stop altinda native stderr yonlendirmesi terminating
# NativeCommandError uretir; child kosulari icin gecici Continue.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
# Q1: gercek script -Action install -Execute -WhatIf => 0 mutasyon + receipt VAR.
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Action install -Execute -WhatIf -ReceiptDirectory $qDir *> $null
$q1Exit = $LASTEXITCODE
$sovAfter1 = @(Get-ScheduledTask -TaskPath '\Sovereign\' -ErrorAction SilentlyContinue).Count
$q1Receipts = @(Get-ChildItem -LiteralPath $qDir -Filter 'receipt-install-*.json' -File)
Assert-True ($q1Receipts.Count -ge 1) 'Q1 dispatcher whatif: receipt dosyasi GERCEKTEN yazildi'
$q1 = Get-Content -LiteralPath $q1Receipts[0].FullName -Raw | ConvertFrom-Json
Assert-True ($q1.whatIfRequested -eq $true -and $q1.requestedExecute -eq $true -and $q1.appliedCount -eq 0 -and $q1.effectiveDryRun -eq $true) 'Q2 dispatcher whatif: alanlar gercegi soyluyor'
Assert-True (@('declined','fail-closed','ok') -contains [string]$q1.outcome) 'Q3 dispatcher whatif: outcome gecerli kumede (ortama gore declined/fail-closed/ok-idempotent)'
Assert-True ($sovAfter1 -eq $sovBefore) 'Q4 dispatcher whatif: \Sovereign\ task sayisi degismedi (0 mutasyon)'
# Q5: -Execute -NoReceipt audit bypass reddi + zorunlu refusal receipt.
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Action install -Execute -NoReceipt -ReceiptDirectory $qDir *> $null
$q5Exit = $LASTEXITCODE
$ErrorActionPreference = $prevEap
$sovAfter2 = @(Get-ScheduledTask -TaskPath '\Sovereign\' -ErrorAction SilentlyContinue).Count
$q5All = @(Get-ChildItem -LiteralPath $qDir -Filter 'receipt-install-*.json' -File | Sort-Object LastWriteTime -Descending)
$q5 = Get-Content -LiteralPath $q5All[0].FullName -Raw | ConvertFrom-Json
Assert-True ($q5Exit -ne 0) 'Q5 dispatcher noreceipt: execute+noreceipt reddedildi (exit!=0)'
Assert-True ($q5.outcome -eq 'fail-closed' -and (($q5.plannedSteps -join ';') -match 'audit bypass')) 'Q6 dispatcher noreceipt: zorunlu refusal receipt yazildi'
Assert-True ($sovAfter2 -eq $sovBefore) 'Q7 dispatcher noreceipt: 0 mutasyon'
$env:SGS_NO_DISPATCH = '1'

# ---- ozet --------------------------------------------------------------
Write-Host ''
Write-Host ("TOPLAM: {0} test, {1} basarisiz" -f $script:TestCount, $script:TestFails)
foreach ($d in @($tmpDir, $lDir, $qDir)) {
  if ($d -and (Test-Path -LiteralPath $d)) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
}
exit $script:TestFails
