# Project Memory

Durum tarihi: 19 Temmuz 2026  
Durum: Kaynak kod ve son kabul kanitlari mevcut. 19 Temmuz son snapshot'inda
MiMo/DeepSeek/restricted Hermes gateway'leri 8642/8643/8644 uzerinde `HTTP 200`,
Docker acik, urun servisleri 4310-4321 kapaliydi. P0-A tamamlandi: iki kaynak
agaci da kontrollu Git baseline altindadir (HERMES `152bf9a`, Sovereign
`9ca47c7`; tag'ler `baseline-hermes-20260719` ve `baseline-sovereign-20260719`;
makbuz `docs/P0A-BASELINE-RECEIPT-2026-07-19.md`). 17 Temmuz kabulunden sonra
HERMES kaynak kodu degismedi; Sovereign'da MCP Bridge ENOBUFS/teardown
duzeltmesi (commit `cf8c9e0`/`63fcc3b`) ve ardindan izole runtime smoke E2E
(commit `8d904a3`/`edf6393`/`5e07e02`) girdi; 18 Temmuz sonrasi temiz baseline
artik TAMAM. Sovereign kaynaginda ayrica `.gitignore` icindeki bozuk
`{console.error(e.code)` kurali commit `e314314` ile `[{]console.error(e.code)`
olarak duzeltildi (yalniz ignore kurali; runtime davranisi degismedi).
Devir/guvenlik belgeleri, ignore kurallari ve bagimsiz itiraz kurali
guncellendi.

Guncelleme (26 Temmuz 2026, Opus/Max): Sovereign product-host artik in-process
(TEK supervisor-owned pid hem urun 4312 hem ic API 4310 dinleyicisini sahiplenir;
grandchild yok). Kok launcher `scripts/start-hermes-sovereign-desktop.ps1` +
sozlesme testi (`...test.ps1`, **43/43**) eklendi; adapter uclusu minimal
`extraResources` ile paketlenmemis resources dizinine paketlendi (paket
URETILMEDI, paketli GUI E2E yok); `sovereign-product-accept.mjs` in-process
mimariye gore yeniden yazildi (**53/53, 2x, 0 orphan**). product-host unit
**42/42**, odakli Sovereign node **165/165**, `tsc --noEmit` temiz. Flag varsayilan
KAPALI; harici Sovereign `e314314` ve korunan 8642-8644 degismedi.

Guncelleme (9 Eylul 2026, Opus 5/Max) - KURULU VENDOR HERMES, urun kaynagi
DEGIL: Kullanicinin makinesindeki `AppData\Local\hermes\hermes-agent` klonu
(upstream NousResearch) bozuk `remote.origin.fetch` refspec'i (yalniz tek tag'i
cekiyordu, `refs/remotes/origin/*` hic olusmuyordu) ve 12 Agustos'tan kalma bayat
`.git/shallow.lock` yuzunden kurulamiyordu; installer `repository` asamasinda
`git checkout main failed (exit 1)` veriyordu. Ikisi de onarildi, kurulum
uctan uca tamamlandi: **Hermes Agent v0.21.1 (2026.9.7), upstream `ead7e91d`**.
Kurulu kopyadaki 675 satirlik yerel Kanban Command Center ozellestirmesi
(v2026.7.7.2 tabanli) CRLF gurultusu ayiklanarak main uzerine tasindi; 15 cakisma
blogu elle cozuldu, dal `local-custom-20260909` commit `ed97e53bb`. pytest 11/11,
typecheck 3/3 config temiz, eslint temiz, desktop yeniden derlendi. Pairing
endpoint'leri (upstream'de zaten var) ve `cryptography==48.0.1` pini (CVE geri
donusu) bilincli olarak REDDEDILDI. Gercek GUI E2E YAPILMADI. Aktif dal
`local-custom-20260909` oldugu icin sonraki `hermes update` / `Retry install`
`git checkout main` yapip ozellestirmeleri uygulamadan dusurur (commit durur).
Proje agaci `runtime/hermes-agent` ve Sovereign kaynagi bu iste DEGISMEDI.

Guncelleme (18 Eylul 2026, Fable 5.1 - kullanici model politikasini bu oturum icin
acikca degistirdi) - VENDOR HERMES, urun kaynagi DEGIL: Trendyol'un reklam API'si
olmadigi resmi dokumandan dogrulandi (reklam yalniz panelden elle). Kullanicinin
Trendyol magazasi (gumus taki) icin `tools/trendyol-mcp/` altinda SALT-OKUNUR bir
MCP stdio sunucusu yazildi ve `owner-orchestrator` profiline kaydedildi: 7 arac
(status, orders, claims, settlements, other_financials, products-V2, sales_summary),
hepsi `read_only_hint`, alici PII atilir, sirlar yalniz profil `.env`'de
(`TRENDYOL_API_KEY/SECRET/SELLER_ID`), config.yaml'a deger yazilmadi. Kanit: pytest
20/20, `hermes mcp test trendyol` Connected/7 tools. CANLI HESAPLA E2E YAPILMADI -
kullanici anahtarlari `.env`'e girince yapilir. Dosyalar untracked, commit yok.
Onceki (9 Eylul) durum gecerli: vendor Hermes v0.21.1 `local-custom-20260909`
dalinda, `TERMINAL_ENV=local`, 25 toolset acik.

Bu belge projenin yasayan kisa hafizasidir. Her calisma sonunda mevcut gercegi
yansitacak sekilde guncellenir. Eksiksiz urun/kullanici/teknik sozlesmesi
`CLAUDE-CODE-MASTER-HANDOFF.md`, onceki teknik ayrintilar `CLAUDE-HANDOFF.md`
icindedir.

Claude'un Manus'u resmi kaynaklardan yeniden arastirmasi zorunludur. Aktif model
karari kullanici tarafindan kesinlestirilmistir: yalniz MiMo ve DeepSeek
kullanilacak, eval bu iki aile arasindaki rol dagilimini belirleyecektir. Diger
acik modeller bilgi amacli izlenir; acik kullanici istegi olmadan entegre edilmez
veya replacement olarak onerilmez. Ayrinti
`docs/research/MANUS-OPEN-MODEL-RESEARCH.md` icindedir.

19 Temmuz'da Claude Code 2.1.206 ile salt-okunur canli devir yapildi. Claude,
urun hedefini, kullanici calisma tarzini, iki kod tabanini, kanit/acik ayrimini,
MiMo + DeepSeek sinirini ve P0 sirasini geri anlatarak `DEVIR_KABULU: TAM`
sonucu verdi. Kalici makbuz `docs/CLAUDE-TAKEOVER-RECEIPT-2026-07-19.md`
icindedir.

Ayni gorunur Claude Desktop oturumunda ikinci derin devir yapildi. Claude master
devir kitabini, dort ozgun promptu, ADR 0001-0009'u, urun/guvenlik/routing/test
belgelerini, eski handoff'lari ve iki kod agacini capraz inceleyip 12 bolumlu
nihai urun sozlesmesi verdi; sonucu `OGRETIM_TAM: EVET` oldu. Baglayici icra
kararlari `docs/CLAUDE-CODE-EXECUTION-CHARTER.md` icindedir.

## Urun Hedefi

