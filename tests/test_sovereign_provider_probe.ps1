<#
  sovereign-provider-probe.ps1 icin mock + seam testleri.
  HTTP (Invoke-SppRawHttpPost) ve env okuma (Get-SppEnvLines, Test-SppPath)
  tamamen mock/fake'tir; gercek dosya sistemine veya aga hicbir zaman
  dokunulmaz, gercek provider cagrisi yapilmaz. Cikis kodu = basarisiz test
  sayisi.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$env:SPP_NO_DISPATCH = '1'
$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\sovereign-provider-probe.ps1'
. $scriptPath

$script:TestCount = 0
$script:TestFails = 0
function Assert-True {
  param([bool]$Condition, [string]$Name)
  $script:TestCount++
  if ($Condition) { Write-Host ("PASS: {0}" -f $Name) }
  else { $script:TestFails++; Write-Host ("FAIL: {0}" -f $Name) -ForegroundColor Red }
}

# ---- ortak yardimcilar ---------------------------------------------------

$script:MimoValidLines = @(
  '# yorum satiri',
  '',
  'XIAOMI_API_KEY=sk-mimo-1234567890abcdef'
)
$script:DeepSeekValidLines = @(
  'DEEPSEEK_API_KEY=sk-deepseek-1234567890abcdef'
)

function New-FakeHttpResponse {
  param(
    [Nullable[int]]$StatusCode,
    [string]$Body = '',
    [bool]$NetworkError = $false
  )
  [pscustomobject]@{ StatusCode = $StatusCode; Body = $Body; NetworkError = $NetworkError }
}

function New-OkChatBody {
  param([string]$Content = 'OK', [int]$PromptTokens = 12, [int]$CompletionTokens = 1)
  $obj = [ordered]@{
    choices = @(@{ message = @{ role = 'assistant'; content = $Content } })
    usage   = [ordered]@{
      prompt_tokens     = $PromptTokens
      completion_tokens = $CompletionTokens
      total_tokens      = ($PromptTokens + $CompletionTokens)
    }
  }
  return ($obj | ConvertTo-Json -Depth 5 -Compress)
}

function New-ChatBodyRawUsage {
  # usage nesnesini serbestce (eksik/bozuk alanlarla) kontrol etmek icin.
  param([string]$Content = 'OK', $UsageObj)
  $obj = [ordered]@{ choices = @(@{ message = @{ role = 'assistant'; content = $Content } }) }
  if ($null -ne $UsageObj) { $obj.usage = $UsageObj }
  return ($obj | ConvertTo-Json -Depth 5 -Compress)
}

# HTTP hic mock edilmeden cagrilirsa test agi kullanir demektir -> fail-closed guard.
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  throw 'TEST-GUARD: Invoke-SppRawHttpPost mock edilmeden cagrildi (gercek ag cagrisi onlendi)'
}
function Get-SppEnvLines {
  param([string]$Path)
  throw 'TEST-GUARD: Get-SppEnvLines mock edilmeden cagrildi'
}
function Test-SppPath {
  param([string]$Path)
  throw 'TEST-GUARD: Test-SppPath mock edilmeden cagrildi'
}

# ======================= A: dry-run =====================================
function Test-SppPath { param([string]$Path) $true }
function Get-SppEnvLines {
  param([string]$Path)
  if ($Path -match 'sovereign-mimo') { return $script:MimoValidLines }
  return $script:DeepSeekValidLines
}
$script:HttpCalls = 0
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) $script:HttpCalls++; New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody) }

$rA = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $false -TimeoutSec 20
Assert-True ($rA.outcome -eq 'dry-run') 'A1 dry-run: outcome=dry-run'
Assert-True ($script:HttpCalls -eq 0) 'A2 dry-run: sifir HTTP cagrisi'
Assert-True ($rA.attemptCount -eq 0) 'A3 dry-run: attemptCount 0'
Assert-True ($null -eq $rA.httpStatus) 'A4 dry-run: httpStatus null'
Assert-True (-not $rA.success) 'A5 dry-run: success false'

