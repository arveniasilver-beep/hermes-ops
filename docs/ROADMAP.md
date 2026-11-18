# HERMES / Sovereign Yol Haritasi

Son guncelleme: 18 Eylul 2026

Durum etiketleri: `TAMAM`, `KISMI`, `BEKLIYOR`, `KANIT GEREKLI`. Bir madde ancak
kod, test ve kullanici akisi kanitlandiginda `TAMAM` olur.

## P0 - Once Gercegi ve Veriyi Koru

Not (9 Eylul 2026): Asagidaki tablo HERMESAGENT urun kaynagi icindir. Kullanicinin
vendor Hermes kurulumu ayri bir hattir; durumu `WORKLOG.md` 9 Eylul kaydindadir.

| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| TAMAM | Vendor Hermes kurulum onarimi | Bozuk tag-only fetch refspec + bayat `shallow.lock` giderildi; kurulum uctan uca tamam (v0.21.1/2026.9.7, upstream `ead7e91d`); installer `-Stage repository` `{"ok":true}` |
| BEKLIYOR | Vendor ozellestirmelerinin guncellemeye dayanmasi | `local-custom-20260909` (`ed97e53bb`) main'e tasindi ve dogrulandi (11/11 pytest, typecheck+lint temiz), ANCAK installer guncelleme yolu `git checkout main` yaptigi icin sonraki update ozellestirmeleri uygulamadan dusurur. Kabul: guncelleme sonrasi ozellestirmeleri otomatik yeniden uygulayan (rebase/patch) bir akis, veya bilincli olarak upstream'e PR |
| BEKLIYOR | Vendor Command Center GUI E2E | Gercek Electron'da Command Center acilip gorev olusturma/listeleme tiklama kaniti; su an kanit yalnizca birim/tip/lint/build seviyesinde |
| TAMAM | Trendyol salt-okunur MCP koprusu | `tools/trendyol-mcp/` (7 GET araci, read_only_hint, PII ayiklama, sirlar yalniz profil .env) `owner-orchestrator` profiline kayitli; pytest 20/20, `hermes mcp test trendyol` Connected/7 tools (18 Eylul). Reklam API'si Trendyol'da yok - kapsam disi |
| KANIT GEREKLI | Trendyol koprusu canli hesap E2E | Kullanici `TRENDYOL_API_KEY/SECRET/SELLER_ID`'yi profil .env'e girince: `trendyol_status` configured=true, `trendyol_sales_summary` 30 gun gercek veri, urun V2 yanit semasi dogrulanir |


| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| KISMI | 17 Temmuz source backup | ZIP + iki baseline bundle mevcut; restore tatbikati bu build icin tekrar edilmeli |
| TAMAM | HERMES Git hygiene | Ilk commit `152bf9a` + tag `baseline-hermes-20260719`; 6.212 dosya explicit allowlist ile; kanit `docs/P0A-BASELINE-RECEIPT-2026-07-19.md` |
| TAMAM | Sovereign version-control baseline | `git init -b master`, ilk commit `9ca47c7` + tag `baseline-sovereign-20260719`; secret/user data/QA kanitlari haric; rollback bundle mevcut |
| TAMAM | 18 Temmuz sonrasi temiz baseline | Typecheck 11/12 workspace kapsaminda temiz, hedef MCP suite 11/11 + full workspace 134/134, `pnpm build` temiz (19 Temmuz, commit `cf8c9e0`/`63fcc3b`); izole runtime smoke E2E (chat/web task/Bilgisayar/artifact) TAMAM (19 Temmuz, commit `8d904a3`/`edf6393`/`5e07e02`, receipt exit 0, helper 21/21); kaniti `docs/VALIDATION.md` |
| BEKLIYOR | Runtime konfigurasyon envanteri | Secret degeri olmadan required/optional config ve health matrisi |
| TAMAM | Dedicated gateway lifecycle | Faz 2A + r4 TAMAM (19 Temmuz, onayli): 3 task `conhost --headless` hidden-launcher zinciriyle kuruldu; konsolsuz profil profil stop/start kabulu (yeni gorunur pencere 0, final gorunur pencere 0, wrapper kalinti 0); 3/3 RUNNING/loopback/HTTP 200 + task owned/config 3/3; 97/97 test (r5). Codex Faz 2A'yi `f2a2a19` uzerinde KABUL etti. Faz 2B Windows reboot acceptance TAMAM (19 Temmuz): checklist 1-14 kanitli, `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` bolum 9. Faz 2B provider probe TAMAM (19 Temmuz, ayni belge bolum 10): DeepSeek ilk denemede kabul, ilk MiMo denemesi thinking-default nedeniyle basarisiz, `thinking.type=disabled` fix'i (commit `a26091a`) sonrasi MiMo kabul edildi, 109/109+97/97 test, secret pattern false. 8644 yalniz health-only + KANIT GEREKLI kalir (P0-B kapsami disinda, engel degil). **P0-B TAMAM** |
| TAMAM | Windows test socket dayanimi | Sovereign commit `cf8c9e0`+`63fcc3b`: MCP hedef suite 11/11, full workspace 134/134, fault-injection (ENOBUFS/EADDRINUSE/exhaustion/sync-throw/idempotent-close/exact-order) kapsandi; Codex stresinde 40/40+60/60=100 ardisik gecis, kalinti port/process 0. Ayrinti `docs/VALIDATION.md` |

