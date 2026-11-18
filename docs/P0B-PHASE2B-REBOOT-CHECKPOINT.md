# P0-B Faz 2B Reboot Checkpoint

Olusturma: 19 Temmuz 2026  
Kaynak commit: `f2a2a19` (P0-B Faz 2A hardening r5)  
Bu repo baseline tag: `baseline-hermes-20260719`  
Sovereign kaynak baseline (ayri repo): `baseline-sovereign-20260719`

Bu belge, kullanicinin onayladigi Windows reboot acceptance ve kucuk canli
provider probe'unu (Faz 2B) GUVENLE, kaldigimiz yerden devam ederek yapabilmek
icin hazirlanmis kalici checkpoint'tir. Bu tur icinde HICBIR mutasyon
yapilmamistir: reboot yok, provider/model cagrisi yok, gateway stop/start yok,
task install/uninstall yok, secret/env okuma-basma yok, remote/push yok. Belge
yalniz Faz 2A kabul kanitini kilitler ve Faz 2B'yi kesin/uygulanabilir hale
getirir.

## 1. Kabul Edilen Zemin (Faz 2A, Codex KABUL)

Codex ucuncu-plus review'de P0-B Faz 2A'yi `f2a2a19` uzerinde kabul etti:

- Parser: 3 dosya (`scripts/sovereign-gateway-service.ps1`,
  `scripts/sovereign-gateway-launch.ps1`,
  `tests/test_sovereign_gateway_service.ps1`) icin 0 sozdizim hatasi.