Kullanicinin istedigi sey bir Hermes temasi veya aracli chatbot degildir. Hedef;
Manus benzeri calisma seffafligina sahip, kullanicinin bilgisayarinda ve onun
denetiminde calisan, sohbet ile kalici ajan gorevini ayiran, tarayici ve Windows
bilgisayarini gercekten kullanabilen, kod ve arastirma yapabilen, gerektiğinde
insana devreden, onay/butce/kanit/artifact/recovery katmanlari bulunan ticari
kalitede tek bir masaustu ajan platformudur.

Basari olcutu yalniz dogru metin cevabi degildir. Bir gorev plan, canli event,
worker/model provenance, approval, maliyet, kanit, indirilebilir cikti ve yeniden
baslatma sonrasi guvenli devam davranisi gostermelidir.

## Kod Tabanlari

| Katman | Yol | Rol | Bugunku durum |
| --- | --- | --- | --- |
| Hermes operasyon paketi | `C:\Users\MSI\Documents\HERMESAGENT` | Hermes v0.18.2 kurulum, profiller, native Phase 8, scriptler, backup ve ADR | `master` dalinda ilk commit `152bf9a`, tag `baseline-hermes-20260719`; working tree temiz |
| Sovereign urun | `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent` | Ana Control Plane, web UI, durable workflow ve capability worker'lar | v1.0.0-rc.1 tabani + 17 Temmuz execution dilimi; `master` ilk commit `9ca47c7`, tag `baseline-sovereign-20260719` |
| Kurulu Hermes fallback | `C:\Users\MSI\AppData\Local\hermes\hermes-agent` | Windows policy engelinde guvenilir fallback | Kullanici verisini koru |

## Calisan Mimari Karari

```text
Native desktop shell (hedefte tek urun; henuz birlesik degil)
  -> React/Vite Sovereign UI
  -> Fastify Control Plane (tek yetki sahibi)
  -> Temporal workflow + policy/approval/budget
  -> capability worker (research/code/browser/computer/tool/Hermes/MCP)
  -> verifier + artifact/evidence
  -> PostgreSQL projection + NATS events
```

Hermes kisitli bir reasoning worker'idir. DeepSeek ve MiMo model backend'leri rol
bazli ve degistirilebilir durumdadir. Hicbir model policy, credential veya
workflow otoritesi degildir.

## Son Kanitlanmis Durum

17 Temmuz 2026 izole kabulunde:

- 119 test gecti, 0 hata; Control Plane 92, Computer Worker 5 test.
- 11 TypeScript workspace projesi typecheck'ten gecti.
- Production build gecti; web build 1.645 modul isledi.
- Dedicated DeepSeek planning/chat ve MiMo critic rotalari canli cagridan gecti;
  token/model provenance kaydedildi, secret sizdirilmadi.
- `https://example.com/` uzerinde gercek web gorevi; uc kanit ve
  `research-result.json` artifact'i ile tamamlandi.
- CUA Driver 0.8.2 ile gercek 1920x1080 Windows desktop read-only incelendi; sifir
  input aksiyonu, dort evidence ve uc artifact uretildi.
- Authenticated Bilgisayar yuzeyi gercek PNG frame'i gostermis, `Devral` agent
  aksiyonunu gercekten kilitlemis ve `Ajana ver` kilidi acmistir.
- Desktop 1280x720 ve mobil 390x844 browser QA gecti; mobil 18 px tasma giderildi.
- MCP Bridge varsayilan bind'i `127.0.0.1:4319` oldu ve contract/health kabulunden
  gecti.

Bu kanit kaynaklari `docs/VALIDATION.md` ve
`docs/decisions/0009-sovereign-execution-platform.md` icindedir. Bunlar son tam
kabul kaydidir; 19 Temmuz gateway health snapshot'i urunun tamamini kapsayan
yeni bir acceptance degildir.

18 Temmuz yeniden denetiminde 11 proje TypeScript kontrolu gecti ve Hermes
routing-report testi `1 passed` verdi. Full test tekrari Windows `ENOBUFS` soket
arizasi nedeniyle MCP Bridge testinde tamamlanamadi; test hata sonrasinda port ve
Node process birakiyor. Production build'in bu oturumdaki tekrari kaynak klasoru
yeni sandbox politikasinda read-only kaldigi icin `EPERM` ile engellendi. Bunlar
17 Temmuz acceptance kaydini silmez, fakat yeni temiz baseline sayilmaz.

### Bugunku model/runtime konfigurasyonu

- `sovereign-deepseek`, `sovereign-mimo` ve `sovereign-hermes` profil dizinleri
  makinede mevcuttur.
- Kalici Sovereign `.env` snapshot'i yalniz `MODEL_GATEWAY_URL` ve
  `MODEL_GATEWAY_DEEPSEEK_URL` icin `127.0.0.1:8643` tanimlar; planner/fast modeli
  `sovereign-deepseek`tir.
