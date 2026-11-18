<#
.SYNOPSIS
  Sovereign provider probe (P0-B Faz 2B, bolum 7 sozlesmesi).
  MiMo (sovereign-mimo/8642 profili) ve DeepSeek (sovereign-deepseek/8643
  profili) icin dogrudan provider /chat/completions ucuna minimal maliyetli,
  sifir hassas-baglamli bir "Yalniz OK yaz." probe cagrisi yapar.

.DESCRIPTION
  Kurallar:
   - Varsayilan mod DRY-RUN'dir; env/dogrulama calisir ama HICBIR agin
     cagrisi yapilmaz. Gercek ucretli cagri yalniz -Execute ile.
   - Secret (API key), base URL ve ham request/response govdesi hicbir zaman
     ekrana, exception mesajina, receipt'e veya loga yazilmaz. Yalniz uzunluk
     ve SHA-256 hash saklanir.
   - Profil basina en fazla 1 inference cagrisi; yalniz transient network
     veya HTTP 408/425/429/500/502/503/504 durumunda en fazla 1 retry. Auth
     (401/403), model/validation (400/404/422) veya diger hatalarda retry
     YOK.
   - Fail-closed: eksik/duplicate/malformed env, non-HTTPS base URL,
     userinfo/query/fragment/non-default-port iceren base URL, host
     allowlist ihlali, secret placeholder, receipt yazim hatasi.
   - Allowlist tam host: api.xiaomimimo.com (MiMo) ve api.deepseek.com
     (DeepSeek). Base URL override yalniz kendi exact hostunda HTTPS olabilir.

.NOTES
  Test modu: $env:SPP_NO_DISPATCH='1' iken yalniz fonksiyonlar yuklenir,
  dispatcher (gercek profil dongusu + exit) calismaz. Testler HTTP
  (Invoke-SppRawHttpPost) ve env okuma (Get-SppEnvLines, Test-SppPath)
  seam'lerini mock/fake eder; gercek dosya sistemine veya aga dokunulmaz.
