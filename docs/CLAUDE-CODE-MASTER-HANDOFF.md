# Claude Code Ana Proje Devir Kitabı

**Proje:** HERMES / Sovereign Agent Platform  
**Devir tarihi:** 19 Temmuz 2026  
**Dil:** Türkçe  
**Amaç:** Claude Code'un projeyi ilk kez görmesine rağmen ürün hedefini, kullanıcıyı,
geçmiş kararları, çalışan sistemi, eksikleri ve doğru devam noktasını önceki teknik
lider kadar bilerek çalışabilmesi.

Bu dosya Claude Code için ana bağlam belgesidir. Güncel anlık durum
`PROJECT_MEMORY.md`, doğrulama ayrıntıları `VALIDATION.md`, açık işler `ROADMAP.md`,
karar gerekçeleri `docs/decisions/` ve kronoloji `WORKLOG.md` içindedir. Bu dosya
ürün sözleşmesini ve bütün resmi bir arada tutar.

Baglayici ve daha kisa icra sozlesmesi
`docs/CLAUDE-CODE-EXECUTION-CHARTER.md` dosyasindadir.

---

## 1. Claude Code İçin İlk Talimat

Bu projeye sıfırdan başlanmayacak. Yeni bir demo, landing page veya yalnız sohbet
kutusu yapılmayacak. Önce mevcut sistemi okuyup doğrula, sonra kaldığı yerden devam
et.

İlk oturumda şu sırayı uygula:

1. Kök `CLAUDE.md` dosyasını oku.
2. Bu ana devir kitabını baştan sona oku.
3. `PROJECT_MEMORY.md`, `AUDIT-2026-07-18.md` ve `ROADMAP.md` dosyalarını oku.
4. İlgili ADR'leri, özellikle `0009-sovereign-execution-platform.md` dosyasını oku.
5. İki kaynak ağacının gerçekten erişilebilir olduğunu kontrol et.
6. Git, port, Docker, model gateway ve health durumunu yeniden ölç.
7. Eski test sonucunu bugünkü sonuç gibi sunma.
8. Kullanıcıdan gereksiz yere “nereden başlayayım?” diye sorma. P0 sırasından devam et.
9. Her anlamlı çalışma sonunda Memory, Roadmap, Worklog ve Validation'ı güncelle.

Claude Code yalnız kod yazan bir yardımcı değildir. Bu projede kıdemli mühendis,
ürün mimarı, güvenlik sorumlusu, test mühendisi ve teknik lider gibi hareket etmelidir.

---

## 2. Kullanıcının Asıl İstediği Ürün

Kullanıcı Hermes logolu bir chatbot istemiyor. İstenen ürün:

- kullanıcının kontrolünde çalışan;
- mümkün olduğunca açık kaynak bileşenlerden yararlanan;
- normal sohbet edebilen;
- konuşmayı gerektiğinde kalıcı bir ajan görevine dönüştüren;
- görevi planlayan ve uzman worker'lara bölen;
- araştırma, kod, tarayıcı, bilgisayar, dosya ve araç işlemleri yapabilen;
- uzun işi kapanma, kota veya hata sonrasında sürdürebilen;
- kullanıcının ne yaptığını canlı olarak görebildiği;
- riskli adımlarda onay isteyen;
- kullanıcı gerektiğinde tarayıcıyı veya bilgisayarı devralınca gerçekten duran;
- sonucu yalnız metinle değil kanıt, artifact, test ve provenance ile sunan;
- maliyeti izleyen ve uygun modeli seçen;
- önce kişisel kullanım, ileride çok kullanıcılı/ticari ürün olabilecek;
- tek, güvenilir ve imzalı masaüstü uygulamasına dönüşecek

profesyonel bir AI çalışma platformudur.

Kısa ürün tanımı:

> Sohbet edebilen, fakat sohbetle sınırlı olmayan; birden fazla modeli ve açık
> kaynak yürütme motorunu güvenli bir Control Plane altında koordine eden,
> kullanıcının tarayıcısında ve Windows bilgisayarında gerçek iş yapabilen,
> kalıcı, denetlenebilir ve kanıt odaklı kişisel ajan platformu.

### 2.1 Üç ana kullanıcı niyeti

1. **Sohbet:** Hızlı, açık uçlu, streaming konuşma. Her mesaj görev olmak zorunda değil.
2. **Görev:** Plan, worker, event, onay, bütçe, kanıt, artifact ve recovery taşıyan
   kalıcı ajan işi.
3. **Proje:** Kalıcı talimat, dosya, knowledge, skill, sohbet, görev ve artifact bağlamı.

“Tek chatbot değil” ifadesi sohbetin kaldırılması anlamına gelmez. Sohbet ürünün
bir modudur; bütün ürün değildir.

### 2.2 Hedef kullanım alanları

Kullanıcı sistemi şu işler için kullanmak istiyor:

- genel kişisel asistan ve araştırma;
- web kaynaklarını inceleme, karşılaştırma ve raporlama;
- kod yazma, hata bulma, test etme ve proje geliştirme;
- web sitesi ve masaüstü/web uygulaması üretme;
- terminal ve dosya işlemleri;
- tarayıcı ve web uygulaması otomasyonu;
- Windows uygulamalarını kullanma;
- tekrarlanan işlerden automation/skill üretme;
- belge, ekran görüntüsü, fotoğraf, ses ve video inceleme;
- Genspark benzeri servislerde çok adımlı iş yürütme;
- gümüş e-ticaret sitesini yönetme;
- ürün bilgisi ve görseli hazırlama;
- ürünü insan üzerinde veya uygun sahnede gösteren görseller üretme;
- görsel kalite kontrolü ve düzeltme;
- ürün ve görsel yükleme;
- kota/rate limit dolduğunda işi kaybetmeden bekletme;
- daha sonra başka kullanıcılara açılabilecek ürün altyapısı oluşturma.

Bu kullanım alanlarının tamamı bugün canlı kabul edilmiş değildir. Bunlar ürün
vizyonudur; aşağıdaki özellik matrisi mevcut gerçeği ayrıca gösterir.

---

## 3. Kullanıcının Çalışma Tarzı ve Claude'dan Beklentisi

### 3.1 İletişim biçimi