- P0-B Faz 2A + r4 hidden-launcher duzeltmesi (19 Temmuz, kullanici onayli):
  uc `\Sovereign\` task'i kuruldu ve Codex'in gorunur-konsol bulgusu uzerine
  action zinciri `conhost --headless + powershell + sovereign-gateway-launch
  .ps1` mimarisine cevrildi (launcher: secretsiz, dosya kilidi, RUNNING
  idempotent, FOREIGN/NONLOOPBACK/PARTIAL fail-closed, DOWN gizli start +
  log yonlendirme + timeoutlu kabul + redacted receipt). Canli yakalanan
  bug'lar: GetNewClosure scope, dot-source param-clobber (`-p all`), WT
  default-terminal tab'i, mutex reentrancy -> hepsi duzeltildi ve teste
  baglandi (83/83). Konsolsuz kabul: her task-start'ta yeni gorunur pencere
  0; final gorunur gateway penceresi 0; 3/3 RUNNING/loopback/HTTP 200; task
  3/3 owned/config; stop dongusunde port kapanisi + canli stale tespiti.
  Reboot acceptance ve kucuk canli provider probe'lari Faz 2B'de (Codex
  Faz 2A kanit review'i sonrasi). r5 hardening: tum gercek start yollari tek
  ortak konsolsuz primitive'de; child cmdline CommandLineToArgvW round-trip
  kanitli quoting ile; launcher beklenmeyen exception'da fail-closed +
  kilit garantili + tek denemelik error receipt (97/97 test). Codex Faz 2A'yi
  `f2a2a19` uzerinde KABUL etti; pre-reboot kalici checkpoint
  `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` yazildi (post-reboot kabul checklist +
  MiMo/DeepSeek provider probe tasarimi, 8644 health-only + KANIT GEREKLI).
  Faz 2B reboot acceptance TAMAM (19 Temmuz). Faz 2B provider probe TAMAM
  (19 Temmuz): DeepSeek ilk denemede kabul, ilk MiMo denemesi thinking-default
  nedeniyle basarisiz oldu, `thinking.type=disabled` fix'i (commit `a26091a`)
  sonrasi MiMo da kabul edildi; 8644 hala health-only + KANIT GEREKLI ama
  P0-B kapsami disinda. **P0-B TAMAM.**
- P0-B Faz 1 r3 (19 Temmuz, ADR 0010): `scripts/sovereign-gateway-service.ps1`
  per-user Scheduled Task mimarisiyle `plan|install|status|start|stop|
  uninstall`; varsayilan dry-run, mutasyon yalniz `-Execute`+ShouldProcess.
  Sertlestirmeler: FOREIGN_TASK sahiplik kaniti (dedicated `\Sovereign\` path
  + marker + SID-canonical principal; tek action/trigger + trigger-user +
  LogonType dahil tam alan dogrulamasi; kanitsiz task silinmez/degistirilmez/
  BASLATILMAZ - start bypass kapali, task yoksa bilincli start-direct
  fallback), recreate zincirinde register yalniz unregister APPLIED ise,
  receipt v1.2 agregat gercegi (fail-closed>failed>declined>ok; atomik
  CreateNew; -WhatIf'ten bagimsiz audit yazimi; -Execute+-NoReceipt reddi +
  zorunlu refusal receipt), gecerli-gozlem receipt secimi, resmi
  CommandLineToArgvW arg parser (Windows disi fail-closed), secretsiz health
  ve NONLOOPBACK containment-stop. 71/71 test (gercek dispatcher
  -Execute -WhatIf receipt + 0-mutasyon kaniti dahil) ve canli read-only
  status (3x RUNNING, loopback, HTTP 200, schema 1.2) gecti. Gercek
  install/start-stop/reboot acceptance'i KANIT GEREKLI; eski
  `sovereign-gateways.ps1` tarihsel referanstir.
- 19 Temmuz salt-okunur olcumunde 8642, 8643 ve 8644 loopback listener'lari
  `HTTP 200` verdi. Docker Desktop acikti; 4310-4321 urun servisleri kapaliydi.
- Bu snapshot gateway route health'ini kanitlar; restart sonrasi otomatik kurulum,
  uc route canli provider probe'u veya tum urun health'i anlamina gelmez.

## Tamamlanan Ana Yetenekler

- Chat: streaming, reconnect, sohbet yasam dongusu, branch/provenance, export,
  archive/restore/delete ve guvenli canonical task promotion.
- Durable task: plan, state machine, event timeline, retry/attempt, pause/resume/
  cancel, follow-up/conversation, verification ve result.
- Capability worker'lar: research, coding, browser, computer, tool, Hermes ve
  task-scoped MCP bridge; contract ve fixture akislari mevcut.
- Proje/skill/knowledge, connector/tool/grant, otomasyon/schedule, bildirim,
  merkezi approval inbox ve artifact version/export/replication yuzeyleri.
- Execution policy, admission/concurrency budget, schedule overlap, aylik spend
  guard ve tahmini token/maliyet kaydi.
- Auth, session, tenant/org, davet/rol, parola/session guvenligi, TOTP, WebAuthn,
  recovery ve hassas islemler icin MFA step-up.
- PostgreSQL RLS/least privilege, Temporal durable chat/task, NATS events,
  production preflight, health/metrics/rate limit/security headers.
- Sifreli backup/verify/dry-run/restore, failure-recovery ve release acceptance.
- Native Hermes Phase 8: sohbet, dosya/proje/artifact/settings, Operations board,
  scheduler, needs-you handoff, yerel browser takeover ve portable recovery.
- Sovereign execution: gercek web deliverable, gercek Windows capture, canli
  Bilgisayar sayfasi ve aksiyon engelleyen insan devralma kilidi.

## Bilinen Aciklar

- Hermes native uygulamasi ile Sovereign UI/servisleri tek imzali urunde
  birlesmedi. (20 Temmuz KISMI: flag-gated Sovereign rotasi + main-process
  service supervisor Hermes Electron shell'ine baglandi, ADR 0011; authenticated
  urun yuzeyi ve tek imzali paket hala BEKLIYOR.)
- Computer takeover ownership bellek ici; worker restart'inda kaybolur.
- Desktop transport iki saniyelik authenticated PNG polling'dir; WebSocket/video
  veya RDP degildir.
- CUA mevcut interaktif Windows kullanicisinin oturumunda calisir; izole desktop
  degildir. Etkili input/yazma aksiyonlari onayli canli kabulden gecmedi.
- Host desktop hassas-bolge redaction uygulanmadi; istek fail-closed olur.
- Browser Use adapter'i ve authenticated session kabul testi yoktur. Skyvern,
  Agent-S/GUI-Owl ve model-driven OpenHands yalniz adapter/contract seviyesindedir.
- Birlesik build icin full Temporal/PostgreSQL/NATS restart/recovery kabulü yok.
- Project export/import, sifreli memory denetimleri, invoice reconciliation,
  signed installer/update, accessibility/localization/offline/upgrade testleri
  tamamlanmadi.
- Tek chat turn'u icinde semantic multi-model routing tam urun ozelligi degildir.
- Git baseline'lari yerel-only'dir; remote/push tanimli degildir ve ayri
  kullanici onayi ister. `git add .` yasagi ve elle staged inceleme kurali
  sonraki commit'lerde de gecerlidir.
- `apps/control-plane/src/runtime-config.test.ts` icindeki sentetik production
  fixture sabitleri herhangi bir remote push oncesinde rotate edilmeli ve
  hicbir gercek ortam degeriyle eslesmedigi teyit edilmelidir
  (`docs/P0A-BASELINE-RECEIPT-2026-07-19.md`).
- (TAMAM 19 Temmuz, kanit `docs/VALIDATION.md`) MCP Bridge'in sabit `4601`
  portu erken network hatasinda server teardown yapmadan process birakiyordu.
  Sovereign commit `cf8c9e0`+`63fcc3b` deterministic test-listen + fault
  injection + Node-resmi close-ordering ile duzeltti: hedef suite 11/11, full
  workspace 134/134, Codex stresinde 100 ardisik gecis, kalinti port/process 0.

## Kesin Sonraki Adim

Once kodu yeniden yazmak degil, kanitlanmis baseline'i yeniden calistirmak:

1. (TAMAM 19 Temmuz) Iki kaynak agaci kontrollu Git baseline'a alindi; makbuz
   `docs/P0A-BASELINE-RECEIPT-2026-07-19.md` icindedir.
2. (Faz 1 TAMAM 19 Temmuz, ADR 0010) `sovereign-gateway-service.ps1` +
   40/40 mock test + canli read-only status hazir. Faz 2: kullanici onayi ile
   gercek install/stop/start, Windows reboot acceptance'i ve kucuk canli
   provider probe; receipt'ler VALIDATION'a islenecek.
3. (TAMAM 19 Temmuz) MCP test teardown/port sorunu duzeltildi (commit
   `cf8c9e0`/`63fcc3b`): hedef suite 11/11, full workspace 134/134, typecheck
   11/12 workspace temiz, `pnpm build` temiz. (TAMAM 19 Temmuz) Izole runtime
   smoke E2E de tamamlandi (commit `8d904a3`/`edf6393`/`5e07e02`): chat gercek
   kademeli akis + 2 kalici tur, gercek web task, Bilgisayar frame/devral/geri
   ver, artifact indirme; ayrinti asagida ve `docs/VALIDATION.md` icinde.
4. Kesin sonraki aktif adim: Hermes Electron/native shell + Sovereign UI +
   Control Plane lifecycle integration spike'i; ardindan devral (takeover)
   restart dayanikliligi ve acik guvenlik kapilariyla active-input (aktif
   mouse/klavye) kabulu.
5. Sonra tek urunlestirme isine gec: Sovereign Control Plane'i canonical backend,
   mevcut Hermes Electron shell'i native host/launcher adayi olarak kullan; once
   ince bir entegrasyon spike'i ve rollback noktasi olustur.

Onceliklerin tam listesi `docs/ROADMAP.md` icindedir.

## 19 Temmuz 2026 Ek - Faz 2B Reboot Acceptance TAMAM

Windows reboot yapildi, kullanici logon oldu; salt-okuma post-reboot olcum
`docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` checklist 1-14'u TAM isaretledi
(bolum 9): LastBoot 14:07:55, 3 task LastRun 14:12:34/LastResult 0/exact
owned-config, 8642/8643/8644 tek 127.0.0.1 listener + HTTP 200, launcher
wrapper 0, gorunur console/Terminal/PowerShell/Hermes penceresi 0, receipt/log
secret-pattern taramasi temiz, kabul ~44 sn (90 sn bound icinde). Kaynak HEAD
`82f908f`, Faz 2A kabul `f2a2a19` degismedi. Kalan tek ac kalem: provider probe
(MiMo 8642 + DeepSeek 8643 ucretli cagri) hala **KANIT GEREKLI**, calistirilmadi.

## 19 Temmuz 2026 Ek - Faz 2B Provider Probe TAMAM, P0-B TAMAM

Bolum 7 provider probe sozlesmesi kullanici onayiyla kosturuldu. Ilk MiMo
denemesi (`receipt-provider-probe-sovereign-mimo-20260719-123730-201-
b5e7e235.json`) HTTP200 ama uygulama seviyesinde basarisiz oldu (outcome
`failed UNEXPECTED_RESPONSE_CONTENT`, responseLength 0); kok neden Xiaomi
resmi dokumanina gore mimo-v2.5 thinking'in varsayilan acik olmasi (8 token
butce tamami reasoning'e gitti). Retry yapilmadi (transient degil). DeepSeek
ilk denemede kabul edildi (exact OK, prompt11/completion1/total12, configured
estimate $0.00000182). Claude Code r3 fix (commit `a26091a`) MiMo istegine
thinking.type=disabled ekledi; provider probe suite 109/109, gateway service
testi 97/97, parser 0 hata. Duzeltme sonrasi MiMo kabul edildi (exact OK,
prompt256/completion2/total258, configured estimate $0.00003640). Kabul
edilen cift toplam 270 token / $0.00003822; bu turdaki tum canli harcama
(basarisiz ilk MiMo dahil) 532 token / $0.00007602 (yerel configured rate,
resmi fatura degil). Tum receipt'lerde secret pattern false; secret/raw body/
base URL yazilmadi. 8644 hala yalniz health-only ve **KANIT GEREKLI**
(P0-B provider-probe kapsami zaten yalniz MiMo+DeepSeek oldugu icin bu
kabulu engellemez). Ayrinti `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` bolum 10
ve `docs/VALIDATION.md`. **Sonuc: Faz 2B TAMAM, P0-B TAMAM** (8644 health-only
sinirlamasi acikca acik kalemtutulur). Sonraki aktif adim: P0 "Tek Gercek
Masaustu Urunu" hattina (native integration spike + service lifecycle) veya
kalan P0 "Once Gercegi ve Veriyi Koru" acik kalemlerine (18 Temmuz sonrasi
temiz baseline / MCP ENOBUFS socket dayanimi) gecis - detay
`docs/ROADMAP.md`.

## 19 Temmuz 2026 Ek - MCP Bridge ENOBUFS/teardown TAMAM

Sovereign commit `cf8c9e0` (deterministic test-listen + MCP cleanup + fault
injection) ve `63fcc3b` (Node resmi close-ordering + exact-order testi) 18
Temmuz denetiminde acilan Windows `ENOBUFS`/teardown kalemini kapatti. Kod
kapsami yalniz `workers/mcp-bridge/src/mcp.test.ts`, `test-listen.ts`,
`test-listen.test.ts`. Pre-fix bu oturumda hedef 1/1 + full workspace 124/124
gecti (sorun intermittent, sizinti yolu kanitli); post-fix hedef 11/11, full
workspace 134/134, typecheck 11/12 workspace kapsaminda temiz, `pnpm build`
temiz (web 1645 modul). Codex stresinde ilk normal-sandbox tur EPERM ile
0/20 (urun hatasi degil); onayli tam-erisim batch 19/20 (bir hata capture
kesintisiyle belirsiz, ENOBUFS kaniti yok); failure-capture duzeltmesi
sonrasi 40/40 + 60/60 = **100 ardisik gecis**, kalinti port/process 0. Ortam
notu: varsayilan sandbox'ta typecheck/build `EPERM` verdi, tam erisimde
temiz gecti (urun/test hatasi degil). Ayrinti `docs/VALIDATION.md`. Bu tur
docs-only; hicbir servis/provider cagrisi yapilmadi. (Guncelleme 19 Temmuz:
`docs/ROADMAP.md` madde 3'un o zaman kalan tek ac kalemi olan izole runtime
smoke'u da asagidaki ekte TAMAM oldu; bu artik tarihsel bir kayittir. Sonraki
aktif adim native integration spike'dir.)

## 19 Temmuz 2026 Ek - Izole Runtime Smoke E2E TAMAM, 18 Temmuz sonrasi baseline TAMAM

Sovereign kaynaginda commit `8d904a3` (izole runtime smoke: chat + browser.inspect
ve computer CUA testi eklendi) ve ardindan `edf6393`/`5e07e02` (ikisi de
`fix(e2e): sanitize child env, prove incremental streaming, gate cleanup on
success`) `docs/ROADMAP.md` madde 3'un kalan tek ac kalemini kapatti.
Sovereign kaynaginda (Repo A) commit `e314314` `.gitignore` icindeki bozuk
`{console.error(e.code)` kuralini `[{]console.error(e.code)` olarak duzeltti;
yalniz bu tek ignore satiri degisti, runtime davranisi etkilenmedi. `rg
--files` artik glob parser hatasi vermiyor ve `qa/isolated-runtime-smoke`
uretilen ciktisi degismeyen `qa/` kurali ile ignore edilmeye devam ediyor.

Codex'in bagimsiz kaniti: helper birim suite (`scripts/lib/runtime-harness.test.mjs`)
21/21; tam workspace testi 134/134; typecheck 12 workspace projesinden 11'i
temiz; build temiz (web 1645 modul, `index.html` 0.45 kB, CSS 106.25 kB, JS
380.45 kB). Tam gercek izole smoke exit 0; makbuz
`C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent\qa\isolated-runtime-smoke\receipt.json`,
uretim zamani `2026-07-19T16:03:16.023Z`. Kanit: benzersiz gecici `DATA_DIR` ve
loopback port 50171-50194; gercek kademeli (incremental) akan chat - partial
`İzole`, final `İzole runtime sohbeti canlı akış ile yanıt veriyor.`; 2 kalici
tur; yerel deterministik mock DeepSeek modeli `deepseek-chat-isolated-smoke`,
ucretli provider cagrisi yok; gercek `browser.inspect` Playwright ile
`https://example.com`, baslik `Example Domain`, 3 artifact, `browser-run.json`
837 bayt SHA-256 `1cde0be7baa2ebc7a61a69d78649094002cabe320c32c0395a32180101830112`;
gecerli 1280x800 PNG 10892 bayt; gercek Windows CUA saglik + frame 431664 bayt
1920x1080, proxied frame 412141 bayt; devral gecisleri agent(false) ->
human(true) -> agent(false), sifir desktop input aksiyonu; consoleErrors ve
failedRequests bos; tum cleanup basarili, gecici dizin silindi, izole portlar
artik dinlemiyor. `chat-desktop.png`, `computer-agent-desktop.png`,
`computer-human-desktop.png` gorsel QA'sinda ortusme/occlusion yok, agent/human
durum etiketleri dogru. Deterministik fault injection `gateway-auth` ve
`gateway-stream` her ikisi de tum cleanup basarili olduktan sonra exit 1 verdi,
orphan worker yok.

Sinirlamalar durustce kayitli: bu tur yerel deterministik mock model gateway
kullandi, ucretli provider cagrisi yok; henuz paketlenmis/imzali tek masaustu
urun degil; aktif mouse/klavye otomasyonu bu smoke'ta calistirilmadi (masaustu
yuzeyi salt-okunur kaldi); devral (takeover) sahiplik restart dayanikliligi
hala bekliyor; 8644 rotasi (`sovereign-hermes`) hala yalniz health-only; bu
belgede baska yerde anlatilan canli HERMES rotalari 8642/8643/8644 bu turda
dokunulmadi.

**Sonuc: 18 Temmuz sonrasi temiz baseline TAMAM, izole runtime smoke TAMAM.**
Sonraki aktif muhendislik adimi: Hermes Electron/native shell + Sovereign UI +
Control Plane lifecycle integration spike'i, ardindan devral (takeover)
restart dayanikliligi ve acik guvenlik kapilariyla active-input (aktif
mouse/klavye) kabulu. Ayrinti `docs/VALIDATION.md` icinde.

## 19 Temmuz 2026 Ek - Claude Code Model Politikasi KESIN (ileriye donuk)

Kullanici kararidir; 19 Temmuz 2026'dan itibaren gecerlidir. Claude Code normal
ve orta karmasikliktaki uygulama isini Fable 5 ile; zor mimari, guvenlik,
kritik review, migration ve karmasik debugging isini Opus ile yapar. Sonnet
yasaktir; cagrilamaz ve fallback olarak kullanilamaz. Her Claude Code cagrisi
secili model destekliyorsa max effort ile calisir; desteklemiyorsa desteklenen
en yuksek seviye kullanilir ve raporda belirtilir. Sessiz model fallback
yoktur. Codex yonlendirici ve son reviewer, Claude proje dosyalarinin tek
yazari olarak kalir. Bu politika urun model routing'ini (yalniz MiMo +
DeepSeek) etkilemez. Onceki kayitlarda Sonnet kullanimini dogru belirten
tarihsel kayitlar degistirilmedi. Baglayici metin:
`docs/CLAUDE-CODE-EXECUTION-CHARTER.md` Bolum 10.