#>
[CmdletBinding()]
param(
  [ValidateSet('sovereign-mimo', 'sovereign-deepseek', 'both')]
  [string]$GatewayProfile = 'both',

  [switch]$Execute,

  [ValidateRange(5, 60)]
  [int]$TimeoutSec = 20,

  [string]$ReceiptDirectory
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- sabitler

$script:SppRepoRoot    = Split-Path -Parent $PSScriptRoot
$script:SppRuntimeDir  = Join-Path $script:SppRepoRoot 'runtime\sovereign-hermes-gateways'
$script:SppProfilesRoot = Join-Path $env:LOCALAPPDATA 'hermes\profiles'
$script:SppSchema      = '1.0'
$script:SppTransientHttpCodes = @(408, 425, 429, 500, 502, 503, 504)
$script:SppMaxAttempts = 2

$script:SppProviders = [ordered]@{
  'sovereign-mimo'     = [pscustomobject]@{
    Provider                   = 'xiaomi'
    Model                      = 'mimo-v2.5'
    ApiKeyEnvName              = 'XIAOMI_API_KEY'
    BaseUrlEnvName             = 'XIAOMI_BASE_URL'
    DefaultBaseUrl             = 'https://api.xiaomimimo.com/v1'
    AllowedHost                = 'api.xiaomimimo.com'
    PricingInputPerMillionUsd  = 0.14
    PricingOutputPerMillionUsd = 0.28
  }
  'sovereign-deepseek' = [pscustomobject]@{
    Provider                   = 'deepseek'
    Model                      = 'deepseek-v4-flash'
    ApiKeyEnvName              = 'DEEPSEEK_API_KEY'
    BaseUrlEnvName             = 'DEEPSEEK_BASE_URL'
    DefaultBaseUrl             = 'https://api.deepseek.com/v1'
    AllowedHost                = 'api.deepseek.com'
    PricingInputPerMillionUsd  = 0.14
    PricingOutputPerMillionUsd = 0.28
  }
}

function Get-SppProfileList {
  param([string]$Scope)
  if ($Scope -eq 'both') { return @($script:SppProviders.Keys) }
  return @($Scope)
}

# ------------------------------------------------------------- dis dunya seam'leri

function Get-SppProfileEnvPath {
  param([string]$ProfileName)
  Join-Path (Join-Path $script:SppProfilesRoot $ProfileName) '.env'
}

function Test-SppPath {
  param([string]$Path)
  Test-Path -LiteralPath $Path
}

function Get-SppEnvLines {
  # I/O seam: testler bu fonksiyonu gercek dosyaya dokunmadan sahte satirlar
  # dondurecek sekilde ezer.
  param([string]$Path)
  [System.IO.File]::ReadAllLines($Path)
}

function Invoke-SppRawHttpPost {
  # HTTP seam: testler bu fonksiyonu ezer; gercek cagri hicbir test yolunda
  # yapilmaz. Donus: StatusCode ($null = network hatasi), Body (yalniz basari
  # govdesi ayristirmasi icin - HATA govdesi hicbir zaman okunmaz/saklanmaz),
  # NetworkError (transient network/DNS/timeout).
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  try {
    $headers = @{ Authorization = $AuthHeaderValue }
    # -MaximumRedirection 0: 3xx otomatik izlenmez; retry politikasi 3xx'i
    # transient saymadigi icin (contract) redirect'e asla sessizce uyulmaz.
    $resp = Invoke-WebRequest -Uri $Uri -Method Post -Headers $headers `
      -ContentType 'application/json' -Body $BodyJson -TimeoutSec $TimeoutSec `
      -MaximumRedirection 0 -UseBasicParsing
    return [pscustomobject]@{ StatusCode = [int]$resp.StatusCode; Body = [string]$resp.Content; NetworkError = $false }
  } catch {
    $ex = $_.Exception
    $statusCode = $null
    if ($ex.PSObject.Properties['Response'] -and $ex.Response) {
      try { $statusCode = [int]$ex.Response.StatusCode } catch { $statusCode = $null }
    }
    if ($null -eq $statusCode) {
      # DNS/connect/timeout/reset: uygulama-katmani HTTP durumu yok -> transient.
      return [pscustomobject]@{ StatusCode = $null; Body = ''; NetworkError = $true }
    }
    # Hata govdesi bilincli olarak OKUNMAZ/saklanmaz (contract: hata body loglanmaz).
    return [pscustomobject]@{ StatusCode = $statusCode; Body = ''; NetworkError = $false }
  }
}

# ------------------------------------------------------------- saf mantik

function Read-SppRequiredEnvValue {
  # Yalniz istenen tek anahtari arar; ayni anahtarin birden fazla tanimi
  # DUPLICATE olarak fail-closed'dir. Diger satirlar/anahtarlar okunmaz.
  param([string[]]$Lines, [string]$KeyName, [bool]$Required)
  $found = @()
  foreach ($line in @($Lines)) {
    if ($null -eq $line) { continue }
    $trimmed = $line.TrimEnd("`r")
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) { continue }
    $eqIdx = $trimmed.IndexOf('=')
    if ($eqIdx -lt 1) { continue }
    $k = $trimmed.Substring(0, $eqIdx)
    if ($k -cne $KeyName) { continue }
    $found += $trimmed.Substring($eqIdx + 1)
  }
  if ($found.Count -gt 1) { throw ('SPP-FAILCLOSED: ENV_DUPLICATE:' + $KeyName) }
  if ($found.Count -eq 0) {
    if ($Required) { throw ('SPP-FAILCLOSED: ENV_MISSING:' + $KeyName) }
    return $null
  }
  return $found[0]
}

function Test-SppSecretPlaceholder {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
  $v = $Value.Trim()
  if ($v.Length -lt 8) { return $true }
  if ($v.Contains("`n") -or $v.Contains("`r")) { return $true }
  $lower = $v.ToLowerInvariant()
  $placeholders = @(
    'changeme', 'change_me', 'your_api_key', 'yourapikey', 'replace_me',
    'placeholder', 'api_key_here', 'insert_key', 'xxxxxxxx', 'todo', 'tbd',
    'example', 'sample', 'dummy', 'fake', 'test-key', 'testkey', 'secret'
  )
  foreach ($p in $placeholders) { if ($lower.Contains($p)) { return $true } }
  return $false
}

