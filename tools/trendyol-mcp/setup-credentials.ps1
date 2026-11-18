# Trendyol kimlik bilgilerini Hermes profil .env dosyasina YEREL olarak yazar.
#
# Degerler yalnizca bu pencerede sorulur (Key/Secret gorunmez girilir); hicbir
# asistana, sohbete, komut satirina veya PowerShell gecmisine dusmez.
# Tekrar calistirilabilir: eski TRENDYOL_* satirlarini degistirir, digerlerine dokunmaz.
# Dosyayi BOM'suz UTF-8 yazar (PS 5.1'in `Set-Content -Encoding utf8`'i BOM ekler;
# BOM ilk anahtarin adini bozabilir).
#
# Kullanim (parametresiz calistir, sorulari yanitla):
#   powershell -ExecutionPolicy Bypass -File tools\trendyol-mcp\setup-credentials.ps1
#
# -ApiKey/-ApiSecret/-SellerId parametreleri YALNIZ otomatik test icindir; gercek
# degerleri komut satirina yazma (gecmise kaydolur).

param(
    [string]$EnvFile = (Join-Path $env:LOCALAPPDATA 'hermes\profiles\owner-orchestrator\.env'),
    [string]$ApiKey,
    [string]$ApiSecret,
    [string]$SellerId,
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

function Read-Secret([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

if (-not (Test-Path -LiteralPath $EnvFile)) {
    throw "Profil .env bulunamadi: $EnvFile"
}

Write-Host ''
Write-Host 'Trendyol Satici Paneli > Hesap Bilgileri > Entegrasyon Bilgileri sayfasini ac.' -ForegroundColor Cyan
Write-Host 'Uc degeri sirayla yapistir. Key ve Secret yazarken ekranda GORUNMEZ - normal.' -ForegroundColor Cyan
Write-Host ''

if (-not $SellerId)  { $SellerId  = Read-Host -Prompt 'Satici ID (sadece rakam)' }
if (-not $ApiKey)    { $ApiKey    = Read-Secret 'API Key' }
if (-not $ApiSecret) { $ApiSecret = Read-Secret 'API Secret' }

$SellerId = "$SellerId".Trim()
$ApiKey = "$ApiKey".Trim()
$ApiSecret = "$ApiSecret".Trim()

if ($SellerId -notmatch '^\d+$') { throw "Satici ID yalniz rakamlardan olusmali. Alinan uzunluk: $($SellerId.Length)" }
foreach ($pair in @(@('API Key', $ApiKey), @('API Secret', $ApiSecret))) {
    if ([string]::IsNullOrEmpty($pair[1])) { throw "$($pair[0]) bos olamaz." }
    if ($pair[1] -match '[\s"''#]') { throw "$($pair[0]) icinde bosluk/tirnak/# var - eksik ya da fazla kopyalanmis olabilir." }
}

# Yedek (ayni klasor, ayni izinler). Onceki yedegin uzerine yazar.
Copy-Item -LiteralPath $EnvFile -Destination ($EnvFile + '.bak-trendyol') -Force

# Get-Content BOM'u okurken atar; eski TRENDYOL_* satirlarini ve bu betigin kendi
# baslik yorumunu ele (yoksa her kosuda baslik cogalir).
$header = '# Trendyol Satici API (salt-okunur MCP koprusu: tools/trendyol-mcp)'
$kept = @(Get-Content -LiteralPath $EnvFile -Encoding UTF8 |
    Where-Object { ($_ -notmatch '^\s*TRENDYOL_(API_KEY|API_SECRET|SELLER_ID)\s*=') -and ($_.Trim() -ne $header) })
while ($kept.Count -gt 0 -and [string]::IsNullOrWhiteSpace($kept[-1])) {
    if ($kept.Count -eq 1) { $kept = @() } else { $kept = $kept[0..($kept.Count - 2)] }
}
$lines = @($kept) + @(
    '',
    $header,
    "TRENDYOL_API_KEY=$ApiKey",
    "TRENDYOL_API_SECRET=$ApiSecret",
    "TRENDYOL_SELLER_ID=$SellerId"
)
[IO.File]::WriteAllLines($EnvFile, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Yazildi: $EnvFile  (yedek: .env.bak-trendyol)" -ForegroundColor Green

if (-not $SkipVerify) {
    $py = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\python.exe'
    $client = Join-Path $PSScriptRoot 'trendyol_client.py'
    if ((Test-Path -LiteralPath $py) -and (Test-Path -LiteralPath $client)) {
        $code = "import sys; sys.path.insert(0, r'$PSScriptRoot'); import trendyol_client as tc; c = tc.load_config(r'$EnvFile', environ={}); print('Dosya okunabiliyor. Satici ID:', c.seller_id, '| Ortam:', 'STAGE' if c.stage else 'PROD')"
        & $py -c $code
    }
    Write-Host 'Simdi Hermes''i tamamen kapatip yeniden ac (yeni oturum sart).' -ForegroundColor Yellow
}