## 20 Temmuz 2026 Ek - Native Sovereign service supervisor spike (P0 madde 4 ilk dilim)

P0 "Tek Gercek Masaustu Urunu" hattinin ilk gercek, test edilebilir dikey
dilimi uygulandi (yalniz HERMES deposu; Sovereign deposu DEGISMEDI, sadece
bootstrap/auth sozlesmesi okundu). ADR 0011 kesinlesti. Ozet:

- Reversible feature flag `HERMES_DESKTOP_SOVEREIGN` (varsayilan KAPALI ->
  rota ve IPC koprusu KAYITLI kalir ama disabled/blocked yanit verir; nav
  girdisi gizlidir; hicbir child process, listener veya network probe olusmaz).
  Konfig yalniz env (`_CMD/_ARGS/_CWD/_PORT/_HEALTH_PATH/_SURFACE_URL`),
  secret okunmaz.
- Main-process supervisor (`electron/sovereign-supervisor.cjs` + `-config` +
  `-ipc` + `-runtime`, hepsi Electron'suz saf ve test edilebilir): yalniz
  sahipligi KANITLANAN process'i discover/start/health/stop eder (canli child
  handle veya bizim urettigimiz ephemeral token'i ready-file/`/health`'te
  echo eden instance). Foreign port/process cakismasinda `blocked FOREIGN_PORT`
  ve dokunmaz; `stop()` sahipsiz process'e dokunmaz. Reserved 8642/8643/8644
  ve non-loopback host fail-closed reddedilir -> kalici gateway'ler yapisal
  olarak yonetilemez. Bounded readiness/graceful-stop/force-tree-kill/port-
  release; child stdio discard (pipe deadlock + secret log yok); windowsHide;
  `disposeSync()` `before-quit`'te orphan birakmaz. Token argv/log/renderer/
  getStatus'a hicbir zaman girmez.