function Resolve-SppBaseUrl {
  # Fail-closed: malformed URI, non-HTTPS, host allowlist disi,
  # userinfo/query/fragment/non-default-port varligi.
  param([string]$RawValue, [string]$DefaultUrl, [string]$AllowedHost)
  $candidate = $DefaultUrl
  if ($RawValue) { $candidate = $RawValue.Trim() }
  $uri = $null
  try { $uri = [System.Uri]$candidate } catch { throw 'SPP-FAILCLOSED: BASEURL_MALFORMED' }
  if (-not $uri.IsAbsoluteUri) { throw 'SPP-FAILCLOSED: BASEURL_MALFORMED' }
  if ($uri.Scheme -ne 'https') { throw 'SPP-FAILCLOSED: BASEURL_NOT_HTTPS' }
  if ($uri.Host -ne $AllowedHost) { throw 'SPP-FAILCLOSED: BASEURL_HOST_NOT_ALLOWLISTED' }
  if ($uri.AbsolutePath -ne '/v1' -and $uri.AbsolutePath -ne '/v1/') { throw 'SPP-FAILCLOSED: BASEURL_PATH_INVALID' }
  if ($uri.UserInfo) { throw 'SPP-FAILCLOSED: BASEURL_HAS_USERINFO' }
  if ($uri.Query) { throw 'SPP-FAILCLOSED: BASEURL_HAS_QUERY' }
  if ($uri.Fragment) { throw 'SPP-FAILCLOSED: BASEURL_HAS_FRAGMENT' }
  if (-not $uri.IsDefaultPort) { throw 'SPP-FAILCLOSED: BASEURL_NONDEFAULT_PORT' }
  return $uri
}

function Get-SppChatCompletionsEndpoint {
  param([System.Uri]$BaseUri)
  $base = $BaseUri.AbsoluteUri
  if ($base.EndsWith('/')) { $base = $base.Substring(0, $base.Length - 1) }
  return ($base + '/chat/completions')
}

function ConvertTo-SppSha256Hex {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = $sha.ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString('x2') })
  } finally {
    $sha.Dispose()
  }
}

function ConvertTo-SppFailClosedReason {
  # Bilinen 'SPP-FAILCLOSED: CODE' sozlesmesi disindaki HER exception (secret
  # icerebilecek ham .NET/IO/network mesajlari dahil) statik bir koda
  # indirgenir; ham exception metni asla receipt/console'a yazilmaz.
  param([string]$ExceptionMessage)
  if ($ExceptionMessage -match '^SPP-FAILCLOSED:\s*(.+)$') { return $Matches[1] }
  return 'UNEXPECTED_EXCEPTION'
}

function Test-SppUsageFields {
  # HTTP 200 + OK icerik olsa bile usage alanlari eksik/bozuk/limit-asimi ise
  # basarisiz sayilir. Donen PromptTokens/CompletionTokens/TotalTokens sadece
  # tum alanlar mevcut+integer+non-negative oldugunda dolu olur; aksi halde
  # $null (receipt'e guvenli/kismi kayit).
  param($ParsedResponse, [int]$MaxCompletionTokens)
  $template = { param($Reason) [pscustomobject]@{ Valid = $false; Reason = $Reason; PromptTokens = $null; CompletionTokens = $null; TotalTokens = $null } }
  if (-not ($ParsedResponse.PSObject.Properties['usage']) -or $null -eq $ParsedResponse.usage) {
    return (& $template 'USAGE_MISSING')
  }
  $u = $ParsedResponse.usage
  foreach ($f in @('prompt_tokens', 'completion_tokens', 'total_tokens')) {
    if (-not ($u.PSObject.Properties[$f]) -or $null -eq $u.$f) { return (& $template 'USAGE_FIELD_MISSING') }
  }
  foreach ($f in @('prompt_tokens', 'completion_tokens', 'total_tokens')) {
    $v = $u.$f
    $isIntegerLike = ($v -is [int]) -or ($v -is [long])
    if (-not $isIntegerLike -and ($v -is [double])) { $isIntegerLike = ($v -eq [Math]::Floor($v)) }
    if (-not $isIntegerLike) { return (& $template 'USAGE_FIELD_NOT_INTEGER') }
    if ([long]$v -lt 0) { return (& $template 'USAGE_FIELD_NEGATIVE') }
  }
  $promptTok = [long]$u.prompt_tokens
  $compTok = [long]$u.completion_tokens
  $totTok = [long]$u.total_tokens
  if (($promptTok + $compTok) -ne $totTok) {
    return [pscustomobject]@{ Valid = $false; Reason = 'USAGE_INCONSISTENT'; PromptTokens = $promptTok; CompletionTokens = $compTok; TotalTokens = $totTok }
  }
  if ($compTok -gt $MaxCompletionTokens) {
    return [pscustomobject]@{ Valid = $false; Reason = 'USAGE_COMPLETION_LIMIT_EXCEEDED'; PromptTokens = $promptTok; CompletionTokens = $compTok; TotalTokens = $totTok }
  }
  return [pscustomobject]@{ Valid = $true; Reason = ''; PromptTokens = $promptTok; CompletionTokens = $compTok; TotalTokens = $totTok }
}