# ======================= B: basarili execute + exact body/limits ========
$script:CapturedBodyJson = $null
$script:CapturedUri = $null
$script:CapturedTimeout = $null
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  $script:CapturedBodyJson = $BodyJson
  $script:CapturedUri = $Uri
  $script:CapturedTimeout = $TimeoutSec
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody -Content 'OK' -PromptTokens 12 -CompletionTokens 1)
}
$script:HttpCalls = 0
$rB = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rB.outcome -eq 'ok') 'B1 execute ok: outcome=ok'
Assert-True ($rB.success) 'B2 execute ok: success true'
Assert-True ($rB.expectedOk) 'B3 execute ok: expectedOk true'
Assert-True ($rB.attemptCount -eq 1) 'B4 execute ok: attemptCount 1 (retry yok)'
Assert-True ($rB.httpStatus -eq 200) 'B5 execute ok: httpStatus 200'
Assert-True ($rB.responseLength -eq 2) 'B6 execute ok: responseLength = len("OK")'
Assert-True ($rB.responseSha256 -eq (ConvertTo-SppSha256Hex -Text 'OK')) 'B7 execute ok: responseSha256 dogru'
Assert-True ($rB.usage.promptTokens -eq 12 -and $rB.usage.completionTokens -eq 1 -and $rB.usage.totalTokens -eq 13) 'B8 execute ok: usage alanlari'
$expectedCost = [Math]::Round(((12 / 1000000.0) * 0.14) + ((1 / 1000000.0) * 0.28), 8)
Assert-True ($rB.configuredCostEstimateUsd -eq $expectedCost) 'B9 execute ok: configuredCostEstimateUsd 0.14/0.28 formulu'
Assert-True ($rB.pricing.inputPerMillionUsd -eq 0.14 -and $rB.pricing.outputPerMillionUsd -eq 0.28) 'B10 execute ok: pricing metadata'
$bodyObj = $script:CapturedBodyJson | ConvertFrom-Json
Assert-True ($bodyObj.model -eq 'mimo-v2.5') 'B11 body: model = mimo-v2.5'
Assert-True ($bodyObj.messages.Count -eq 1 -and $bodyObj.messages[0].role -eq 'user' -and $bodyObj.messages[0].content -eq 'Yalniz OK yaz.') 'B12 body: tek user mesaji exact'
Assert-True ($bodyObj.temperature -eq 0) 'B13 body: temperature 0'
Assert-True ($bodyObj.max_tokens -eq 8) 'B14 body: max_tokens 8'
Assert-True ($bodyObj.stream -eq $false) 'B15 body: stream false'
Assert-True ($bodyObj.thinking.type -eq 'disabled') 'B15b mimo body: thinking.type=disabled'
Assert-True ($script:CapturedUri -eq 'https://api.xiaomimimo.com/v1/chat/completions') 'B16 endpoint: direct provider /chat/completions'
Assert-True ($script:CapturedTimeout -eq 20) 'B17 timeout: TimeoutSec iletildi'

# DeepSeek icin ayni kontrat
function Get-SppEnvLines { param([string]$Path) $script:DeepSeekValidLines }
$rBd = Invoke-SppProfileProbe -ProfileName 'sovereign-deepseek' -DoExecute $true -TimeoutSec 20
Assert-True ($script:CapturedUri -eq 'https://api.deepseek.com/v1/chat/completions') 'B18 deepseek endpoint dogru'
$bodyObjD = $script:CapturedBodyJson | ConvertFrom-Json
Assert-True ($bodyObjD.model -eq 'deepseek-v4-flash') 'B19 deepseek body model dogru'
Assert-True ($bodyObjD.thinking.type -eq 'disabled') 'B19b deepseek body: thinking.type=disabled'
function Get-SppEnvLines {
  param([string]$Path)
  if ($Path -match 'sovereign-mimo') { return $script:MimoValidLines }
  return $script:DeepSeekValidLines
}

# ======================= C: retry politikasi =============================
# C1: transient 503 -> 1 retry -> basari (toplam 2 attempt)
$script:HttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  if ($script:HttpCalls -eq 1) { return New-FakeHttpResponse -StatusCode 503 }
  return New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody)
}
$rC1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($script:HttpCalls -eq 2) 'C1 retry: 503 sonrasi tam 1 retry (2 cagri)'
Assert-True ($rC1.attemptCount -eq 2) 'C1b retry: attemptCount 2'
Assert-True ($rC1.outcome -eq 'ok') 'C1c retry: retry sonrasi basari'