- Renderer: flag-gated `/sovereign` in-shell rotasi + command-palette nav
  girdisi; preload `window.hermesDesktop.sovereign.*` koprusu (yeni
  nodeIntegration yok, contextIsolation/sandbox/navigation zayiflatilmadi).
  Surface, ready+healthy+loopback `_SURFACE_URL` varsa imperatif `<webview>`
  (contextIsolation on, nodeIntegration off, sandbox, `persist:sovereign`)
  ile gomulur; yoksa durust "authenticated surface pending" durumu next
  contract'i yazar.
- Auth BYPASS EDILMEDI: stok control-plane API'si `sovereign_session` cookie
  ister; bu dilim urun yolunda `AUTH_MODE=disabled` kullanmaz ve authenticated
  yuzeyi baglamaz.
- Kanit: 44/44 main-process unit + 16/16 renderer (webview lockdown assertion
  dahil) + izole acceptance harness 16/16 (gercek fake service child:
  start->owned(token)->healthy->reach 200->stop, port released + pid dead,
  0 orphan; foreign fail-closed; reserved 8643 pre-spawn reddi), typecheck
  temiz. Ayrinti `docs/VALIDATION.md`, ADR 0011.
- Durust acik kalemler: authenticated urun yuzeyi (ephemeral session bootstrap
  contract'i) BEKLIYOR; cross-session ownership persist BEKLIYOR; gercek
  paketlenmis Electron GUI E2E BEKLIYOR; stok control-plane `/health` henuz
  owner token echo etmiyor (asagidaki 20 Temmuz hardening'i sonrasi bu, stok
  control-plane'in bu supervisor tarafindan SAHIPLENILEMEDIGI anlamina gelir -
  token kaniti gelene kadar start `OWNERSHIP_UNPROVEN` ile fail-closed olur).
  Genis `vitest run src` suite'inde ~25 pre-existing hata var (tr-TR sayi
  bicimi + `explicit_only` gibi urun drift'i); stash ile baseline'da ayni 13
  dosyada 25 hata dogrulandi, hicbiri bu dilime ait degil.

## 20 Temmuz 2026 Ek - Native Sovereign supervisor hardening (Codex review-fix)

Yukaridaki spike'a uygulanan dar kapsamli guvenlik/dayaniklilik review-fix
paketi (tests-first). Yalniz HERMES desktop uygulamasi degisti; Sovereign repo
DOKUNULMADI, flag hala varsayilan KAPALI, hicbir provider/model cagrisi yok.
Bu ek, spike bolumundeki bazi ifadeleri gunceller:

- **Sahiplik artik yalniz TOKEN kaniti iledir; canli child handle tek basina
  yeterli DEGILDIR.** Varsayilan token crypto ile uretilir (24 bayt = 192 bit).
  Hazir olmak icin health OK ARTI token kaniti gerekir: tam `/health` ownerToken
  eslesmesi VEYA token'i eslesip port'u tam configured port'a esit olan
  ready-file. Health OK ama kanit yoksa `OWNERSHIP_UNPROVEN` ile durust fail;
  yalniz bu supervisor'un spawn ettigi child temizlenir. `'child'` ownership
  proof turu kaldirildi. Yanlis/eksik portlu ready-file token'i kanit sayilmaz.
- Race-free FIFO kuyrugu `inFlight` desenini degistirir; start/stop/reach
  serilestirilir (sirali, cift-spawn yok, rejection sonrasi kuyruk kurtarilir).
- `fetchSovereignHealth` HAM BAYT sinirlar (JS char degil); >64 KiB abort +
  fail-closed, kesik prefix asla parse edilmez.
- `makeSovereignSpawn` ortam degiskenlerinin tamamini MIRAS ALMAZ; muhafazakar
  OS/runtime allowlist uzerine yalniz supervisor env'i biner. Ambient
  ANTHROPIC/OPENAI/DEEPSEEK/MIMO + `*_API_KEY`/`*_TOKEN`/`*_SECRET` child'a
  ulasmaz.
- IPC gonderen guveni: `registerSovereignIpc` enjekte authorizer alir, bes
  kanalda config/supervisor cagrisindan ONCE fail-closed olur, sabit
  `UNTRUSTED_SENDER` doner. main.cjs canli BrowserWindow-sahipli top/main frame
  + tam renderer konumu ister; webview guest/subframe/foreign reddedilir.
- Teardown POSIX'te inatci child birakmaz (Windows agac + direct child SIGKILL);
  disposeSync ayni garanti + ready-file senkron silme.
- Surface URL userinfo credential iceriyorsa reddedilir; `persist:sovereign`
  session'da fail-closed subresource egress filtresi (yalniz configured
  authority). Renderer yalniz ready+healthy+`owned`+surfaceUrl'de gomer; Stop
  yeni `controllable` durumuna baglidir (bayat ready degil).

