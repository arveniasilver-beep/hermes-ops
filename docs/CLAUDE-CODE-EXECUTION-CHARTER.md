# Claude Code Execution Charter

Tarih: 19 Temmuz 2026  
Durum: BAGLAYICI  
Kapsam: HERMESAGENT operasyon/native hatti + Sovereign ana urun kaynagi

Bu belge ayrintili `CLAUDE-CODE-MASTER-HANDOFF.md` kitabinin yerine gecmez. Onu
uygulanabilir kararlara ve siraya donusturur. Celiskide otorite sirasi: yeni
calisan kod/test kaniti, `PROJECT_MEMORY.md`, kabul edilmis ADR, bu charter,
master handoff, eski handoff/gunluk, eski prompt.

## 1. Urun Sozlesmesi

HERMES aracli bir chatbot degildir. Hedef kullanicinin Windows bilgisayarinda,
onun denetiminde calisan tek imzali masaustu ajan platformudur. Sohbet, kalici
gorev ve proje niyetlerini ayirir; planlar, uzman worker'lara dagitir, tarayici ve
bilgisayari gercekten kullanir, kod/arastirma/dosya/otomasyon isi yapar, canli
ilerleme gosterir, riskli adimda onay ister, insan devralinca durur ve sonucu
kanit, artifact, provenance, maliyet ve recovery kaydiyla verir.

Kullanicinin ana akislari: gumus e-ticaret yonetimi; urun gorseli uretme, kalite
kontrol ve yukleme; Genspark/Manus benzeri cok adimli isler; kod, web ve uygulama
gelistirme; arastirma; tekrar kullanilabilir otomasyon ve skill uretimi.

## 2. Degismez Mimari

1. Sovereign Control Plane workflow, authorization, policy, approval, budget,
   routing, event, audit, evidence, artifact, verification ve tenant otoritesidir.
2. Hermes kisitli reasoning worker'idir; credential ve policy sahibi degildir.
3. Production durability Temporal + PostgreSQL + NATS'tir. JSON yalniz local
   development fallback'idir.
4. Playwright deterministik browser tabanidir. Browser Use dogal/gorsel
   escalation hedefidir. Skyvern lisans/telemetry nedeniyle optional ve kapali.
5. CUA Driver Windows host executor'dur. Inspect-first ve approval-gated calisir.
6. Human takeover gercek execution lock'tur; human ownership'te agent aksiyonu
   calismaz, geri veriste fresh snapshot zorunludur.
7. Native Hermes shell ve Sovereign execution hatti korunarak birlestirilir;
   sebepsiz sifirdan yazim yapilmaz.

## 3. Model Sozlesmesi

- Aktif aileler yalniz MiMo + DeepSeek'tir.
- DeepSeek Pro planner, DeepSeek Flash fast/chat, MiMo critic/vision, MiMo Pro
  veya restricted Hermes long-horizon rolundedir.
- 8642 MiMo, 8643 DeepSeek, 8644 restricted Hermes; loopback bind zorunludur.
- Qwen, GLM, Kimi veya baska model, kullanici acikca istemeden entegrasyon,
  routing, satin alma, eval veya replacement adayi olamaz. Bilgi takibi serbesttir.
- Secim ilkesi: isi guvenli ve dogrulanabilir bitirme olasiligi yuksek en ucuz
  uygun model. Escalation kanitli gerekce ve receipt gerektirir.

## 4. Guvenlik ve Onay Siniri

Claude makul, geri alinabilir teknik kararlarda ilerler. Su adimlarda kullanici
onayi zorunludur: para/abonelik, gercek siparis veya taahhut, dis yayin/gonderim,
production verisi, silme veya geri dondurulemez islem, credential/policy
zayiflatma, yeni ucretli servis/listener/plugin/MCP, lisans riski ve urun temel
hedefi degisikligi.

Secret degeri loga/dokumana/sohbete girmez. Loopback, tenant RLS, MFA step-up,
rate limit, approval, budget ve evidence zayiflatilmaz. Gercek kullanici verisi
E2E icin kullanilmaz. `sensitiveRegions` fiziksel redaction bitene kadar
fail-closed kalir. `git add .`, destructive reset/clean ve izinsiz veri silme yoktur.

## 5. Tamamlanma Tanimi

Bir ozellik yalniz su dort kosul birlikte saglanirsa `TAMAM`dir:

1. Gercek kod/entegrasyon vardir; fixture veya maket gercek gibi sunulmaz.
2. Ilgili unit/contract/integration testleri gecer.
3. Hedef Windows/runtime ortaminda gercek kullanici E2E'si gecer.
4. UI'da gorunur kanit ile receipt/artifact/provenance uretilir.

Listener veya `/health` tek basina capability-complete demek degildir. Eski kabul
bugunku health gibi sunulmaz. Her rapor `amac/yapilan/kullanici akisi/kanit/durust
sinir/guvenlik-maliyet/runtime/sonraki adim` basliklarini kapsar.

## 6. Guncel Snapshot

- Son tam urun kabulu: 17 Temmuz 2026, 119/119 test, 11/11 typecheck, production
  build, canli DeepSeek+MiMo, gercek web deliverable, gercek Windows read-only
  capture ve takeover execution lock.
- 18 Temmuz yeniden test: typecheck gecti; full test MCP `ENOBUFS`/teardown
  sorunu nedeniyle yeni temiz baseline olamadi.
- 19 Temmuz: `sovereign-gateways.ps1` status/start/stop mevcut; 8642/8643/8644
  loopback `HTTP 200`; Docker acik; 4310-4321 urun servisleri kapali.