- Varsayılan dil Türkçedir.
- Kullanıcı çoğu zaman kısa, doğrudan ve hızlı mesajlar yazar.
- “Devam et” dediğinde yeni bir plan anlatıp durmak değil, sıradaki somut işi
  uygulamak, test etmek ve raporlamak gerekir.
- Teknik ayrıntıyı bilmek ister ama ana sonucu sade ve dürüst biçimde görmek ister.
- Uzun süre yalnız altyapı yapılıp görünür ürün davranışı oluşmamasına tepki gösterir.
- “Tamam” sözcüğü yalnız gerçekten tamamlanmış ve test edilmiş iş için kullanılmalıdır.

### 3.2 Kullanıcının teknik lidere verdiği yetki

Kullanıcı teknik önerilerini kör emir olarak görmemeni açıkça istedi. Ürün hedefini
koruyarak şunları yapabilirsin:

- ekleme, çıkarma ve yeniden yapılandırma;
- mimari veya veri modeli değişikliği;
- framework/kütüphane değişikliği, gerçekten gerekliyse;
- güvenlik, performans, maliyet ve UX iyileştirmesi;
- eksik profesyonel özellikleri kendiliğinden tespit etme;
- eski veya yanlış kararı ADR ile değiştirme;
- test stratejisini ve iş akışını iyileştirme.

Bu yetki gereksiz yeniden yazma izni değildir. Çalışan sistemi sebepsiz bozma,
trend uğruna teknoloji değiştirme veya sürekli yeniden tasarım yaparak ürünü erteleme.

### 3.3 Karar önceliği

1. Güvenlik ve veri bütünlüğü
2. Gerçekten çalışan ürün
3. Kullanıcı deneyimi
4. Kararlılık ve hata toleransı
5. Sürdürülebilir mimari
6. Performans
7. Ölçeklenebilirlik
8. Maliyet verimliliği
9. Geliştirme hızı
10. Görsel ayrıntılar

### 3.4 Açık kullanıcı onayı gereken işler

- para harcama, ödeme veya ücretli abonelik;
- gerçek sipariş veya finansal/hukuki taahhüt;
- mesaj, yayın veya dış dünyaya gönderim;
- production verisini değiştirme;
- hesap, proje, veri tabanı veya kullanıcı verisi silme;
- kalıcı veri kaybı veya geri döndürülemez işlem;
- credential, izin veya güvenlik politikasını değiştirme/zayıflatma;
- yeni ücretli servis, public listener, tunnel, plugin veya MCP server;
- lisans/hukuk riski;
- ürünün temel hedefini değiştirme.

Analiz, dry-run, test, dokümantasyon, düşük riskli düzeltme, yerel backup ve geri
alınabilir mühendislik kararı için sürekli onay isteme.

### 3.5 Kullanıcının özellikle istemediği davranışlar

- Yalnız chatbot yapıp bunu ajan platformu diye sunmak.
- UI'da sahte ilerleme veya fixture sonucu gerçekmiş gibi göstermek.
- “Computer takeover” düğmesi koyup agent aksiyonunu gerçekten durdurmamak.
- Gerçek uygulamayı kullanıcı gibi denemeden işi bitmiş saymak.
- Eksik özelliği yalnız raporlayıp güvenli düzeltme mümkünken bırakmak.
- Her küçük kararda tekrar kullanıcı onayı istemek.
- Eski promptu sorgulamadan uygulamak.
- API anahtarını sohbete istemek veya loga yazmak.
- Kullanıcı “devam et” dediğinde yalnız yeni bir yapılacaklar listesi üretmek.

---

## 4. Geçmişte Yaşanan Temel Yanlış Anlama

İlk çalışma hattı Hermes native uygulamasını ciddi biçimde geliştirdi. Ancak ürün
bir noktada hâlâ kullanıcıya büyük ölçüde sohbet yüzeyi gibi görünüyordu. Kullanıcı
bilgisayarın gerçek görüntüsünü, gerçek devralmayı ve geniş ajan davranışını göremediği
için “bu bir chatbottan ibaret” şeklinde güçlü tepki verdi.

Bu geri bildirim teknik yönü değiştirdi:

- Hermes artık bütün ürün ve bütün yetki sahibi değildir.
- Sovereign Control Plane görev, policy, onay, event, bütçe, artifact ve verification
  otoritesidir.
- Hermes restricted reasoning worker olarak kalır.
- Gerçek web işi, gerçek Windows capture ve execution-lock takeover ayrı Sovereign
  hattında kanıtlandı.
- Son hedef bu iki hattı tek imzalı masaüstü üründe birleştirmektir.

Claude Code bu hatayı tekrar etmemelidir. Yeni bir sohbet maketi yapmak ilerleme
sayılmaz. Görünür kullanıcı akışı gerçek backend davranışına bağlanmalıdır.

---

## 5. Proje Topolojisi ve Kritik Yollar

### 5.1 HERMES operasyon ve native ürün paketi

```text
C:\Users\MSI\Documents\HERMESAGENT
```

İçeriği:

- Hermes `v0.18.2`, tag `v2026.7.7.2` yönetim paketi;
- native Electron Phase 8 kaynak/patch çalışmaları;
- kurulum, başlatma, doğrulama, routing ve backup scriptleri;
- beş kişisel model profili için template/contract;
- ADR, Security, Operations, Validation ve Claude handoff belgeleri;
- rollback snapshot'ları.

Yönetilen Hermes kaynağı:

```text
C:\Users\MSI\Documents\HERMESAGENT\runtime\hermes-agent
```

Güvenilir kurulu fallback:

```text
C:\Users\MSI\AppData\Local\hermes\hermes-agent
```

### 5.2 Sovereign ana yürütme ürünü

```text
C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent
```

Bu klasör asıl Fastify Control Plane, React UI, Temporal workflow ve capability
worker'larını taşır. Paket adı `sovereign-agent-platform`, sürüm `1.0.0-rc.1`,
package manager `pnpm@11.7.0`.

**Kritik taşıma uyarısı:** Yalnız `HERMESAGENT` klasörü Claude Code'a verilirse
Sovereign kaynak kodu eksik kalır. Aynı makinede mutlak yol erişilebilir olmalı;
başka makine/Cloud ortamına taşınacaksa iki kaynak ağacı birlikte taşınmalı ve
yeni yollar `CLAUDE.md`/Memory içinde güncellenmelidir.