Kanit (bu makine, izole, ucretsiz): Sovereign node testleri **85/85**
(pre-fix 56; olculen per-file dagilim config 13 / supervisor 28 / ipc 12 /
runtime 18 / webview 14 — onceki kayit 16/28/13/18/17 yanlisti, toplami 92
eder; r3'te duzeltildi);
renderer **18/18** (pre-fix 16); `test:sovereign:accept` iki kez exit 0,
**23/23** kontrol (senaryo D: gercek healthy-ama-sessiz child `OWNERSHIP_
UNPROVEN` + orphan yok), sonra 0 kalinti fake process; hedef ESLint 0 hata/
0 uyari; typecheck temiz; `git -c core.whitespace=cr-at-eol diff --check`
temiz (main.cjs LF, churn yok). Tam `test:desktop:platforms`: **394 test,
391 gecti, 1 hata, 2 skip**. Tek hata onceden var olan, ilgisiz
`resolveUnpackedRelease ... release/<plat>-unpacked` (update-relaunch.test.cjs;
dokunulmadi). NOT: brief "3 pre-existing update-relaunch failure" dedi; bu
checkout'ta olculen gercek **1** (ADR 0011'deki "one pre-existing Linux-path
assertion" ile tutarli) - gizlenmeden oldugu gibi raporlandi. 8642/8643/8644
degismedi (PID 17364/17348/17352, 127.0.0.1); 4310-4321 serbest; uc `\Sovereign\`
task `Ready` (dokunulmadi). Ayrinti `docs/VALIDATION.md`, ADR 0011.

Durust sinirlar (degismedi): authenticated yuzey BEKLIYOR (auth bypass yok);
stok control-plane token echo etmedigi icin henuz SAHIPLENILEMEZ; cross-restart
ownership persist yok; paketlenmis Electron GUI E2E yok; aktif input yok; tam
Manus urunu tamam degil. Kullanicinin AgentOS deposu/gecici klonu yalniz istege
bagli karsilastirma/referanstir - kopyalanmadi/import/merge/bagimlilik/degisiklik
yok; incelenen snapshot'ta ust duzey LICENSE yoktu ve farkli Claude-merkezli
stack'e dusuyordu, bu yuzden hicbir kod alinmadi. Acik-kaynak/Manus arastirmasi
iptal degil, planli kalir.

## 20 Temmuz 2026 Ek - Native Sovereign supervisor r3 (Codex review duzeltmeleri)

Ayni uncommitted dilim uzerinde ikinci, kucuk Codex review paketi uygulandi
(yalniz HERMES desktop; Sovereign repo DOKUNULMADI; flag varsayilan KAPALI;
provider/model cagrisi ve commit yok). Alti duzeltme (detay ADR 0011 r3 bolumu):

- **Adopt icin canli spawned handle sart:** doStart'in dolu-port adoption yolu
  yalniz mevcut token kaniti AYNI canli spawn edilmis child ile birlikteyse
  READY doner. Token echo'layan ama spawned handle'i olu olan dinleyici
  fail-closed `FOREIGN_PORT` sayilir, asla owned/controllable olmaz; bayat
  ownership/handle dusurulur.
- **READY sonrasi beklenmeyen child exit aninda reconcile:** spawn aninda
  kurulan handle-scoped exit/error watcher ile durum `FAILED`/`CHILD_EXIT`,
  healthy/owned/controllable false, ownership/pid/proof temizlenir. STOPPING
  sirasindaki beklenen exit `doStop`'a birakilir (yanlis siniflama yok);
  ownership yayinlanmadan once son bir `childAlive()` re-check dar
  readiness-to-listener yarisini kapatir. FIFO ve token-only kanit zayiflatilmadi.
- **Renderer durustlugu:** `ready+healthy+owned=false` artik "owned" diyen
  auth-pending panelini GOSTERMEZ; ozel fail-closed "Ownership lost or
  unproven" paneli cikar (embed yok, Stop kapali). Start yalniz bu bayat
  unowned+uncontrollable ready'de aciktir (sonraki start portu FOREIGN_PORT'a
  reconcile edebilsin diye); gercek owned READY start edilemez kalir. STARTING
  sirasindaki Stop istegi FIFO ile bounded start'in ARKASINA serilestirilir
  (aninda iptal degildir) - yorum/dokuman boyle duzeltildi.
- **Sender predicate ayri modulde:** `electron/sovereign-ipc-trust.cjs`
  (Electron'suz; fromWebContents/renderer URL/platform enjekte) + kendi node
  test suite'i `test:desktop:platforms`'a eklendi. Paketli guven artik BOS
  file-URL hostname ister (`file://evil-host/<ayni path>` reddedilir) ve
  path karsilastirmasi `fileURLToPath`+normalize iledir (encoded `/`
  fail-closed); ikincil pencereler yalniz query/hash degistirebilir. main.cjs
  lokalize sekilde test edilmis helper'a baglandi.
- **In-page egress daraltildi:** `persist:sovereign` filtresi in-page olarak
  yalniz `data:`/`blob:`/`about:` gecirir; `devtools:`/`chrome:`/
  `chrome-extension:` ve bilinmeyen scheme'ler reddedilir. Ayni-authority
  http/https/ws/wss davranisi degismedi.
- **Durust yorum/sayim:** flag-off ifadesi (rota/IPC kayitli ama
  disabled/blocked; process/listener/network yok), runtime ready-file yorumu
  (live-child fallback yok) ve r2 per-file test sayimlari duzeltildi.

Kanit (bu makine, izole, ucretsiz, 20 Temmuz olcumu): Sovereign node
**108/108** (config 13, supervisor 32 [+4 lifecycle], ipc 12, ipc-trust 19
[yeni], runtime 18, webview 14; r2 taban yeniden olculdu: 85 = 13/28/12/18/14).
Renderer **19/19** (index 10, store 4, routes 5). Hedefli ESLint 0 hata/0
uyari; typecheck temiz; `test:sovereign:accept` 2x exit 0 **23/23**, 0 kalinti
fake process; `git -c core.whitespace=cr-at-eol diff --check` temiz. Read-only:
8642/8643/8644 degismedi (127.0.0.1, PID 17364/17348/17352), 4310-4321 serbest,
uc `\Sovereign\` task `Ready`. Tam `test:desktop:platforms` bu turda bilerek
KOSULMADI (Codex bagimsiz kosacak). AgentOS istege bagli/no-import ve
MiMo+DeepSeek-only kararlari degismedi.

Oturum sonu ortam kaydi (oldugu gibi raporlandi): yukaridaki yesil olcumlerden
SONRA host yeni loopback listener kabul etmemeye basladi (`listen ENOBUFS`) -
ilgisiz `ArkSignerManagement` (PID 23048) 15.771 Bound TCP soketi tutuyordu ve
taze node'da bagimsiz `net.createServer().listen(0,'127.0.0.1')` probe'u da
ENOBUFS verdi (host-geneli kanit). Bu nedenle son kapida gercek-HTTP fixture
kullanan `sovereign-runtime` 12/18'e dustu (ayni oturumda daha once iki kez
18/18 gecmisti); soket kullanmayan bes suite son kapida da 90/90. r3 o dosyada
yalniz yorum degistirdi - urun/test regresyonu degil, host kosulu (19 Temmuz
MCP-bridge ENOBUFS gecmisiyle uyumlu). Yabanci surece DOKUNULMADI. Codex tam
suite kosmadan once ArkSigner kapatilmali/yeniden baslatilmali (veya reboot) ve
runtime suite yeniden dogrulanmali.

## 25 Temmuz 2026 - Native Sovereign r4 (Opus 5/Max) ve ortam duzeltmesi

**Model politikasi (kullanici karari, baglayici):** Claude Code implementation ve
review yalniz **Opus 5 + Max** ile yapilir; Fable/Sonnet kullanilmaz. MiMo ve
DeepSeek HERMES/Sovereign runtime'inin provider'laridir - Claude Code'un kodlama
modeli degildir; iki katman karistirilmaz. Ayrinti `CLAUDE.md`.

**Ortam duzeltmesi (append-correct, onceki kaydi gecersiz kilar):** yukaridaki
r3 oturum-sonu notunda gecen `listen ENOBUFS` kosulu DIS ORTAM kaynakli ve
GECICIYDI (ilgisiz `ArkSignerManagement` dinamik port havuzunu tuketmisti).
Windows reboot sonrasi dinamik `listen(0)` yeniden calisiyor ve
`sovereign-runtime` **standart ephemeral portlarla 18/18** geciyor. Bu nedenle:
onerilen deterministic 4310-4321 sabit-test-portu yamasi UYGULANMADI; sabit test
portu, ArkSigner restart veya reboot bu suite'ler icin **gereklilik degildir**.
ArkSigner'a hicbir zaman dokunulmadi.

**r4 hardening (uc dar degisiklik, hepsi HERMES desktop; Sovereign deposu, flag
varsayilani ve urun runtime davranisi degismedi):**

1. Supervisor total exception safety kodu calisma agacinda zaten vardi; bu turda
   eksik olan **fault-injection kaniti** eklendi (+6 test) ve on-hardening
   sozlesmesini bekleyen bayat bir test gercek davranisa gore duzeltildi.
2. Renderer'da paylasilan `busy` bayragi Stop'u kilitlemeyi birakti: gating
   operasyon bazli, `controllable` true iken Start pending olsa bile Stop
   istenebiliyor ve panel bunun **FIFO queued teardown** oldugunu (immediate
   cancel degil) yaziyor. Config okuma hatasi artik "integration disabled" gibi
   gorunmuyor; config/status/mutation hatalari icin stack/ham-mesaj/secret
   icermeyen fail-closed panel + Retry var.
3. Webview subresource egress'i **protocol-family**'ye pinlendi (http yuzey =>
   http+ws, https yuzey => https+wss); karsi aile ayni authority'de bile
   reddediliyor, bilinmeyen yuzey scheme'i tum ag egress'ini kapatiyor.

**Kanit (izole, ucretli cagri yok, 25 Temmuz):** focused Sovereign node
**115/115** (config 13, supervisor 38, ipc 12, ipc-trust 19, runtime 18, webview
15); renderer vitest **22/22**; `test:sovereign:accept` 2x exit 0 **23/23**,
0 kalinti fake process; hedefli ESLint 0/0; `tsc --noEmit` temiz;
`git -c core.whitespace=cr-at-eol diff --check` temiz; tam
`test:desktop:platforms` **424 test / 421 pass / 1 fail / 2 skip** (tek hata bu
dilimin dokunmadigi, onceden var olan ilgisiz `update-relaunch` Linux-path
assertion'i); tam `npm run build` basarili. Read-only host: 4310-4321 serbest;
korunan gateway'ler degismedi (127.0.0.1, **8642 PID 11692, 8643 PID 17636,
8644 PID 8680**); uc `\Sovereign\` task `Ready`/`LastTaskResult=0`.

Commit yapilmadi (kullanici talimati). Authenticated Sovereign yuzeyi, cross-
session ownership persist ve packaged Electron GUI E2E hala BEKLIYOR.

**r4 review-fix (25 Temmuz, Codex r4 bulgulari):** uc kusur kapatildi -
(1) kuyruk paneli `canStop && startPending` yerine `stopPending && startPending`
(panel artik ancak GERCEKTEN istenen Stop, pending Start arkasindayken gorunur;
onceki test yanlis nedenle geciyordu), (2) eksik/bos preload bridge artik
"Integration disabled" degil fail-closed error state (sabit
`SOVEREIGN_BRIDGE_UNAVAILABLE`, UI'ya yazilmaz; Retry ile toparlanma testli),
(3) `waitForChildExit` icinde throw eden `clearTimeout` promise'i strand
edebiliyordu -> timer iptali best-effort, resolve garantili; throw eden
`setTimeout` de sinirsiz bekleme yerine escalation'a dusuyor. Her uc duzeltme
icin guard testleri, duzeltme gecici geri alinarak KIRMIZI oldugu dogrulanip
restore edildi. Guncel kanit: focused node **118/118** (13/41/12/19/18/15),
renderer **24/24**, acceptance 2x **23/23** (exit 0, orphan 0), ESLint 0/0,
typecheck + `diff --check` temiz, tam platforms **427/424 pass/1 onceden var
olan ilgisiz fail/2 skip**, tam build basarili. Read-only: 4310-4321 serbest,
8642/8643/8644 PID 11692/17636/8680 degismedi, uc task `Ready`/0. Commit yok.

**r4 review-fix #2 (25 Temmuz, Codex ikinci review):** iki itiraz da hakliydi.
(1) throw eden `handle.once`/`timer.unref`, `waitForChildExit`'i reject edip
`killOwned`'in force escalation'ini ATLATIYOR, stubborn spawned child'i orphan
birakiyordu; artik best-effort + `finish(false)` ile escalation garantili
(yalniz kendi pid; foreign occupant'a dokunulmuyor, kanitlanamayan release
`PORT_NOT_RELEASED` olarak raporlaniyor). (2) IPC start/stop/reach basari-sekilli
`{ error }` donuyordu (renderer isError'a dusmuyordu) ve config/status raw
exception'i sinirdan geciriyordu; bes kanal da sabit
`SOVEREIGN_OPERATION_FAILED` ile reject ediyor, ayrinti yalniz main log'da,
`UNTRUSTED_SENDER` onceligi korunuyor; renderer `error` tasiyan payload'i da
fail-closed sayiyor. Guncel kanit: focused node **123/123** (13/44/14/19/18/15),
renderer **27/27**, ESLint 0/0, typecheck + `diff --check` temiz; guard'lar geri
alininca ilgili testler kirmizi. Full platform/build/acceptance bu turda
kosulmadi (Codex final sweep). Commit yok.

**Sovereign gorunur nav satiri (25 Temmuz, Codex final GUI review):** `/sovereign`
artik command-palette-only degil. Sidebar birincil navigasyonunda Shield ikonlu
Sovereign satiri var (Capabilities'ten hemen sonra); yalniz descriptor yuklendi
VE `enabled` ise gosteriliyor - flag off, bridge yok veya config load hatasinda
satir hic olusmuyor (olu rota reklam edilmiyor). Kesif paylasilan
`@/store/sovereign` load'u uzerinden idempotent (palette ile yaris/cift fetch
yok), satirda `action` olmadigi icin tiklama yalniz `SOVEREIGN_ROUTE`a gidiyor
ve servisi baslatmiyor. Nav dizisi saf `src/app/chat/sidebar/nav-items.tsx`
modulune cikarildi; testler o saf sinirda (9/9; gorunurluk kapisi zorla acilinca
4 test kirmizi). Kanit: dokunulan alti dosya **51/51 (6 dosya)** - onceki
"87/87" iddiasi geri cekildi (dizin globu yedinci dosyayi da katiyordu),
focused node 123/123, ESLint
0/0, typecheck + diff-check temiz. **Final sweep duzeltmesi:** tam platform
suite'inin dogru sonucu **432/427 pass/3 fail/2 skip**'tir (onceki 427/424/1/2
nihai degildi); uc hata da bu dilimin dokunmadigi, onceden var olan
`update-relaunch.test.cjs` Windows/POSIX tasinabilirlik vakalaridir. Commit yok;
sirada Codex'in gorunur rotadan canli Start -> Probe -> Stop dogrulamasi.

**Codex bagimsiz final dogrulama (26 Temmuz):** CANLI Electron GUI kaniti alindi -
gorunur sidebar satiri, gercek fare tiklamasiyla `/sovereign`a gecis ve tam
Start -> Probe -> Stop dongusu (Start: ready/healthy/owned(token)/PID 28356, 4310
tam olarak fake-sovereign-service node surecinde, auth bypass yok; Stop: idle,
4310 serbest, fake process 0; pencere kapaninca Electron PID 10700 gitti).
Korunan gateway'ler degismedi (8642/11692, 8643/17636, 8644/8680; uc task
Ready/0). Boylece "gercek tiklama/lifecycle GUI kanitlanmadi" ifadeleri
gecersizdir; PACKAGED/imzali build, cross-session ownership ve authenticated
yuzey hala BEKLIYOR. Sayi duzeltmesi: dokunulan alti dosya icin dogru sonuc
**51/51 (6 dosya)**; onceki "87/87 / 7 dosya" iddiasi geri cekildi (dizin globu
yedinci dosyayi katiyordu). Diff hijyeni: `src/app/types.ts` CRLF->LF churn'u
(168/161) HEAD'den geri alinip CRLF korunarak yeniden uygulandi -> **8/1**.
Yuk altinda gorulen tek renderer flake'i (disabled-panel testi) gizlenmeden
kaydedildi; iki ardisik temiz kosu 51/51.

## 26 Temmuz 2026 Ek - Authenticated Sovereign urun yuzeyi (local JSON dilimi) TAMAM/KISMI

ADR 0011'in acik biraktigi "authenticated urun yuzeyi BEKLIYOR / stok control-
plane SAHIPLENILEMEZ" kalemi, auth BYPASS EDILMEDEN kapatildi. HERMES-sahipli bir
on-plan urun host adapter'i (`electron/sovereign-product-host.cjs` saf cekirdek +
`scripts/sovereign-product-host.mjs` calistirilabilir giris) tek supervisor
child'i oluyor ve stok Sovereign control-plane'ini sariyor:

- Adapter, `apps/web/dist`i loopback urun portunda serve eder ve `/api,/health,
  /livez,/readyz`i AYRI loopback API portundaki DOGRUDAN spawn edilen control-
  plane'e (grandchild) reverse-proxy eder. Boylece supervisor readiness'i (health
  2xx + `/__hermes/health`te tam `ownerToken` echo ARTI atomik ready-file token+
  port) karsilanir; stok control-plane artik SAHIPLENILEBILIR.
- Auth bypass YOK: bootstrap/login izole `persist:sovereign` webview icinde urun
  origin'inde olur; sir Hermes IPC/argv/log/receipt'e girmez; `AUTH_MODE=disabled`
  yok. Control-plane env'i bilincli allowlist/overlay (yalniz CONTROL_PLANE_HOST/
  PORT + DATA_DIR): NODE_ENV=production/DB/NATS/Temporal/provider/secret YOK =>
  JSON store + NoopEventBus + yerel TaskEngine, auth ACIK. `.env` okunmadi.
- Dis Sovereign deposu DEGISTIRILMEDI (`e314314` temiz); `main.cjs`/renderer
  degisikligi YOK - entegrasyon env/config ile. Renderer zaten ready+healthy+
  owned+surfaceUrl'de webview'i gomdugu icin ek kod gerekmedi.
- Kanit: product-host unit 25/25; focused Sovereign node 148/148; acceptance
  `test:sovereign:product` 50/50 (2x exit 0, 0 orphan) - first cycle static+auth
  (bootstrap 201->cookie->session), restart ayni DATA_DIR (setupRequired false +
  bootstrap 409 + login 200 + session), supervised faz GERCEK supervisor'la
  start->owned(token)/healthy/surface 200/reach 200/stop->serbest; tam platforms
  457/454 pass/1 onceden var olan ilgisiz fail/2 skip; in-scope ESLint 0/0; tsc
  temiz; diff-check temiz. Host: 4310-4321 serbest, korunan gateway'ler degismedi
  (8642/11692, 8643/17636, 8644/8680), uc task Ready/0, 0 orphan.

Baglatma (secretsiz, varsayilan KAPALI, geri alinabilir): `HERMES_DESKTOP_
SOVEREIGN=1`, `_CMD=<node>`, `_ARGS=["<abs>/scripts/sovereign-product-host.mjs",
"--source-root","<abs Sovereign source>","--data-dir","<abs Hermes-owned data>",
"--api-port","0"]`, `_PORT=4312`, `_HEALTH_PATH=/__hermes/health`, `_SURFACE_URL=
http://127.0.0.1:4312/`. Bu makinede kanonik Sovereign source
`C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent` (runtime koduna
gomulmez; env/argv ile verilir).

Durust sinirlar (bu yalniz local JSON dilimidir, tum urun degil): worker/Temporal/
Postgres/NATS/provider/computer yurutmesi kanitlanmadi; dev auth-encryption secret
sabit yerel sabit (production degil); WebAuthn/MFA step-up denenmedi; ephemeral
API-port TOCTOU ihmal edilebilir + fail-closed; cross-desktop-restart ownership
persist YOK; paketli/imzali GUI E2E, durable takeover, active-input approval E2E
BEKLIYOR. **Bir sonraki kesin adim:** cross-session ownership persist (adopt) VEYA
paketli Electron GUI E2E; ardindan active-input approval kabulu. Commit yok.
