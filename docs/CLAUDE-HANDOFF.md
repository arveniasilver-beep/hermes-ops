# Claude Icin Ayrintili Proje Devir Belgesi

Son guncelleme: 18 Temmuz 2026  
Hazirlayan: Onceki teknik lider/Codex  
Kapsam: Hermes operasyon paketi, native Hermes Phase 8 ve Sovereign Agent Platform

## 1. Yonetici Ozeti

Bu projenin hedefi, Hermes'i biraz gelistirilmis bir sohbet arayuzu olarak sunmak
degildir. Kullanici; Manus benzeri gorunur calisma akisini, Claude benzeri sade
etkilesimi ve self-hosted bir sistemin denetimini birlestiren profesyonel bir
masaustu ajan platformu istiyor.

Ilk denemeler Hermes native uygulamasini profiller, operasyon paneli, scheduler,
human handoff, local browser takeover ve backup ile genisletti. Bu hat gercek ve
degerli olmakla birlikte, Hermes'i tum otorite yapmak urunu aracli bir chatbota
indirgedi. Bu nedenle daha genis `sovereign-agent` control-plane mimarisi ana
yurutme platformu olarak gelistirildi. Son karar: bu iki hatti yok edip sifirdan
baslamak degil; Sovereign'i canonical execution backend, Hermes'i kisitli worker
ve mevcut native shell'i tek masaustu urunu icin yeniden kullanilabilecek host
olarak birlestirmek.

17 Temmuz'da izole Sovereign build'i DeepSeek/MiMo routing, gercek web gorevi,
gercek Windows desktop capture ve aksiyon engelleyen insan devralma akisi ile
test edildi. Ancak bu yetenekler hala native Hermes paketinin icinde tek imzali
urun halinde degildir. 18 Temmuz devir aninda ilgili runtime servisleri kapaliydi.

## 2. Kullanici Hedefi ve Calisma Beklentisi

Kullanici su urun davranislarini bekliyor:

- **Sohbet modu:** normal, hizli, streaming AI sohbeti.
- **Gorev modu:** uzun isi planlayan, uzman worker'lara bolen, calisirken gorunen,
  durabilen/devam edebilen ve kanitli deliverable ureten kalici ajan.
- **Proje modu:** kalici talimat, dosya, knowledge, skill, konusma ve artifact
  baglami.
- **Gercek tarayici:** sayfa acma, okuma, kaynak toplama, login gerektiren oturumu
  kullanicidan guvenli devralma ve tekrar ajana verme.
- **Gercek bilgisayar:** Windows ekranini gorme, kontrollu UI Automation, canli
  goruntu ve kullanici takeover. Yalniz ekran resmi gosteren sahte devralma kabul
  edilmez.
- **Kod ve arastirma:** izole calisma alaninda kod uretme/test etme ve kaynakli
  arastirma sonucu.
- **Profesyonel guvenlik:** credentials modele verilmez; onaylar, least privilege,
  tenant izolasyonu, audit, redaction ve recovery gercek sinirlardir.
- **Dogruluk:** tamamlanmamis ozellik tamamlanmis gibi yazilmaz. UI animasyonu,
  fixture veya mock gercek capability diye sunulmaz.
- **Kullanim kolayligi:** ilk ekran landing page degil kullanilabilir urundur;
  teknik ayrinti ana akisi bogmaz.

Iletisim dili Turkcedir. Kullanici teknik liderin makul ve geri alinabilir
kararlari kendisi almasini, yalniz para, veri kaybi, production, hukuki risk ve
geri dondurulemez islemlerde onay istemesini bekliyor. Her ozelligin gercek
kullanici gibi test edilmesine ozel onem veriyor.

## 3. Kalici Calisma Alanlari

### 3.1 Hermes operasyon/kurulum deposu

`C:\Users\MSI\Documents\HERMESAGENT`

Icerik:

- upstream Hermes Agent `v0.18.2` icin yonetilen kaynak ve kurulum contract'i;
- native Electron Phase 8 patch/package calismalari;
- bes model profili, launch/repair/validate/backup scriptleri;
- mimari, guvenlik, routing, operasyon, validation ve ADR belgeleri;
- kaynak rollback arsivi.

