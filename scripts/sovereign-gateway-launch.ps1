<#
.SYNOPSIS
  Sovereign gateway hidden launcher (P0-B Faz 2A review-fix r4).
  Scheduled Task action'i bu script'i powershell.exe -WindowStyle Hidden ile
  calistirir; gateway child'i gorunmez pencereyle baslar, wrapper kisa surede
  biter.

.DESCRIPTION
  Kurallar (ADR 0010):
   - Secret/credential tasimaz, okumaz, basmaz.
   - Profil basina dosya kilidi (FileShare::None) ile cift calisma engellenir
     (duplicate-suppressed, exit 0).
   - Mevcut lifecycle status mantigi SALT-OKUNUR yeniden kullanilir:
     RUNNING => idempotent exit 0; FOREIGN/NONLOOPBACK/PARTIAL_NO_LISTENER =>
     fail-closed exit 2, HICBIR process baslatilmaz; DOWN => hermes servis
     icindeki ORTAK konsolsuz start contract'i ile baslar, stdout/stderr gitignore'lu
     runtime\sovereign-hermes-gateways\logs altina yonlenir, timeoutlu
     RUNNING+loopback kabulu yapilir (basari exit 0, timeout exit 3 ve yalniz
     kendi profil agacimiz temizlenir).
   - Her sonuc redacted launcher receipt'i birakir (schema 1.2, action=launcher).