function New-SppResultTemplate {
  param([string]$ProfileName, $Cfg, [string]$Mode)
  [ordered]@{
    schemaVersion             = $script:SppSchema
    tool                      = 'sovereign-provider-probe'
    provider                  = $Cfg.Provider
    profile                   = $ProfileName
    model                     = $Cfg.Model
    timestampUtc              = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    mode                      = $Mode
    attemptCount              = 0
    httpStatus                = $null
    latencyMs                 = $null
    success                   = $false
    expectedOk                = $false
    responseLength            = $null
    responseSha256            = $null
    usage                     = [ordered]@{ promptTokens = $null; completionTokens = $null; totalTokens = $null }
    configuredCostEstimateUsd = $null
    pricing                   = [ordered]@{
      inputPerMillionUsd  = $Cfg.PricingInputPerMillionUsd
      outputPerMillionUsd = $Cfg.PricingOutputPerMillionUsd
      note                = 'local configured estimate, not an official/current provider price feed'
    }
    outcome                   = 'ok'
    failClosedReason          = ''
  }
}

function Resolve-SppValidatedProfileConfig {
  # Yalniz gerekli iki alani okur (API key + optional base URL); tum diger
  # dogrulama saf mantikta yapilir. Basarida ApiKey ve BaseUri doner; hatada
  # throw eder (mesaj hicbir secret degeri icermez, yalniz kod adi).
  param([string]$ProfileName, $Cfg)
  $envPath = Get-SppProfileEnvPath -ProfileName $ProfileName
  if (-not (Test-SppPath -Path $envPath)) { throw 'SPP-FAILCLOSED: ENV_MISSING_FILE' }
  $lines = @(Get-SppEnvLines -Path $envPath)
  $apiKey = Read-SppRequiredEnvValue -Lines $lines -KeyName $Cfg.ApiKeyEnvName -Required $true
  if (Test-SppSecretPlaceholder -Value $apiKey) { throw 'SPP-FAILCLOSED: SECRET_PLACEHOLDER' }
  $rawBaseUrl = Read-SppRequiredEnvValue -Lines $lines -KeyName $Cfg.BaseUrlEnvName -Required $false
  $baseUri = Resolve-SppBaseUrl -RawValue $rawBaseUrl -DefaultUrl $Cfg.DefaultBaseUrl -AllowedHost $Cfg.AllowedHost
  [pscustomobject]@{ ApiKey = $apiKey; BaseUri = $baseUri }
}