# C2: transient network error iki kez -> fail-closed, en fazla 2 deneme
$script:HttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  New-FakeHttpResponse -StatusCode $null -NetworkError $true
}
$rC2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($script:HttpCalls -eq 2) 'C2 retry: network hatasi max 2 denemede durur'
Assert-True ($rC2.outcome -eq 'fail-closed') 'C2b retry: tukenen transient -> fail-closed'
Assert-True ($rC2.failClosedReason -eq 'NETWORK_TRANSIENT_EXHAUSTED') 'C2c retry: sebep kodu'

# C3: 401 (auth) -> retry YOK (tek cagri)
$script:HttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  New-FakeHttpResponse -StatusCode 401
}
$rC3 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($script:HttpCalls -eq 1) 'C3 no-retry: 401 auth hatasinda tek cagri'
Assert-True ($rC3.attemptCount -eq 1) 'C3b no-retry: attemptCount 1'
Assert-True ($rC3.outcome -eq 'failed' -and $rC3.failClosedReason -eq 'HTTP_401') 'C3c no-retry: HTTP_401 failed'

# C4: 400 (validation) -> retry YOK
$script:HttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  New-FakeHttpResponse -StatusCode 400
}
$rC4 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($script:HttpCalls -eq 1) 'C4 no-retry: 400 validation hatasinda tek cagri'

# C5: beklenmeyen icerik (expectedOk=false) -> failed, ama success=false, httpStatus 200
$script:HttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:HttpCalls++
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody -Content 'Merhaba, nasil yardimci olabilirim?')
}
$rC5 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True (-not $rC5.expectedOk -and -not $rC5.success) 'C5 unexpected content: expectedOk/success false'
Assert-True ($rC5.outcome -eq 'failed' -and $rC5.failClosedReason -eq 'UNEXPECTED_RESPONSE_CONTENT') 'C5b unexpected content: outcome/reason'
Assert-True ($rC5.responseLength -gt 0 -and $rC5.responseSha256.Length -eq 64) 'C5c unexpected content: uzunluk/hash kaydedilir'

# ======================= D: env fail-closed ===============================
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: HTTP cagrilmamali' }

# D1: env dosyasi yok
function Test-SppPath { param([string]$Path) $false }
$rD1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD1.outcome -eq 'fail-closed' -and $rD1.failClosedReason -eq 'ENV_MISSING_FILE') 'D1 env yok: fail-closed ENV_MISSING_FILE'
function Test-SppPath { param([string]$Path) $true }

# D2: gerekli anahtar eksik
function Get-SppEnvLines { param([string]$Path) return @('SOME_OTHER_KEY=deneme12345') }
$rD2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD2.outcome -eq 'fail-closed' -and $rD2.failClosedReason -eq 'ENV_MISSING:XIAOMI_API_KEY') 'D2 anahtar eksik: fail-closed ENV_MISSING'

# D3: duplicate anahtar
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-birinci-1234567890', 'XIAOMI_API_KEY=sk-ikinci-1234567890')
}
$rD3 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD3.outcome -eq 'fail-closed' -and $rD3.failClosedReason -eq 'ENV_DUPLICATE:XIAOMI_API_KEY') 'D3 duplicate anahtar: fail-closed ENV_DUPLICATE'

# D4: placeholder/kisa secret
function Get-SppEnvLines { param([string]$Path) return @('XIAOMI_API_KEY=changeme') }
$rD4 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD4.outcome -eq 'fail-closed' -and $rD4.failClosedReason -eq 'SECRET_PLACEHOLDER') 'D4 placeholder secret: fail-closed SECRET_PLACEHOLDER'
function Get-SppEnvLines { param([string]$Path) return @('XIAOMI_API_KEY=short') }
$rD4b = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD4b.outcome -eq 'fail-closed' -and $rD4b.failClosedReason -eq 'SECRET_PLACEHOLDER') 'D4b kisa secret: fail-closed SECRET_PLACEHOLDER'