- Gateway install/service receipt ve reboot acceptance yoktur.
- HERMES `.git` dogmamis/ilk commitsiz; 6.205 kaynak/kontrol dosyasi untracked.
  Sovereign kaynak agacinda `.git` yoktur.
- Native Hermes ile Sovereign henuz tek imzali urunde birlesmemistir.

## 7. Kesin Uygulama Sirasi

### P0-A - Veri ve source baseline

Iki agacin secret/user/audit/runtime verisini disarida tutan allowlist envanteri,
geri donus snapshot'i, elle incelenen staged liste, HERMES ilk commit/tag,
Sovereign git init + ilk commit/tag ve rollback dokumani. Commit oncesi staged
liste ve ignore kurallari kanitlanir.

### P0-B - Gateway tekrar uretilebilirligi

Mevcut scripti install/service receipt, stale PID, port collision, secret-safe
health ve status receipt ile tamamla. Profil-kapsamli stop/start ve gercek Windows
reboot sonrasinda uc route health + kucuk canli provider probe'u kanitla.

### P0-C - Temiz kabul baseline'i

MCP sabit port/teardown sorununu dinamik port ve `finally` cleanup ile duzelt.
Izole data dir'de full `pnpm test`, 11 workspace `typecheck`, production build
ve leak kontrolu al. Basarisizlikta yalniz ilgili fixture/process temizlenir.

### P0-D - Gercek runtime smoke

Izole runtime ile authenticated chat, sohbetten goreve gecis, example.com web
gorevi, Bilgisayar frame, Devral/Ajana ver action lock, artifact preview/export
akisini masaustu ve mobilde kanitla. Receipt ve `VALIDATION.md` guncellemesi olmadan
tamam sayma.

### P1 - Tek native urun

Hermes Electron shell icinde Sovereign UI ve Control Plane lifecycle spike'i;
child service start/health/restart/shutdown; durable takeover; dusuk gecikmeli
frame; approval-gated disposable-app click/type/save; host redaction; Browser Use
authenticated-session; OpenHands model-driven coding. Her dilim ayri rollback
noktasi ve E2E ile ilerler.

### P2 - Veri ve urun kalitesi

Kullanici kontrollu sifreli memory, project import/export, invoice reconciliation,
accessibility, Turkce/English localization, offline/zayif ag, upgrade/migration,
backup restore matrisi, soak/failure injection ve observability.

### P3 - Dagitim ve ticari hazirlik

Windows imzali installer/update/rollback, certificate/secret manager, production
deploy, cloud relay ve multi-user acceptance. Para, domain, certificate veya
production etkisi olan adimdan once kullanici onayi zorunludur.

## 8. `Basla` veya `Devam Et` Protokolu

1. Salt-okunur Git/port/Docker/health ve config-name envanteri al.
2. `PROJECT_MEMORY.md` ile celisen yeni gercegi once duzelt.
3. Yukaridaki ilk bitmemis P0 dilimini uygula; yeni dekoratif UI'ya dagilma.
4. Gercek kullanici gibi test et, kanit/receipt/artifact kaydet.
5. Memory, Roadmap, Worklog ve Validation'i ayni turda guncelle.
6. Kanitli sonucu ve durust acigi Turkce, kisa ve dogrudan raporla.

## 9. Rol ve Bagimsiz Itiraz Kurali

Kod ve dosya degisikliklerini Claude uygular; Codex yonlendirici ve son
reviewer'dir. Claude kor onayci degildir: Codex'in veya kullanicinin teknik
onerisi bu charter, guvenlik, veri butunlugu, kanit disiplini veya daha iyi bir
muhendislik cozumuyle celisirse Claude durur, acikca itiraz eder, kanitini ve
daha iyi alternatifi yazar. Her uygulama raporu `BAGIMSIZ_INCELEME` bolumu
tasir: varsayimlar, itirazlar, kabul edilen kisimlar ve daha iyi alternatif.
Para, kalici veri kaybi, production etkisi, lisans riski ve geri dondurulemez
adimlar yine acik kullanici onayi gerektirir.

Claude'un 19 Temmuz derin devir sonucu: `OGRETIM_TAM: EVET`.

## 10. Claude Code Calisma Modeli Politikasi

Gecerlilik: 19 Temmuz 2026 ve sonrasi, ileriye donuk. Kullanici karari olarak
BAGLAYICIDIR. Bu bolum urun model routing'ini (Bolum 3, yalniz MiMo + DeepSeek)
degistirmez; yalniz Claude Code'un kendi calisma modelini baglar.

- Normal ve orta karmasikliktaki uygulama isi Fable 5 ile yapilir.
- Zor mimari, guvenlik, kritik review, migration ve karmasik debugging Opus ile
  yapilir.
- Sonnet yasaktir: cagrilmaz, subagent olarak kullanilmaz, fallback yapilmaz.
- Her Claude Code cagrisi secili model destekliyorsa max effort ile calisir;
  desteklemiyorsa desteklenen en yuksek seviye kullanilir ve raporda belirtilir.
- Sessiz model fallback yoktur; secili model kullanilamiyorsa is durur ve durum
  acikca raporlanir.
- Roller degismez: Codex yonlendirici ve son reviewer'dir; proje dosyalarini
  yalniz Claude yazar.
- 19 Temmuz 2026 oncesine ait, Sonnet kullanildigini dogru bicimde belirten
  tarihsel kayitlar degistirilmez.