## P0 - Tek Gercek Masaustu Urunu

| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| KISMI | Hermes native shell | Phase 8 calisiyor; unsigned package policy engeline takiliyor |
| KISMI | Sovereign execution UI/backend | Web runtime kabul edildi; native pakette degil |
| KISMI | Native integration spike | Flag-gated Sovereign rotasi + surface Hermes Electron shell'ine baglandi (ADR 0011); render izolasyonu korundu (webview: contextIsolation on, nodeIntegration off, sandbox, `persist:sovereign`). Authenticated urun yuzeyi bilincli olarak BEKLIYOR (auth bypass yok; durust "authenticated surface pending" durumu next contract'i yaziyor). 25 Temmuz (Codex final GUI review): rota artik command-palette-only degil - sidebar birincil navigasyonunda Shield ikonlu **gorunur Sovereign satiri** var; yalniz descriptor YUKLENDI ve `enabled` ise gosterilir (flag off / bridge yok / config load hatasi => satir yok, olu rota reklam edilmez), paylasilan store ile tek-sefer fetch (palette ile yaris yok), tiklama yalniz `SOVEREIGN_ROUTE`a gider (action yok => servis baslatmaz). **CANLI GUI KANITI (Codex, bagimsiz, 26 Temmuz):** gercek Electron'da satir Capabilities'ten sonra gorunur haldeydi, gercek fare tiklamasi `/sovereign`a gitti; Start => ready/healthy/owned(token)/PID 28356 ve 4310 tam olarak `fake-sovereign-service.mjs` node surecinde, auth bypass edilmedi (authenticated-surface-pending paneli); Probe => ayni PID, hatasiz; Stop => idle/healthy no/owned no/PID dash, 4310 serbest, fake process 0; pencere kapaninca Electron PID 10700 gitti, 4310 serbest. Korunan gateway'ler boyunca degismedi (8642/11692, 8643/17636, 8644/8680; uc task Ready/0). Kanit: nav-items 9/9 (gate zorla acilinca 4 test kirmizi), dokunulan alti dosya **51/51 (6 dosya; onceki "87/87" iddiasi geri cekildi - dizin globu yedinci dosyayi katiyordu)**, focused node 123/123. **26 Temmuz - authenticated urun yuzeyi baglandi (auth bypass YOK, local JSON dilimi):** HERMES-sahipli product host adapter (`electron/sovereign-product-host.cjs` + `scripts/sovereign-product-host.mjs`) stok control-plane'i sararak tek supervisor child'i oluyor - `apps/web/dist`i loopback urun portunda serve edip `/api,/health,/livez,/readyz`i AYRI loopback API portundaki grandchild control-plane'e reverse-proxy ediyor, token'i yalniz web+upstream canliyken `/__hermes/health`te echo ediyor. Bootstrap/login izole webview'de kaliyor; control-plane env'i bilincli allowlist (JSON store/NoopEventBus/local TaskEngine, auth ACIK); dis Sovereign deposu ve `main.cjs`/renderer DEGISMEDI. Kanit: product-host unit 25/25, focused node 148/148, acceptance `test:sovereign:product` 50/50 (2x exit 0, 0 orphan: bootstrap->cookie->session, restart ayni DATA_DIR 409+login, supervised faz GERCEK supervisor owned(token)/healthy/surface 200/stop-serbest), platforms 457/454 pass/1 onceden-var-olan-ilgisiz/2 skip. ADR 0011 (26 Temmuz), `docs/VALIDATION.md` |
| KISMI | Service lifecycle | Main-process supervisor: discover/start/health/stop yalniz sahipligi TOKEN ile kanitlanan process icin (canli child handle tek basina yetmez; kanitsiz health `OWNERSHIP_UNPROVEN`); foreign port/process cakismasinda fail-closed; reserved 8642-8644 asla yonetilmez; race-free FIFO kuyruk; bounded readiness/stop + POSIX SIGKILL fallback; muhafazakar child-env allowlist; IPC sender-trust (r3: Electron'suz `sovereign-ipc-trust.cjs` modulu, bos file-URL hostname sarti); konsolsuz; disposeSync quit. r3 (20 Temmuz, Codex duzeltmeleri): adoption canli spawned handle ister, READY sonrasi beklenmeyen child exit aninda FAILED/CHILD_EXIT'e reconcile edilir (ownership/pid/proof temiz), renderer bayat unowned ready icin fail-closed ownership-lost paneli gosterir, in-page egress data:/blob:/about:'a daraltildi. r4 (25 Temmuz, Opus 5/Max): supervisor total exception safety fault-injection ile KANITLANDI (pre-spawn probe reject 0 spawn/0 kill; post-spawn ready-file throw yalniz kendi child'imizi temizler ve token tasiyan ready-file'i siler; stop release-probe reject asla IDLE demez; throwing kill/force-kill stop'u kilitlemez; FIFO her faultan sonra toparlar), renderer paylasilan `busy` yerine operasyon-bazli gating ile Start pending iken de Stop'u kabul eder ve bunu "FIFO queued teardown" olarak durustce yazar, config/status/mutation hatalari icin stack/ham-mesajsiz fail-closed panel + Retry eklendi, webview egress protocol-family'ye pinlendi (http=>http+ws, https=>https+wss; karsi aile ayni authority'de bile red). r4 review-fix (Codex r4 bulgulari): kuyruk paneli `stopPending && startPending` kosuluna cekildi (panel yalniz gercekten istenen Stop pending Start arkasindayken gorunur), eksik/bos preload bridge artik "Integration disabled" degil fail-closed error state (sabit sentinel UI'ya yazilmaz, Retry ile toparlanir), `waitForChildExit` icinde throw eden `clearTimeout`/`setTimeout` artik promise'i strand edemez (best-effort iptal + garantili resolve, aksi halde dogrudan escalation); uc duzeltmenin guard testleri, duzeltme gecici geri alinarak kirmizi oldugu dogrulanip restore edildi. r4 review-fix #2 (Codex ikinci review): throw eden `handle.once`/`timer.unref` artik force escalationi atlatamaz (stubborn spawned child orphan olmuyor, yalniz kendi pid, foreign occupanta dokunulmuyor), IPC hatalari basari kiligina girmiyor - bes kanal da sabit `SOVEREIGN_OPERATION_FAILED` ile reject ediyor (ayrinti yalniz main log) ve renderer `error` tasiyan payloadi fail-closed sayiyor. Guncel kanit: **123/123** Sovereign node (13/44/14/19/18/15) + **27/27** renderer + izole acceptance **23/23** (2x, exit 0, 0 orphan), hedefli ESLint 0 hata/0 uyari, typecheck temiz, `diff --check` temiz, tam `test:desktop:platforms` 427/424 pass/1 onceden var olan ilgisiz fail/2 skip, tam `npm run build` basarili. r3'teki ArkSigner/ENOBUFS kaydi DIS ORTAM/geciciydi: reboot sonrasi dinamik `listen(0)` calisiyor ve `sovereign-runtime` standart ephemeral portlarla 18/18 geciyor; sabit test portu veya ArkSigner restart bir gereklilik DEGILDIR. Restart dayanikliligi (cross-session ownership persist) ve gercek Electron GUI E2E hala BEKLIYOR. Kanit `docs/VALIDATION.md`, ADR 0011. 25 Temmuz |
| BEKLIYOR | Signed package/update | Windows policy uyumlu imzali installer, rollback ve data koruma |
| BEKLIYOR | Merged failure/recovery | Native build + Temporal/PostgreSQL/NATS kesinti ve restart kabulü |

