# Calisma Gunlugu

Bu dosya append-only kronolojik ozet kaydidir. Ayrintili 10-15 Temmuz gunlugu
Sovereign kaynak kokundeki `HANDOFF.md` icindedir. Eski kayitlari silme veya
sessizce yeniden yazma; duzeltme gerekiyorsa yeni tarihli bir not ekle.

## 10-15 Temmuz 2026 - Sovereign v1.0.0-rc.1 tabani

- TypeScript/pnpm monorepo, Fastify Control Plane, React/Vite UI, capability
  worker'lar, Temporal/PostgreSQL/NATS durable hat kuruldu.
- Task, chat, project/skill/knowledge, automation, approval, notification,
  artifact, evaluation, auth/org/MFA, backup/recovery ve release gate dilimleri
  tamamlandi.
- Qwen gecici deneyi kaldirildi; DeepSeek canli streaming rotasi kabul edildi.
- Son checkpoint: 110 test, 11 workspace typecheck ve production build gecti.
- Ayrintilar: Sovereign `HANDOFF.md` ve `docs/MASTER-HANDOFF.md`.

## 16-17 Temmuz 2026 - Gercek execution ve takeover

- Hermes'in tek urun otoritesi olmadigi, restricted reasoning worker olacagi
  ADR 0009 ile kesinlestirildi.
- Dedicated DeepSeek/MiMo/Hermes gateway profilleri ve rol bazli routing
  uygulandi; canli model cagrilari token provenance ile test edildi.
- Planner normalization ve unsupported capability rejection eklendi.
- Gercek public web task'i evidence ve JSON artifact ile tamamlandi.
- Windows Computer Worker direct CUA Driver 0.8.2'ye baglandi; gercek 1920x1080
  read-only desktop acceptance yapildi.
- Authenticated Bilgisayar UI, frame proxy, `agent | human` control gate,
  Devral/Ajana ver akisi ve action-block testi eklendi.
- PNG artifact preview, System Refresh ve mobil overflow duzeltildi.
- MCP Bridge default bind loopback yapildi.
- Dogrulama: 119 test, 0 hata; 11 proje typecheck; production build; desktop ve
  mobile browser QA.
- Rollback: `backups/sovereign-agent-source-20260717-015654.zip`.

## 18 Temmuz 2026 - Claude devir ve kalici hafiza

- Hermes ve Sovereign klasorleri, eski handoff'lar, ADR 0009, Product Status ve
  17 Temmuz Validation capraz kontrol edildi.
- Runtime port snapshot'i alindi: 4310-4319, 4320-4321 ve 8642-8644 dinlemiyordu;
  uygulama devir aninda kapali olarak kaydedildi.
- `CLAUDE.md`, `PROJECT_MEMORY.md`, `CLAUDE-HANDOFF.md`, `ROADMAP.md`, bu worklog ve
  `MEMORY-PROTOCOL.md` ile katmanli devir sistemi kuruldu.
- Otomatik `CLAUDE.md` okumayan Claude yuzeyleri icin tek seferlik
  `CLAUDE-START-PROMPT.md` eklendi.
- Codex'in gecici attachment alanindaki dort ana kullanici promptu yaygin secret
  desenleriyle tarandi, eslesme bulunmadi ve SHA-256 indeksli olarak
  `docs/history/original-prompts/` altina arsivlendi.
- Sovereign eski handoff belgeleri tarihsel kanit olarak korundu ve guncel
  otoriteye yonlendirildi.
- Bu calisma kod davranisini degistirmedi; test/build yeniden calistirilmadi.
  Belge iceriginde secret/API key degeri bulunmuyor.

## 18 Temmuz 2026 - Uctan uca devir denetimi

- Devir iddialari kaynak kod, profil dizinleri, `.env` anahtar adlari, portlar,
  backup ve Git gorunurluguyle capraz kontrol edildi.
- TypeScript 11 proje icin gecti; routing-report testi `1 passed` verdi.
- Full test MCP Bridge'de Windows `ENOBUFS` nedeniyle tamamlanamadi. Erken hata
  sabit 4601 listener/process'ini birakti; hedefli olarak temizlendi.
- Build tekrari yeni sandbox politikasinda external Sovereign kaynagina `EPERM`
  nedeniyle calisamadi. Docker ve butun urun listener'lari kapaliydi.
- Uc `sovereign-*` profil diskte mevcut; kalici Sovereign `.env` yalniz DeepSeek
  8643'u tanimliyor. MiMo/Hermes gateway lifecycle scripti eksik bulundu.
- HERMES'te 6.303 untracked dosya bulundu. `backups/`, audit data, gateway state
  ve runtime screenshot'lari `.gitignore` ile commit riskinden cikarildi.
- README devir girisi, ADR 0009 linki, Project Memory, Roadmap, Handoff ve
  Validation gercek denetim sonucuyla guncellendi.
- Ayrintili bulgular `docs/AUDIT-2026-07-18.md` icindedir. Uygulama kaynak kodu
  degistirilmedi; dosya stage/commit edilmedi.

## 18 Temmuz 2026 - Claude Code eksiksiz master devir

- Kullanıcının dört özgün ana promptu, eski Sovereign handoff'ları, ADR zinciri,
  Product Status, Security, Routing, Validation ve son audit yeniden tarandı.
- Ürün vizyonu, kullanıcının çalışma biçimi, teknik lider yetkisi, onay sınırları,
  geçmiş yanlış anlaşılma, iki kod tabanı, bütün ana özellikler, model routing,
  güvenlik, test geçmişi ve kesin devam sırası tek kapsamlı
  `docs/CLAUDE-CODE-MASTER-HANDOFF.md` kitabında birleştirildi.
- Aynı makine ve başka makine/Cloud taşıma senaryoları için
  `docs/CLAUDE-CODE-TRANSFER-CHECKLIST.md` eklendi. İki kaynak ağacının birlikte
  taşınması ve AppData/secret/audit verisinin taşınmaması açıkça kaydedildi.
- Kök `CLAUDE.md`, başlangıç promptu, README, Project Memory ve Memory Protocol
  yeni master belgeye bağlandı.
- Uygulama kaynak kodu veya kullanıcı verisi değiştirilmedi; stage/commit yapılmadı.

## 18 Temmuz 2026 - Manus ve acik model arastirma gorevi

- Claude'un yalniz mevcut devir bilgisini kullanmasi yeterli gorulmedi; resmi
  Manus dokumantasyonunu kendisinin yenilemesi zorunlu hale getirildi.
- Browser Operator, Cloud Browser, My Computer, local terminal/dosya izni,
  takeover, canli gorev ve artifact davranislari icin tarihli gap analizi ciktisi
  tanimlandi.
- MiMo-V2-Flash, DeepSeek-V4 Flash/Pro, Qwen3-Coder-Next, GLM-5.2, Kimi-K2.5 ve
  kucuk local modeller resmi kaynaklardan aday snapshot'ina alindi; tek bir
  model `en iyi` ilan edilmedi.
- Acik kaynak/acik agirlik/acik API ayrimi, lisans/revision kaydi ve Hermes'e ozel
  coding/planning/research/browser/vision/Turkce/safety eval receipt'i zorunlu oldu.
- `CLAUDE.md`, master devir, baslangic promptu, Project Memory, Roadmap ve Memory
  Protocol yeni arastirma talimatina baglandi. Uygulama kodu ve runtime degismedi;
  ucretli model cagrisi, stage veya commit yapilmadi.

## 18 Temmuz 2026 - Model kapsami duzeltmesi

- Onceki arastirma notunun Qwen/GLM/Kimi'yi aktif secim adayi gibi gostermesi
  kullanicinin daha once verdigi kararla celisiyordu.
- Aktif model karari yeniden kesinlestirildi: urun yalniz MiMo ve DeepSeek
  kullanacak; eval bu iki aile icindeki varyant ve rol dagilimini belirleyecek.
- Diger acik modeller yalniz bilgi/teknoloji takibi olarak tutulacak; kullanici
  acikca istemeden entegrasyon, satin alma, routing veya replacement yapilmayacak.
- Claude baslangic talimati, master handoff, Project Memory, Roadmap ve arastirma
  belgesi bu sinira gore duzeltildi. Kod/runtime degismedi.

## 19 Temmuz 2026 - Claude Code canli devir

- Claude Code 2.1.206 kurulumu ve Anthropic oturumu dogrulandi.
- `HERMES resmi devir` adli salt-okunur oturumda Claude'a yalniz Read/Glob/Grep
  verildi; edit/write/bash ve proje runtime degisiklikleri kapatildi.
- Claude master handoff, Project Memory, Audit, Roadmap, Validation, Worklog,
  Memory Protocol, research talimati, ADR'ler ve Sovereign tarihsel handoff'larini
  capraz kontrol etti.
- Urun hedefi, kullanici beklentisi, iki kod tabani, 17/18 Temmuz kanit ayrimi,
  yalniz MiMo + DeepSeek karari, Manus siniri ve P0 sirasi dogru geri anlatildi.
- Claude sonucu `DEVIR_KABULU: TAM` olarak verdi. Ayrintili makbuz
  `docs/CLAUDE-TAKEOVER-RECEIPT-2026-07-19.md` icindedir.
- Kod/config/runtime degismedi; servis veya proje model gateway'i baslatilmadi.
- Claude Desktop Code arayuzunun `C:` kokundeki eski oturumlari gosterdigi fark
  edildi. Local proje `HERMESAGENT` olarak secildi ve solda gorunen
  `HERMES resmi devri` oturumu olusturuldu.
- Masaustu oturumu yedi ana belgeyi okuyup iki kaynak agacini dogruladi; ikinci
  kez `DEVIR_KABULU: TAM` sonucu verdi.

## 19 Temmuz 2026 - Claude derin ogretim ve icra sozlesmesi

- Gorunur `HERMES resmi devri` oturumunda master devir, dort ozgun prompt, ADR
  0001-0009, urun/guvenlik/routing/test belgeleri, eski handoff'lar ve iki kaynak
  agacinin package/worker yapisi derin salt-okunur capraz incelendi.
- Claude kullanici niyeti, urun ilkeleri, ozellik matrisi, mimari ownership,
  MiMo+DeepSeek siniri, Manus/acik kaynak plani, guvenlik/onay sinirlari, UX,
  kabul matrisi, P0-P3, riskler ve ilk uygulama dizisini 12 bolumde geri anlatti.
- Sonuc `OGRETIM_TAM: EVET` oldu; kod/config degistirilmedi ve servis acma/kapama
  yapilmadi.
- `scripts/sovereign-gateways.ps1` dosyasinin uc profil icin idempotent
  `status|start|stop` uyguladigi bulundu. Codex status olcumunde 8642/8643/8644
  loopback route'larinin her biri `HTTP 200` verdi.
- Ayni snapshot'ta Docker Desktop acik, 4310-4321 urun servisleri kapaliydi.
  Install/service receipt ve reboot acceptance olmadigi icin gateway lifecycle
  tamamlanmis sayilmadi.
- Bayat current-state kayitlari duzeltildi ve
  `docs/CLAUDE-CODE-EXECUTION-CHARTER.md` baglayici icra sozlesmesi eklendi.
- Claude guncel charter/memory/roadmap/makbuzu yeniden okuyup dort kesin karari
  teyit etti; `Eksik baglam: Yok` ve `BASLAMAYA_HAZIR: EVET` sonucunu verdi.
- P0-A on olcumunde Sovereign kaynak yolundaki onceki `EPERM` yazma kosulu tekrar
  kontrol edilecek; calisma sirasi degismedi.