# D5: non-HTTPS base URL
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=http://api.xiaomimimo.com/v1')
}
$rD5 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD5.outcome -eq 'fail-closed' -and $rD5.failClosedReason -eq 'BASEURL_NOT_HTTPS') 'D5 non-https base URL: fail-closed'

# D6: host allowlist ihlali
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://evil.example.com/v1')
}
$rD6 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD6.outcome -eq 'fail-closed' -and $rD6.failClosedReason -eq 'BASEURL_HOST_NOT_ALLOWLISTED') 'D6 host allowlist ihlali: fail-closed'

# D7: userinfo iceren base URL
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://user:pass@api.xiaomimimo.com/v1')
}
$rD7 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD7.outcome -eq 'fail-closed' -and $rD7.failClosedReason -eq 'BASEURL_HAS_USERINFO') 'D7 userinfo icerir: fail-closed'

# D8: query iceren base URL
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1?x=1')
}
$rD8 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD8.outcome -eq 'fail-closed' -and $rD8.failClosedReason -eq 'BASEURL_HAS_QUERY') 'D8 query icerir: fail-closed'

# D9: fragment iceren base URL
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1#frag')
}
$rD9 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD9.outcome -eq 'fail-closed' -and $rD9.failClosedReason -eq 'BASEURL_HAS_FRAGMENT') 'D9 fragment icerir: fail-closed'

# D10: non-default port
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com:8443/v1')
}
$rD10 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD10.outcome -eq 'fail-closed' -and $rD10.failClosedReason -eq 'BASEURL_NONDEFAULT_PORT') 'D10 non-default port: fail-closed'

# D11: gecerli override base URL kabul edilir (execute ile birlikte basariya gider)
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1')
}
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:CapturedUri = $Uri
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody)
}
$rD11 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rD11.outcome -eq 'ok') 'D11 gecerli override base URL: basari'
Assert-True ($script:CapturedUri -eq 'https://api.xiaomimimo.com/v1/chat/completions') 'D11b override URL ile endpoint dogru'

# ======================= E: dry-run da env dogrulamasi yapar (fail-closed) =
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: dry-run HTTP cagirmamali' }
function Get-SppEnvLines { param([string]$Path) return @('SOME_OTHER_KEY=x') }
$rE1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $false -TimeoutSec 20
Assert-True ($rE1.outcome -eq 'fail-closed') 'E1 dry-run: eksik anahtar yine fail-closed olarak raporlanir'

# ======================= F: secret/response body hicbir yerde yok ========
function Get-SppEnvLines { param([string]$Path) return @('XIAOMI_API_KEY=sk-cok-gizli-deger-123456') }
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody -Content 'OK')
}
$rF = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
$rFJson = ($rF | ConvertTo-Json -Depth 8)
Assert-True (-not ($rFJson -match 'sk-cok-gizli-deger')) 'F1 secret degeri receipt/result JSON icinde YOK'
Assert-True (-not ($rFJson -match '"content"')) 'F2 ham response icerigi ayri bir "content" alani olarak result JSON icinde YOK (yalniz hash/uzunluk)'
Assert-True ($rF.responseSha256 -eq (ConvertTo-SppSha256Hex -Text 'OK')) 'F3 responseSha256 dogru hesaplanir'