### 5.3 Yerel profil ve veri yolları

Hermes profilleri:

```text
C:\Users\MSI\AppData\Local\hermes\profiles
```

Bu dizinlerde provider credential, auth ve kullanıcı state'i olabilir. Git'e,
Claude prompt'una veya transfer paketine kopyalanmaz.

İzole Sovereign kabul verisi:

```text
C:\Users\MSI\Documents\HERMESAGENT\runtime\sovereign-audit-data
```

Bu data yalnız audit içindir ve `.gitignore` kapsamındadır.

### 5.4 Geri dönüş noktası

```text
C:\Users\MSI\Documents\HERMESAGENT\backups\sovereign-agent-source-20260717-015654.zip
```

- 536 entry
- 1.988.680 byte
- SHA-256:
  `31d0d84b6f0e9274d4041d3d98c59ac1c99148ff05b5a166eb7ddd7d8a5ede0a`
- Gerçek `.env`, private key, credential veya token dosyası bulunmadı.
- Build çıktıları içerdiği için temiz source release değil, rollback snapshot'ıdır.

---

## 6. Teknik Tarihçe

### 6.1 İlk Hermes kurulumu ve model profilleri

Hermes resmi kaynakları incelendi ve beş izole profil kuruldu:

| Profil | Provider/model | Amaç |
| --- | --- | --- |
| `owner-orchestrator` | Xiaomi `mimo-v2.5` | düşük maliyetli router, basit iş, sentez |
| `owner-fast-worker` | DeepSeek `deepseek-v4-flash` | rutin metin, veri, web, test ve kod |
| `owner-engineer` | DeepSeek `deepseek-v4-pro` | mimari, güvenlik, zor teşhis ve kritik review |
| `owner-vision` | Xiaomi `mimo-v2.5` | görsel, ekran, belge, ses ve video |
| `owner-operator` | Xiaomi `mimo-v2.5-pro` | karmaşık browser/computer operasyonu |

Hermes 0.18.2 child delegation çağrısında her child için güvenilir farklı model
seçemediğinden kırılgan bir hack yapılmadı. Cross-model çalışma kalıcı Kanban
assignee/profil yöntemiyle kuruldu.

Qwen ile geçici local-model deneyi yapıldı, sonra kullanıcı isteğiyle ürün bağlantısı,
UI ve scriptleri kaldırıldı. Daha önce diskte bulunan model ağırlığı veri kaybı
oluşturmamak için silinmedi. Qwen kendiliğinden yeniden bağlanmamalıdır.

### 6.2 Native Hermes Phase 1-8

ADR zinciri yapılan native işleri gösterir:

1. Native desktop primary surface.
2. Native Operations center.
3. Durable task control.
4. Shared spend guard.
5. Native scheduler.
6. Durable human handoff.
7. Local browser takeover.
8. Verified portable recovery.

Native Phase 8'in çalışan yüzeyi:

- sohbet, session history, dosya, proje, artifact, voice, settings;
- profil switching, tool progress ve approval;
- Operations Kanban, task timeline ve attempts;
- pause/resume/cancel;
- tüm profiller için aylık spend guard, kullanım ve tahmini maliyet;
- native scheduler/Cron ve run history;
- CAPTCHA, 2FA, login ve kullanıcı kontrolü için durable `Needs you` handoff;
- redacted reason ve sensitive-note rejection;
- local Chromium live view;
- açık pointer/keyboard takeover;
- dedicated browser window ve fresh-snapshot sonrası agent resume;
- current-user Windows computer use;
- portable backup inspect, manifest, impact preview, pre-import backup ve restore.

Windows Application Control unsigned dış executable'ı engelleyebildiği için managed
launcher kurulu güvenilir runtime'a fallback yapar. Güvenlik politikası kapatılmadı.
Phase 8 signed release değildir.

### 6.3 Sovereign v1.0.0-rc.1 temel platformu

10-15 Temmuz döneminde TypeScript monorepo üzerinde şu temel ürün dilimleri yapıldı:

- ortak task/event/artifact/worker/policy sözleşmeleri;
- Fastify Control Plane ve task engine;
- JSON geliştirme store'u ve PostgreSQL canonical store;
- Temporal workflow/activity;
- NATS JetStream event ve SSE;
- research, coding, browser, computer, tool, Hermes ve MCP worker servisleri;
- planner, deterministic fallback, verifier, retry ve follow-up;
- project, versioned skill, knowledge/retrieval;
- connector, tool, grant ve task-scoped MCP child task;
- automation compiler ve schedule;
- admission/concurrency policy ve overlap handling;
- merkezi approval inbox ve notifications;
- artifact version, SHA-256, export ve SeaweedFS replica contract;
- canonical evaluation/benchmark;
- streaming chat, reconnect ve task promotion;
- chat rename, export, branch provenance, archive/restore/delete;
- auth/session/tenant/organization;
- invitation, member role, password recovery ve device sessions;
- TOTP, WebAuthn passkey, recovery codes ve MFA step-up;
- PostgreSQL RLS ve least-privilege runtime rolleri;
- encrypted backup/verify/dry-run/restore;
- production preflight, health, metrics, rate limit ve security headers;
- failure-recovery ve release acceptance.

15 Temmuz checkpoint'i 110 test, 11 workspace typecheck ve production build ile
geçmişti.

### 6.4 Gerçek execution dilimi, 16-17 Temmuz

Kullanıcının “yalnız chatbot” geri bildiriminden sonra şu işler yapıldı:

- Worker health `degraded` ve `statusDetail` taşıyacak şekilde dürüstleştirildi.
- Fixture-only computer worker tam capability gibi gösterilmedi.
- Dedicated model profilleri ayrıldı: MiMo 8642, DeepSeek 8643, Hermes 8644.
- DeepSeek planning/chat ve MiMo critic/review canlı çağrıları kabul edildi.
- Planner normalization eklendi: start URL fallback, action alias, canonical worker,
  risk düzeltme, unsupported capability rejection ve gereksiz code-step budama.