Yonetilen kaynak: `runtime\hermes-agent`  
Kurulu fallback: `C:\Users\MSI\AppData\Local\hermes\hermes-agent`

Windows Application Control unsigned outer executable'i engelledigi icin managed
launcher guvenilir kurulu runtime'a fail-safe fallback yapar. Politika kesinlikle
zayiflatilmamalidir. Native Phase 8 signed release olarak iddia edilmez.

### 3.2 Sovereign ana urun kaynagi

`C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent`

Paket: `sovereign-agent-platform`, surum `1.0.0-rc.1`, pnpm `11.7.0`.  
Bu klasorde `.git` yoktur. Eski `HANDOFF.md` yaklasik 2.500 satirlik kronolojik
gunluk, `docs/MASTER-HANDOFF.md` 15 Temmuz ozetidir. Ikisi tarihsel kaynaktir;
18 Temmuz sonrasi guncel otorite HERMESAGENT altindaki bu devir setidir.

### 3.3 Kanit ve geri donus

- Kaynak arsivi:
  `C:\Users\MSI\Documents\HERMESAGENT\backups\sovereign-agent-source-20260717-015654.zip`
- Sovereign eski output alani:
  `C:\Users\MSI\Documents\Codex\2026-07-10\n\outputs`
- Son izole audit data alani:
  `C:\Users\MSI\Documents\HERMESAGENT\runtime\sovereign-audit-data`

Aktif servise arsiv restore etme. Once servisleri durdur, hedef yolu dogrula ve
mevcut verinin ayri backup'ini al.

## 4. Tarihce ve Yapilan Calismalar

### 4.1 Hermes native hat

Upstream Hermes icin bes izole profil kuruldu:

| Profil | Saglayici/model | Rol |
| --- | --- | --- |
| `owner-orchestrator` | Xiaomi `mimo-v2.5` | genel orkestrasyon |
| `owner-fast-worker` | DeepSeek `deepseek-v4-flash` | hizli/ucuz is |
| `owner-engineer` | DeepSeek `deepseek-v4-pro` | kod ve zor muhakeme |
| `owner-vision` | Xiaomi `mimo-v2.5` | goruntu |
| `owner-operator` | Xiaomi `mimo-v2.5-pro` | uzun/operasyonel is |

Native Phase 8'e sohbetler, history, dosya/proje/artifact, voice, settings,
profil degistirme, tool progress ve approvals yaninda su profesyonel yuzeyler
eklendi:

- Operations Kanban, task timeline ve run attempt'leri;
- pause/resume/cancel ve shared monthly spend guard;
- native scheduler/Cron ve run history;
- CAPTCHA/2FA/login icin durable `Needs you` handoff;
- local Chromium live view, pointer/keyboard takeover ve snapshot-gated resume;
- current-user Windows computer use;
- portable backup inspect/manifest/impact/restore ve otomatik pre-import backup.

Bu hat yerel browser devralma saglar; arbitrary Windows desktop devralma daha
sonra Sovereign web urununde yapildi.

### 4.2 Sovereign v1 release-candidate tabani

10-15 Temmuz arasinda TypeScript monorepo kuruldu ve asagidaki dilimler
tamamlandi:

- task/event/artifact/worker/policy contract'lari ve state machine;
- Fastify Control Plane, JSON gelistirme store'u ve PostgreSQL canonical store;
- Temporal workflow/activity, NATS JetStream live event ve SSE;
- research, coding, browser, computer, tool, Hermes ve MCP worker servisleri;
- planlama, deterministic fallback, verifier, retry ve follow-up;
- projects, versioned skills, Project Knowledge/retrieval;
- connector/tool/grant ve task-scoped MCP child task yolu;
- otomasyon compiler'i, schedule, overlap ve admission/concurrency politikasi;
- artifact version, SHA-256 integrity, export ve SeaweedFS replica contract'i;
- notifications/activity center ve merkezi approval inbox;
- canonical eval/benchmark ve calisma kalitesi yuzeyi;
- serbest streaming chat, reconnect, task promotion, rename/export/branch/
  archive/restore/delete yasam dongusu;