- Test: `tests/test_sovereign_gateway_service.ps1` **97/97** gecti.
- Task: `\Sovereign\` altinda 3 task exact (owned + config match).
- Route: 8642 / 8643 / 8644 loopback-only, secretsiz `/health` `HTTP 200`.
- Konsol: her task-start'ta yeni gorunur pencere 0; final gorunur gateway
  penceresi 0 (conhost `--headless` zinciri).

Ayrinti kanit: `docs/VALIDATION.md` (P0-B Phase 2A + r4 + r5 bolumleri),
`docs/decisions/0010-sovereign-gateway-peruser-scheduled-task.md`,
`docs/WORKLOG.md` (19 Temmuz Faz 2A kayitlari).

## 2. Mevcut Exact Task Mimarisi

Uc gateway per-user Windows Scheduled Task olarak `\Sovereign\` TaskPath altinda
kayitlidir. Her task ayni sabloda:

- **Trigger:** logon (`MSFT_TaskLogonTrigger`), enabled, trigger-user =
  current-user SID.
- **Principal:** current-user (`Interactive`, `Limited`), yukseltme yok.
- **Action (tek):** `conhost.exe --headless "<powershell>" -NoProfile
  -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File
  "<sovereign-gateway-launch.ps1>" -GatewayProfile <exact-profil>`.
- **Ownership marker:** Description icinde dedicated `\Sovereign\` sahiplik
  imzasi; kanitsiz ayni isimli task FOREIGN_TASK fail-closed.
- **Secret:** task tanimi, CLI ve receipt secretsizdir; secret yalniz profil
  `.env` alaninda kalir ve hermes tarafindan yuklenir.

Launcher (`sovereign-gateway-launch.ps1`): dosya kilidi (FileShare::None), status
mantigini SALT-OKUNUR kullanir; RUNNING=idempotent exit 0,
FOREIGN/NONLOOPBACK/PARTIAL=fail-closed exit 2 (0 start), DOWN=gizli start +
gitignore'lu `runtime/sovereign-hermes-gateways/logs` yonlendirme + timeoutlu
RUNNING/loopback kabul (timeout'ta yalniz token-kanitli kendi agac temizligi,
exit 3), beklenmeyen exception fail-closed exit 4 (+ receipt yazimi da patlarsa
exit 5). Tum gercek start yollari tek ortak konsolsuz primitive
`Invoke-SgsStartHermesConsoleless` uzerinden gecer.

| Profil | Port | Task (dedicated path) |
| --- | --- | --- |
| `sovereign-mimo` | 8642 | `\Sovereign\` altinda owned task |
| `sovereign-deepseek` | 8643 | `\Sovereign\` altinda owned task |
| `sovereign-hermes` | 8644 | `\Sovereign\` altinda owned task |

## 3. Mevcut Canli Durum (checkpoint aninda, salt-gozlem)

Faz 2A/r5 son olcumu (`f2a2a19`, mutasyonsuz): 3/3 RUNNING, loopback-only,
`HTTP 200`, `\Sovereign\` task 3/3 owned/config, receipt secret-tarama temiz
(`receipt-status-20260719-104013-014-d75ed6f3.json`). Bu checkpoint turunda
canli durum tekrar olculmedi; yeni bir olcum Faz 2B'nin ILK adimidir (bkz. 6).

## 4. Sinirlar (bu tur ve checkpoint boyunca)

- Reboot YOK.
- Provider/model cagrisi YOK (probe yalniz tasarlandi, calistirilmadi - bkz. 7).
- Gateway stop/start YOK, task install/uninstall YOK.
- Yeni listener YOK, secret/env okuma-basma YOK.
- Remote/push YOK; `f2a2a19` rewrite edilmez, task tanimi degismez, baseline
  tag'leri oynatilmaz.

## 5. Rollback

- Task'lari kaldirma: `scripts/sovereign-gateway-service.ps1 -Action uninstall
  -Execute` yalniz KANITLI-sahip uc `\Sovereign\` task'ini kaldirir; profil
  verisine ve farkli path'teki ayni isimli task'lara dokunmaz. Task'siz durumda
  start bilincli `start-direct` fallback'ine doner.
- Kod/dokuman geri alma: bu checkpoint yalniz yeni belge + append-only hafiza
  ekler; `git revert` ile temiz geri alinir. Faz 2B'de kod degismezse revert'e
  gerek kalmaz.
- Acil durdurma: bir route bozulursa profil kapsamli stop kullanilir
  (`gateway stop --all` YASAK); yalniz kanitli exact-owned tree hedeflenir.

## 6. Reboot Kesintisinden Sonra Kaldigimiz Yerden Devam Protokolu

Reboot Faz 2B'de yapilir; oturum burada kesilebilir. Yeniden acilista:

1. Bu belgeyi ve `docs/PROJECT_MEMORY.md` son durumunu oku; kaynak commit
   `f2a2a19` degismemis olmali (`git log --oneline -1`, working tree temiz).
2. Kullanici Windows'a logon oldugunda (task trigger logon), Faz 2B post-reboot
   kabul checklist'ini (bkz. asagi) SALT-OKUNUR baslat; ilk adim canli status
   olcumudur, mutasyon degil.
3. Checklist yesilse Faz 2B provider probe adimina gec (bkz. 7); herhangi bir
   `KANIT GEREKLI` alani acik/kirmizi kalirsa DUR, receipt'i kaydet, mutasyon
   yapma ve Codex/kullaniciya rapor et.

---

## Faz 2B Post-Reboot Kabul Checklist (KESIN)

Onkosul: Windows reboot yapildi ve kullanici logon oldu (logon trigger'in
tetiklenmesi icin gerekli). Her satir KANIT GEREKLI - `[ ]` alanlari canli
olcum receipt'i ile doldurulmadan Faz 2B TAMAM sayilmaz. Olcumler
`scripts/sovereign-gateway-service.ps1 -Action status` (secretsiz, salt-okuma)
ve raw task re-read ile yapilir; redacted receipt otomatik yazilir.

| # | Kabul kriteri | Beklenen | KANIT (doldurulacak) |
| --- | --- | --- | --- |
| 1 | Logon sonrasi 3 task tetikledi mi | 3/3 auto-start | `[x]` LastBoot 2026-07-19 14:07:55 (Istanbul); 3 task LastRun 14:12:34 |
| 2 | Task exact ownership (SID-canonical principal + marker) | 3/3 owned | `[x]` 3/3 owned (MSI Interactive/Limited principal, sahiplik marker eslesti) |
| 3 | Task config match (tek action/trigger, exe/args/workdir, LogonType, RunLevel) | 3/3 match | `[x]` 3/3 exact config: tek `conhost --headless` action, tek enabled current-user logon trigger |
| 4 | Task `LastTaskResult` | 3/3 = 0 (basari) | `[x]` 3/3 LastResult 0, Ready |
| 5 | Port 8642 dinleyici | yalniz `127.0.0.1` | `[x]` PID 17364, tek 127.0.0.1 listener, HTTP 200 |
| 6 | Port 8643 dinleyici | yalniz `127.0.0.1` | `[x]` PID 17348, tek 127.0.0.1 listener, HTTP 200 |
| 7 | Port 8644 dinleyici | yalniz `127.0.0.1` | `[x]` PID 17352, tek 127.0.0.1 listener, HTTP 200 |
| 8 | `/health` (secretsiz GET) | 3/3 `HTTP 200` | `[x]` 8642/8643/8644 uc route HTTP 200 |
| 9 | Launcher powershell wrapper artigi | 0 kalan wrapper | `[x]` Launcher wrapper 0 |
| 10 | Yeni gorunur Terminal penceresi | 0 | `[x]` `sky.list_apps` gorunur Terminal penceresi 0 |
| 11 | Yeni gorunur PowerShell penceresi | 0 | `[x]` `sky.list_apps` gorunur console/PowerShell penceresi 0 |
| 12 | Yeni gorunur Hermes/gateway penceresi | 0 | `[x]` `sky.list_apps` gorunur Hermes/gateway penceresi 0 |
| 13 | Receipt/log secret-pattern taramasi | temiz (0 eslesme) | `[x]` Uc launcher receipt (14:13:34) + status receipt secret-pattern false; out log 1155 byte, err log 0, alti log toplam secret-pattern false |
| 14 | Kabul zaman asimi | her route kabulu bounded timeout icinde | `[x]` 14:12:50 -> 14:13:34 (~44 sn), 90 sn bound icinde |

- **Pencere kaniti yontemi:** UI otomasyonu degil, process metadata (yeni
  gorunur pencere sayimi Faz 2A r4'te oldugu gibi; regresyon tespiti kanitli).
- **Timeout (14):** launcher DOWN start yolu zaten timeoutlu; post-reboot
  kabulde de her route icin bounded bekleme; asimda o route `KANIT GEREKLI`
  kalir ve fail-closed olarak isaretlenir.
- **Rollback tetigi:** herhangi bir route NONLOOPBACK/FOREIGN/PARTIAL cikarsa
  start fail-closed; gerekirse profil kapsamli containment-stop + bolum 5
  rollback. Reboot sonrasi 3/3 gelmezse Faz 2B BLOKE raporlanir, task tanimi
  elle degistirilmeden once Codex review istenir.

---

## 7. Faz 2B Provider Probe Tasarimi (CALISTIRILMADI - yalniz tasarim)

Amac: gateway route'unun yalniz health degil, gercek model backend'ine
ulastigini minimal maliyet ve sifir hassas baglamla dogrulamak. Bu tur icinde
CALISTIRILMAZ; asagidaki sozlesme Faz 2B'de kullanici onayi kapsaminda kosar.

### Kapsam ve model siniri

- Yalniz **MiMo 8642** ve **DeepSeek 8643** ucretli probe'a girer (aktif model
  karari: yalniz MiMo + DeepSeek).
- **sovereign-hermes 8644** icin ucretli probe YALNIZ route semantigi ayrica
  dogrulanirsa yapilir (8644 restricted Hermes reasoning worker route'u; chat/
  completion semantigi 8642/8643 ile ayni degilse ucretli probe atlanir).
  Aksi halde 8644 yalniz `/health` ile sinirli kalir ve durumu `KANIT GEREKLI`
  olarak acik birakilir.

### Istek sozlesmesi (profil basina)

- Prompt: tek kucuk mesaj - `Yalniz OK yaz.`
- Max output: **8 token**.
- Temperature: **0**.
- Hassas baglam: YOK (system/kullanici verisi, dosya, gecmis eklenmez).
- Cagri sayisi: profil basina **en fazla 1** cagri.
- Retry: yalniz **transient network hatasinda** (baglanti reset/timeout/DNS)
  **en fazla 1** retry; HTTP 4xx/5xx uygulama hatasi retry EDILMEZ.
- Loglama yasak: anahtar, header, request body, response body ham metni
  loglanmaz/receipt'e yazilmaz.

### Kayit (redacted receipt alanlari)

Profil basina yalniz sunlar kaydedilir:

- HTTP durum kodu.
- Latency (ms).
- Cozulen model adi/id (backend'in bildirdigi).
- Usage token sayilari (prompt/completion/total).
- Cevap uzunlugu-hash'i (cevap metninin kendisi degil; uzunluk + hash).
- Redacted cost estimate (paylasilan spend guard tahmini; anahtar/deger yok).

### Kabul ve fail-closed

- Basari: `HTTP 200` + gecerli usage + model id + beklenen kisa cevap
  imzasi (uzunluk/hash makul).
- Transient network -> 1 retry; hala basarisizsa o profil `KANIT GEREKLI`,
  fail-closed, mutasyon yok.
- 8644 route semantigi dogrulanamazsa: 8644 satiri health-only + `KANIT
  GEREKLI` (ucretli probe atlandi notu ile).
- Butun probe adimi paylasilan aylik spend guard altinda kalir; guard reddi
  deterministik olarak bir kez doner ve probe durur.

## 8. Faz 2B Resume Ilk Komut (referans, bu turda CALISTIRILMAZ)

Reboot + logon sonrasi ilk adim (salt-okuma):

```powershell
Set-Location 'C:\Users\MSI\Documents\HERMESAGENT'
git log --oneline -1        # f2a2a19 degismemis olmali
# Faz 2B post-reboot checklist adim 1-14, secretsiz status olcumu:
# scripts/sovereign-gateway-service.ps1 -Action status   (mutasyonsuz)
```

Provider probe (bolum 7) ancak checklist yesil ve kullanici onayi teyitli iken
kosar.

---

## 9. Post-Reboot Evidence (19 Temmuz 2026, kaydedildi)

Gercek kanit, mutasyonsuz salt-okuma olcumden:

- **Reboot:** LastBoot 2026-07-19 14:07:55 (Istanbul).
- **Task 3/3:** LastRun 14:12:34, LastTaskResult 0, Ready; her ucu de exact
  owned/config (tek `conhost --headless` action, tek enabled current-user
  logon trigger, principal MSI Interactive/Limited).
- **Route 3/3:** 8642 PID 17364, 8643 PID 17348, 8644 PID 17352; her portta
  tek `127.0.0.1` listener ve `/health` `HTTP 200`.
- **Konsol/pencere:** Launcher powershell wrapper artigi 0;
  `sky.list_apps` gorunur console/Terminal/PowerShell/Hermes penceresi 0.
- **Receipt:** Uc launcher receipt 14:13:34, outcome ok, applied 2 / failed 0,
  secret-pattern false. Resmi status receipt
  `receipt-status-20260719-112433-839-2081c97c.json`, outcome ok, 3 gateway,
  secret-pattern false.
- **Log:** out log 1155 byte, err log 0 byte; alti log dosyasinin tumu
  secret-pattern taramasinda false (temiz).
- **Zaman asimi:** 14:12:50 -> 14:13:34 araligi (~44 sn), 90 sn bound
  icinde kaldi.
- **Kaynak:** HEAD `82f908f`; Faz 2A kabul commit'i `f2a2a19` degismedi.

**Sonuc:** Checklist 1-14 TAM (yukaridaki tablo). Faz 2B reboot acceptance
bolumu TAM. Bolum 7 provider probe (MiMo 8642 + DeepSeek 8643 ucretli cagri)
bu turda CALISTIRILMADI; durumu hala **KANIT GEREKLI**. Bolum 7 ancak ayri
kullanici onayi ve spend guard kapsaminda kosturulmalidir.

## 10. Provider Probe Canli Kanit (19 Temmuz 2026, TAMAM)

Bolum 7 sozlesmesi kullanici onayiyla kosturuldu. Iki route de kabul edildi;
ilk MiMo denemesi kok nedeni bulunan bir uygulama-seviyesi UNEXPECTED_
RESPONSE_CONTENT ile basarisiz oldu, duzeltildi ve tekrar kosturulup kabul
edildi. Retry mekanizmasi (transient-only) hic tetiklenmedi; her iki basarisiz
ve basarili deneme tek cagridir.

### 10.1 Ilk MiMo denemesi - basarisiz, kok neden bulundu

- Receipt:
  `runtime/sovereign-hermes-gateways/receipts/receipt-provider-probe-sovereign-mimo-20260719-123730-201-b5e7e235.json`
- HTTP 200, latency 2242 ms, attempts 1, prompt 254 / completion 8 / total 262
  token, responseLength 0, expectedOk false, outcome `failed
  UNEXPECTED_RESPONSE_CONTENT`, configured estimate $0.00003780, secret
  pattern false.
- Kok neden: Xiaomi'nin resmi dokumantasyonuna gore `mimo-v2.5` derin
  dusunme (thinking) varsayilan olarak acik geliyor; 8 token'lik butce
  tamamen reasoning'e gitti ve beklenen kisa "OK" govde metni hic
  uretilmedi. Retry yapilmadi (bu bir HTTP 4xx/5xx degil, uygulama
  seviyesinde beklenmeyen icerik; sozlesme geregi retry edilmez).
- Referans: Xiaomi Chat Completions deep thinking rehberi
  (`https://mimo.mi.com/docs/zh-CN/quick-start/usage-guide/text-generation/deep-thinking`)
  ve responses/reasoning alan aciklamasi
  (`https://mimo.mi.com/docs/en-US/api/chat/responses`).