# ======================= G: receipt atomik yazim + carpisma + hata =======
$tmpReceiptDir = Join-Path ([System.IO.Path]::GetTempPath()) ('spp-test-receipts-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($tmpReceiptDir)
try {
  $sampleResult = New-SppResultTemplate -ProfileName 'sovereign-mimo' -Cfg $script:SppProviders['sovereign-mimo'] -Mode 'dry-run'
  $sampleResult.outcome = 'dry-run'
  $path1 = Write-SppReceipt -Result ([pscustomobject]$sampleResult) -Directory $tmpReceiptDir
  Assert-True (Test-Path -LiteralPath $path1) 'G1 receipt: dosya olusturuldu'
  $path2 = Write-SppReceipt -Result ([pscustomobject]$sampleResult) -Directory $tmpReceiptDir
  Assert-True (($path1 -ne $path2) -and (Test-Path -LiteralPath $path2)) 'G2 receipt: ayni icerikle ikinci cagri farkli/benzersiz dosya uretir (carpisma yok)'
  $filesNow = @(Get-ChildItem -LiteralPath $tmpReceiptDir -Filter 'receipt-provider-probe-*.json')
  Assert-True ($filesNow.Count -eq 2) 'G3 receipt: iki ayri receipt dosyasi mevcut'

  # G4: receipt yazim hatasi (dizin olarak var olan bir dosya yolu / erisilemez hedef) fail-closed sayilir
  $badDir = Join-Path $tmpReceiptDir 'blocked-as-file'
  [void](New-Item -ItemType File -Path $badDir -Force)
  $threw = $false
  try { Write-SppReceipt -Result ([pscustomobject]$sampleResult) -Directory $badDir | Out-Null }
  catch { $threw = $true }
  Assert-True $threw 'G4 receipt: yazilamayan hedefte throw (fail-closed)'
} finally {
  Remove-Item -LiteralPath $tmpReceiptDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ======================= H: env dosya yolu (gercek IO'ya dokunmadan) =====
$script:SppProfilesRoot = 'C:\fake\hermes\profiles'
Assert-True ((Get-SppProfileEnvPath -ProfileName 'sovereign-mimo') -eq 'C:\fake\hermes\profiles\sovereign-mimo\.env') 'H1 env path: profil basina .env yolu dogru kurulur'

# ======================= I: hedef surumler tam eslesir ====================
Assert-True ($script:SppProviders['sovereign-mimo'].Provider -eq 'xiaomi' -and $script:SppProviders['sovereign-mimo'].Model -eq 'mimo-v2.5') 'I1 mimo provider/model sabitleri'
Assert-True ($script:SppProviders['sovereign-deepseek'].Provider -eq 'deepseek' -and $script:SppProviders['sovereign-deepseek'].Model -eq 'deepseek-v4-flash') 'I2 deepseek provider/model sabitleri'
Assert-True ($script:SppProviders['sovereign-mimo'].DefaultBaseUrl -eq 'https://api.xiaomimimo.com/v1') 'I3 mimo default base URL'
Assert-True ($script:SppProviders['sovereign-deepseek'].DefaultBaseUrl -eq 'https://api.deepseek.com/v1') 'I4 deepseek default base URL'
Assert-True ($script:SppProviders['sovereign-mimo'].PricingInputPerMillionUsd -eq 0.14 -and $script:SppProviders['sovereign-mimo'].PricingOutputPerMillionUsd -eq 0.28) 'I5 mimo pricing sabitleri'
Assert-True ($script:SppProviders['sovereign-deepseek'].PricingInputPerMillionUsd -eq 0.14 -and $script:SppProviders['sovereign-deepseek'].PricingOutputPerMillionUsd -eq 0.28) 'I6 deepseek pricing sabitleri'

# ======================= J: MiMo + DeepSeek ikisi de thinking:disabled ====
function Get-SppEnvLines {
  param([string]$Path)
  if ($Path -match 'sovereign-mimo') { return $script:MimoValidLines }
  return $script:DeepSeekValidLines
}
function Test-SppPath { param([string]$Path) $true }
$script:CapturedBodyJson = $null
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:CapturedBodyJson = $BodyJson
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody)
}
$rJMimo = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
$mimoBodyObj = $script:CapturedBodyJson | ConvertFrom-Json
Assert-True ($null -ne $mimoBodyObj.PSObject.Properties['thinking']) 'J1 mimo body: thinking alani VAR'
Assert-True ($mimoBodyObj.thinking.type -eq 'disabled') 'J2 mimo body: thinking.type=disabled'
Assert-True ($rJMimo.outcome -eq 'ok') 'J2b mimo: thinking eklenmesiyle birlikte basari devam eder'

$rJDs = Invoke-SppProfileProbe -ProfileName 'sovereign-deepseek' -DoExecute $true -TimeoutSec 20
$dsBodyObj = $script:CapturedBodyJson | ConvertFrom-Json
Assert-True ($null -ne $dsBodyObj.PSObject.Properties['thinking']) 'J3 deepseek body: thinking alani VAR'
Assert-True ($dsBodyObj.thinking.type -eq 'disabled') 'J4 deepseek body: thinking.type=disabled'
Assert-True ($rJDs.outcome -eq 'ok') 'J4b deepseek: thinking eklenmesiyle birlikte basari devam eder'

# ======================= K: -MaximumRedirection 0 kaynak kaniti ===========
$script:ProbeScriptText = [System.IO.File]::ReadAllText($scriptPath)
Assert-True ($script:ProbeScriptText -match '-MaximumRedirection\s+0') 'K1 kaynak kaniti: Invoke-WebRequest -MaximumRedirection 0 kullanir (3xx otomatik izlenmez)'

# ======================= L: receipt dizini preflight yazilabilirlik =======
$writableDir = Join-Path ([System.IO.Path]::GetTempPath()) ('spp-test-writable-' + [guid]::NewGuid().ToString('N'))
$wOk = Test-SppReceiptDirWritable -Directory $writableDir
Assert-True $wOk 'L1 preflight: yazilabilir dizin icin true doner'
$leftoverProbes = @(Get-ChildItem -LiteralPath $writableDir -Filter '.spp-writable-probe-*' -ErrorAction SilentlyContinue)
Assert-True ($leftoverProbes.Count -eq 0) 'L2 preflight: probe dosyasi temizlenir (kalinti yok)'
Remove-Item -LiteralPath $writableDir -Recurse -Force -ErrorAction SilentlyContinue

$blockedPreflightPath = Join-Path ([System.IO.Path]::GetTempPath()) ('spp-test-blocked-preflight-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType File -Path $blockedPreflightPath -Force)
$wBad = Test-SppReceiptDirWritable -Directory $blockedPreflightPath
Assert-True (-not $wBad) 'L3 preflight: yazilamayan hedef (dosya olarak var) icin false doner'
Remove-Item -LiteralPath $blockedPreflightPath -Force -ErrorAction SilentlyContinue

# ======================= M: Invoke-SppDispatch - preflight + fail-closed halt
function Get-SppEnvLines {
  param([string]$Path)
  if ($Path -match 'sovereign-mimo') { return $script:MimoValidLines }
  return $script:DeepSeekValidLines
}
function Test-SppPath { param([string]$Path) $true }

# M1: preflight basarisiz -> sifir profil islenir, sifir HTTP, ExitCode 5
function Test-SppReceiptDirWritable { param([string]$Directory) $false }
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: preflight basarisizliginda HTTP cagrilmamali' }
$dispatchM1 = Invoke-SppDispatch -Profiles @('sovereign-mimo', 'sovereign-deepseek') -DoExecute $true -TimeoutSec 20 -ReceiptDir 'C:\fake\unwritable'
Assert-True ($dispatchM1.PreflightFailed) 'M1 dispatch: preflight basarisiz raporlanir'
Assert-True ($dispatchM1.ExitCode -eq 5) 'M1b dispatch: preflight basarisizliginda ExitCode=5'
Assert-True ($dispatchM1.Entries.Count -eq 0) 'M1c dispatch: preflight basarisizliginda sifir profil islenir (sifir HTTP)'

# M2: dry-run modda preflight kontrolu HIC calismaz (HTTP zaten yapilmayacak)
function Test-SppReceiptDirWritable { param([string]$Directory) throw 'TEST-GUARD: dry-run preflight cagirmamali' }
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: dry-run HTTP cagirmamali' }
$dispatchM2 = Invoke-SppDispatch -Profiles @('sovereign-mimo') -DoExecute $false -TimeoutSec 20 -ReceiptDir 'C:\fake\dry-run-dir'
Assert-True (-not $dispatchM2.PreflightFailed) 'M2 dispatch: dry-run modda preflight calismaz/basarisiz sayilmaz'
Assert-True ($dispatchM2.Entries.Count -eq 1 -and $dispatchM2.Entries[0].Result.outcome -eq 'dry-run') 'M2b dispatch: dry-run profil islenir'

# M3: preflight gecer ama ilk profilin receipt yazimi basarisiz -> ikinci profil icin HTTP cagrilmaz
function Test-SppReceiptDirWritable { param([string]$Directory) $true }
$script:DispatchHttpCalls = 0
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:DispatchHttpCalls++
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody)
}
function Write-SppReceipt { param($Result, [string]$Directory) throw 'SIMULATED_RECEIPT_WRITE_FAILURE' }
$dispatchM3 = Invoke-SppDispatch -Profiles @('sovereign-mimo', 'sovereign-deepseek') -DoExecute $true -TimeoutSec 20 -ReceiptDir 'C:\fake\writable-dir'
Assert-True (-not $dispatchM3.PreflightFailed) 'M3 dispatch: preflight basarili'
Assert-True ($dispatchM3.ExitCode -eq 5) 'M3b dispatch: receipt yazim hatasinda ExitCode=5'
Assert-True ($dispatchM3.Entries.Count -eq 1) 'M3c dispatch: ilk profil receipt hatasi sonrasi durur (ikinci profil hic islenmez)'
Assert-True ($script:DispatchHttpCalls -eq 1) 'M3d dispatch: ikinci profil icin HTTP cagrisi ASLA yapilmaz'
Assert-True ($dispatchM3.Entries[0].ReceiptError) 'M3e dispatch: ilk profilin receipt hatasi kaydedilir'