- auth/session/tenant/org, invitation/role, password recovery ve device sessions;
- TOTP, sanal/gercek WebAuthn passkey, recovery codes ve global MFA step-up;
- PostgreSQL RLS ve ayrik least-privilege `sovereign_app`/`sovereign_auth` rolleri;
- sifreli backup/verify/dry-run/restore ve service failure-recovery;
- production preflight, liveness/readiness, metrics auth, rate limit, security
  headers, Docker images ve sekiz kapili release acceptance.

Qwen ile gecici local-model deneyi yapildi fakat kullanici istegiyle urun
baglantisi, UI ve scriptleri kaldirildi. Diskte daha once var olan model agirligi
veri kaybi yaratmamak icin silinmedi. Qwen otomatik olarak yeniden baglanmamalidir.

15 Temmuz checkpoint'inde 110/110 test, 11/11 typecheck ve production build
gecmisti. Bu sayi 17 Temmuz yeni testlerden onceki release-candidate kanitidir.

### 4.3 16-17 Temmuz Sovereign execution dilimi

Kullanicinin `bu yalniz chatbot` geri bildirimi uzerine mimari ve capability
gercekligi yeniden denetlendi. Su degisiklikler uygulandi:

1. Worker health `degraded` ve `statusDetail` tasiyacak sekilde durustlestirildi;
   gercek planner olmayan computer fixture connected/tam capability gibi
   gosterilmedi. UI `Sinirli` durumu gosterebilir.
2. Dedicated loopback model gateway profilleri ayrildi:
   `8642` MiMo, `8643` DeepSeek, `8644` restricted Hermes. DeepSeek/MiMo
   profillerinden toolsets kaldirildi; Hermes yalniz izinli web/delegation ile
   sinirlandi.
3. Role routing DeepSeek planner/fast ve MiMo critic/vision/long-horizon
   davranisina baglandi. Canli DeepSeek chat ve MiMo review cagrilari token
   provenance ile kabul edildi.
4. Planner normalization eklendi: browser `startUrl` fallback'i, action alias,
   canonical worker ID, risk zorlamasi, unsupported capability rejection ve
   izole workspace'ler arasinda ise yaramayan bos code step budama.
5. `https://example.com/` uzerinde gercek public-web gorevi DeepSeek plan + MiMo
   review ile tamamlandi; uc evidence ve `research-result.json` uretildi.
6. Windows'ta Docker fixture yerine direct `cua-driver` provider eklendi.
   CUA Driver 0.8.2 UI Automation ve Windows Graphics Capture ile 1920x1080
   interaktif desktop'a baglandi. Read-only gorev sifir action/assertion, dort
   evidence ve uc artifact ile tamamlandi.
7. Computer control gate eklendi: ownership `agent | human`; worker
   `/desktop/frame`, control plane authenticated `/api/computer/status`,
   `/takeover`, `/release`, `/frame` proxy'leri; webde yeni `Bilgisayar` yuzeyi;
   `Devral` sonraki agent aksiyonunu bloke eder, `Ajana ver` devam izni verir.
8. Artifact PNG secimi ve authenticated preview duzeltildi.
9. System `Refresh` komutunun `/api/system` cagrisi yapmamasi duzeltildi.
   Browser worker etiketi `Playwright + optional Skyvern` olarak dogrulandi.
10. MCP Bridge varsayilan bind'i `0.0.0.0` yerine `127.0.0.1:4319` yapildi;
    container network bind ancak acik `MCP_BRIDGE_HOST` override'i ile mumkun.
11. Desktop ve mobile Playwright QA yapildi. 390 px'de 18 px nav overflow bulundu;
    redundant runtime badge mobilde gizlenerek sifirlandi.

Bu dilim sonunda 119/119 test, 11 proje typecheck ve production build gecti.

### 4.4 18 Temmuz devir ve hafiza sistemi

Mevcut iki kod tabani, eski handoff'lar, 17 Temmuz validation ve calisan portlar
capraz kontrol edildi. Bu `CLAUDE.md` + devir + project memory + roadmap + worklog
+ memory protocol sistemi yeni tek devir girisi olarak kuruldu. Servislerin o an
kapali oldugu kaydedildi; hicbir secret degeri okunmadi veya belgeye alinmadi.

## 5. Teknik Mimari

### 5.1 Ana cagri yolu