## 19 Temmuz 2026 - P0-A kontrollu Git/veri baseline uygulamasi

- Rol kurali kalicilastirildi: bagimsiz itiraz/`BAGIMSIZ_INCELEME` kurali kok
  `CLAUDE.md` ve `docs/CLAUDE-CODE-EXECUTION-CHARTER.md` (bolum 9) icine yazildi.
- On olcumler: Sovereign yazma probu gecti (EPERM yok); system gitconfig
  `core.autocrlf=true` iki repoda repo-lokal `false` + `* -text`
  `.gitattributes` ile etkisizlestirildi; `core.longpaths=true`; global Git
  kimligi mevcut oldugu icin commit izni kullanildi.
- HERMESAGENT: explicit pathspec allowlist ile 6.212 dosya stage edildi; yasak
  ad/dizin taramalari bos; secret-sekilli eslesmeler maskeli incelemeyle yalniz
  upstream placeholder/fixture sinifinda dogrulandi. Ilk commit `152bf9a`,
  annotated tag `baseline-hermes-20260719`.
- Sovereign: `.gitignore` sertlestirildi (data/qa/log/pid/tsbuildinfo/komut
  artigi; env varyantlari; iki env-example istisnasi), `git init -b master`,
  220 dosya allowlist ile stage edildi, 8/8 `check-ignore` kaniti gecti. Ilk
  commit `9ca47c7`, annotated tag `baseline-sovereign-20260719`.
- QA uretilmis PNG/log kanitlari sentetik recovery/secret benzeri degerler
  tasiyabildigi icin bilincli olarak commit disi birakildi; kanitlar diskte ve
  bundle'da korunuyor.
- Rollback: `backups/` altina `sovereign-baseline-20260719.bundle` ve
  `hermes-baseline-20260719.bundle` yazildi; ayrintili makbuz
  `docs/P0A-BASELINE-RECEIPT-2026-07-19.md` icindedir.
- Bu turda servis/model cagrisi yapilmadi, remote/push yok, dosya silinmedi,
  secret degeri okunmadi/basilmadi. Test/typecheck/build kosulmadi (P0-C
  kapsaminda).

## 19 Temmuz 2026 - P0-A Codex review duzeltmeleri

- Codex salt-okunur review'i uc bulgu verdi; ucu de kabul edildi ve duzeltildi.
- (1) Orijinal HERMES bundle'inda `--all` nedeniyle beklenmeyen
  `refs/codex/turn-diffs/checkpoints/...` ref'i vardi. Iki repo icin de yalniz
  `HEAD + master + kendi annotated baseline tag'i` tasiyan canonical bundle'lar
  uretildi (`*-canonical.bundle`); `git bundle verify` her ikisinde `complete
  history` verdi. Eski bundle dosyalari silinmedi; canonical surumler esastir.
- (2) Onceki kayitlardaki `kanitlar disk + bundle uzerinde korunur` ifadesi
  yanlisti: Git bundle yalniz tracked source/history tasir; ignored/untracked
  QA PNG kanitlari bundle'da DEGILDIR. Dogrusu: QA PNG kanitlari yalniz mevcut
  yerel diskte korunur; 17 Temmuz ZIP kapsami bu kanitlar icin dogrulanmadi ve
  iddia edilmez. Receipt ve Validation buna gore duzeltildi; ayni hatali ifade
  Sovereign `.gitignore` yorum satirinda da vardir ve bir sonraki Sovereign
  dilimindeki commit'te duzeltilecektir.
