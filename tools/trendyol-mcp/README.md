# trendyol-mcp — Hermes icin salt-okunur Trendyol Satici API koprusu

Hermes asistaninin Trendyol magaza verisini (siparis, iade, hakedis, urun)
**yalniz okuyabilmesi** icin kucuk bir MCP stdio sunucusu. Reklam API'si
Trendyol'da yoktur; bu arac reklam kararini veriye dayandirmak icindir.

Guvenlik tasarimi:

- Yalniz GET. Stok/fiyat/urun/siparis degistiren hic bir arac yok.
- Kimlik bilgileri (API Key/Secret/Seller ID) **yalniz** Hermes profil `.env`
  dosyasinda durur. Sunucuya sadece o dosyanin yolu verilir; config.yaml'a,
  komut satirina veya sohbete deger girmez.
- Alici kisisel verisi (ad, e-posta, TCKN, adres) siparis satirlarindan
  atilir; analiz icin gerekmez.
- Oran siniri: 4 istek/sn (Trendyol limiti 50/10 sn), 429'da geri cekilir.

## Dosyalar

- `trendyol_client.py` — HTTP istemci, tarih/parca mantigi, PII ayiklama, satis ozeti (SDK'dan bagimsiz).
- `server.py` — MCP kabugu (`mcp` 2.0, stdio). Araclar: `trendyol_status`, `trendyol_orders`,
  `trendyol_claims`, `trendyol_settlements`, `trendyol_other_financials`, `trendyol_products`,
  `trendyol_sales_summary`.
- `test_trendyol_client.py` — 20 birim testi, ag yok (`httpx.MockTransport`).

## Kurulum

1. Trendyol Satici Paneli > **Hesap Bilgileri > Entegrasyon Bilgileri** (yalniz master kullanici gorur).
2. Kolay yol - yerel kurulum betigi (degerler yalniz senin pencerende sorulur, Key/Secret
   gorunmez girilir, dosya BOM'suz yazilir, tekrar calistirilabilir):

   ```
   powershell -ExecutionPolicy Bypass -File tools\trendyol-mcp\setup-credentials.ps1
   ```

   Elle yapmak istersen: Hermes profil `.env` dosyasina **sen** ekle (degerleri asistana yazma):

   ```
   TRENDYOL_API_KEY=...
   TRENDYOL_API_SECRET=...
   TRENDYOL_SELLER_ID=...
   ```

   Dosya: `C:\Users\MSI\AppData\Local\hermes\profiles\owner-orchestrator\.env`
   (Test ortami icin ek olarak `TRENDYOL_STAGE=1`; stage anahtarlari PROD'dan farklidir.)

3. Hermes'e kaydet (tek satir):

   ```
   hermes mcp add trendyol --command "C:\Users\MSI\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe" --env TRENDYOL_ENV_FILE=C:\Users\MSI\AppData\Local\hermes\profiles\owner-orchestrator\.env --args "C:\Users\MSI\Documents\HERMESAGENT\tools\trendyol-mcp\server.py"
   ```

4. Dogrula: `hermes mcp test trendyol` — kimlik bilgisi yokken de baglanir ve
   7 araci listeler; `trendyol_status` ne eksik oldugunu soyler.

## Test

```
C:\Users\MSI\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe -m pytest tools\trendyol-mcp -q
```

## Sinirlar (durust)

- Siparis/iade uclari tek cagrida <= 14 gun, finans uclari <= 15 gun (Trendyol kurali).
  `trendyol_sales_summary` bunu kendisi parcalar (<= 92 gun).
- `net_estimate` siparis satirlarindan tahmindir (komisyon dusulmemis). Kesin gelir:
  `trendyol_settlements` (`sellerRevenue`).
- Canli hesapla uctan uca dogrulama kimlik bilgisi girildikten sonra yapilir.