### 10.2 Duzeltme

- Claude Code r3 fix, commit `a26091a`: MiMo istegine de `thinking.type=
  disabled` alani eklendi (DeepSeek zaten thinking'i kapatiyordu).
- Regresyon: provider probe suite 109/109, gateway service test 97/97,
  parser 0 hata.

### 10.3 DeepSeek - kabul edildi

- Receipt:
  `runtime/sovereign-hermes-gateways/receipts/receipt-provider-probe-sovereign-deepseek-20260719-124120-200-a2cb21ee.json`
- HTTP 200, latency 1338 ms, attempts 1, outcome exact OK, prompt 11 /
  completion 1 / total 12 token, responseLength 2, configured estimate
  $0.00000182, secret pattern false. Thinking disabled.
- Referans: DeepSeek Create Chat Completion API
  (`https://api-docs.deepseek.com/api/create-chat-completion`).

### 10.4 MiMo - duzeltme sonrasi kabul edildi

- Receipt:
  `runtime/sovereign-hermes-gateways/receipts/receipt-provider-probe-sovereign-mimo-20260719-124537-820-0c5f04fe.json`
- HTTP 200, latency 2305 ms, attempts 1, outcome exact OK, prompt 256 /
  completion 2 / total 258 token, responseLength 2, configured estimate
  $0.00003640, secret pattern false.

### 10.5 Maliyet ozeti (configured estimate, resmi fatura degil)

- Kabul edilen cift (DeepSeek + duzeltilmis MiMo) toplam: 270 token,
  configured estimate $0.00003822.
- Bu turdaki tum canli cagri harcamasi (ilk basarisiz MiMo dahil): 532
  token, configured estimate $0.00007602.
- Fiyat kaynagi: paylasilan spend guard'daki yerel configured rate (0.14
  input / 0.28 output USD/M token); bu resmi guncel fatura iddiasi degildir.