## P0 - Bilgisayar ve Tarayici Gercekligi

| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| TAMAM | Windows read-only capture | CUA 1920x1080, evidence/artifact, sifir input |
| TAMAM | Human takeover execution lock | UI + worker next-action block testi |
| BEKLIYOR | Durable ownership | Worker/control-plane restart'inda human lock korunur |
| BEKLIYOR | Dusuk gecikmeli frame transport | Authenticated stream, reconnect, backpressure ve mobil QA |
| BEKLIYOR | Approval-gated CUA write E2E | Disposable app'te click/type/save; approval ve verifier kaniti |
| BEKLIYOR | Host redaction | Hassas bolge fiziksel redaction ve fail-closed testleri |
| BEKLIYOR | Browser Use adapter | Authenticated session, CAPTCHA/2FA handoff ve evidence E2E |
| BEKLIYOR | Manus resmi gap analizi | Browser Operator, Cloud Browser, My Computer, takeover, gorev/event/artifact matrisi; Hermes kabul testlerine bagli tarihli rapor |

## P1 - Ajan Yurutme Kalitesi

| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| KISMI | DeepSeek/MiMo dedicated routing | 17 Temmuz canli kabul; 19 Temmuz uc gateway HTTP 200; reboot + provider-probe kabulu TAMAM (P0-B, bkz. yukarida); persisted config kalici degil, semantic multi-model routing hala BEKLIYOR |
| KISMI | Plan normalization/verifier | Public web gorevi kabul edildi; daha genis eval seti gerekli |
| BEKLIYOR | Semantic multi-model chat routing | Tek turn icinde rol secimi, cost/latency ve fallback gorunurlugu |
| BEKLIYOR | OpenHands live coding | Izole repo patch + test + diff artifact + approval |
| BEKLIYOR | Agent-S optional planner | Strict action schema arkasinda disposable-app kabulü |
| BEKLIYOR | Browser benchmark | Playwright vs Browser Use escalation kalite/maliyet eval'i |
| BEKLIYOR | MiMo + DeepSeek eval harness | Yalniz secili iki aile ayni Hermes setinde; tool/schema/safety/kalite/latency/token/maliyet receipt'leri ve rol bazli karar |