# M4: her iki profil de basariyla islenir (receipt hatasi yok) -> her ikisi de calisir
function Write-SppReceipt { param($Result, [string]$Directory) 'C:\fake\receipt.json' }
$script:DispatchHttpCalls = 0
$dispatchM4 = Invoke-SppDispatch -Profiles @('sovereign-mimo', 'sovereign-deepseek') -DoExecute $true -TimeoutSec 20 -ReceiptDir 'C:\fake\writable-dir'
Assert-True ($dispatchM4.Entries.Count -eq 2) 'M4 dispatch: receipt hatasi yoksa iki profil de islenir'
Assert-True ($script:DispatchHttpCalls -eq 2) 'M4b dispatch: iki profil icin de HTTP cagrisi yapilir'
Assert-True ($dispatchM4.ExitCode -eq 0) 'M4c dispatch: iki profil de basariliysa ExitCode=0'

# ======================= N: beklenmeyen exception -> statik fail-closed reason
function Test-SppReceiptDirWritable { param([string]$Directory) $true }
function Get-SppEnvLines { param([string]$Path) throw 'raw internal IO error containing secret-abc123' }
function Test-SppPath { param([string]$Path) $true }
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: HTTP cagrilmamali' }
$rN1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rN1.outcome -eq 'fail-closed' -and $rN1.failClosedReason -eq 'UNEXPECTED_EXCEPTION') 'N1 config-asamasi beklenmeyen exception: statik UNEXPECTED_EXCEPTION'
$rN1Json = ($rN1 | ConvertTo-Json -Depth 8)
Assert-True (-not ($rN1Json -match 'secret-abc123')) 'N1b config-asamasi beklenmeyen exception: ham mesaj JSON icinde YOK'