```text
React/Vite UI
  -> Fastify Control Plane
  -> Auth principal + tenant boundary
  -> Planner veya deterministic fallback
  -> Temporal durable workflow
  -> execution policy + admission + approval
  -> capability worker
  -> verifier
  -> artifact/evidence/provenance
  -> PostgreSQL canonical projection
  -> NATS/SSE live event -> UI
```

### 5.2 Monorepo bilesenleri

- `apps/control-plane`: API, auth, store, Temporal, planner, policy, approval,
  automation, chat, artifact, model router, health ve computer proxy.
- `apps/web`: React/Vite sohbet, gorev, approvals, notifications, files,
  automations, projects, skills, connectors, system ve Bilgisayar yuzeyleri.
- `packages/contracts`: ortak Zod/TypeScript task, event, worker, auth, policy,
  project, skill, connector, automation ve artifact sozlesmeleri.
- `packages/runtime-backup`: sifreli coordinated backup/restore araci.
- `workers/research-worker`: Fetch + Cheerio tabanli kaynakli web okuma.
- `workers/coding-worker`: OpenHands/Daytona/Docker izole kod calisma kontrati.
- `workers/browser-worker`: Playwright, optional Skyvern adapter.
- `workers/computer-worker`: CUA Windows provider, optional Agent-S/GUI-Owl
  planner, takeover gate ve frame endpoint'i.
- `workers/tool-worker`: grant/policy sinirli connector tool invocation.
- `workers/hermes-worker`: restricted Hermes Runs API.
- `workers/mcp-bridge`: task-scoped child task koprusu, loopback default.

### 5.3 Dayaniklilik ve veri

- Production: Temporal + PostgreSQL + NATS.
- Development fallback: local JSON; production crash recovery iddiasi tasimaz.
- Object artifact replica: SeaweedFS S3; konfigure degilse local artifact canonical
  kalir fakat replica gerektiren release gate bekler.
- Auth ve task verileri ayri rollerde, tenant claim ve RLS ile tutulur.
- Ham session/davet/recovery token'lari kalici store'a yazilmaz; hash veya
  sifrelenmis gerekli secret tutulur.

### 5.4 Model ve Hermes routing

Model workflow sahibi degildir; Control Plane rol ister. Son kabul mimarisi:

| Rol | Tercih edilen backend | Gateway/profile |
| --- | --- | --- |
| planner | DeepSeek Pro | `127.0.0.1:8643` / sovereign-deepseek |
| fast/chat | DeepSeek Flash/uygun DeepSeek | `127.0.0.1:8643` |
| critic/review | MiMo 2.5 | `127.0.0.1:8642` / sovereign-mimo |
| vision | MiMo 2.5 | `127.0.0.1:8642` |
| long-horizon | MiMo Pro veya restricted Hermes | role policy'ye gore |
| wide research | Hermes | `127.0.0.1:8644` / sovereign-hermes |

Credential'lar local `.env`/profile alaninda kalir; dokumana, task prompt'una,
event'e veya artifact'a kopyalanmaz. Provider health her yeni runtime'da canli
probe ile yeniden kanitlanir.

**18 Temmuz mevcut-konfigurasyon notu:** Uc `sovereign-*` profil dizini diskte
mevcuttur, fakat Sovereign `.env` yalniz DeepSeek `8643` endpoint'ini ve
`sovereign-deepseek` planner/fast modellerini kalici olarak tanimlar. MiMo `8642`
ve restricted Hermes `8644` icin repoda idempotent start/stop/status scripti
yoktur. Tablo 17 Temmuz kabul topolojisini anlatir; makine yeniden basladiginda
otomatik olarak ayni topolojinin kurulacagini iddia etmez.

### 5.5 Portlar

Normal development varsayimlari:

| Servis | Port |
| --- | ---: |
| Control Plane | 4310 |
| Research Worker | 4311 |
| Web UI | 4312 |
| Coding Worker | 4314 |
| Browser Worker | 4315 |
| Computer Worker | 4316 |
| Tool Worker | 4317 |
| Hermes Worker | 4318 |
| MCP Bridge | 4319 |
| PostgreSQL | 5432 |
| Temporal / UI | 7233 / 8233 |
| NATS / monitoring | 4222 / 8222 |
| SeaweedFS S3 / master | 8333 / 9333 |
| Bifrost | 8088 |
| MiMo / DeepSeek / Hermes gateway | 8642 / 8643 / 8644 |