function Invoke-SppLiveAttempt {
  # Profil basina en fazla 1 gercek deneme + (yalniz transient) 1 retry.
  param([string]$Endpoint, [string]$ApiKey, [string]$BodyJson, [int]$TimeoutSec)
  $authHeader = 'Bearer ' + $ApiKey
  $attempt = 0
  $lastResp = $null
  $lastLatencyMs = $null
  while ($attempt -lt $script:SppMaxAttempts) {
    $attempt++
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-SppRawHttpPost -Uri $Endpoint -AuthHeaderValue $authHeader -BodyJson $BodyJson -TimeoutSec $TimeoutSec
    $sw.Stop()
    $lastLatencyMs = [int]$sw.ElapsedMilliseconds
    $lastResp = $resp
    $isTransient = ([bool]$resp.NetworkError) -or ($resp.StatusCode -and ($script:SppTransientHttpCodes -contains [int]$resp.StatusCode))
    if (-not $isTransient) { break }
  }
  [pscustomobject]@{ Response = $lastResp; AttemptCount = $attempt; LatencyMs = $lastLatencyMs }
}

function Invoke-SppProfileProbe {
  param([string]$ProfileName, [bool]$DoExecute, [int]$TimeoutSec)
  $cfg = $script:SppProviders[$ProfileName]
  $mode = 'dry-run'
  if ($DoExecute) { $mode = 'execute' }
  $result = New-SppResultTemplate -ProfileName $ProfileName -Cfg $cfg -Mode $mode

  $validated = $null
  try {
    $validated = Resolve-SppValidatedProfileConfig -ProfileName $ProfileName -Cfg $cfg
  } catch {
    # Bilinen SPP-FAILCLOSED: CODE disindaki HER exception (secret icerebilir)
    # statik UNEXPECTED_EXCEPTION koduna indirgenir; ham mesaj asla yazilmaz.
    $result.outcome = 'fail-closed'
    $result.failClosedReason = ConvertTo-SppFailClosedReason -ExceptionMessage ([string]$_.Exception.Message)
    return [pscustomobject]$result
  }

  if (-not $DoExecute) {
    $result.outcome = 'dry-run'
    return [pscustomobject]$result
  }

  try {
    $endpoint = Get-SppChatCompletionsEndpoint -BaseUri $validated.BaseUri
    $bodyObj = [ordered]@{
      model       = $cfg.Model
      messages    = @(@{ role = 'user'; content = 'Yalniz OK yaz.' })
      temperature = 0
      max_tokens  = 8
      stream      = $false
      # Her iki saglayicinin da guncel resmi create-chat-completion sozlesmesi
      # (DeepSeek deepseek-v4-flash, MiMo mimo-v2.5 - Xiaomi mimo.mi.com/docs,
      # 2026-07-17 guncellemesi) thinking'i varsayilan enabled tutuyor. 8
      # tokenlik butcenin tamami reasoning'e gidip gorunur icerik uretilmemesini
      # onlemek icin iki profilde de acikca disabled istenir.
      thinking    = [ordered]@{ type = 'disabled' }
    }
    $bodyJson = ($bodyObj | ConvertTo-Json -Depth 5 -Compress)

    $attemptResult = Invoke-SppLiveAttempt -Endpoint $endpoint -ApiKey $validated.ApiKey -BodyJson $bodyJson -TimeoutSec $TimeoutSec
    # Secret bu noktadan sonra artik gerekmiyor.
    $validated = $null
    $bodyJson = $null

    $result.attemptCount = $attemptResult.AttemptCount
    $result.latencyMs = $attemptResult.LatencyMs
    $resp = $attemptResult.Response

    if ($resp.NetworkError) {
      $result.outcome = 'fail-closed'
      $result.failClosedReason = 'NETWORK_TRANSIENT_EXHAUSTED'
      return [pscustomobject]$result
    }

    $result.httpStatus = [int]$resp.StatusCode
    if ([int]$resp.StatusCode -ne 200) {
      $result.outcome = 'failed'
      $result.failClosedReason = ('HTTP_' + [int]$resp.StatusCode)
      return [pscustomobject]$result
    }

    try {
      $parsed = $resp.Body | ConvertFrom-Json
      $content = [string]$parsed.choices[0].message.content
    } catch {
      $result.outcome = 'failed'
      $result.failClosedReason = 'RESPONSE_PARSE_ERROR'
      return [pscustomobject]$result
    }

    $result.responseLength = $content.Length
    $result.responseSha256 = ConvertTo-SppSha256Hex -Text $content
    # Case-sensitive exact eslesme: 'ok' / 'Ok' vb. kabul edilmez.
    $result.expectedOk = ($content.Trim() -ceq 'OK')

    $usageCheck = Test-SppUsageFields -ParsedResponse $parsed -MaxCompletionTokens 8
    $result.usage.promptTokens = $usageCheck.PromptTokens
    $result.usage.completionTokens = $usageCheck.CompletionTokens
    $result.usage.totalTokens = $usageCheck.TotalTokens

    if (-not $usageCheck.Valid) {
      # usage eksik/bozuk/limit-asimi ise content OK olsa bile basarisiz.
      $result.success = $false
      $result.outcome = 'failed'
      $result.failClosedReason = $usageCheck.Reason
      return [pscustomobject]$result
    }

    $result.configuredCostEstimateUsd = [Math]::Round(
      (($usageCheck.PromptTokens / 1000000.0) * $cfg.PricingInputPerMillionUsd) +
      (($usageCheck.CompletionTokens / 1000000.0) * $cfg.PricingOutputPerMillionUsd), 8)

    if ($result.expectedOk) {
      $result.success = $true
      $result.outcome = 'ok'
    } else {
      $result.success = $false
      $result.outcome = 'failed'
      $result.failClosedReason = 'UNEXPECTED_RESPONSE_CONTENT'
    }
    return [pscustomobject]$result
  } catch {
    $result.outcome = 'fail-closed'
    $result.failClosedReason = ConvertTo-SppFailClosedReason -ExceptionMessage ([string]$_.Exception.Message)
    return [pscustomobject]$result
  }
}