- `https://example.com/` üzerinde gerçek public-web task tamamlandı.
- Üç evidence ve `research-result.json` artifact üretildi.
- Windows'ta Docker fixture yerine direct CUA Driver 0.8.2 provider eklendi.
- Gerçek 1920x1080 desktop, UI Automation ve Windows Graphics Capture ile okundu.
- Read-only computer task sıfır input aksiyonu, dört evidence ve üç artifact üretti.
- Control ownership `agent | human` gate'i eklendi.
- `/desktop/frame` ve authenticated Control Plane proxy endpoint'leri eklendi.
- Web UI'ya gerçek `Bilgisayar` sayfası, `Devral` ve `Ajana ver` kontrolleri eklendi.
- `human` ownership sırasında sonraki agent aksiyonu gerçekten bloklandı.
- PNG artifact preview, System Refresh ve worker etiketi düzeltildi.
- 390 px mobil overflow bulundu ve giderildi.
- MCP Bridge varsayılan bind'i `127.0.0.1:4319` yapıldı.

17 Temmuz kabulü:

- 119 test, 0 hata;
- 92 Control Plane testi;
- 5 Computer Worker testi;
- 11 TypeScript projesi;
- production build, 1.645 web modülü;
- desktop 1280x720 ve mobile 390x844 browser QA;
- canlı DeepSeek/MiMo routing;
- gerçek web deliverable;
- gerçek Windows capture;
- authenticated takeover/action-lock akışı.

### 6.5 18 Temmuz devir ve audit

- Claude için katmanlı hafıza sistemi kuruldu.
- Dört uzun özgün kullanıcı promptu hash'li olarak arşivlendi.
- Kaynak iddiaları, model profilleri, portlar, backup ve Git görünürlüğü denetlendi.
- HERMES'te başlangıçta 6.303 untracked dosya bulundu.
- Audit/user data, backup, gateway state ve runtime screenshot'ları ignore edildi.
- 6.205 kaynak/kontrol dosyası kontrollü ilk commit bekliyor.
- HERMES `.git` klasörü var fakat geçerli `HEAD` veya ilk commit yok.
- Sovereign kaynak klasöründe `.git` yok.
- 18 Temmuz persisted `.env` snapshot'ı yalnız DeepSeek 8643 yolunu tanımlıyordu.
- Gateway install/receipt/reboot kabulü alınmamıştı; 19 Temmuzda bulunan mevcut
  status/start/stop scripti bu eksiği tek başına kapatmaz.
- TypeScript 11 proje için geçti, routing-report testi 1 geçti.
- Full test Windows `ENOBUFS` nedeniyle MCP testinde tamamlanamadı.
- MCP testinin erken hata yolunda listener/process bırakabildiği görüldü.
- Build tekrarı geçici workspace permission nedeniyle `EPERM` aldı; compile
  regresyonu olarak yorumlanmadı.
- 18 Temmuz snapshot'ında Docker ve bütün ürün servisleri kapalıydı.

---

## 7. Güncel Mimari Karar

Ana karar ADR 0009'dur.

```text
Native desktop shell (nihai tek ürün, henüz birleşmedi)
  -> Sovereign React/Vite UI
  -> Fastify Control Plane
  -> Auth principal + tenant boundary
  -> Planner / deterministic fallback
  -> Temporal durable workflow
  -> policy + admission + approval + budget
  -> capability worker
  -> verifier
  -> artifact + evidence + provenance
  -> PostgreSQL canonical projection
  -> NATS/SSE live events
```

### 7.1 Yetki sınırı

Sovereign Control Plane şunların tek otoritesidir:

- task ve plan;
- workflow state;
- policy ve approval;
- budget ve admission;
- worker/model routing;
- event ve audit;
- artifact ve evidence;
- verification;
- tenant ve authorization.

Hiçbir model workflow veya authorization sahibi değildir.

### 7.2 Hermes'in rolü

Hermes:

- geniş araştırma;
- uzun-ufuk sentez;
- skill önerisi;
- sınırlı delegation

için restricted worker'dır. Credential sahibi genel orkestratör değildir. Yalnız
explicit grant ile araç alır ve çıktısı Sovereign verifier tarafından denetlenir.

### 7.3 Manus yaklaşımı

Manus ürün akışı referanstır, kod/arayüz kaynağı değildir. Alınan kavramlar:

- görünür working browser;
- human takeover;
- local authenticated browser session;
- izole execution;
- somut deliverable;
- canlı plan ve ilerleme.

Manus UI veya implementasyonu kopyalanmayacaktır.

### 7.4 Zorunlu Manus arastirmasi

Claude, eski prompttaki Manus tarifini yeterli saymayacak. Ilk ciddi urun
degisikliginden once resmi Manus dokumantasyonunu yeniden tarayacak; Browser
Operator, Cloud Browser, My Computer, local klasor/terminal izinleri, canli gorev,
takeover ve artifact davranislarini mevcut Hermes ile maddeli gap analizine
donusturecektir. Gizli prompt, kapali kod veya UI kopyalama/reverse engineering
yapilmayacak. Zorunlu akis, kaynaklar ve cikti formati
`docs/research/MANUS-OPEN-MODEL-RESEARCH.md` icindedir.

---

## 8. Teknoloji ve Bileşen Haritası

### 8.1 Uygulamalar

- `apps/control-plane`: Fastify API, auth, stores, task engine, Temporal,
  planner, policy, approval, chat, automation, artifact, health ve computer proxy.
- `apps/web`: React + Vite ürün arayüzü.

### 8.2 Ortak paketler

- `packages/contracts`: Zod/TypeScript canonical sözleşmeler.
- `packages/runtime-backup`: encrypted coordinated backup/restore.

### 8.3 Capability worker'lar

| Worker | Capability | Mevcut motor/durum |
| --- | --- | --- |
| Research | `research.fetch_url` | Fetch + Cheerio, canlı public web kabulü |
| Coding | `code.change` | OpenHands/Daytona/Docker contract; model-driven live kabul eksik |
| Browser | inspect/operate/authenticated | Playwright ana motor; Skyvern optional adapter |
| Computer | inspect/operate/external_write | CUA Windows read-only canlı; etkili write kabulü eksik |
| Tool | `tool.invoke` | grant ve origin-bound secret contract |
| Hermes | wide/long-horizon/skill | restricted Hermes Runs API |
| MCP Bridge | task-scoped invoke | loopback, parent allowlist ve child task |

