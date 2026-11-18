<#
.SYNOPSIS
  Sovereign dedicated Hermes gateway'leri (MiMo/DeepSeek/restricted Hermes) icin
  idempotent yasam dongusu: status | start | stop.

.NOTES
  TARIHSEL (19 Temmuz 2026): Bu script yerini ADR 0010 ile
  `scripts/sovereign-gateway-service.ps1` dosyasina birakti. Yeni is icin
  onu kullan; bu dosya referans olarak korunur.

  17 Temmuz kabul topolojisinin tekrar uretilebilir hali. Gercek baslatma
  komutlari Codex'in oturum hafizasindan cikarilip diskte dogrulandi.

  Guvenlik/dogruluk kurallari (Codex tuzak uyarilari):
   - Profil-kapsamli calis. ASLA `gateway stop --all` kullanma: ana
     `owner-orchestrator` gateway'ini oldurur.
   - Durumu PID/gateway_state.json dosyasindan OKUMA; onlar stale kalir.
     Gercek olcut: CommandLine eslesmesi + TCP listener + (varsa) /health.
   - Secret DEGERI ekrana/loga yazma. API anahtari yalnizca /health header'inda
     kullanilir, gosterilmez.
   - Duplicate-start yarisi daha once yasandi; start yalnizca calismayani baslatir.
#>
[CmdletBinding()]
param(
  [ValidateSet('status', 'start', 'stop')]
  [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'

$HermesExe = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$WorkDir   = 'C:\Users\MSI\Documents\HERMESAGENT'
$LogRoot   = Join-Path $WorkDir 'runtime\sovereign-hermes-gateways'

$Gateways = [ordered]@{
  'sovereign-mimo'     = 8642
  'sovereign-deepseek' = 8643
  'sovereign-hermes'   = 8644
}

function Get-GatewayProcess {
  param([string]$Profile)
  # Gercek olcut: komut satirinda profil + "gateway run" gecen hermes/python sureci.
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '^(hermes|python)\.exe$' -and
    $_.CommandLine -match [regex]::Escape($Profile) -and
    $_.CommandLine -match 'gateway run'
  }
}

function Test-Listener {
  param([int]$Port)
  [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Test-GatewayHealth {
  param([int]$Port)
  # Opsiyonel: MODEL_GATEWAY_API_KEY varsa authenticated /health dener.
  # Anahtar yalnizca header'da kullanilir, dondurulmez.
  $key = $env:MODEL_GATEWAY_API_KEY
  $headers = @{}
  if ($key) { $headers['Authorization'] = "Bearer $key" }
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -Headers $headers -TimeoutSec 4 -UseBasicParsing
    return "HTTP $($r.StatusCode)"
  } catch {
    if ($_.Exception.Response) { return "HTTP $([int]$_.Exception.Response.StatusCode)" }
    return 'no-response'
  }
}

function Show-Status {
  Write-Host "== Sovereign gateway durumu ==" -ForegroundColor Cyan
  foreach ($name in $Gateways.Keys) {
    $port = $Gateways[$name]
    $proc = @(Get-GatewayProcess -Profile $name)
    $listening = Test-Listener -Port $port
    $health = if ($listening) { Test-GatewayHealth -Port $port } else { '-' }
    $pids = if ($proc) { ($proc | ForEach-Object { $_.ProcessId }) -join ',' } else { '-' }
    $state = if ($listening -and $proc) { 'UP' } elseif ($proc -or $listening) { 'PARTIAL' } else { 'DOWN' }
    "{0,-20} port {1}  {2,-8} listener={3,-5} health={4,-9} pid={5}" -f `
      $name, $port, $state, $listening, $health, $pids | Write-Host
  }
}

function Start-Gateways {
  if (-not (Test-Path $HermesExe)) { throw "hermes.exe bulunamadi: $HermesExe" }
  New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null
  foreach ($name in $Gateways.Keys) {
    if (Get-GatewayProcess -Profile $name) {
      Write-Host "$name zaten calisiyor - atlandi" -ForegroundColor Yellow
      continue
    }
    Start-Process -FilePath $HermesExe `
      -ArgumentList @('-p', $name, 'gateway', 'run') `
      -WorkingDirectory $WorkDir `
      -RedirectStandardOutput (Join-Path $LogRoot "$name.stdout.log") `
      -RedirectStandardError  (Join-Path $LogRoot "$name.stderr.log") `
      -WindowStyle Hidden | Out-Null
    Write-Host "$name baslatildi" -ForegroundColor Green
    Start-Sleep -Seconds 3
  }
  Write-Host "20sn readiness bekleniyor..." -ForegroundColor DarkGray
  Start-Sleep -Seconds 20
  Show-Status
}

function Stop-Gateways {
  foreach ($name in $Gateways.Keys) {
    # 1) Once profil-kapsamli graceful stop.
    try {
      & $HermesExe -p $name gateway stop 2>$null | Out-Null
    } catch { }
  }
  Start-Sleep -Seconds 3
  # 2) Kalan varsa yalnizca ESLESEN profil surecini force-kill (asla --all).
  foreach ($name in $Gateways.Keys) {
    $proc = @(Get-GatewayProcess -Profile $name)
    foreach ($p in $proc) {
      Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
      Write-Host "$name force-stop (pid $($p.ProcessId))" -ForegroundColor Yellow
    }
  }
  Start-Sleep -Seconds 2
  Show-Status
}

switch ($Action) {
  'status' { Show-Status }
  'start'  { Start-Gateways }
  'stop'   { Stop-Gateways }
}