# ----------------------------------------------------------- receipt yazimi

function Write-SppReceipt {
  # Atomik/benzersiz: .NET FileMode.CreateNew ile receipt carpismasi asla
  # ustune yazilmaz; 16 denemede olusturulamazsa throw eder (fail-closed).
  param($Result, [string]$Directory)
  $json = ($Result | ConvertTo-Json -Depth 8)
  [void][System.IO.Directory]::CreateDirectory($Directory)
  $utf8 = New-Object System.Text.UTF8Encoding($true)
  $bytes = $utf8.GetBytes($json)
  for ($attempt = 0; $attempt -lt 16; $attempt++) {
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
    $nonce = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $candidate = Join-Path $Directory ('receipt-provider-probe-{0}-{1}-{2}.json' -f $Result.profile, $stamp, $nonce)
    try {
      $fs = [System.IO.File]::Open($candidate, [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
      try { $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Dispose() }
      return $candidate
    } catch [System.IO.IOException] { continue }
  }
  throw 'SPP: receipt dosyasi 16 denemede olusturulamadi.'
}

# ----------------------------------------------------- preflight + dispatch

function Test-SppReceiptDirWritable {
  # Execute modunda HERHANGI HTTP cagrisindan once calisir: atomik
  # create+delete probe dosyasi ile receipt dizininin yazilabilir oldugu
  # dogrulanir. Basarisizlikta $false doner (throw etmez) - dispatcher
  # bunu sifir-HTTP + exit 5 olarak yorumlar.
  param([string]$Directory)
  try {
    [void][System.IO.Directory]::CreateDirectory($Directory)
    $probePath = Join-Path $Directory ('.spp-writable-probe-' + [guid]::NewGuid().ToString('N'))
    $fs = [System.IO.File]::Open($probePath, [System.IO.FileMode]::CreateNew,
      [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    $fs.Dispose()
    [System.IO.File]::Delete($probePath)
    return $true
  } catch {
    return $false
  }
}

function Invoke-SppDispatch {
  # Testable dispatcher govdesi (HTTP'siz cagirilabilir - Invoke-SppProfileProbe
  # ve Write-SppReceipt seam olarak ezilebilir). Kurallar:
  #  - Execute'ta HERHANGI HTTP'den once receipt dizini preflight'i yapilir;
  #    basarisizsa sifir profil islenir (sifir HTTP), ExitCode=5.
  #  - Bir profilin receipt yazimi basarisiz olursa sonraki profil icin
  #    provider cagrisi YAPILMAZ (fail-closed halt).
  param([string[]]$Profiles, [bool]$DoExecute, [int]$TimeoutSec, [string]$ReceiptDir)
  $exitCode = 0
  $entries = @()

  if ($DoExecute -and -not (Test-SppReceiptDirWritable -Directory $ReceiptDir)) {
    return [pscustomobject]@{ PreflightFailed = $true; ExitCode = 5; Entries = $entries }
  }

  $halted = $false
  foreach ($p in $Profiles) {
    if ($halted) { break }
    $result = Invoke-SppProfileProbe -ProfileName $p -DoExecute:$DoExecute -TimeoutSec $TimeoutSec

    $receiptPath = ''
    $receiptError = $false
    try {
      $receiptPath = Write-SppReceipt -Result $result -Directory $ReceiptDir
    } catch {
      $receiptError = $true
      if ($exitCode -lt 5) { $exitCode = 5 }
      $halted = $true
    }

    $entries += [pscustomobject]@{ Profile = $p; Result = $result; ReceiptPath = $receiptPath; ReceiptError = $receiptError }

    if (-not $receiptError) {
      if ($result.outcome -eq 'fail-closed' -and $exitCode -lt 2) { $exitCode = 2 }
      elseif ($result.outcome -eq 'failed' -and $exitCode -lt 3) { $exitCode = 3 }
    }
  }

  [pscustomobject]@{ PreflightFailed = $false; ExitCode = $exitCode; Entries = $entries }
}

# ----------------------------------------------------------- dispatcher

if ($env:SPP_NO_DISPATCH -eq '1') { return }

$receiptDir = $ReceiptDirectory
if (-not $receiptDir) { $receiptDir = Join-Path $script:SppRuntimeDir 'receipts' }

Write-Host ('== sovereign-provider-probe :: profile={0} execute={1} timeoutSec={2} ==' -f $GatewayProfile, [bool]$Execute, $TimeoutSec) -ForegroundColor Cyan
if (-not $Execute) {
  Write-Host 'DRY-RUN: hicbir gercek provider cagrisi yapilmayacak (env/URL dogrulamasi calisir).' -ForegroundColor Yellow
}

$dispatch = Invoke-SppDispatch -Profiles (Get-SppProfileList -Scope $GatewayProfile) -DoExecute:([bool]$Execute) -TimeoutSec $TimeoutSec -ReceiptDir $receiptDir

if ($dispatch.PreflightFailed) {
  Write-Host 'PREFLIGHT-FAILCLOSED: receipt dizini yazilabilir degil; hicbir provider cagrisi yapilmadi.' -ForegroundColor Red
  exit $dispatch.ExitCode
}

$exitCode = $dispatch.ExitCode
foreach ($entry in $dispatch.Entries) {
  $p = $entry.Profile
  $result = $entry.Result

  if ($entry.ReceiptError) {
    Write-Host ('[{0}] receipt yazilamadi (fail-closed); sonraki profil icin cagri yapilmayacak.' -f $p) -ForegroundColor Red
  }

  $summary = '[{0}] provider={1} model={2} mode={3} outcome={4} httpStatus={5} latencyMs={6} attempts={7} success={8} expectedOk={9} responseLen={10} costEstUsd={11}' -f `
    $p, $result.provider, $result.model, $result.mode, $result.outcome, $result.httpStatus, `
    $result.latencyMs, $result.attemptCount, $result.success, $result.expectedOk, `
    $result.responseLength, $result.configuredCostEstimateUsd
  if ($result.failClosedReason) { $summary += (' reason={0}' -f $result.failClosedReason) }
  $color = 'Green'
  if ($result.outcome -eq 'fail-closed') { $color = 'Red' }
  elseif ($result.outcome -eq 'failed') { $color = 'Red' }
  elseif ($result.outcome -eq 'dry-run') { $color = 'Yellow' }
  Write-Host $summary -ForegroundColor $color
  if ($entry.ReceiptPath) { Write-Host ('  receipt: {0}' -f $entry.ReceiptPath) -ForegroundColor DarkGray }
}

exit $exitCode