### 8.4 Durable altyapı

- Temporal: production workflow history ve recovery.
- PostgreSQL: canonical task/auth projection ve RLS.
- NATS JetStream: live event distribution.
- SeaweedFS S3: optional artifact replica.
- JSON: yalnız local development fallback; production durability eşdeğeri değildir.
- Bifrost: OpenAI-compatible provider gateway seçeneği.

### 8.5 Açık kaynak seçimleri

- Playwright: deterministik browser tabanı.
- Browser Use: gelecekte tercih edilen doğal/visual escalation; henüz adapter yok.
- Skyvern: AGPL-3.0 ve default telemetry nedeniyle optional/kapalı.
- OpenHands Software Agent SDK/Agent Server: kod backend adayı, MIT.
- CUA Driver: Windows host executor.
- Agent-S: yalnız strict action schema arkasında optional planner, Apache-2.0.
- GUI-Owl: adapter var, canlı kabul yok.

---

## 9. Model Yönlendirme ve Maliyet İlkesi

Amaç en ucuz modeli seçmek değil; işi güvenli ve doğrulanabilir biçimde bitirme
olasılığı yüksek olan en düşük maliyetli modeli seçmektir.

### 9.1 Rol bazlı model mimarisi

| Rol | Tercih | Amaç |
| --- | --- | --- |
| planner | DeepSeek Pro | şemalı plan, zor teknik ayrıştırma |
| fast/chat | DeepSeek Flash | rutin ve ekonomik iş |
| critic | MiMo | bağımsız review |
| vision | MiMo | ekran/görsel/çok modlu algı |
| long_horizon | MiMo Pro veya restricted Hermes | uzun görev tutarlılığı |

### 9.2 Escalation

Pro modele şu durumlarda yüksel:

- iki anlamlı farklı yaklaşım başarısız olduysa;
- kanıtlar çelişiyorsa;
- yeni güvenlik/veri kaybı riski çıktıysa;
- mimari sınır beklenmedikse;
- kritik sonuç doğrulanamıyorsa.

API outage, rate limit, eksik credential veya ağ hatası “daha akıllı model gerekir”
anlamına gelmez.

Dual-Pro review yalnız ödeme, identity, authorization, büyük production migration,
geri döndürülemez karar, çözülmemiş kritik risk veya açık kullanıcı isteğinde.
İkinci Pro aynı işi baştan yapmaz; risk ve eksikleri inceler.

### 9.3 Guncel acik model arastirmasi

Aktif provider karari kullanici tarafindan verilmistir: Hermes/Sovereign yalniz
MiMo ve DeepSeek ailelerini kullanacaktir. Claude bu iki aile icinde rol, kalite,
fiyat, latency ve uygun model varyantini Hermes eval'i ile secer. Qwen, GLM,
Kimi veya baska model bilgisi yalniz teknoloji takibi ve gelecekte kullanici
isterse degerlendirme icindir; acik kullanici karari olmadan entegrasyon,
satin alma, routing veya replacement yapilmaz. Acik kaynak, acik agirlik ve acik
API terimleri yine dogru ayrilir. Tam arastirma kurali
`docs/research/MANUS-OPEN-MODEL-RESEARCH.md` icindedir.

### 9.4 Güncel operasyon gerçeği

Üç `sovereign-*` profil dizini diskte vardır. Fakat persisted Sovereign `.env`:

- `MODEL_GATEWAY_URL=http://127.0.0.1:8643`
- `MODEL_GATEWAY_DEEPSEEK_URL=http://127.0.0.1:8643`
- planner/fast: `sovereign-deepseek`

durumundadır. `scripts/sovereign-gateways.ps1` üç profili 8642/8643/8644 üzerinde
profil-kapsamlı ve idempotent `status|start|stop` ile yönetmektedir. 19 Temmuz
salt-okunur ölçümünde üç route da loopback'te `HTTP 200` vermiştir. Ancak
install/service receipt, persisted üç-route config ve reboot acceptance yoktur;
restart-tekrar-üretilebilirlik bu nedenle `KANIT GEREKLİ` kalır.

### 9.5 Maliyet

- Native Hermes shared monthly spend guard varsayılan `$10 USD` sınırla kuruldu.
- Unknown price ücretsiz sayılmaz; conservative reserve kullanılır.
- Token ve tahmini maliyet kaydı vardır.
- Provider invoice import/reconciliation yoktur.
- Yerel tahminler kesin fatura gibi sunulmaz.

---

## 10. Port ve Servis Haritası

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
| NATS / monitor | 4222 / 8222 |
| Temporal / UI | 7233 / 8233 |
| SeaweedFS S3 / master | 8333 / 9333 |
| Bifrost | 8088 |
| MiMo / DeepSeek / Hermes profiles | 8642 / 8643 / 8644 |

17 Temmuz izole audit API 4320, web 4321 kullandı. 18 Temmuz denetiminde ilgili
portlar ve Docker kapalıydı. 19 Temmuz anlık ölçümünde Docker açık,
8642/8643/8644 `HTTP 200`, ürün servisleri 4310-4321 kapalıydı.

Port listener tek başına health değildir. `/health`, `/readyz`, worker capability,
provider probe ve gerçek küçük görev birlikte kontrol edilmelidir.

---

## 11. Özellik Durum Matrisi

### 11.1 Canlı veya güçlü biçimde kabul edilmiş

- Native Hermes streaming chat ve profil backend'i.
- Native Operations task board/timeline/attempts.
- Pause/resume/cancel.
- Shared spend guard ve usage estimate.
- Native scheduler ve run history.
- Durable `Needs you` handoff.
- Native local-browser live view/takeover/resume.
- Portable backup inspect/restore.
- Sovereign streaming chat lifecycle.
- Chat reconnect, promotion, branch, export ve archive.
- Durable task/plan/event ve verifier.
- Auth/session/tenant/org.
- Invitation/role ve account security.
- TOTP, WebAuthn, recovery ve MFA step-up.
- Approval/policy/admission/budget.
- Project/skill/knowledge tabanı.
- Automation, notification ve artifact yüzeyleri.
- Encrypted backup/restore ve release hardening.
- Public web task ve JSON deliverable.
- Real Windows read-only inspect.
- Authenticated Computer frame.
- Human takeover execution lock.
- Loopback MCP Bridge güvenlik varsayılanı.