## P1 - Veri, Hafiza ve Maliyet

| Durum | Is | Kabul olcutu |
| --- | --- | --- |
| TAMAM | Project/skill/knowledge tabani | Contract, persistence ve UI mevcut |
| BEKLIYOR | Kullanici kontrollu sifreli memory | Goruntule/sil/export/retention ve tenant testleri |
| BEKLIYOR | Project import/export | Integrity manifest, conflict preview, dry-run ve rollback |
| KISMI | Token/maliyet tahmini | Shared spend guard var; provider invoice ile uzlasma yok |
| BEKLIYOR | Invoice reconciliation | DeepSeek/MiMo gercek fatura importu ve sapma raporu |

## P2 - Ticari ve Production Kalitesi

- `BEKLIYOR` Accessibility: klavye, screen reader, contrast ve zoom acceptance.
- `BEKLIYOR` Turkce/English localization ve uzun metin/layout QA.
- `BEKLIYOR` Offline ve zayif ag davranisi; queue/retry/clear error UX.
- `BEKLIYOR` Upgrade/migration ve eski backup restore matrisi.
- `BEKLIYOR` Uzun sureli soak, worker crash ve failure-injection kampanyasi.
- `BEKLIYOR` External metrics/dashboard/alerts ve audit retention.
- `BEKLIYOR` Gercek secret manager, certificate, domain, deploy ve rollback kabulü.
- `BEKLIYOR` Cloud relay ve production multi-user; local-first guvenlik korunarak.