17 Temmuz izole audit runtime'i API `4320`, web `4321` kullandi. 18 Temmuz devir
aninda bu portlarin hicbiri dinlemiyordu. Port varligi tek basina health kaniti
degildir; `/health`, `/readyz` ve worker capability response'larini da kontrol et.

## 6. Temel Mimari Kararlar ve Gerekceleri

1. **Hermes tum urun degil.** Reasoning ile yetki/yurutme/recovery ayni process'e
   konursa sistem buyuk bir aracli chatbot olur. Bu nedenle Sovereign Control
   Plane tek otoritedir.
2. **Capability bazli worker.** Browser, computer, code, research ve tool farkli
   blast radius, runtime ve approval kurallarina sahiptir.
3. **Durable production workflow Temporal.** JSON store yalniz hizli local
   gelistirme icindir; restart dayanikliligi gibi sunulamaz.
4. **Kanita dayali tamamlanma.** Worker cevabi tek basina basari sayilmaz;
   verifier, artifact/evidence ve provenance gerekir.
5. **Playwright deterministik taban.** Browser Use gelecekte dogal/visual
   escalation; Skyvern AGPL-3.0 ve default telemetry nedeniyle optional/kapali.
6. **CUA Windows birincil host executor.** UI Automation + Windows Graphics
   Capture cursor calmayabilir ve inspect-first akisa uygundur. Agent-S yalniz
   strict action schema arkasinda optional planner olabilir.
7. **OpenHands kod backend'i.** MIT SDK/Agent Server izole workspace icin uygun;
   model-driven canli kabul tamamlanmadan capability tam sayilmaz.
8. **Insan takeover gercek execution lock'tur.** UI toggle degildir; `human`
   ownership varken worker yeni agent aksiyonunu reddeder/bloke eder.
9. **Local-first ve loopback default.** Computer frame/control ve MCP Bridge
   dogrudan LAN'a acilmaz; UI authenticated Control Plane proxy'sini kullanir.
10. **Tek urun hedefi, kontrollu entegrasyon.** Iki calisan hatti bir anda yeniden
    yazmak yerine Sovereign backend + mevcut native shell uzerinde ince spike,
    acceptance ve rollback ile birlestirmek en dusuk riskli yoldur.

Ilgili ADR'ler `docs/decisions/0001`-`0009` arasindadir. `0009` guncel ana
mimari karardir.

## 7. Kanitlanmis Ozellik Matrisi

| Alan | Durum | Kanit/Not |
| --- | --- | --- |
| Streaming chat ve lifecycle | Tamamlandi | JSON + PostgreSQL/Temporal E2E |
| Durable task/plan/event | Tamamlandi | unit, worker contract, durable E2E |
| Auth/org/MFA/step-up | Tamamlandi | durable DB ve UI E2E |
| Approval/policy/budget | Tamamlandi | concurrency ve schedule acceptance |
| Artifact/evidence/export | Tamamlandi | integrity/version/export tests |
| Backup/restore/recovery | Tamamlandi | encrypted isolated E2E |
| DeepSeek/MiMo routing | Canli yerel kabul | 17 Temmuz dedicated profiles |
| Public web task | Canli kabul | example.com + JSON artifact |
| Windows read-only inspect | Canli kabul | CUA 1920x1080 + evidence |
| Human computer takeover gate | Canli kabul | UI + next-action block test |
| Native Hermes Operations | Phase 8 kabul | signed release degil |
| Browser Use | Bekliyor | adapter ve auth-session E2E yok |
| Agent-S/GUI-Owl live action | Bekliyor | contract var, live acceptance yok |
| OpenHands model-driven coding | Bekliyor | backend contract var, live acceptance yok |
| Etkili Windows write/input | Bekliyor | approval-gated live acceptance yok |
| Tek native Sovereign paketi | Bekliyor | iki yuzey henuz ayri |

## 8. Guvenlik Degismezleri

- Model ve worker ham credential goremez; origin-bound grant veya kisitli proxy
  kullanir.