function Get-SppEnvLines {
  param([string]$Path)
  if ($Path -match 'sovereign-mimo') { return $script:MimoValidLines }
  return $script:DeepSeekValidLines
}
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'network raw fault detail-xyz-789' }
$rN2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rN2.outcome -eq 'fail-closed' -and $rN2.failClosedReason -eq 'UNEXPECTED_EXCEPTION') 'N2 execute-asamasi beklenmeyen exception: statik UNEXPECTED_EXCEPTION'
$rN2Json = ($rN2 | ConvertTo-Json -Depth 8)
Assert-True (-not ($rN2Json -match 'detail-xyz-789')) 'N2b execute-asamasi beklenmeyen exception: ham mesaj JSON icinde YOK'

# ======================= O: usage alanlari zorunlu/tutarli/limitli =========
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $null)
}
$rO1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO1.outcome -eq 'failed' -and -not $rO1.success -and $rO1.failClosedReason -eq 'USAGE_MISSING') 'O1 usage nesnesi yok: failed USAGE_MISSING (content OK olsa bile)'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = 5; total_tokens = 5 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO2.outcome -eq 'failed' -and $rO2.failClosedReason -eq 'USAGE_FIELD_MISSING') 'O2 completion_tokens eksik: failed USAGE_FIELD_MISSING'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = 5; completion_tokens = 1.5; total_tokens = 6.5 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO3 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO3.outcome -eq 'failed' -and $rO3.failClosedReason -eq 'USAGE_FIELD_NOT_INTEGER') 'O3 completion_tokens tam sayi degil: failed USAGE_FIELD_NOT_INTEGER'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = -1; completion_tokens = 1; total_tokens = 0 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO4 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO4.outcome -eq 'failed' -and $rO4.failClosedReason -eq 'USAGE_FIELD_NEGATIVE') 'O4 negatif alan: failed USAGE_FIELD_NEGATIVE'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = 5; completion_tokens = 1; total_tokens = 999 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO5 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO5.outcome -eq 'failed' -and $rO5.failClosedReason -eq 'USAGE_INCONSISTENT') 'O5 prompt+completion != total: failed USAGE_INCONSISTENT'
Assert-True ($rO5.usage.promptTokens -eq 5 -and $rO5.usage.completionTokens -eq 1 -and $rO5.usage.totalTokens -eq 999) 'O5b usage yine de receipte guvenle kaydedilir'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = 5; completion_tokens = 9; total_tokens = 14 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO6 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO6.outcome -eq 'failed' -and $rO6.failClosedReason -eq 'USAGE_COMPLETION_LIMIT_EXCEEDED') 'O6 completion_tokens > 8: failed USAGE_COMPLETION_LIMIT_EXCEEDED (content OK olsa bile)'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $usage = [ordered]@{ prompt_tokens = 5; completion_tokens = 8; total_tokens = 13 }
  New-FakeHttpResponse -StatusCode 200 -Body (New-ChatBodyRawUsage -Content 'OK' -UsageObj $usage)
}
$rO7 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rO7.outcome -eq 'ok' -and $rO7.success) 'O7 completion_tokens tam sinirda (8): basarili kabul edilir'