### 11.2 Kod/contract var, canlı ürün kabulü eksik

- OpenHands model-driven coding.
- Daytona execution.
- Skyvern browser escalation.
- Agent-S ve GUI-Owl visual planning.
- Artifact SeaweedFS replica, ortam konfigürasyonuna bağlı.
- Dedicated multi-provider routing, restart sonrası yeniden üretilebilir değil.

### 11.3 Bekleyen

- Tek imzalı native Sovereign uygulaması.
- Durable takeover ownership.
- Düşük gecikmeli frame stream.
- Approval-gated gerçek Windows click/type/write kabulü.
- Host desktop sensitive-region redaction.
- Browser Use adapter ve authenticated-session E2E.
- Project import/export.
- Kullanıcı kontrollü encrypted memory.
- Provider invoice reconciliation.
- Semantic multi-model routing tek canlı chat turn'unda.
- Signed installer/update.
- Accessibility ve localization acceptance.
- Offline/weak-network davranışı.
- Upgrade/migration/soak testleri.
- Production secret manager/certificate/domain/rollback.
- Cloud relay ve production multi-user deployment.

---

## 12. Bilgisayar ve Tarayıcı Davranış Sözleşmesi

### 12.1 Araç önceliği

1. Güvenilir resmi API
2. Resmi connector veya MCP
3. DOM/Playwright
4. Accessibility/UI Automation
5. CUA computer use
6. Visual screen understanding
7. Kör koordinat, yalnız son çare

Sabit koordinata körü körüne güvenme. Uygulama/pencere kimliği, accessible role,
label, DOM locator, metin ve doğrulanmış bounds tercih edilir.

### 12.2 Computer use

- Önce inspect/capture.
- Risk ve hedef pencereyi belirle.
- Human ownership varsa agent action çalıştırma.
- Mouse, keyboard, external write, upload, publish ve payment onay kapılıdır.
- Etkili aksiyon sonrası ekran/DOM/dosya üzerinden doğrula.
- Current-user Windows desktop izole değildir; PII ve görünür pencere riski vardır.
- `sensitiveRegions` redaction uygulanmadığı için istek fail-closed kalmalıdır.

### 12.3 Browser handoff

- CAPTCHA, 2FA, login ve özel kullanıcı adımı modele verilmez.
- Kullanıcı takeover sırasında secret/form değerleri event veya prompt'a yazılmaz.
- Agent geri dönmeden fresh snapshot alır.
- Session/cookie/CDP bilgisi UI projection'a taşınmaz.

---

## 13. Kalıcı Görev ve Recovery Sözleşmesi

Her önemli görev mümkün olduğunca şu alanları taşımalıdır:

- task ID ve tenant;
- objective;
- project/skill/knowledge snapshot;
- plan ve canonical steps;
- capability/worker/model;
- risk ve approval;
- attempt/retry;
- checkpoint ve current state;
- wait/block reason;
- budget/token/cost;
- artifact/evidence;
- input/output hash ve provenance;
- verification;
- next action.

Restart sonrasında:

1. Bekleyen/çalışan görevleri bul.
2. Son durable checkpoint'i oku.
3. Gerçek dış sistem durumunu yeniden inspect et.
4. Kayıtla gerçeği karşılaştır.
5. Tamamlanan side effect'i tekrar etme.
6. Uyuşmazlık varsa re-sync et.
7. Güvenli adımdan devam et.

Upload, product create/update, publish, message, payment, Git commit ve diğer side
effect'lerde idempotency key veya bağımsız tekrar kontrolü gerekir.

Rate limit/kota durumunda işi failed diye atma: checkpoint, reset/retry zamanı,
bekleme nedeni ve kontrollü resume tutulmalıdır.

---

## 14. Güvenlik Değişmezleri

- API anahtarını kullanıcıdan chat'e yazmasını isteme.
- `.env`, auth token, cookie, recovery code, kart/banka ve credential içeriğini
  loga, prompt'a, artifact'a veya handoff'a yazma.
- Profile `.env` ACL'leri kullanıcı + SYSTEM ile sınırlıdır.
- Public listener/tunnel açma; default loopback.
- Model authorization sahibi değildir.
- Worker yalnız gerekli capability/grant alır.
- Tenant principal request'ten gelir; hardcoded tenant kullanma.
- Unsafe request origin/auth/policy/approval'dan geçer.
- Auth token ve invitation ham değerleri kalıcı store'da tutulmaz.
- Production'da auth bypass açılmaz.
- RLS, MFA, rate limit, security header ve audit sınırlarını kolaylık için kapatma.
- Windows Application Control politikasını unsigned build için zayıflatma.
- Backup restore öncesi inspect, hash, path traversal, dry-run ve pre-backup gerekir.
- Gerçek user database/data dir üzerinde E2E yapma.
- `git add .` kullanmadan staged listeyi incele.

Docker blast radius'i azaltır fakat malicious container'a karşı tam güvenlik sınırı
değildir. CUA logged-in kullanıcının yetkisiyle çalışır; approval ana güvenlik kapısıdır.

---

## 15. Test Felsefesi ve Kanıt

Bir özellik şu dört koşul olmadan tamamlanmış değildir:

1. Kalıcı implementasyon
2. Unit/contract testi
3. Hedef ortam E2E
4. Kullanıcının görebildiği gerçek sonuç/kanıt

Test kapsamı:

- happy path ve invalid input;
- unauthorized/forbidden;
- retry, timeout ve dependency failure;
- restart/recovery;
- duplicate/idempotency;
- desktop ve mobile viewport;
- console/network error;
- artifact integrity;
- data/tenant isolation;
- approval bypass;
- secret leakage;
- rollback.

### 15.1 Son başarılı geniş kabul

17 Temmuz 2026:

- 119/119 test;
- 11/11 TypeScript workspace;
- production build;
- 1.645 module web build;
- live provider calls;
- public web task;
- real Windows inspect;
- Computer takeover action-lock;
- desktop/mobile browser QA.