- (3) Receipt'teki global Git kimlik degeri belgeden kaldirildi; yalniz `global
  kimlik mevcut ve kullanildi; commit author metadata remote oncesi privacy
  review gerektirir` kaydi birakildi. Kimlik degeri commit author metadata'sinda,
  receipt'in git gecmisindeki ilk surumunde ve eski bundle'larda kalir; history
  rewrite bilincli olarak yapilmadi (commit/tag tasima yasagi) ve push oncesi
  privacy review zorunlulugu kayda gecirildi.
- Canonical bundle SHA-256 ve ref listeleri
  `docs/P0A-BASELINE-RECEIPT-2026-07-19.md` bolum 9'dadir. Commit hash'leri ve
  tag hedefleri degistirilmedi; servis/model cagrisi ve dosya silme yok.

## 19 Temmuz 2026 - P0-B Faz 1: gateway lifecycle servisi

- ADR 0010 kabul edildi: uc sovereign gateway icin per-user Scheduled Task
  mimarisi (logon tetik, Limited run level, admin/policy degisikligi yok,
  task action'inda secret yok). Windows Service ve NSSM reddedildi.
- `scripts/sovereign-gateway-service.ps1` yazildi:
  `plan|install|status|start|stop|uninstall`; varsayilan DRY-RUN, gercek
  mutasyon yalniz `-Execute` + ShouldProcess onayi; tek process snapshot,
  launcher-child agaci, stale PID karsilastirmasi, FOREIGN/NONLOOPBACK
  fail-closed, profil kapsamli stop (`--all` yasak), redacted JSON receipt.
- `tests/test_sovereign_gateway_service.ps1` mock paketi: 40/40 gecti. Ilk
  kosuda 1 gercek bug yakalandi: .NET regex IgnoreCase current-culture ile
  katladigi icin Turkce locale'de `API_KEY` redaction'i kaciyordu
  (buyuk I / noktasiz i); `RegexOptions.CultureInvariant` ile duzeltildi.
- Parser kontrolu 3 script icin temiz; PSScriptAnalyzer kurulu degil ve yeni
  bagimlilik bilincli olarak eklenmedi.
- Guvenli canli read-only status olculdu (mutasyonsuz): 3x RUNNING,
  loopback-only, HTTP 200, uclu process agaclari, stale yok, task kurulu
  degil (beklenen). Redacted receipt runtime/receipts altinda.
- Bu turda gercek task install/uninstall, gateway stop/start, reboot, yeni
  listener, ucretli provider cagrisi, remote/push ve dosya silme YAPILMADI
  (testin kendi TEMP calisma klasoru haric). Install/reboot kabulu Faz 2'de
  kullanici onayina baglidir.

## 19 Temmuz 2026 - P0-B Faz 1 Codex review duzeltmeleri (r2)

- Codex'in alti bulgusu da kabul edildi ve uygulandi: (1) FOREIGN_TASK
  sahiplik kaniti - dedicated `\Sovereign\` TaskPath + Description ownership
  marker + current-user principal + tam action/trigger/RunLevel dogrulamasi;
  kanitsiz ayni isimli task fail-closed, install/uninstall'da 0 mutasyon,
  farkli path'teki ayni isimli task'a hicbir kosulda dokunulmaz. (2) Receipt
  v1.1 gercegi: requested/whatIf/applied/declined/failed/effectiveDryRun +
  adim sonuclari; -WhatIf/ShouldProcess reddi declined; hata yolu da redacted
  receipt birakir; dosya adi UTC-ms+nonce. (3) Stale kiyasi yalniz treePids
  tasiyan en yeni GECERLI gozlem receipt'inden; plan/install/bozuk receipt
  atlanir. (4) Process kimligi token-level: exact `-p <profil>`/`--profile` +
  ardisik `gateway run`; decoy substring launcher sayilmaz. (5) Health probe
  secretsiz; authenticated probe ayri tasarim/onay konusu olarak BLOKE.
  (6) NONLOOPBACK: start fail-closed, stop yalniz kanitli exact-owned tree
  uzerinde containment-stop olarak etiketli.
- Mock paketi 70/70 gecti; execute akisi sahte ShouldProcess + wrapper-log ile
  olculdu (mutasyon hedefleri, execute-mode kaniti, declined/failed kayitlari).
  Testler uc gercek bug daha yakaladi ve duzeltildi: PS 5.1 `@(komut)` cift
  paketleme (`,()` idiomu) ve `@()`+List[object] ArgumentException; onceki
  turdan tr-TR IgnoreCase dersi korunarak CultureInvariant kullanildi.
- Canli read-only status (secretsiz probe): 3x RUNNING, loopback-only,
  HTTP 200, schema 1.1 redacted receipt; gercek cmdline'larda token-matcher
  ayni uc process agacini dogruladi.
- Bu turda da gercek install/uninstall/start/stop/reboot, yeni listener,
  provider/model cagrisi, remote/push ve dosya silme yapilmadi; b4c25a0
  rewrite edilmedi, baseline tag'leri oynatilmadi.

## 19 Temmuz 2026 - P0-B Faz 1 ikinci review duzeltmeleri (r3)

- Codex'in bes yeni bulgusu da kabul edildi ve uygulandi:
  (1) START SAHIPLIK BYPASS kapatildi: start yalniz IdentityOwned VE
  ConfigMatches task'i exact TaskPath ile baslatir; dedicated path'te
  foreign/drift task varken start fail-closed (0 mutasyon); task hic yoksa
  dogrudan Start-Process fallback'i BILINCLI davranis olarak ADR'de ve
  receipt'te `start-direct` etiketiyle tanimlandi; farkli path'teki ayni
  isimli task asla baslatilmaz.
  (2) RECREATE bagimliligi: register yalniz unregister adimi APPLIED ise
  calisir; declined/failed durumunda register atlanir ve step log
  skipped/failed gercegini yazar (kuyruklu sahte ShouldProcess ve firlatan
  wrapper testleriyle).
  (3) RECEIPT agregat gercegi: toplam sonuc step log'dan turetilir
  (fail-closed > failed > declined > ok), acik applied/declined/failed
  boolean'lari eklendi; receipt yazimi .NET FileMode.CreateNew ile atomik ve
  -WhatIf'ten bagimsiz; GERCEK dispatcher testiyle -Execute -WhatIf altinda
  receipt dosyasinin yazildigi ve \Sovereign\ task sayisinin degismedigi
  kanitlandi; -Execute + -NoReceipt audit bypass'i reddedilir ve zorunlu
  refusal receipt yazilir.
  (4) TASK TAM ALAN DOGRULAMA: ActionCount=1, TriggerCount=1, trigger
  enabled, trigger-user SID, LogonType ve RunLevel dogrulanir; principal
  SID-canonical kiyaslanir (NTAccount->SID; cevrilemeyen fail-closed; ayni
  kullanici adli farkli domain/SID FOREIGN). Register explicit current-user
  principal (Interactive, Limited) ve -AtLogOn -User ile yazildi (canli
  register Faz 2'de).
  (5) ARG PARSER: ev yapimi tokenizer resmi Win32 CommandLineToArgvW
  P/Invoke ile degistirildi; escaped quote / backslash-before-quote / bos
  arguman / decoy testleri eklendi; Windows disi ortam acik fail-closed.
- Test paketi 71/71 gecti (64 mock + 7 gercek dispatcher/parser kaniti).
  Suite iki ortam tuzagini daha belgeledi: child process'in
  SGS_NO_DISPATCH env mirasi ve EAP=Stop altinda native stderr
  yonlendirmesinin terminating hataya donusmesi; test harness'ta cozuldu.
- Canli read-only status: 3x RUNNING, loopback-only, HTTP 200, schema 1.2
  receipt, secret taramasi temiz.
- Sinirlar korundu: gercek task/gateway mutasyonu, reboot, listener,
  provider/model cagrisi, remote/push, secret okuma/basma yok; 8cafd8a
  rewrite edilmedi, baseline tag'leri oynatilmadi.

## 19 Temmuz 2026 - P0-B Faz 1 Codex kabulu (ucuncu review)

- Codex ucuncu salt-okunur review'de P0-B Faz 1'i KABUL etti: ec39deb ayri
  commit, working tree temiz, parser 0 hata, Codex tekrarinda 71/71 test,
  canli status olcumunde 3 profil RUNNING/loopback-only/dogru process tree.
  R3 bulgulari kod/testte dogrulandi. Faz 2 kullanici onayina birakildi.

## 19 Temmuz 2026 - P0-B Faz 2A: gercek task kurulumu ve stop/start kabulu

- Kullanici Faz 2'nin tamamini onayladi; guvenlik icin bu tur yalniz Faz 2A
  uygulandi (reboot ve provider/model cagrisi Faz 2B'ye birakildi).
- Preflight kritik bulgu: uc gateway DOWN, onceki oturum-baslatmali PID'ler
  stale (makine yeniden baslamis) - Faz 2 gerekcesinin canli kaniti.
  `\Sovereign\` bos, FOREIGN_TASK yok; fail-closed on kosullar gecti.
- Canli execute GERCEK bir bug yakaladi (fail-safe tuttu, 0 mutasyon):
  `GetNewClosure()` scriptblock'u yeni dinamik modul scope'una baglayip
  gercek -File kosusunda script fonksiyonlarini goremiyor; mock kosular bunu
  uretmiyordu. Cozum: closure'siz parametreli `-Body`/`-BodyArgs`. Parser 0,
  71/71 test yeniden yesil.
- Gercek kurulum: 3/3 register applied; raw yeniden-okumada tum alanlar
  dogru (tek action/trigger, exact exe/args/workdir, logon trigger enabled +
  current-user, principal Interactive/Limited, marker). Ikinci install 3/3
  idempotent skip - gercek nesnelerde sahiplik+config dogrulamasi kaniti.
- Profil profil kabul (sirayla mimo, deepseek, hermes; DOWN on-durumuna
  uyarlanmis dongu: task-owned start -> RUNNING kabul -> profil kapsamli
  stop -> DOWN/port kapanis kabul -> task-owned start -> RUNNING + secretsiz
  health HTTP 200). Her adim redacted receipt birakti; eski PID'ler stop
  sonrasi canli stale tespitine dustu; diger route'lara dokunulmadi ve
  sonradan RUNNING dogrulandi. `gateway stop --all` hicbir yerde kullanilmadi.
- Final: 3/3 RUNNING, loopback-only, HTTP 200, taskOwned/cfg 3/3,
  `\Sovereign\` task 3/3, final receipt secret-taramasi temiz.
- Rollback: `-Action uninstall -Execute` yalniz kanitli-sahip uc task'i
  kaldirir; task'siz start bilincli start-direct fallback'ine doner.
- Sinirlar: reboot YOK, provider/model cagrisi YOK, yeni listener YOK,
  remote/push YOK, secret okuma/basma YOK. Baseline tag'leri yerinde.

## 19 Temmuz 2026 - P0-B Faz 2A review duzeltmesi: hidden launcher (r4)

- Codex'in bloklayici bulgusu (task action'larin hermes.exe'yi dogrudan
  calistirip her gateway icin GORUNUR terminal penceresi acmasi) kabul edildi
  ve kapatildi. Canli uygulama iki gercek bug daha yakaladi:
  (1) launcher servis scriptini dot-source ederken servis param blogu
  `$GatewayProfile`'i `all` ile ezdi; hermes `-p all` ile baslayip oldu,
  launcher durustce exit 3 + failed receipt verdi (fail-safe tuttu). Cozum:
  parametreleri dot-source oncesi ozel adlara kopyalamak + exact-olmayan
  profili fail-closed reddeden guard.
  (2) Windows Terminal default-terminal iken `powershell -WindowStyle
  Hidden` bile wrapper icin GORUNUR WT tab'i acti; tum konsol zinciri
  `conhost.exe --headless` sarmasina alindi (task action + hermes cocugu).
  Ayrica named mutex ayni thread'de reentrant oldugu icin cift-calisma
  korumasi dosya kilidine (FileShare::None) cevrildi.
- Yeni `scripts/sovereign-gateway-launch.ps1`: secretsiz, dosya kilidi,
  RUNNING=idempotent / FOREIGN-NONLOOPBACK-PARTIAL=fail-closed (0 start) /
  DOWN=gizli start + log yonlendirme + timeoutlu kabul (timeout'ta yalniz
  token-kanitli kendi agac temizligi), her sonucta redacted receipt.
- Test paketi 83/83 (launcher gruplari + conhost task-action assert'leri;
  Q3 ortam-saglam hale getirildi).
- Canli kabul: drift-recreate 6/6 (calisan gateway'lere dokunulmadan), raw
  alan dogrulamasi conhost/--headless zinciriyle; uc profil icin konsolsuz
  stop -> task-start donguleri; her start'ta YENI gorunur pencere 0; eski
  gorunur konsollar yalniz kendi profillerinin stop'uyla dogal kapandi;
  final gorunur gateway penceresi 0, wrapper kalinti 0, 3/3 RUNNING/
  loopback/HTTP 200, task 3/3 owned/config, receipt taramasi temiz.
- Sinirlar korundu: reboot/provider/model/listener/remote/push/secret yok.
  Reboot + provider probe Faz 2B'de.

## 19 Temmuz 2026 - P0-B Faz 2A hardening (r5)

- Codex r4 review'inin uc bulgusu dar bir hardening dilimiyle kapatildi
  (canli uc route'a ve task tanimlarina dokunulmadan):
  (1) tum gercek start yollari tek ortak konsolsuz primitive'e indirildi
  (`Invoke-SgsStartHermesConsoleless`); start-direct fallback'indeki eski
  gorunur `Start-Process hermes.exe` yolu kaldirildi; launcher ayni
  contract'a delege eder, recursive launcher/task cagrisi yok.
  (2) hermes child komut satiri CommandLineToArgvW round-trip'iyle KANITLI
  Windows quoting helper'iyla uretiliyor (bosluklu/tirnakli yollar exact;
  mevcut yolda bayt-ayni cikti => task drift yok, `plan` 3x
  already-installed).
  (3) launcher beklenmeyen exception'larda fail-closed: exit 4, dosya kilidi
  finally ile kesin serbest, tek denemelik redacted outcome=error receipt;
  receipt yazimi da patlarsa recursion yok, exit 5.
- Testler 97/97 (kaynak-birlesme kanitlari, quoting round-trip, exception
  sertligi); parser 3 dosyada 0 hata. Canli read-only: 3/3 RUNNING/loopback/
  HTTP 200. Sinirlar: reboot/provider/route-stop/remote/push/secret yok.

## 19 Temmuz 2026 - P0-B Faz 2A Codex kabul + Faz 2B reboot checkpoint

- Codex Faz 2A'yi `f2a2a19` uzerinde KABUL etti: parser 0, 97/97 test, 3 task
  exact, 8642/8643/8644 loopback HTTP 200, yeni gorunur terminal 0. Kullanici
  tum Faz 2'yi onaylamisti.
- Pre-reboot kalici checkpoint `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` yazildi:
  kaynak commit/baseline tag, mevcut exact task mimarisi, canli durum, sinirlar,
  rollback, reboot kesintisinden sonra devam protokolu; kesin post-reboot kabul
  checklist'i (3 task owned/config + LastTaskResult, loopback 8642/8643/8644,
  /health HTTP 200, launcher wrapper 0, yeni gorunur Terminal/PowerShell/Hermes
  penceresi 0, receipt/log secret-tarama, timeout, rollback - hepsi KANIT
  GEREKLI acik); provider probe TASARIMI (yalniz MiMo 8642 + DeepSeek 8643,
  prompt 'Yalniz OK yaz.', max 8 token, temp 0, hassassiz, profil basina 1
  cagri + yalniz transient hatada 1 retry, anahtar/header/body log yok;
  HTTP/latency/model/usage/cevap-hash/redacted cost kaydi; 8644 ucretli probe
  yalniz route semantigi dogrulanirsa, aksi health-only + KANIT GEREKLI).
- Bu tur 0 mutasyon: reboot yok, provider/model cagrisi yok, gateway stop/start
  yok, task install/uninstall yok, secret/env okuma-basma yok, remote/push yok.
  `f2a2a19` rewrite edilmedi; task tanimi degismedi; VALIDATION kaniti
  degistirilmedi. Yeni belge ayri commit'te.

## 19 Temmuz 2026 - P0-B Faz 2B reboot acceptance (post-reboot kanit)

- Reboot yapildi, kullanici logon oldu; salt-okuma olcum: LastBoot 14:07:55,
  3 task LastRun 14:12:34/LastResult 0/Ready/exact owned-config; 8642/8643/
  8644 PID'leri tek 127.0.0.1 listener + HTTP 200; launcher wrapper 0;
  `sky.list_apps` gorunur console/Terminal/PowerShell/Hermes penceresi 0.
- Uc launcher receipt (14:13:34) ve status receipt
  `receipt-status-20260719-112433-839-2081c97c.json` outcome ok, secret-pattern
  false; out log 1155 byte, err log 0, alti log temiz; kabul 14:12:50->14:13:34
  (~44 sn, 90 sn bound icinde).
- `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` checklist 1-14 TAM isaretlendi, bolum
  9 post-reboot evidence eklendi. Faz 2B reboot acceptance TAMAM. Provider
  probe (MiMo 8642 + DeepSeek 8643) CALISTIRILMADI, hala KANIT GEREKLI. Kaynak
  HEAD `82f908f`, Faz 2A kabul `f2a2a19` degismedi. Kod/task/gateway/provider
  degistirilmedi; yalniz belge guncellendi.

## 19 Temmuz 2026 - P0-B Faz 2B provider probe canli kanit - TAMAM

- Bolum 7 sozlesmesi kullanici onayiyla kosturuldu. Ilk MiMo denemesi
  (receipt `...mimo-20260719-123730-201-b5e7e235.json`) HTTP200 ama outcome
  `failed UNEXPECTED_RESPONSE_CONTENT` (responseLength0, prompt254/
  completion8/total262); kok neden Xiaomi resmi dokumana gore mimo-v2.5
  thinking varsayilan acik, 8 token butce tamamen reasoning'e gitti. Retry
  yapilmadi (uygulama seviyesi icerik uyumsuzlugu, transient degil).
- DeepSeek ilk denemede kabul edildi: receipt
  `...deepseek-20260719-124120-200-a2cb21ee.json`, exact OK, prompt11/
  completion1/total12, configured estimate $0.00000182, secret pattern false.
- Claude Code r3 fix (commit `a26091a`): MiMo istegine de thinking.type=
  disabled eklendi; provider probe suite 109/109, gateway service testi
  97/97, parser 0 hata.
- Duzeltme sonrasi MiMo kabul edildi: receipt
  `...mimo-20260719-124537-820-0c5f04fe.json`, exact OK, prompt256/
  completion2/total258, configured estimate $0.00003640, secret pattern
  false.
- Kabul edilen cift toplam 270 token, configured estimate $0.00003822; bu
  turdaki tum canli harcama (ilk basarisiz MiMo dahil) 532 token, configured
  estimate $0.00007602 (yerel configured rate, resmi fatura degil). Hicbir
  receipt'te secret/raw body/base URL yok; secret pattern false.
- 8644 sinirlamasi degismedi: yalniz health, ucretli probe kapsam disi
  (P0-B kapsami zaten yalniz MiMo+DeepSeek), bu yuzden Faz 2B kabulunu
  engellemiyor.
- `docs/P0B-PHASE2B-REBOOT-CHECKPOINT.md` bolum 10 ve `docs/VALIDATION.md`
  ilgili bolum guncellendi. **Faz 2B TAMAM. P0-B TAMAM** (8644 health-only
  sinirlamasi acikca not edilerek). Kod/task/gateway degismedi; bu tur
  yalniz onceden yapilmis canli probe kanitini belgeye kilitledi, yeni
  provider cagrisi yapilmadi.

## 19 Temmuz 2026 - MCP Bridge Windows ENOBUFS/teardown kaniti belgeye kilitlendi

- Sovereign kaynaginda commit `cf8c9e0` (deterministic test-listen + MCP
  cleanup + fault injection) ve `63fcc3b` (Node resmi siraya gore close once,
  sonra closeIdle/closeAll + exact-order testi) 18 Temmuz denetiminde acilan
  ENOBUFS/teardown roadmap kalemini kapatti. Kod kapsami yalniz
  `workers/mcp-bridge/src/mcp.test.ts`, `test-listen.ts`,
  `test-listen.test.ts`; bu oturumda baska urun kodu degismedi.
- Pre-fix bu oturum tekrarinda hedef dosya 1/1 ve full workspace 124/124
  gecti; sorun intermittent dogrulandi ama sabit `127.0.0.1:4601` erken hata
  sonrasi listener/process birakma kaynak sizinti yolu kaniyla kanitliydi.
- Post-fix: hedef MCP suite 11/11, full workspace 134/134, TypeScript 11/12
  kapsamdaki workspace projesi icin temiz, `pnpm build` temiz (web build 1645
  modul). Fault injection kapsami: port0 ENOBUFS->bounded fallback,
  EADDRINUSE->next candidate, nonretryable immediate fail, exhaustion bounded
  fail, sync throw listener cleanup, idempotent close, close error, erken
  application-error cleanup, exact close-ordering testi (Node resmi sira).
- Codex stres kaniti: ilk normal-sandbox tekrar dongusu sandbox EPERM
  nedeniyle 0/20 (urun hatasi degil). Onaylanan tam-erisim exact-command
  batch'i 19/20 verdi; tek hatanin kok-neden ciktisi capture yontemiyle
  kesildi ve ENOBUFS kaniti tasimiyordu - reproduction sayilmadi, belirsiz
  olarak kaydedildi. Failure-capture duzeltmesi sonrasi 40/40 ve 60/60 = **100
  ardisik gecis, sifir hata**. Bu kayit orijinal ENOBUFS'un tekrar
  reprodüklendigini iddia etmez; yalniz close-ordering/cleanup yolunun tekrarli
  stres altinda artik deterministik oldugunu kaniyler.
- Final ortam kontrolu: aday portlar 4601/4691/4692/4693 listener sayisi 0;
  repo tsx/node --test kalinti process 0. Sovereign `git status` 63fcc3b'de
  temiz.
- Ortam notu (urun/test hatasi degil): varsayilan sandbox profilinde
  typecheck/build harici Sovereign kaynak agacindan `tsc` okuyamadigi icin
  EPERM verdi; tam erisimli tekrarda ikisi de temiz gecti - 18 Temmuz
  denetimindeki ayni sandbox-izin bulgusunun tekrari.
- Bu tur docs-only: HERMES canonical belgelerine (VALIDATION, WORKLOG,
  PROJECT_MEMORY, ROADMAP) kanit yazildi; hicbir servis/provider/model
  cagrisi yapilmadi, HERMES veya Sovereign urun kodu degistirilmedi.

## 19 Temmuz 2026 - Izole Runtime Smoke E2E TAMAM

- Sovereign kaynaginda commit `8d904a3`, `edf6393`, `5e07e02`; ayrica
  hygiene-only `.gitignore` commit `e314314` (`e314314` yalniz Sovereign
  `.gitignore` satirini degistirdi, hicbir runtime davranisi degismedi).
- Helper suite 21/21, full workspace 134/134, TypeScript 11/12; `pnpm build`
  temiz - web build 1645 modul, `index` 0.45 kB, CSS 106.25 kB, JS 380.45 kB.
- Gercek izole smoke calistirildi, exit 0. Receipt:
  `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent\qa\isolated-runtime-smoke\receipt.json`,
  zaman damgasi `2026-07-19T16:03:16.023Z`. Kosum benzersiz gecici `DATA_DIR`
  ve port araligi 50171-50194 kullandi.
- Incremental UI chat: kismi metin "İzole" ve nihai metin "Izole runtime
  sohbeti canlı akış ile yanıt veriyor.", 2 kalici (persisted) tur. Model
  yerel deterministic mock `deepseek-chat-isolated-smoke` idi; ucretli cagri
  yapilmadi.
- Gercek Playwright `browser.inspect` `https://example.com` adresine calisti,
  baslik "Example Domain" dogrulandi, 3 artifact uretti; `browser-run.json`
  837 bayt, SHA-256 `1cde0be7baa2ebc7a61a69d78649094002cabe320c32c0395a32180101830112`;
  gecerli PNG 1280x800, 10892 bayt.