## Bir Sonraki Oturumun Somut Paketi

1. (TAMAM 19 Temmuz) Source-control/secret hygiene ve geri donulebilir Git
   baseline; makbuz `docs/P0A-BASELINE-RECEIPT-2026-07-19.md`.
2. (TAMAM 19 Temmuz, P0-B) Gateway lifecycle install/receipt/reboot
   acceptance + provider probe; kanit `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md`.
3. (TAMAM 19 Temmuz) MCP `ENOBUFS`/teardown duzeltmesi ve baseline test/build
   tamamlandi (Sovereign commit `cf8c9e0`/`63fcc3b`); izole runtime smoke E2E de
   tamamlandi (commit `8d904a3`/`edf6393`/`5e07e02`, kanit `docs/VALIDATION.md`).
4. Hermes Electron icinde Sovereign UI + Control Plane lifecycle integration
   spike'i.
5. Tek uygulamadan `Sohbet -> Gorev -> Bilgisayar -> Devral -> Ajana ver ->
   Artifact` kullanici yolunun Playwright ve native screenshot kaniti.

Madde 4'un ilk gercek dilimi TAMAM/KISMI (20 Temmuz, ADR 0011): flag-gated
Sovereign rotasi + main-process service supervisor Hermes Electron shell'ine
baglandi; 44/44 unit + 16/16 renderer + izole acceptance 16/16 (0 orphan),
typecheck temiz. Guncelleme (26 Temmuz, ADR 0011): madde (a) authenticated urun
yuzeyi **local JSON dilimi icin TAMAM** - product host adapter stok control-plane'i
sararak authenticated surface'i auth bypass ETMEDEN bagladi (bootstrap/login izole
webview'de, `sovereign_session` cookie urun origin'inde; acceptance 50/50, gercek
supervisor owned(token)). Kalan durust acik kalemler:
(b) supervisor ownership'inin desktop restart'inda persist edilmesi (cross-session
adopt); (c) gercek paketlenmis/imzali Electron GUI E2E; (d) local JSON disina
cikip gercek worker/Temporal/Postgres/NATS/provider/computer yurutmesini birlesik
build'de kanitlamak; ardindan devral (takeover) restart dayanikliligi ve acik
guvenlik kapilariyla active-input kabulu.

Guncelleme (26 Temmuz r2, ADR 0011): product-host artik in-process (TEK
supervisor-owned pid hem urun 4312 hem ic API 4310 dinleyicisini sahiplenir;
grandchild yok - eski grandchild aciklamasi calisan kod icin gecersiz). Kok
launcher `scripts/start-hermes-sovereign-desktop.ps1` (+ sozlesme testi 43/43),
adapter uclusu minimal `extraResources` ile paketlenmemis resources dizinine
paketlendi (paket URETILMEDI) ve `sovereign-product-accept.mjs` in-process
mimariye gore yeniden yazildi (**53/53, 2x, 0 orphan**). Kalan (c) paketli/imzali
GUI E2E'ye ek olarak: launcher'in localhost bind'inin gercek GUI'de uctan uca
dogrulanmasi da BEKLIYOR (bugun sozlesme yapisal dogrulandi).

Bu paket tamamlanmadan yeni dekoratif UI veya genis entegrasyon listesine
dagilma.