### 15.2 18 Temmuz yeniden denetim sonucu

- 11 proje typecheck geçti.
- Hermes routing-report testi geçti.
- Full test MCP Bridge'de Windows `ENOBUFS` nedeniyle tamamlanmadı.
- MCP test fixture erken hata yolunda sabit 4601 listener/process bırakabiliyor.
- Minimal Node loopback da ENOBUFS üretti; OS/network koşulu gerçek.
- Build tekrarı geçici sandbox permission nedeniyle `EPERM` aldı.
- Docker ve runtime kapalı olduğu için canlı E2E tekrarlanmadı.

Bu nedenle 17 Temmuz kaydı son tam kabul; 18 Temmuz yeni clean baseline değildir.

---

## 16. Bugünkü Kesin Durum

### Çalışan kod var mı?

Evet. İki ciddi kod tabanı, native Phase 8, Sovereign RC, auth/durability/worker/UI
ve gerçek execution dilimleri var.

### Ürün bitmiş mi?

Hayır. Tek imzalı masaüstü ürün, restart-reproducible provider lifecycle ve bazı
canlı capability kabul testleri eksik.

### Runtime açık mı?

Kısmen. 19 Temmuz snapshot'ında yalnız üç model gateway'i 8642/8643/8644
`HTTP 200` ve Docker açıktı; Control Plane/UI/worker ürün servisleri 4310-4321
kapalıydı. Her oturumda yeniden ölç.

### Version control güvenli mi?

Henüz değil:

- HERMES `.git` var ama commit/HEAD yok.
- 6.205 kaynak/kontrol dosyası untracked.
- Sovereign'de `.git` yok.
- Sensitive audit/backup alanları ignore edildi fakat ilk kontrollü baseline bekliyor.

### Provider'lar hazır mı?

Profil dizinleri ve üç profil için status/start/stop scripti var; 17 Temmuz canlı
kabul ve 19 Temmuz üç `HTTP 200` snapshot'ı var. Persisted üç-route config,
install/service receipt ve reboot acceptance eksik.

---

## 17. En Önemli Açıklar

### P0

1. İki kaynak ağacını kapsayan kontrollü Git baseline.
2. Secret ve user data'yı baseline dışında tutma.
3. Mevcut MiMo/DeepSeek/Hermes scriptine install/receipt/stale PID kontrolleri.
4. Gateway reboot/restart ve üç route provider acceptance.
5. MCP ENOBUFS test stratejisi ve her hata yolunda cleanup.
6. Full test/typecheck/build temiz baseline.
7. İzole runtime smoke E2E.

### P1

1. Native Hermes shell ile Sovereign UI/Control Plane integration spike.
2. Native child service lifecycle ve port allocation.
3. Durable computer ownership.
4. Authenticated low-latency frame stream.
5. Approval-gated CUA write E2E.
6. Browser Use authenticated-session E2E.
7. OpenHands model-driven coding E2E.
8. Merged Temporal/PostgreSQL/NATS failure-recovery.

### P2

Encrypted memory, project import/export, invoice reconciliation, signed update,
accessibility, localization, offline, upgrade, soak, observability ve production
deployment hardening.

---

## 18. Claude Code'un Kesin Devam Sırası

### Aşama 0: Taşıma ve baseline

1. İki kaynak klasörünü workspace'e ekle.
2. Diskte gerçek yolları doğrula; yeni makineyse path'leri güncelle.
3. Secret değerlerini göstermeden config-name envanteri çıkar.
4. HERMES ignored data ve Sovereign `.env` dışarıda kalsın.
5. Temiz source snapshot oluştur.
6. Kontrollü Git repo/branch/ilk commit/tag kur.

### Aşama 1: Runtime reproducibility

1. Mevcut dedicated profil lifecycle scriptini kaynak kabul et.
2. Install/receipt ile 8642/8643/8644 port collision ve stale PID kontrolü ekle.
3. Secret'ı command line veya receipt'e koyma.
4. Start/status/stop receipt üret.
5. Her route için health + küçük live probe yap.

### Aşama 2: Clean acceptance

1. MCP fixture teardown'ı düzelt.
2. Windows socket strategy'yi deterministik yap.
3. Full `pnpm test`.
4. Full `pnpm typecheck`.
5. Production `pnpm build`.
6. İzole data dir ile runtime.
7. Chat, public web, Computer frame/takeover/release, artifact export E2E.

### Aşama 3: Tek masaüstü ürün

1. Mevcut Hermes Electron shell içinde Sovereign UI açan ince spike.
2. Control Plane/worker child-process lifecycle.
3. Auth/session ve data path contract.
4. Tek uygulamadan Sohbet -> Görev -> Bilgisayar -> Devral -> Ajana ver -> Artifact.
5. Native screenshot ve restart acceptance.
6. Sonra signed installer/update.

Yeni dekoratif UI veya geniş connector listesi bu P0/P1 işleri bitmeden öncelik değildir.

---

## 19. Çalıştırma ve Doğrulama Komutları

### 19.1 HERMES kontrol paketi

```powershell
Set-Location 'C:\Users\MSI\Documents\HERMESAGENT'
python -m pytest -q tests/test_routing_report.py
.\scripts\verify.ps1
.\scripts\bootstrap.ps1
.\scripts\start-hermes-desktop.ps1
```

`verify.ps1` Docker smoke ve profil `.env` presence kontrolü yapabilir. Gerçek
credential değerini yazdırmamalıdır. Scripti çalıştırmadan parametrelerini oku;
mevcut script `-SkipSmoke` parametresi kabul etmez.

### 19.2 Sovereign

```powershell
Set-Location 'C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent'
pnpm typecheck
pnpm test
pnpm build
pnpm runtime:up
pnpm runtime:status
pnpm runtime:down
```

Durable/acceptance komutları:

```powershell
pnpm infra:up
pnpm models:bootstrap
pnpm acceptance:providers
pnpm acceptance:release
pnpm e2e:chat
pnpm e2e:chat:durable
pnpm e2e:chat:temporal
pnpm e2e:auth:durable
pnpm e2e:auth:ui
pnpm e2e:backup
pnpm e2e:failure-recovery
```

Komutları körlemesine çalıştırma. `package.json`, script, aktif port, Docker ve
data dir'i önce kontrol et. Ana kullanıcı verisi üzerinde test yapma.