- Gercek Windows CUA frame 431664 bayt 1920x1080 ve proxy edilmis kopyasi
  412141 bayt. Takeover sirasi dogrulandi: agent false -> human true -> agent
  false; masaustune aktif fare/klavye girisi yapilmadi.
- Konsol veya request hatasi yok; visual QA temiz. Tum cleanup basarili -
  gecici dizin silindi, portlar kapatildi. `gateway-auth` ve `gateway-stream`
  fault kosumlari yalniz cleanup sonrasi exit 1 verdi, orphan worker kalmadi.
- Durust sinirlar: model gateway yerel mock'tur, paketlenmis/imzali tekil
  masaustu urunu degildir, ucretli istek yapilmadi, aktif fare/klavye kabulu
  yok, takeover restart dayanikliligi (durability) beklemede, 8644 yalniz
  health, canli 8642-8644 dokunulmadi. Sonraki adim Hermes Electron veya
  native shell artı Sovereign UI ve Control Plane yasam dongusu entegrasyonu,
  ardindan takeover restart dayanikliligi ve guvenlik-kapili aktif girdi.
- Bu tur docs-only: hicbir servis/provider/model cagrisi yapilmadi, HERMES
  veya Sovereign urun kodu degistirilmedi.

## 20 Temmuz 2026 - Native Sovereign supervisor hardening (Codex review-fix)

- Dar kapsamli guvenlik/dayaniklilik review-fix paketi tests-first uygulandi.
  Yalniz HERMES desktop; Sovereign repo DOKUNULMADI (clean HEAD `e314314`),
  flag varsayilan KAPALI, hicbir provider/model cagrisi yok, para harcanmadi.
- Sahiplik artik yalniz TOKEN kaniti iledir (crypto 192-bit; canli child handle
  tek basina yetmez). Hazir = health OK + (tam `/health` ownerToken VEYA
  token+tam-port ready-file). Kanitsiz health -> `OWNERSHIP_UNPROVEN`, yalniz
  spawn edilen child temizlenir. `'child'` proof turu kaldirildi.
- `inFlight` yerine race-free FIFO kuyruk (start/stop/reach serilestirilir);
  health fetch HAM BAYT sinirlar (>64 KiB abort, kesik parse yok); child env
  muhafazakar allowlist (provider key sizmaz); IPC sender-trust enjekte
  authorizer + sabit `UNTRUSTED_SENDER`; POSIX teardown SIGKILL fallback +
  senkron ready-file silme; credentialed surface URL reddi + `persist:sovereign`
  subresource egress filtresi; renderer yalniz ready+healthy+owned+surfaceUrl'de
  gomer, Stop yeni `controllable` durumuna baglidir.
- Kanit (izole, ucretsiz): Sovereign node **85/85** (pre-fix 56), renderer
  **18/18** (pre-fix 16), `test:sovereign:accept` 2x exit 0 **23/23** (senaryo D
  OWNERSHIP_UNPROVEN + 0 orphan; sonra 0 kalinti fake process), hedef ESLint
  0 hata/0 uyari, typecheck temiz, `diff --check` (cr-at-eol) temiz. Tam
  `test:desktop:platforms`: **394 test / 391 gecti / 1 hata / 2 skip**; tek hata
  onceden var olan ilgisiz `resolveUnpackedRelease ... release/<plat>-unpacked`
  (update-relaunch.test.cjs, dokunulmadi). Brief "3" dedi; olculen gercek **1**,
  oldugu gibi raporlandi.