# ======================= P: expectedOk case-sensitive exact 'OK' ==========
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody -Content 'ok')
}
$rP1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True (-not $rP1.expectedOk -and -not $rP1.success) 'P1 kucuk harf ok: expectedOk/success false (case-sensitive)'
Assert-True ($rP1.outcome -eq 'failed' -and $rP1.failClosedReason -eq 'UNEXPECTED_RESPONSE_CONTENT') 'P1b kucuk harf ok: failed UNEXPECTED_RESPONSE_CONTENT'

function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody -Content ' OK ')
}
$rP2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rP2.expectedOk -and $rP2.success) 'P2 bosluklu exact OK (trim sonrasi): kabul edilir'

# ======================= Q: base URL path exact /v1 veya /v1/ ==============
function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v2')
}
function Invoke-SppRawHttpPost { param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec) throw 'TEST-GUARD: HTTP cagrilmamali' }
$rQ1 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rQ1.outcome -eq 'fail-closed' -and $rQ1.failClosedReason -eq 'BASEURL_PATH_INVALID') 'Q1 yanlis path (/v2): fail-closed BASEURL_PATH_INVALID'

function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1/extra')
}
$rQ2 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rQ2.outcome -eq 'fail-closed' -and $rQ2.failClosedReason -eq 'BASEURL_PATH_INVALID') 'Q2 fazladan path segmenti (/v1/extra): fail-closed BASEURL_PATH_INVALID'

function Get-SppEnvLines {
  param([string]$Path)
  return @('XIAOMI_API_KEY=sk-gecerli-1234567890', 'XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1/')
}
function Invoke-SppRawHttpPost {
  param([string]$Uri, [string]$AuthHeaderValue, [string]$BodyJson, [int]$TimeoutSec)
  $script:CapturedUri = $Uri
  New-FakeHttpResponse -StatusCode 200 -Body (New-OkChatBody)
}
$rQ3 = Invoke-SppProfileProbe -ProfileName 'sovereign-mimo' -DoExecute $true -TimeoutSec 20
Assert-True ($rQ3.outcome -eq 'ok') 'Q3 trailing-slash /v1/: kabul edilir'
Assert-True ($script:CapturedUri -eq 'https://api.xiaomimimo.com/v1/chat/completions') 'Q3b trailing-slash /v1/: endpoint dogru kurulur'

# ======================= sonuc =============================================
Write-Host ''
Write-Host ("Toplam: {0}  Basarisiz: {1}" -f $script:TestCount, $script:TestFails)
exit $script:TestFails