- Unsafe web/API islemleri auth principal, tenant, policy ve gerekli approval'dan
  gecmelidir.
- External write, publish, payment, mouse/keyboard ve benzeri etkili bilgisayar
  aksiyonlari default-deny/onaylidir.
- Takeover ownership `human` iken agent aksiyonu calismaz.
- Computer/MCP worker loopback'tir; UI authenticated Control Plane proxy'sini
  kullanir.
- Host `sensitiveRegions` redaction uygulanana kadar fail-closed.
- Main database'e test kullanicisi veya credential yazma; izole data dir/DB kullan.
- Backup restore'da path traversal, manifest/hash/HMAC/GCM ve dry-run kontrolu
  atlanmaz.
- Windows Application Control, MFA, RLS, rate limit veya approval kolaylik icin
  kapatilmaz.
- Log, belge ve screenshot'ta secret/token/redacted veri sizintisi aranir.

## 9. Bilinen Sorunlar ve Yari Kalan Isler

### Kritik urun butunlugu

- Native Hermes ile Sovereign tek uygulama degildir. Kullanici `kos koca Hermes
  var ama chatbottan ibaret` tepkisini tam olarak bu kopukluk nedeniyle verdi.
- Sovereign kaynak kodu version control altinda degildir. Once backup ve secret
  taramasi, sonra duzenli Git tabani gerekir.
- HERMES deposunda 18 Temmuz denetiminde once 6.303 dosya untracked bulundu.
  Audit data/backups/gateway log alani ignore edilince 6.205 kaynak/kontrol
  dosyasi kaldi. `.git` ve dogmamis `master` dal adi vardir, fakat `HEAD`/ilk
  commit yoktur.
- Dedicated MiMo/DeepSeek/Hermes gateway kabul topolojisinin yeniden
  uretilebilir lifecycle scripti yoktur; mevcut `.env` yalniz DeepSeek'i kalici
  baglar.
- Birlesik native build icin full Temporal/PostgreSQL/NATS failure/recovery ve
  signed installer acceptance yapilmadi.

### Computer/browser/code gercekligi

- Takeover owner state in-memory; worker restart'inda kaybolur.
- Frame akisi 2 saniye PNG polling; input latency/streaming olculmedi.
- Current-user desktop izole degil. PII ve hassas pencere riskleri vardir.
- Read-only inspect kabul edildi; onayli click/type/write icin disposable test app
  E2E yok.
- Browser Use yok; authenticated browser session, CAPTCHA/2FA handoff Sovereign
  yolunda kabul edilmedi. Native Hermes local browser handoff ayri hatta var.
- Agent-S/GUI-Owl, Skyvern ve model-driven OpenHands canli capability degil.
- MCP Bridge contract testi Windows `ENOBUFS` kosulunda fail olur ve erken hata
  yolunda sabit `4601` listener/process'ini birakabilir. Test fixture'i her hata
  yolunda kapanmali ve socket stratejisi deterministik olmalidir.

### Urun ve operasyon

- Semantic multi-model routing tek live chat turn'unda tam UX olarak yok.
- Project export/import ve kullanici kontrollu sifreli memory yok.
- Provider invoice import/reconciliation yok; maliyetler tahmindir.
- Signed installer/update ve guvenli auto-update yok.
- Accessibility, localization, offline, failure-injection, upgrade ve uzun sureli
  soak testleri eksik.
- Cloud relay, multi-user production deploy, external alert/dashboard ve gercek
  secret manager/certificate/rollback acceptance bekliyor.

## 10. Claude Icin Onerilen Devam Sirasi

### Asama 0 - Baseline'i koru ve yeniden kanitla

1. Her iki yolun varligini, disk boslugunu ve backup arsivini kontrol et.
2. Secret degerlerini basmadan `.env` anahtar adlari/config preflight yap.
3. Sovereign'de `pnpm install --frozen-lockfile` yalniz dependency eksikse;
   ardindan `pnpm typecheck`, `pnpm test`, `pnpm build`.
4. Izole data dir ve cakismayan portlarla runtime ac; health/readiness'i kaydet.
5. Chat, public web task, Bilgisayar frame/devral/geri ver, artifact preview/export
   icin Playwright smoke E2E yap. Gercek etkili input kullanma.