.NOTES
  Test modu: $env:SGL_NO_DISPATCH='1' iken yalniz fonksiyonlar yuklenir.
  Servis fonksiyonlari zaten yukluyse yeniden dot-source edilmez (testlerin
  mock'lari korunur).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('sovereign-mimo', 'sovereign-deepseek', 'sovereign-hermes')]
  [string]$GatewayProfile = 'sovereign-mimo',
  [int]$TimeoutSec = 90,
  [int]$PollSec = 3
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# KRITIK (canli Faz 2A'da yakalandi): servis scripti dot-source edilirken
# kendi param blogu calisir ve $GatewayProfile'i 'all' varsayilaniyla EZER.
# Parametreleri dot-source'tan ONCE ayri adlara kopyala; sonrasinda yalniz
# bunlari kullan.
$script:SglProfile    = $GatewayProfile
$script:SglTimeoutSec = $TimeoutSec
$script:SglPollSec    = $PollSec

# Servis fonksiyonlarini salt-okunur yeniden kullan (dispatch'siz yukle).
if (-not (Get-Command -Name 'Get-SgsGatewayStatus' -ErrorAction SilentlyContinue)) {
  $prevNoDispatch = $env:SGS_NO_DISPATCH
  $env:SGS_NO_DISPATCH = '1'
  try {
    . (Join-Path $PSScriptRoot 'sovereign-gateway-service.ps1')
  } finally {
    if ($null -eq $prevNoDispatch) { Remove-Item Env:SGS_NO_DISPATCH -ErrorAction SilentlyContinue }
    else { $env:SGS_NO_DISPATCH = $prevNoDispatch }
  }
}

$script:SglLogDir = Join-Path $script:SgsRuntimeDir 'logs'

function Invoke-SglStartHermesHidden {
  # r5: ince delegator - servisteki TEK ortak konsolsuz child-start
  # contract'ini kullanir (conhost --headless + hidden + log redirect +
  # round-trip kanitli quoting). Recursive launcher/task cagrisi yoktur.
  param([string]$ProfileName, [string]$OutLog, [string]$ErrLog)
  Invoke-SgsStartHermesConsoleless -ProfileName $ProfileName -OutLog $OutLog -ErrLog $ErrLog
}

function Invoke-SglStopProfileTree {
  # Yalniz timeout temizligi icin: token-kanitli KENDI profil agacimiz.
  param([string]$ProfileName)
  $table = @(Get-SgsProcessTable)
  $tree = Resolve-SgsTree -Table $table -ProfileName $ProfileName
  foreach ($treePid in $tree.AllPids) {
    Stop-Process -Id $treePid -Force -ErrorAction SilentlyContinue
  }
  return @($tree.AllPids)
}

function Get-SglProfileStatus {
  param([string]$ProfileName)
  $list = @(Invoke-SgsStatusAction -Scope $ProfileName -SkipHealth -PreviousReceipt $null)
  return $list[0]
}

function Invoke-SglMain {
  # Donus: process exit kodu. 0=ok/idempotent/duplicate, 2=fail-closed,
  # 3=start/timeout-fail, 4=beklenmeyen exception (fail-closed),
  # 5=sonuc receipt'i yazilamadi.
  # r5 garanti: beklenmeyen status/lock/IO exception'lari disari KACAMAZ;
  # kilit kesin birakilir; receipt TEK denemedir (recursion yok) ve
  # yazilamazsa exit nonzero olur.
  param([string]$ProfileName, [int]$TimeoutSeconds = 90, [int]$PollSeconds = 3)

  Reset-SgsStepLog
  $outcome = 'ok'
  $exitCode = 0
  $errMsg = ''
  $gatewayResults = @()
  $planned = @()
  $lockStream = $null

  try {
    # Savunma katmani: yalniz bilinen TEK profil ('all' dahil her gecersiz
    # deger fail-closed; param-clobber sinifina karsi).
    if (-not $script:SgsGateways.Contains($ProfileName)) {
      Add-SgsStepResult -ProfileName ([string]$ProfileName) -Operation 'launcher' `
        -Target ([string]$ProfileName) -Status 'refused' `
        -Detail 'gecersiz profil (exact tek profil gerekli)'
      $planned = @('REFUSE fail-closed (gecersiz profil): ' + $ProfileName)
      $outcome = 'fail-closed'
      $exitCode = 2
    } else {
      # Cift calisma korumasi: profil basina dosya kilidi (FileShare::None).
      # Named mutex ayni thread'de reentrant oldugu icin bilincli olarak
      # dosya kilidi secildi.
      $lockDir = Join-Path $script:SgsRuntimeDir 'locks'
      [void][System.IO.Directory]::CreateDirectory($lockDir)
      $lockPath = Join-Path $lockDir ($ProfileName + '.lock')
      try {
        $lockStream = [System.IO.File]::Open($lockPath,
          [System.IO.FileMode]::OpenOrCreate,
          [System.IO.FileAccess]::ReadWrite,
          [System.IO.FileShare]::None)
      } catch [System.IO.IOException] { $lockStream = $null }
      if ($null -eq $lockStream) {
        Add-SgsStepResult -ProfileName $ProfileName -Operation 'launcher' -Target $ProfileName `
          -Status 'skipped' -Detail 'duplicate-suppressed (dosya kilidi)'
        $planned = @('duplicate-suppressed: ' + $ProfileName)
        $exitCode = 0
      } else {
        $st = Get-SglProfileStatus -ProfileName $ProfileName
        $gatewayResults = @($st)
        switch ($st.state) {
          'RUNNING' {
            Add-SgsStepResult -ProfileName $ProfileName -Operation 'launcher' -Target $ProfileName `
              -Status 'skipped' -Detail 'idempotent (zaten RUNNING)'
            $planned = @('idempotent-running: ' + $ProfileName)
            $exitCode = 0
          }
          'DOWN' {
            [void][System.IO.Directory]::CreateDirectory($script:SglLogDir)
            $stamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
            $outLog = Join-Path $script:SglLogDir ('{0}-launch-{1}.out.log' -f $ProfileName, $stamp)
            $errLog = Join-Path $script:SglLogDir ('{0}-launch-{1}.err.log' -f $ProfileName, $stamp)
            $planned = @(('hidden-start: {0} (loglar: runtime\sovereign-hermes-gateways\logs)' -f $ProfileName))
            try {
              Invoke-SglStartHermesHidden -ProfileName $ProfileName -OutLog $outLog -ErrLog $errLog
              Add-SgsStepResult -ProfileName $ProfileName -Operation 'hidden-start' -Target $ProfileName -Status 'applied'
            } catch {
              Add-SgsStepResult -ProfileName $ProfileName -Operation 'hidden-start' -Target $ProfileName `
                -Status 'failed' -Detail (Protect-SgsText -Text ([string]$_.Exception.Message))
              $outcome = 'failed'
              $exitCode = 3
            }
            if ($exitCode -eq 0) {
              $t0 = Get-Date
              $accepted = $false
              do {
                Start-Sleep -Seconds $PollSeconds
                $st2 = Get-SglProfileStatus -ProfileName $ProfileName
                if ($st2.state -eq 'RUNNING' -and $st2.loopbackOnly) { $accepted = $true; break }
                if ($st2.failClosed) { break }
              } while (((Get-Date) - $t0).TotalSeconds -lt $TimeoutSeconds)
              $gatewayResults = @((Get-SglProfileStatus -ProfileName $ProfileName))
              if ($accepted) {
                Add-SgsStepResult -ProfileName $ProfileName -Operation 'accept' -Target $ProfileName `
                  -Status 'applied' -Detail 'RUNNING + loopback-only'
              } else {
                # Fail-closed temizlik: yalniz kendi token-kanitli agacimiz.
                $cleaned = @(Invoke-SglStopProfileTree -ProfileName $ProfileName)
                Add-SgsStepResult -ProfileName $ProfileName -Operation 'accept' -Target $ProfileName `
                  -Status 'failed' -Detail ('timeout/fail-closed; temizlenen pid: ' + ($cleaned -join ','))
                $outcome = 'failed'
                $exitCode = 3
              }
            }
          }
          default {
            # FOREIGN | NONLOOPBACK | PARTIAL_NO_LISTENER: hicbir sey baslatma.
            Add-SgsStepResult -ProfileName $ProfileName -Operation 'launcher' -Target $ProfileName `
              -Status 'refused' -Detail ('fail-closed durum: ' + $st.state)
            $planned = @('REFUSE fail-closed (' + $st.state + '): ' + $ProfileName)
            $outcome = 'fail-closed'
            $exitCode = 2
          }
        }
      }
    }
  } catch {
    # Beklenmeyen status/lock/IO exception'i: fail-closed nonzero; hicbir
    # start denemesi bu noktadan sonra yapilmaz.
    $errMsg = [string]$_.Exception.Message
    try {
      Add-SgsStepResult -ProfileName ([string]$ProfileName) -Operation 'launcher' `
        -Target ([string]$ProfileName) -Status 'failed' `
        -Detail (Protect-SgsText -Text $errMsg)
    } catch { }
    $outcome = 'error'
    $exitCode = 4
  } finally {
    if ($null -ne $lockStream) { try { $lockStream.Dispose() } catch { } }
  }

  # TEK deneme receipt: yazim basarisizsa recursion/yeniden deneme YOK;
  # exit nonzero'ya cekilir.
  $receiptPath = ''
  try {
    $receipt = New-SgsReceipt -ActionName 'launcher' -RequestedExecute $true `
      -GatewayResults $gatewayResults -PlannedSteps $planned `
      -StepResults @($script:SgsStepLog) -Outcome $outcome -ErrorMessage $errMsg `
      -Directory (Join-Path $script:SgsRuntimeDir 'receipts')
    $receiptPath = [string]$receipt.Path
  } catch {
    try {
      Write-Host ('launcher receipt yazilamadi: ' + (Protect-SgsText -Text ([string]$_.Exception.Message)))
    } catch { }
    if ($exitCode -eq 0) { $exitCode = 5 }
  }
  try {
    Write-Host ('launcher[{0}] exit={1} outcome={2} receipt={3}' -f $ProfileName, $exitCode, $outcome, $receiptPath)
  } catch { }
  return $exitCode
}

if ($env:SGL_NO_DISPATCH -eq '1') { return }

exit (Invoke-SglMain -ProfileName $script:SglProfile -TimeoutSeconds $script:SglTimeoutSec -PollSeconds $script:SglPollSec)