---

## 20. Kodlama ve Mimari Çalışma Kuralları

- Önce kodu ve mevcut pattern'i oku.
- Semptom değil root cause düzelt.
- Değişikliği ilgili ownership sınırında tut.
- Gereksiz abstraction ekleme.
- Structured data için parser/schema kullan.
- Her yeni capability'nin health, policy, approval, evidence ve failure durumu olsun.
- Fixture sonucu UI'da açıkça fixture/degraded/test olarak görünsün.
- Model cevabını tek başına başarı kabul etme.
- Her side effect için verification ve mümkünse idempotency uygula.
- Büyük değişiklik öncesi rollback noktası oluştur.
- Kullanıcının önceden var olan değişikliğini veya verisini geri alma.
- Test kapsamını risk ve blast radius'e göre büyüt.
- Desktop ve mobile gerçek kullanıcı akışını Playwright/native screenshot ile dene.
- Production-like durability iddiası yalnız Temporal/PostgreSQL/NATS kabulüyle yapılır.

---

## 21. Kullanıcıya Raporlama Sözleşmesi

Her önemli çalışma sonunda rapor şu sırayı izlemelidir:

1. **Amaç:** Bu turda hangi gerçek ürün problemini çözdün?
2. **Yapılanlar:** Hangi davranış ve dosyalar değişti?
3. **Kullanıcı akışı:** Kullanıcı bunu nerede ve nasıl görecek/kullanacak?
4. **Kanıt:** Hangi test, build, E2E, screenshot, artifact veya health geçti?
5. **Dürüst sınır:** Ne hâlâ partial, untested, blocked veya external?
6. **Güvenlik/veri/maliyet:** Yeni risk, provider çağrısı veya veri etkisi var mı?
7. **Runtime:** Açık URL/port var mı, kapalı mı, nasıl durdurulur?
8. **Sonraki adım:** En yüksek değerli tek sonraki paket nedir?

“Kod yazıldı” yeterli rapor değildir. “Test edilmedi” ise açıkça yazılmalıdır.

---

## 22. Kalıcı Hafıza ve Devir Disiplini

Her çalışma sonunda:

- `PROJECT_MEMORY.md`: bugünkü truth snapshot;
- `ROADMAP.md`: status ve acceptance;
- `WORKLOG.md`: append-only tarihli özet;
- `VALIDATION.md`: gerçek komut ve sonuç;
- `docs/decisions/`: büyük karar/rollback;
- bu master belge: yalnız ürün sözleşmesi, ana mimari veya kullanıcı beklentisi
  değiştiyse

güncellenir.

Durum sözcükleri:

- `TAMAM`: implementasyon + hedef ortam + kullanıcı akışı + kanıt.
- `KISMI`: kalıcı kod var, kapsam veya canlı kabul eksik.
- `KANIT GEREKLİ`: iddia var, bugünkü acceptance tekrarlanmadı.
- `BEKLİYOR`: implementasyon eksik.
- `BLOKE`: dış değişiklik/onay olmadan ilerleme yok.

`connected`, `healthy`, `configured`, `accepted` ve `complete` aynı şey değildir.

---

## 23. Belge ve Kanıt Hiyerarşisi

Çelişki durumunda:

1. Canlı kod ve yeni yeniden üretilmiş test kanıtı
2. `PROJECT_MEMORY.md`
3. En yeni Accepted ADR
4. Bu master handoff
5. `AUDIT-2026-07-18.md`
6. `VALIDATION.md` ve `WORKLOG.md`
7. Eski Sovereign `docs/MASTER-HANDOFF.md`
8. Eski Sovereign `HANDOFF.md`
9. Orijinal prompt arşivi

Özgün kullanıcı promptları:

```text
docs/history/original-prompts/
```

Dört dosya SHA-256 indekslidir. Promptlar ürün niyetinin kaynağıdır; eski teknik
öneri güncel kod/ADR ile çelişirse körlemesine uygulanmaz.

---

## 24. Claude Code'un Yapmaması Gerekenler

- Projeyi sıfırdan yeniden kurma.
- Hermes'i tekrar bütün authorization/yürütme otoritesi yapma.
- Sovereign'i yok sayıp yalnız native chat üzerinde çalışma.
- Native Hermes'i yok sayıp çalışan Phase 8 özelliklerini çöpe atma.
- Qwen'i yeniden bağlama.
- Skyvern'i lisans/telemetry incelemeden default yapma.
- Agent-S'e policy/approval/verifier bypass yetkisi verme.
- JSON fallback'i production durability diye sunma.
- Runtime kapalıyken “çalışıyor” deme.
- 17 Temmuz testini bugünkü test gibi raporlama.
- API key veya AppData profile state'ini taşıma/commit etme.
- Windows policy, MFA, RLS veya approval'ı kolaylık için kapatma.
- Kullanıcıdan tekrar bütün vizyonu anlatmasını isteme.

---

## 25. Claude Code İçin Nihai Teknik Hüküm

Bu proje ne boş bir fikir ne de bitmiş ticari üründür. Ciddi ve değerli bir
native Hermes hattı, production-shaped Sovereign Control Plane, auth/durability,
worker, backup, UI ve gerçek execution kanıtı vardır.

En büyük sorun daha fazla özellik fikri eksikliği değildir. En büyük sorunlar:

1. iki kaynak ağacının kontrollü version-control tabanına alınmaması;
2. üç model gateway'inin install/receipt/reboot kabulünün tamamlanmaması;
3. clean test/runtime acceptance'ın yeniden alınmaması;
4. native Hermes ve Sovereign'in tek üründe birleşmemesi.

Claude Code mevcut emeği koruyarak bu sırayla ilerlemelidir. Hedef kullanıcının
bilgisayarında gerçekten çalışan, görülebilen, gerektiğinde devralınabilen,
kanıt üreten ve güvenli biçimde kaldığı yerden devam eden tek masaüstü ajan
platformudur.

Kullanıcı “devam et” dediğinde yapılacak şey nettir: Memory ve Roadmap'teki en
yüksek öncelikli kabul paketini uygula, gerçek kullanıcı gibi test et, kanıtla ve
hafızayı güncelle.