6. Source snapshot ve secret scan sonrasinda Git baselining oner; kullanici verisi
   veya `.env` commitlenmesin.

### Asama 1 - Tek urun entegrasyonu

1. Sovereign web UI + authenticated Control Plane'i mevcut Hermes Electron
   shell'inde ince bir integration spike olarak ac.
2. Child service lifecycle, port allocation, profile/data path, shutdown ve crash
   recovery'yi native host'ta yonet.
3. Native Hermes'in calisan sohbet/scheduler/handoff yuzeylerini hemen silme;
   duplicate navigasyonu feature flag ile kademeli birlestir.
4. Ilk kabul: tek executable'dan chat + durable task + real computer live view +
   takeover + artifact indirme.
5. Spike kanitlaninca signed package/update ve rollback acceptance'a gec.

### Asama 2 - Execution capability'lerini tamamla

1. Takeover state'ini PostgreSQL/Temporal'a tasiyip restart acceptance yap.
2. PNG polling'i authenticated low-latency stream'e cevir; ownership arbitration
   ve reconnect testleri ekle.
3. Disposable test uygulamasinda approval-gated CUA click/type/save E2E yap.
4. Browser Use adapter + authenticated profile + CAPTCHA/2FA handoff acceptance.
5. OpenHands model-driven coding E2E: repo patch, test, diff artifact, approval.
6. Agent-S ancak strict action schema, approval ve verifier ile canli kabul edilirse
   optional planner olarak acilsin.

### Asama 3 - Ticari kalite

Durable memory controls, project import/export, invoice reconciliation, signed
updates, accessibility/localization, offline/upgrade/failure/soak testleri,
observability ve production secret/certificate/rollback acceptance.

## 11. Baslatma ve Dogrulama Notlari

Sovereign ana scriptleri `package.json` icindedir:

```powershell
pnpm runtime:up
pnpm runtime:status
pnpm runtime:down
pnpm dev
pnpm dev:durable
pnpm typecheck
pnpm test
pnpm build
pnpm acceptance:release
```

Komutlari korlemesine calistirma: `package.json`, `.env.example`, README ve aktif
portlari once oku. `runtime:down` volume silmemelidir; yine de gercek komutu
incelemeden calistirma. Izole QA icin ana kullanici data dir'i yerine ayrik data
dir/DB kullan.

## 12. Devirde Korunacak Kaynaklar

- HERMESAGENT `docs/VALIDATION.md`: native Phase 3-8 ve 17 Temmuz execution kaniti.
- `docs/decisions/0001`-`0009`: mimari karar zinciri.
- Sovereign `HANDOFF.md`: ayrintili 10-15 Temmuz kronolojisi.
- Sovereign `docs/MASTER-HANDOFF.md`: 15 Temmuz release-candidate snapshot'i.
- Sovereign `docs/ORIGINAL-VISION.md`: kullanici vizyonunun kalici kopyasi.
- Sovereign `docs/ARCHITECTURE.md`: capability ve cagri yollari.
- HERMES source backup ZIP: 17 Temmuz rollback noktasi.
- `docs/history/original-prompts/`: dort uzun orijinal kullanici promptunun
  SHA-256 kayitli, secret taramasindan gecmis kalici arsivi.

Eski belgeleri silme. Guncel olmadiklarini ust notla belirt ve yeni calismayi bu
hafiza sistemine isle.

## 13. Devir Sonu Kesin Hukum

Proje sifirdan baslanacak bir fikir degil. Ciddi miktarda calisan control-plane,
auth, durability, worker, UI, backup ve acceptance altyapisi vardir. Ayni zamanda
bitmis ticari masaustu urunu de degildir. En buyuk eksik yeni bir ozellik listesi
degil, kanitlanmis Sovereign execution katmanini tek guvenilir native urune
donusturmek ve computer/browser/code capability'lerini canli, approval-gated ve
restart-dayanikli hale getirmektir.

Claude bu gercegi koruyarak devam etmelidir: mevcut calisan sistemi yeniden
yazma, Hermes'i yeniden tek otorite yapma, fixture'i gercek capability diye
sunma ve test kaniti olmadan `tamamlandi` deme.