### 10.6 8644 sinirlamasi (degismedi)

- `sovereign-hermes` 8644 route'u bu turda da yalniz `/health` ile
  sinirli kaldi. Ucretli inference/semantic route kaniti yoktur ve hala
  **KANIT GEREKLI**. P0-B provider probe kapsami sozlesme geregi yalniz
  MiMo 8642 + DeepSeek 8643 oldugu icin bu durum Faz 2B kabulunu
  ENGELLEMEZ (bkz. bolum 7, "8644 icin ucretli probe YALNIZ route
  semantigi ayrica dogrulanirsa yapilir").

### 10.7 Sonuc

Bolum 7 provider probe sozlesmesi tamamlandi: her iki kapsam-ici route
(MiMo 8642, DeepSeek 8643) HTTP 200 + gecerli usage + model kabul kriterini
karsiladi; secret/raw response/body loglanmadi (secret pattern false tum
receipt'lerde); cagri sayisi profil basina en fazla 1 (ilk MiMo basarisiz
denemesi ayri, duzeltme sonrasi ikinci deneme ayri kayittir, retry degildir);
aylik spend guard ihlali olmadi. **Faz 2B TAMAM.** **P0-B TAMAM** (8644
health-only sinirlamasi acikca not edilerek; P0-B'nin kapsami zaten yalniz
MiMo + DeepSeek'ti).