- Read-only: 8642/8643/8644 degismedi (PID 17364/17348/17352, 127.0.0.1);
  4310-4321 serbest; uc `\Sovereign\` task `Ready`.
- Durust acik kalemler degismedi: authenticated yuzey/token echo/cross-restart
  persist/paket GUI E2E/aktif input/Manus tam urun BEKLIYOR. AgentOS deposu
  yalniz istege bagli referans (import/merge/bagimlilik yok; LICENSE yoktu ->
  kod alinmadi). Acik-kaynak/Manus arastirmasi planli. Ayrinti
  `docs/VALIDATION.md`, ADR 0011.

## 20 Temmuz 2026 - Native Sovereign supervisor r3 (Codex review duzeltmeleri)

- Ayni uncommitted dilime ikinci, kucuk Codex review paketi: alti duzeltme.
  Yalniz HERMES desktop; Sovereign repo dokunulmadi; flag varsayilan KAPALI;
  provider/model cagrisi yok; commit yok.
- Supervisor: dolu-port adoption yalniz token kaniti + AYNI canli spawned child
  ile (olu handle + token echo = fail-closed FOREIGN_PORT, bayat ownership
  dusurulur); spawn aninda handle-scoped exit watcher READY sonrasi beklenmeyen
  exit'i aninda FAILED/CHILD_EXIT + ownership/pid/proof temizligiyle reconcile
  eder; STOPPING'deki beklenen exit doStop'ta kalir; ownership yayinlanmadan
  once son childAlive() re-check. FIFO/token-only kanit degismedi.
- Renderer: ready+healthy+unowned artik "owned" diyen auth-pending yerine ozel
  fail-closed ownership-lost paneli (embed yok, Stop kapali); Start yalniz bayat
  unowned+uncontrollable ready'de acik, gercek owned READY start edilemez;
  STARTING'de Stop isteginin FIFO ile start arkasina sirali oldugu durustce
  yazildi.
- `electron/sovereign-ipc-trust.cjs` cikarildi (Electron'suz sender predicate;
  bos file-URL hostname sarti, fileURLToPath+normalize karsilastirma) + 19
  testlik yeni suite `test:desktop:platforms`'a eklendi; main.cjs lokalize
  baglandi. `persist:sovereign` in-page egress yalniz data:/blob:/about:'a
  daraltildi (devtools:/chrome:/chrome-extension:/bilinmeyen deny).
- Durust yorum/sayim: flag-off = rota/IPC kayitli ama disabled/blocked (process/
  listener/network yok); runtime ready-file yorumunda live-child fallback yok;
  r2 per-file sayimlari duzeltildi (olculen 85 = config 13 / supervisor 28 /
  ipc 12 / runtime 18 / webview 14; eski 16/28/13/18/17 kaydi yanlisti).
- Kanit (izole, ucretsiz): Sovereign node **108/108** (13/32/12/19/18/14;
  supervisor +4 lifecycle, ipc-trust 19 yeni), renderer **19/19** (10/4/5),
  hedefli ESLint 0/0, typecheck temiz, `test:sovereign:accept` 2x exit 0
  **23/23** + 0 kalinti fake process, cr-at-eol diff --check temiz. Read-only:
  8642/8643/8644 degismedi (PID 17364/17348/17352), 4310-4321 serbest, uc
  `\Sovereign\` task `Ready`. Tam `test:desktop:platforms` bu turda bilerek
  kosulmadi (Codex bagimsiz kosacak). Ayrinti `docs/VALIDATION.md` r3 bolumu,
  ADR 0011 r3 bolumu.
- Oturum sonu ortam kaydi: yesil olcumlerden sonra host `listen ENOBUFS`
  durumuna girdi (ilgisiz ArkSignerManagement PID 23048, 15.771 Bound TCP
  soket; bagimsiz taze-node listen probe'u da ENOBUFS). Gercek-HTTP fixture'li
  `sovereign-runtime` son kapida bu yuzden 12/18 (ayni oturumda onceden 2x
  18/18); soket kullanmayan bes suite 90/90 kaldi. Regresyon degil, host
  kosulu; yabanci surece dokunulmadi. Tam suite oncesi ArkSigner kapat/yeniden
  baslat (veya reboot) + runtime suite'i yeniden dogrula.

## 25 Temmuz 2026 - Native Sovereign r4 hardening (Opus 5 / Max)

- Model politikasi guncellendi (kullanici karari): Claude Code implementation ve
  review yalniz **Opus 5 + Max** ile yapilir; Fable/Sonnet kullanilmaz. MiMo ve
  DeepSeek HERMES runtime provider'laridir, Claude Code'un kodlama modeli
  degildir. `CLAUDE.md` icine baglayici bolum olarak yazildi.
- **Ortam duzeltmesi (append-correct):** r3 sonundaki `listen ENOBUFS` kosulu
  disaridan ve geciciydi (ilgisiz `ArkSignerManagement` dinamik port havuzunu
  tuketmisti). Reboot sonrasi dinamik `listen(0)` yeniden calisiyor;
  `sovereign-runtime` **standart ephemeral portlarla 18/18** geciyor. Onerilen
  deterministic 4310-4321 sabit-test-portu yamasi BILINCLI OLARAK UYGULANMADI;
  sabit test portu / ArkSigner restart / reboot artik bu suite'ler icin
  gereklilik degildir - ENOBUFS yalnizca dis ortam kanitidir.
- Uc dar hardening uygulandi (HERMES desktop; Sovereign deposu, flag varsayilani
  ve urun runtime davranisi degismedi):
  1. **Supervisor total exception safety** kodu calisma agacinda zaten vardi; bu
     turda eksik olan **fault-injection kaniti** eklendi ve on-hardening
     sozlesmesini bekleyen bayat bir test gercek davranisa gore duzeltildi.
     Kanitlananlar: pre-spawn probe reject => 0 spawn/0 kill/0 yabanci sinyal;
     post-spawn ready-file throw => token tasiyan ready-file silinir ve YALNIZ
     kendi spawn'imiz temizlenir; `removeReadyFile` best-effort'tur; stop
     release-probe reject => asla IDLE iddia edilmez; throwing kill/force-kill
     stop'u kilitleyemez; FIFO kuyruk her faultan sonra toparlar. Hicbir
     reason'da ham hata metni yok.
  2. **Honest queued Stop UX**: paylasilan `busy` bayragi Stop'u kilitlemeyi
     birakti (supervisor'un `controllable` sozlesmesiyle celisiyordu). Gating
     artik operasyon bazli; Start pending iken `controllable` true ise Stop
     istenebiliyor ve bunun FIFO queued teardown oldugu panelde durustce
     yaziyor. Config okuma hatasi artik "integration disabled" gibi gorunmuyor;
     kendi fail-closed panelinde Retry ile geliyor. Status/mutation hatalari
     hangi cagrinin dustugunu sabit kelime dagarciyla gosteren kompakt panelde;
     stack/ham mesaj/secret UI'ya sizmiyor.
  3. **Webview egress protocol-family pinning**: filtre yalniz host+port
     karsilastiriyordu, bu yuzden `http` yuzey ayni authority uzerinde
     `https`/`wss`'i de aciyordu. Artik aile pinlenmis durumda (http =>
     http+ws, https => https+wss); karsi aile ayni authority'de bile reddediliyor,
     bilinmeyen yuzey scheme'i tum ag egress'ini kapatiyor. data:/blob:/about:
     ve permission/download/navigation reddi aynen korundu.
- Kanit (izole, ucretli cagri yok): focused Sovereign node **115/115**
  (config 13, supervisor 38, ipc 12, ipc-trust 19, runtime 18, webview 15);
  renderer vitest **22/22**; `test:sovereign:accept` 2x exit 0 **23/23**, 0
  kalinti fake process; hedefli ESLint 0 hata/0 uyari; `tsc --noEmit` temiz;
  `git -c core.whitespace=cr-at-eol diff --check` temiz; tam
  `test:desktop:platforms` **424 test / 421 pass / 1 fail / 2 skip** (tek hata
  bu dilimin dokunmadigi, onceden var olan ilgisiz `update-relaunch`
  Linux-path assertion'i - gizlenmedi); tam `npm run build` basarili.
- Final read-only host durumu: 4310-4321 **tamamen serbest**; korunan
  gateway'ler degismedi (127.0.0.1, 8642 PID 11692, 8643 PID 17636, 8644 PID
  8680); uc `\Sovereign\` task `Ready`/`LastTaskResult=0`; gercek
  `fake-sovereign-service` process **0** (tek CIM eslesmesi olcum yapan
  PowerShell'in kendi komut satiriydi - self-match, elendi).
- Sinirlar korundu: commit yok, reboot yok, provider/model cagrisi yok, external
  network yok, task mutasyonu yok, secret okuma/yazma/basma yok, remote/push
  yok, korunan 8642-8644 servis/PID'lerine dokunulmadi.

## 25 Temmuz 2026 - r4 review-fix (Codex'in uc bulgusu)

- Codex bagimsiz r4 review'i uc kusur buldu; ucu de yeniden uretildi, en dar
  guvenli duzeltmeyle kapatildi ve her biri icin duzeltme GECICI OLARAK GERI
  ALINIP testin gercekten kirmizi oldugu kanitlandi (sonra restore edildi):
  1. Kuyruk paneli yanlis kosula bagliydi (`canStop && startPending`): Stop
     tiklanmadan gorunuyor, tiklaninca kayboluyordu. `stopPending &&
     startPending` yapildi; test artik sadik (tiklama oncesi panel yok, iki
     promise pending iken var, Start once sonra Stop cozulur ve nihai `idle`
     status kazanir).
  2. Eksik preload bridge "Integration disabled" gibi gosteriliyordu.
     Config/status/uc mutation artik `SOVEREIGN_BRIDGE_UNAVAILABLE` sabit
     hatasiyla fail-closed error state'e dusuyor (sabit metin UI'ya
     yazilmiyor); bridge geri gelince Retry toparliyor.
  3. `waitForChildExit.finish` icinde `clearTimeoutFn` throw ederse `resolve`
     hic calismiyor ve stop sonsuza dek pending kalabiliyordu. Timer iptali
     best-effort try/catch'e alindi; `setTimeoutFn` throw ederse de sinirsiz
     bekleme yerine dogrudan escalation'a dusuluyor.
- Kanit: focused Sovereign node **118/118** (config 13, supervisor 41, ipc 12,
  ipc-trust 19, runtime 18, webview 15); renderer **24/24** (sovereign 15,
  store 4, routes 5); acceptance 2x exit 0 **23/23**, orphan 0; hedefli ESLint
  0/0; `tsc --noEmit` temiz; `diff --check` temiz; tam
  `test:desktop:platforms` **427 test / 424 pass / 1 fail / 2 skip** (tek hata
  onceden var olan ilgisiz `update-relaunch` Linux-path assertion'i); tam
  `npm run build` basarili.
- Regresyon-guard kaniti: duzeltmeler geri alininca renderer 3 failed/12 passed,
  supervisor timer testleri 0 pass/2 fail; restore sonrasi ikisi de yesil.
- Read-only host: 4310-4321 serbest; 8642 PID 11692 / 8643 PID 17636 / 8644 PID
  8680 degismedi; uc `\Sovereign\` task `Ready`/`LastTaskResult=0`; gercek
  `fake-sovereign-service` process 0.
- Commit yok; network/provider/task/process mutasyonu yok.

## 25 Temmuz 2026 - r4 review-fix #2 (Codex ikinci r4 review)

- Codex'in iki itirazi da HAKLIYDI; ikisi de en dar guvenli fix + kanitli
  regression testiyle kapatildi:
  1. `handle.once`/`timer.unref` throw yolu: waitForChildExit reject edince
     `killOwned` icindeki await, forceKillTree/SIGKILL escalationina VARMADAN
     disari cikiyordu; `safeKillOwned` rejecti yutuyor, `doStop` handle'i
     temizliyordu. Sonuc: stubborn spawned child hayatta kaliyor, supervisor
     handle'i kaybediyordu ("spawned child leak etmez" maddesinin ihlali).
     Artik `unref` hatasi yutuluyor, throw eden `once` ise `finish(false)` ile
     "cikmadi" raporlayip escalation'a dusuyor. Testler: hostile once =>
     yalniz kendi pid force-kill, bounded IDLE, stale ownership yok, queue
     recover; throw eden unref + stubborn child => escalation'a ulasiliyor;
     foreign occupant varken yalniz kendi pid'imiz oldurulup durustce
     `PORT_NOT_RELEASED` raporlaniyor (yabanci surece dokunulmuyor).
  2. IPC hata sozlesmesi: start/stop/reach basari-sekilli `{ error }` payload
     donuyordu; renderer'in null kontrolu bunu gecirdigi icin isError false
     kaliyor, panel acilmiyor ve mesaj metni cache'e giriyordu. config/status
     ise hic try/catch tasimiyordu (raw exception IPC sinirini geciyordu).
     Bes kanal da artik yakalayip redacted ayrintiyi YALNIZ main log'a yaziyor
     ve sabit `SOVEREIGN_OPERATION_FAILED` ile reject ediyor; sender trust hala
     once calisiyor (`UNTRUSTED_SENDER` degismedi, supervisor'a hic gidilmiyor).
     Renderer defense-in-depth olarak `error` tasiyan payload'i da fail-closed
     sayiyor (cache/DOM'a girmiyor).
- Kanit: focused Sovereign node **123/123** (config 13, supervisor 44, ipc 14,
  ipc-trust 19, runtime 18, webview 15); renderer **27/27** (sovereign 18,
  store 4, routes 5); hedefli ESLint 0/0; `tsc --noEmit` temiz; `diff --check`
  temiz. Regresyon kaniti: once/unref guard'lari geri alininca ilgili iki test
  0 pass/2 fail, restore sonrasi 2/2.
- Full platform/build/acceptance bu turda bilerek KOSULMADI (Codex tek sefer
  final sweep yapacak). Commit yok; network/provider/task/process mutasyonu yok.

## 25 Temmuz 2026 - Sovereign gorunur navigasyon satiri + final sweep duzeltmesi

- Codex final GUI review'i gercek bir kesfedilebilirlik acigi buldu: gercek
  Electron uygulamasinda `/sovereign` yalnizca command palette'ten
  erisilebiliyordu (Windows UI otomasyonu Ctrl+K'yi guvenilir sekilde
  tetikleyemedi; ayrica flag-gated bir native control-plane ekrani zaten
  palette-only olmamali).
- En dar idiomatik cozum: sidebar birincil navigasyon dizisi saf
  `src/app/chat/sidebar/nav-items.tsx` modulune cikarildi ve Sovereign satiri
  ORADAN, paylasilan descriptor durumundan ekleniyor. Mevcut satir markup'i,
  tooltip/label yolu ve Sovereign gorunumunun `Shield` ikonu aynen kullanildi;
  satir Capabilities'ten hemen sonra (Operations/Capabilities ile ayni kume).
- Gorunurluk: yalniz descriptor YUKLENDI ve `enabled` ise. Yuklenmedi / flag
  kapali / preload bridge yok / config load hatasi (son ikisi store'da
  `{loaded:true, config:null}`) => satir hic yok, olu rota reklam edilmiyor.
- Yaris yok: kesif mevcut `@/store/sovereign` uzerinden, `loadStarted` guard'i
  sayesinde idempotent; palette'in kendi flag kapisi degismedi.
- Satirda `action` yok; sidebar'in tek generic tiklama yolu bu nedenle sadece
  `SOVEREIGN_ROUTE`a navigate edebilir - ekrani acmak servisi baslatmaz/probe
  etmez. Lifecycle yalniz gorunumun Start/Probe/Stop kontrollerinde.
- Test siniri durustce secildi: sidebar bileseni cok buyuk ve shadcn sidebar
  context'ine bagli oldugu icin render brittle olurdu; dizinin kendi
  konvansiyonu saf unit test. `nav-items.test.tsx` 9 test (gizli: yuklenmedi /
  flag off / bridge-yok-veya-hata, base nav degismiyor, gorunur: enabled,
  siralama, base dizi mutasyonsuz, tiklama kontrati route+action-yok+
  `appViewForPath` = 'sovereign', Shield ikonu/fallback label). Snapshot yok.
  Regresyon kaniti: gorunurluk kapisi zorla acilinca 9 testin 4'u kirmizi.
- Kanit (SAYI DUZELTMESI, asagidaki 26 Temmuz kaydina bakiniz): dokunulan ALTI
  dosya icin **51/51 (6 dosya)**; bu satirin ilk halindeki "87/87 (7 dosya)"
  iddiasi geri cekilmistir - o sayi `src/app/chat/sidebar` DIZININI vitest'e
  vermekten geliyordu ve adi gecen alti dosyanin disindaki yedinci bir dosyayi
  da kapsiyordu. Focused Sovereign node **123/123** (bu dilimle degismedi),
  hedefli ESLint 0/0, `tsc --noEmit` temiz, `diff --check` temiz.
- **Final sweep duzeltmesi (append-correct):** Codex'in bagimsiz tam platform
  kosusu bu oturumun onceki raporunu supersede eder. Dogru sayilar **432 total,
  427 pass, 3 fail, 2 skip**; onceki 427/424/1/2 kaydi nihai degildi. Uc hatanin
  ucu de bu dilimin dokunmadigi, onceden var olan
  `electron/update-relaunch.test.cjs` Windows/POSIX tasinabilirlik vakalari
  (POSIX yol semantigi + iki `/bin/bash` temp-path donusumu). Ayni sweep'te
  acceptance 2x 23/23 orphan 0, ESLint/tsc/diff-check temiz ve `npm run build`
  basarili (yalniz dirty-stamp/CSS optimizer/large-chunk uyarilari).
- Commit yok; provider credential, korunan 8642/8643/8644 servis/task ve AgentOS
  islerine dokunulmadi. Sirada Codex'in Electron'u yeniden baslatip gorunur
  rotadan Start -> Probe -> Stop dogrulamasi var.

## 26 Temmuz 2026 - Codex bagimsiz final dogrulama: canli GUI + sayi/diff duzeltmeleri

- **CANLI ELECTRON GUI KANITI (Codex, bagimsiz):** gercek built renderer +
  gercek main/preload IPC uzerinde dogrulandi. Flag-gated sidebar satiri
  Capabilities'ten sonra GORUNUR haldeydi ve gercek fare tiklamasi
  `/sovereign`a gitti. Baslangic: idle, 127.0.0.1:4310, healthy no, owned no,
  PID dash; Start enabled, Stop disabled. Start => ready, healthy yes, owned yes
  (token), PID 28356; 4310 tam olarak `scripts/fake-sovereign-service.mjs`
  node surecine aitti; authenticated-surface-pending paneli gosterildi ve auth
  BYPASS EDILMEDI. Probe => ayni PID ile ready/healthy/owned, hata yok. Stop =>
  idle/healthy no/owned no/PID dash, 4310 serbest birakildi, fake service
  process sayisi 0. Test penceresi kapatilinca Electron PID 10700 gitti, 4310
  serbest, kalinti fake process yok. Korunan gateway'ler bastan sona degismedi:
  8642 PID 11692, 8643 PID 17636, 8644 PID 8680; uc `\Sovereign\` task Ready /
  LastTaskResult 0.
- Bu kanit, belgelerdeki "gercek tiklama/lifecycle GUI hala kanitlanmadi"
  ifadelerini gecersiz kilar (VALIDATION + ADR 0011 duzeltildi). PACKAGED/imzali
  build, cross-session ownership adoption ve authenticated urun yuzeyi hala
  durustce BEKLIYOR.
- **Sayi duzeltmesi (append-correct):** benim raporladigim "87/87 / 7 dosya"
  iddiasi geri cekildi. O sayi `src/app/chat/sidebar` DIZINININ vitest'e
  verilmesinden geliyordu ve adi gecen alti dosyanin disindaki yedinci bir
  dosyayi da kapsiyordu. Adi gecen komutun dogru sonucu **51/51, 6 dosya**
  (nav-items 9, order, session-actions-menu, app/sovereign 18, store/sovereign
  4, routes 5). Tum belgelerde duzeltildi.
- **Flake (gizlenmedi):** alti dosyalik komutun bir kosusunda, makine agir
  yuk altindayken `app/sovereign/index.test.tsx` icindeki "renders the honest
  disabled panel when the flag is off" testi 6.2 sn'de dustu (environment kurulumu
  tek basina 61 sn suren bir kosu; RTL find timeout'u). Ayni dosya tek basina
  18/18 gecti ve alti dosyalik komut ardindan iki kez ust uste 51/51 gecti.
  Yuke bagli zamanlama flake'i olarak kayda gecirildi, urun kusuru degil.
- **Diff hijyeni duzeltmesi:** `src/app/types.ts` tek uyeli `SidebarNavId`
  degisikligi icin 168 ekleme / 161 silme gosteriyordu; nedeni scriptli bir
  duzenlemenin CRLF dosyayi LF olarak yeniden yazmasiydi. Dosya `HEAD`den
  geri alinip minimal degisiklik CRLF korunarak byte-guvenli yeniden uygulandi:
  diff artik **8 ekleme / 1 silme**, dosya 168 CR baytini koruyor. Diger dort
  nav-slice dosyasi incelendi, kaza eseri EOL churn yok (en.ts 1 ekleme,
  sidebar/index.tsx 45 satir / 4 odakli hunk, iki yeni nav-items dosyasinin
  onceki surumu yok).
- Bu turda yeniden calistirilan dogrulamalar: alti dosyalik renderer komutu
  **51/51 (2 ardisik temiz kosu)**, focused Sovereign node **123/123**, hedefli
  ESLint **0 hata/0 uyari**, `tsc --noEmit` temiz,
  `git -c core.whitespace=cr-at-eol diff --check` temiz.
- Davranissal genisletme yok, commit yok, provider/korunan servis-task/AgentOS
  mutasyonu yok.

## 26 Temmuz 2026 - Sovereign urun host adapter (authenticated surface, auth bypass YOK)

- P0 "Tek Gercek Masaustu Urunu" hattinda authenticated urun yuzeyi baglandi.
  HERMES-sahipli bir on-plan (foreground) urun host adapter'i tek supervisor
  child'i olarak calisiyor; stok Sovereign web build'ini loopback urun portunda
  serve ediyor, API/stream isteklerini AYRI bir loopback API portundaki dogrudan
  spawn edilen control-plane'e reverse-proxy ediyor ve sahiplik token'ini yalniz
  hem web host hem upstream API canliyken echo ediyor. Dis Sovereign deposu
  DEGISTIRILMEDI (`e314314` temiz); `main.cjs`/renderer degisikligi YOK
  (entegrasyon mevcut supervisor uzerinden env/config ile). Ayrinti ADR 0011
  (26 Temmuz bolumu) ve `docs/VALIDATION.md`.
- Mimari: supervisor -> adapter -> control-plane (grandchild). Windows tree kill
  (`taskkill /T`) ve `disposeSync` tum agaci topluyor. Adapter, stok control-
  plane'i *ownable* yapan parca: supervisor readiness sozlesmesi (health 2xx +
  tam `ownerToken` echo VEYA ready-file token+port) adapter tarafindan karsilaniyor.
- Auth BYPASS EDILMEDI: control-plane hala `sovereign_session` cookie istiyor;
  bootstrap/login izole `persist:sovereign` webview icinde, urun origin'inde
  olur. Parola/session/recovery/MFA degeri Hermes preload/IPC/argv/log/receipt'e
  hicbir zaman girmez. `AUTH_MODE=disabled` kullanilmadi.
- Control-plane child env'i bilincli allowlist/overlay: yalniz `CONTROL_PLANE_
  HOST/PORT` + `DATA_DIR` (+ Electron altinda `ELECTRON_RUN_AS_NODE`). `NODE_ENV=
  production`, DB/NATS/Temporal/`MODEL_GATEWAY_URL`/`AUTH_MODE` ve `*_API_KEY/
  *_TOKEN/*_SECRET` YOK => JSON store + `NoopEventBus` + yerel `TaskEngine`,
  auth ACIK. `.env` okunmadi. Supervisor token'i allowlist'te olmadigi icin
  control-plane'e ulasmiyor.
- Fail-closed dogrulama: eksik `apps/web/dist/index.html` veya
  `apps/control-plane/dist/bootstrap.js`, non-loopback host/api-host, gecersiz/
  reserved/cakisan port, ve source agacinin ICINE dusen DATA_DIR
  (`DATA_DIR_INSIDE_SOURCE` - repo'nun kendi `data/`sine yazmayi engeller) hepsi
  spawn/bind/write oncesi reddediliyor. API portu ayri loopback port, varsayilan
  ephemeral. Supervisor health path'i `/__hermes/` ozel namespace'inde olmali
  (token echo yapisal olarak proxy'lenemez/serve edilemez); diger `/__hermes/*`
  404, ifsa yok.
- Proxy: SSE dahil bufferlanmadan stream; status/header/`set-cookie` korunur;
  hop-by-hop iki yonde de silinir; cookie/body forward; upstream Host loopback
  authority'ye pinlenir; hedef sabit dogrulanmis loopback (SSRF yok - guest yalniz
  path'i etkiler); yalniz connect/first-response bounded (SSE oldurulmez);
  disconnect'te upstream abort; upstream red/timeout'ta 502/504. Statik: path
  containment, dogru MIME (octet-stream fallback), SPA fallback yalniz
  `Accept: text/html` ve kok icin; eksik asset 404; dizin listesi yok; index/auth
  HTML `no-store`, hashed asset immutable; `nosniff`+`no-referrer`. Electron
  `persist:sovereign` egress filtresi gercek ag siniri olarak degismedi.
- Teardown/orphan yok: POSIX'te adapter SIGTERM handler'i control-plane'i nazikce
  durdurur, in-flight proxy'yi abort eder, ready-file'i siler, cikar. Windows'ta
  OS/tree cleanup grandchild'i ve iki soketi bounded pencerede (gozlemlenen alt-
  saniye) topluyor; supervisor `forceKillTree`/`disposeSync` belt-and-braces.
  READY sonrasi upstream olumu `/__hermes/health`i aninda 503 yapar VE adapter'i
  nonzero cikarir => supervisor `CHILD_EXIT` reconcile eder.
- Once bir de-risking probe ile stok control-plane'in dev/JSON modunda headless
  calistigi kanitlandi (health 200, bootstrap 201 + `sovereign_session` Secure'siz
  loopback cookie, session authenticated, ikinci bootstrap 409); sonra adapter
  yazildi.
- Kanit (bu makine, izole, ucretsiz): product-host unit **25/25**; tam focused
  Sovereign node **148/148** (config 13/supervisor 44/ipc 14/ipc-trust 19/runtime
  18/webview 15/product-host 25); acceptance `test:sovereign:product` **50/50, 2x
  exit 0, 0 orphan** (first cycle static+auth bootstrap->cookie->session; restart
  ayni DATA_DIR: setupRequired false + bootstrap 409 + login 200 + session;
  supervised faz: GERCEK `createSovereignSupervisor` start->owned(token)/healthy/
  surface index 200 + api proxied 200/reach 200/stop->portlar serbest+cp olu);
  tam `test:desktop:platforms` **457 test / 454 pass / 1 fail (onceden var olan
  ilgisiz `update-relaunch` Linux-path) / 2 skip**; in-scope ESLint 0/0 (scripts/
  *.mjs mevcut linlenmemis-harness konvansiyonunu izliyor); `tsc --noEmit` temiz;
  `diff --check` temiz; yeni dosyalar LF.
- Read-only host: 4310-4321 serbest, 0 orphan; korunan gateway'ler degismedi
  (8642/11692, 8643/17636, 8644/8680); uc `\Sovereign\` task `Ready`/0.
- Durust sinirlar: yerel JSON dilimi (worker/Temporal/Postgres/NATS/provider/
  computer yurutmesi kanitlanmadi); dev auth-encryption secret sabit yerel sabit
  (local-first icin dogru, production degil); WebAuthn/MFA step-up denenmedi
  (canonical `localhost:<port>` gerekebilir); ephemeral API-port seciminde ihmal
  edilebilir loopback TOCTOU (fail-closed); cross-restart ownership persist yok;
  paketli/imzali Electron GUI E2E, durable takeover, active-input approval E2E
  BEKLIYOR. Commit yok.

## 26 Temmuz 2026 - Sovereign product-host launcher + paketleme + in-process acceptance duzeltmesi (Opus, Max)

Kapsam: yalniz HERMES deposu; harici Sovereign kaynagi (`e314314`) DEGISMEDI;
flag varsayilan KAPALI; commit yok; korunan 8642-8644 ellenmedi.

- Kok launcher `scripts/start-hermes-sovereign-desktop.ps1`: mevcut
  `start-hermes-desktop.ps1`'i saran, product-host ortamini YALNIZ o cocuk cagri
  icin kuran ince sarmalayici. SourceRoot varsayilan harici checkout (mutlak
  override); DataDir HERMES_HOME altinda dayanikli ve kaynak agacinin DISINDA;
  sistem Node mutlak yola cozulur + surum kapisi (^20.19 || >=22.12); localhost
  urun origin'i `http://localhost:4312/` (WebAuthn canonical), ic API
  127.0.0.1:4310, ozel saglik yolu `/__hermes/health`. Launch oncesi fail-closed
  dogrulama: kaynak containment/build artefaktlari, data-dir ayrimi, ayri izinli
  loopback portlar, rezerve gateway portlari, mesgul portlar, adapter dosyalari,
  JSON argv. Nested launcher donunce (basari VEYA hata) ortam TAM geri yuklenir
  (try/finally, tam env snapshot). Token/cookie/parola/API anahtari basilmaz.
- Paketleme: adapter uclusu (scripts/*.mjs + electron/*.cjs x2) minimal
  `extraResources` ile paketlenmemis, harici-Node-okunur resources dizinine
  kopyalanir; `scripts/*.mjs -> ../electron/*.cjs` goreli import iliskisi korunur.
  Harici Sovereign kaynagi/DATA_DIR pakete GIRMEZ. Launcher paketli yolu tercih
  eder, yoksa kaynak adapter'e (gelistirme fallback) duser.
- package.json: `test:sovereign:product:unit` (product-host unit) ve
  `test:sovereign:product:accept` (gercek acceptance) eklendi; `test:desktop:platforms`
  icindeki product-host unit korundu (CRLF korundu, 0 lone-LF).
- `scripts/sovereign-product-accept.mjs` GUNCEL in-process mimariye gore yeniden
  yazildi: grandchild varsayimlari/yorumlari kaldirildi; TEK adapter pid HEM urun
  HEM ic API portunu sahiplenir (`sole.pidOwnsBothPorts`), node grandchild YOK
  (`sole.noNodeGrandchild` - Windows `conhost.exe` zararsiz console host'u disinda
  tutuldu, control-plane dist'inde `child_process`/`fork`/`spawn`/`worker_threads`
  yok); orphan sweep artik `sovereign-product-host.mjs` node surecini arar; auth
  istekleri canonical `Origin: http://localhost:<port>` tasir (127.0.0.1 transport
  korunur); varsayilan kaynak kok mevcutsa otomatik kesfedilir, yoksa durustce SKIP.
- Sozlesme testi `scripts/start-hermes-sovereign-desktop.test.ps1` (Pester yok,
  verify.ps1 deseni; UI baslatmaz): env geri yukleme basari+hata, malformed/relative
  red, source/data ortusme red, korunan+mesgul+ayni port red, eksik adapter/artefakt
  red, argv JSON bosluk round-trip, feature opt-in.

Kanit (bu makine, izole, ucretsiz, olcum 26 Temmuz):
- product-host unit `node --test`: **42/42**.
- Launcher sozlesme testi: **43/43**, exit 0 (2x).
- Gercek product acceptance `test:sovereign:product` (stok harici Sovereign,
  otomatik kesif): **53/53, 2x exit 0, orphan sweep 0** - first+restart cycle
  (static + auth bootstrap 201 -> hardened `sovereign_session` cookie -> session;
  restart ayni DATA_DIR: setupRequired false + bootstrap 409 + login 200 + session)
  + supervised (gercek `createSovereignSupervisor` owned(token)/healthy, surface 200
  + `/api/auth/status` proxied 200 + reach 200, stop -> iki port serbest + tek pid
  olu + node grandchild 0).
- Odakli Sovereign `node --test`: **165/165** (config 13/supervisor 44/ipc 14/
  ipc-trust 19/runtime 18/webview 15/product-host 42).
- `tsc -p . --noEmit` temiz; package.json CRLF korundu (0 lone-LF); yeni .ps1/.mjs
  LF; `git -c core.whitespace=cr-at-eol diff --check` temiz.
- Read-only host: 4310-4319 serbest (0 listener); korunan gateway'ler degismedi
  (8642/11692, 8643/17636, 8644/8680); 0 lingering adapter node sureci; harici
  Sovereign `e314314` temiz.
- Durust sinirlar (yeni/kesin): paketli electron-builder pack CALISTIRILMADI
  (`extraResources` yapilandirildi ama paket URETILMEDI); paketli/imzali Electron
  GUI E2E YOK - iddia edilmiyor. Launcher'in localhost bind'i uctan uca calistirilmadi
  (sozlesme yapisal dogrulandi; acceptance 127.0.0.1 transport + localhost Origin).
  Yerel JSON dilimi sinirlari degismedi. Commit yok.

## 9 Eylul 2026 - Kurulu Hermes onarimi + yerel ozellestirmelerin main'e tasinmasi (Opus 5/Max)

Kapsam notu: bu is HERMESAGENT urun kaynagini DEGISTIRMEZ. Konu, kullanicinin
makinesindeki vendor kurulumudur: `C:\Users\MSI\AppData\Local\hermes\hermes-agent`
(upstream `NousResearch/hermes-agent` klonu). Proje agaci `runtime/hermes-agent`
ve Sovereign kaynagi bu calismada hic dokunulmadi.

Belirti: desktop bootstrap installer `repository` asamasinda duruyordu -
`git checkout main failed (exit 1)` / `error: pathspec 'main' did not match`.

Kok neden (iki ayri ariza):
- Klon vaktiyle tag'e sabitlenerek kurulmus ve `remote.origin.fetch` degeri
  `+refs/tags/v2026.7.7.2:refs/tags/v2026.7.7.2` kalmisti. Bu refspec YALNIZ o tek
  tag'i cekiyor, `refs/remotes/origin/*` hic olusmuyordu. `git fetch origin main`
  sadece FETCH_HEAD yaziyor, ardindan `git checkout main` ne yerel dal ne de
  `origin/main` bulabiliyordu.
- `.git/shallow.lock` 12 Agustos'tan kalma bayat kilitti (calisan `git.exe` yoktu),
  shallow fetch'i blokluyordu.

Duzeltme: refspec standarda dondurüldü (`+refs/heads/*:refs/remotes/origin/*`),
bayat kilit yedeklenip kaldirildi, `origin/main` cekildi, `core.autocrlf=false`
sabitlendi. Kurulum betiginin kendi `-Stage repository` protokolu ile dogrulandi:
`{"ok":true}` / `[OK] Repository ready`.

Kurulum tamamlandi (asama asama, hepsi `ok:true`): repository, python (3.11.15
kuruldu), venv, dependencies (hash-verified), node-deps (124 sn, CUA surucusu
dahil), desktop, path, config-templates (58 skill), platform-sdks,
bootstrap-marker. Sonuc: `Hermes Agent v0.21.1 (2026.9.7) · upstream ead7e91d`,
`.hermes-bootstrap-complete` yazildi, Hermes.exe (214 MB) + Masaustu/Baslat
kisayollari. Kullanici ayarlari (`.env`, `config.yaml`, `auth.json`, 15-16 Temmuz)
repo dizininin disinda oldugu icin dokunulmadi.

Yerel ozellestirmeler: kurulu kopyada 12 dosyada 675 satir elle yapilmis degisiklik
vardi (Kanban Command Center: paused/cancelled durumlari, `/api/kanban/tasks`,
desktop UI, i18n, Xiaomi MiMo fiyatlandirmasi, 3 test dosyasi). Installer bunlari
autostash etmisti; v2026.7.7.2 tabanina gore yazildiklari icin main'e dogrudan
uygulanamiyorlardi (8 dosyada cakisma). CRLF gurultusu ayiklanip (9143 satirlik
sahte fark -> 675 gercek satir) temiz bir taban commit'i uretildi ve main uzerine
cherry-pick edilerek 15 cakisma blogu elle cozuldu.

Tasima kararlari (dal `local-custom-20260909`, commit `ed97e53bb`):
- `web_server.py` -> yeni `web_routers/kanban.py`: upstream route'lari
  `web_routers/`'a tasidigi icin endpoint'ler kendi modulunde. `connect_closing`
  kanonik `kanban_db_connect` yolundan aliniyor - eski `kanban_db` yolu
  **2026-09-14'te kaldiriliyor** (deprecation uyarisi testte yakalandi).
- `hermes.ts` -> yeni `api/kanban.ts`: upstream hermes.ts'i barrel'a cevirmis.
- `usage_pricing.py`: Xiaomi MiMo v2.5/v2.5-pro upstream'in yeni `_SNAPSHOTS`
  formatina; `"xiaomi"` `_SNAPSHOT_PROVIDER_ALIASES`'a (eski set kaldirilmisti).
- `kanban_db.py`: `paused_from_status` upstream'in `_TASK_EMPTY_IS_NULL_COLUMNS`
  listesinden okunuyor (`from_row` artik kompakt `g()` yardimcisi).
- `analytics`: `_fill_missing_usage_estimates` `web_routers/analytics.py`'ye
  tasindi; testin importu yeni konuma guncellendi.
- `command-center`: `navGroups`'a `tasks -> Clipboard` ikon dali eklendi.

Reddedilenler (gerekce ile):
- Pairing endpoint'leri: upstream bunlari `web_routers/ops.py`'de zaten uyguladi;
  yerel 166 satirlik kopya gereksizdi.
- `cryptography==48.0.1`: upstream 50.0.0'da (CVE-2026-69247, GHSA-m2h6-j472-rp4c,
  GHSA-jwv3-5hgf-82ww). Yerel pini almak CVE'leri geri getirirdi.

Kanit (bu makine, olcum 9 Eylul):
- pytest **11/11** gecti (test_usage_pricing_xiaomi, test_web_server_kanban,
  test_web_server_usage_pricing), 0 uyari.
- `npm run typecheck` (3 tsconfig) temiz; dokunulan 5 TS dosyasi icin eslint temiz.
- Desktop yeniden derlendi; bundle'da `api/kanban/tasks` dogrulandi
  (`dist/assets/hermes-uPD9OjNe.js`).
- `hermes --version`: v0.21.1 (2026.9.7), "Up to date".

Durust sinirlar:
- Gercek GUI E2E YAPILMADI. Command Center'in kullanici gozuyle acilip gorev
  olusturdugu tiklama testi yok; kanit birim/tip/lint/build seviyesinde.
- Upstream'in tam test paketi calistirilmadi; yalniz kullanicinin 3 test dosyasi.
- `KanbanTaskStatus` frontend tipi `paused`/`cancelled` icermiyor, ama backend
  `VALID_STATUSES` iceriyor. Backend bu iki durumu dondurursa `TASK_STATUS_DOT`
  aramasi `undefined` verir. Bu yerel tasarimda ONCEDEN vardi, tasima yaratmadi;
  giderilmedi.
- Aktif dal `local-custom-20260909`. Installer'in guncelleme yolu `git checkout main`
  yapar; sonraki `Retry install` / `hermes update` ozellestirmeleri uygulamadan
  DUSURUR (dal ve commit durur, kaybolmaz).

Yedekler: `backups/hermes-install-repair-20260909/` (stash yamalari, izlenmeyen
test dosyalari, shallow yedegi, onceki durum kaydi). Eski HEAD
`hermes-pre-repair-20260909` dal/tag olarak sabit. Autostash `stash@{0}` guvenlik
agi olarak korundu.

## 18 Eylul 2026 - Trendyol salt-okunur MCP koprusu (Fable 5.1; kullanici model politikasini bu oturum icin acikca degistirdi)

Kapsam: kullanicinin vendor Hermes kurulumu (profil `owner-orchestrator`) icin
Trendyol magaza verisine SALT-OKUNUR erisim. HERMESAGENT urun kaynagi ve
Sovereign DEGISMEDI; yeni kod `tools/trendyol-mcp/` altinda (untracked, commit yok).

Arastirma (resmi kaynak, 18 Eylul): Trendyol'un reklam API'si YOK - developers.trendyol.com
endpoint listesinde 10 alan var (urun, stok/fiyat, siparis/kargo, iade, webhook, fatura,
soru-cevap, finans, kargo, export), reklam/kampanya alani yok; reklam yalniz Satici
Paneli > Reklam Yonetimi'nden elle verilir. Resmi "Trendyol Developer Tools" MCP'si
(Apache-2.0, SSE, anonim erisilebilir) yalniz dokuman/sozlesme araclari sunar
(getEndpoint, validatePayload...), canli satici verisi vermez. Topluluk `trendyol-mcp`
(theyahia) GitHub'da 404 - dogrulanamadi, elendi. Karar: kendi minimal sunucu.

Kesinlestirilen sozlesmeler: taban `https://apigw.trendyol.com/integration`
(stage: `stageapigw`), Basic Auth (apiKey:apiSecret), zorunlu
`User-Agent: "{sellerId} - SelfIntegration"` (yoksa 403), uc basina 50 istek/10 sn;
siparis `GET /order/sellers/{id}/orders` (size<=200), iade `.../claims` (size<=200),
hakedis `GET /finance/che/sellers/{id}/settlements` (size 500|1000, aralik<=15 gun,
transactionTypes zorunlu), `.../otherfinancials` (ayni), urun V2
`GET /product/sellers/{id}/products/approved` (size<=100, page*size<=10000, nextPageToken).
Product V2 gecis son tarihi 15 Eylul 2026 GECTI - V2 yolu kullanildi.

Tasarim (guvenlik oncelikli):
- Yalniz GET; stok/fiyat/urun/siparis degistiren arac yok. Tum araclar
  `ToolAnnotations(read_only_hint=True)`.
- Sirlar YALNIZ profil `.env`'de (`TRENDYOL_API_KEY/SECRET/SELLER_ID`, istege bagli
  `TRENDYOL_STAGE`). Hermes sunucuya yalniz dosya YOLUNU (`TRENDYOL_ENV_FILE`) gecirir;
  config.yaml'a deger yazilmadi (grep ile dogrulandi: 0 eslesme).
- Alici PII (ad, e-posta, TCKN, adres, `customer*`) siparis satirlarindan atilir (KVKK).
- Oran siniri 4 istek/sn, 429'da Retry-After/backoff (3 deneme), 401 -> AuthError.
- Tarihler 'YYYY-AA-GG' Istanbul saati -> epoch ms; siparis 14 gun, finans 15 gun
  pencere zorlanir; `trendyol_sales_summary` <=92 gunu 14'luk parcalara boler,
  sayfa siniri asilirsa `truncated_chunks` ile ACIKCA bildirir (sessiz eksik toplam yok).
- `mcp 2.0.0` API'si introspection ile dogrulandi: `mcp.server.mcpserver.MCPServer`
  (`fastmcp` yok), anotasyon alanlari snake_case. `_guard` sarmalayici
  `functools.wraps` ile - aksi halde arac semalari bos cikiyordu (yakalandi, duzeltildi).

Dosyalar: `tools/trendyol-mcp/trendyol_client.py` (SDK'dan bagimsiz cekirdek),
`server.py` (7 arac: status, orders, claims, settlements, other_financials, products,
sales_summary), `test_trendyol_client.py`, `README.md`.

Kanit (bu makine, 18 Eylul):
- pytest `tools/trendyol-mcp`: **20/20** (MockTransport; ag yok). Ilk kosuda 19/20 -
  hata benim beklenen sabitimdeydi (1 saat), kod dogruydu; sabit duzeltildi.
- Cevrimdisi uctan uca: 7 arac listelendi, hepsi read_only, semalar dolu; kotu tarih ve
  eksik kimlik `{"error": ...}` olarak dondu (traceback yok).
- `hermes mcp add trendyol ...` (stdin'e 'Y' boru ile; prompt EOF'ta iptal ediyor):
  `Saved ... (7/7 tools enabled)`. `hermes mcp list`: enabled. `hermes mcp test trendyol`:
  **Connected (3906ms), Tools discovered: 7** - Hermes'in kendi stdio istemcisiyle.
- Hermes `validate_mcp_server_entry`: Python betikleri acikca serbest (yalniz IOC ve
  kabuk egress/persistence sekilleri bloklu); giris temiz kabul edildi.

Durust sinirlar:
- CANLI HESAPLA E2E YAPILMADI: kimlik bilgileri henuz `.env`'de yok; `trendyol_status`
  su an `configured: false` doner. Gercek veriyle dogrulama kullanici anahtari
  girdikten sonra.
- Urun V2 yanit semasi (ApprovedContent/ApprovedVariant) dokumandan tam
  cikarilamadi; `trendyol_products` icerigi jenerik olarak gecirir, `images/attributes`
  atar. Canli denemede sema surprizi olabilir.
- Siparis ucu icin 14 gun siniri dokumanda yazmiyor; deneyime dayali ihtiyati secim.
- Reklam verme otomasyonu bilincli olarak KAPSAM DISI (API yok; panel surme riskli).
- Kayit yalniz `owner-orchestrator` profilinde. Diger profiller gormez.
- `tools/trendyol-mcp/` untracked; commit kullanici isterse.

### 18 Eylul 2026 (devam) - Bastan denetim (Fable 5.1): taze kanitla durum tespiti

Kullanici "durumu bastan ele al" dedi; onceki turlarin anlatimina degil olcume dayanildi.

Olculen durum: vendor Hermes `local-custom-20260909` @ `ed97e53bb`, temiz; `hermes --version`
v0.21.1, **"Update available"** (upstream 1 commit ileride). `TERMINAL_ENV=local`. MCP: `trendyol`
enabled. Profil `.env`'de TRENDYOL_* YOK -> kopru atil. Profil varsayilan modeli `mimo-v2.5`
(masaustundeki "Pro" oturumluk secim; profilin kendi tarifi "dusuk maliyetli router" oldugu icin
varsayilani Pro yapma onerisi GERI CEKILDI - kullanicinin cok-profilli yonlendirme tasarimiyla celisir).
Docker kapali (local modda gerekmiyor). Artik: `win-unpacked.bak` 385 MB (silinmedi).

Bulunan kusur (benim onceki komutumdan): 9 Eylul'de kullaniciya verilen
`Set-Content -Encoding utf8` PS 5.1'de profil `.env`'in basina BOM yazdi (`ef bb bf` dogrulandi).
Etki: YOK - 1. satir yorum ve Hermes yukleyicisi `utf-8-sig` kullaniyor
(`hermes_cli/env_loader.py:229`). Ancak `trendyol_client.load_config` duz utf-8 okuyordu;
ilk satir anahtar olsaydi adi `\ufeffTRENDYOL_API_KEY` olurdu. Duzeltme: `dotenv_values(...,
encoding="utf-8-sig")` + regresyon testi `test_load_config_survives_bom_on_first_key`.

Yeni: `tools/trendyol-mcp/setup-credentials.ps1` - kimlik bilgilerini YEREL pencerede sorar
(Key/Secret `-AsSecureString`), asistandan/sohbetten/gecmisten gecirmez; eski TRENDYOL_*
satirlarini degistirir, BOM'suz UTF-8 yazar (mevcut BOM'u da temizler), yedek alir, sonunda
`load_config` ile dosyayi dogrular. Gerekce: kullanici elle `.env` duzenlemede zorlaniyor ve
otomatik mod asistanin o dosyaya yazmasini (haklı olarak) engelliyor.

Kanit: pytest `tools/trendyol-mcp` **21/21**. Betik SAHTE degerlerle gecici kopyada sinandi
(gercek `.env`'e dokunulmadi): BOM silindi (`23 20 50`), 3 kosuda baslik 1 / TRENDYOL satiri 3,
eski deger degisti, yedek olustu; bosluklu key ve harfli ID net hatayla reddedildi ve dosya
hash'i DEGISMEDI. Ilk surumde baslik yorumu her kosuda cogaliyordu - testte yakalandi, duzeltildi.

Acik riskler (oncelik sirasiyla): (1) kopru anahtarsiz - kullanici betigi calistirmali;
(2) "Update available" dugmesi `git checkout main` yapip ozellestirmeleri uygulamadan dusurur -
guvenli guncelleme akisi hala BEKLIYOR (ROADMAP); (3) web arama anahtari yok; (4) 25 toolset'in
~8'i anahtarsiz/donanimsiz (spotify, homeassistant, yuanbao, x_search, image/video_gen...) -
kucuk modelde her cagrida token ve arac secimi maliyeti; kullanici "hepsini ac" dedigi icin
dokunulmadi, kirpma ONERILIR; (5) charter "yalniz Opus 5" diyor, kullanici Fable secti - politika
satiri kullanici isterse guncellenmeli. Canli Trendyol E2E hala YAPILMADI.
