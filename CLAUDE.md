# HERMES / Sovereign - Claude Baslangic Talimati

Son guncelleme: 19 Temmuz 2026

Claude Code disindaki bir Claude sohbetine devir yapilacaksa hazir ilk mesaj
`CLAUDE-START-PROMPT.md` icindedir.

Bu dosya Claude'un proje icin birinci giris noktasidir. Proje tek bir chatbot
degildir: kullanicinin denetiminde calisan, sohbet, kalici ajan gorevi, proje,
tarayici, bilgisayar, kod, arastirma, otomasyon, hafiza, onay, kanit ve artifact
yeteneklerini tek urunde birlestiren profesyonel bir masaustu ajan platformudur.

## Her Oturumda Okuma Sirasi

1. `docs/CLAUDE-CODE-MASTER-HANDOFF.md` - eksiksiz urun, kullanici ve teknik devir.
2. `docs/CLAUDE-CODE-EXECUTION-CHARTER.md` - baglayici icra kararlari ve sira.
3. `docs/research/MANUS-OPEN-MODEL-RESEARCH.md` - zorunlu guncel Manus ve model arastirmasi.
4. `docs/PROJECT_MEMORY.md` - bugunku kisa ve otoriter durum.
5. `docs/ROADMAP.md` - oncelikli bekleyen isler.
6. `docs/AUDIT-2026-07-18.md` - tarihsel uctan uca denetim ve aciklar.
7. `docs/CLAUDE-HANDOFF.md` - ayrintili teknik tarihce ve onceki devir.
8. Yapilacak ise ait `docs/decisions/*.md` ADR kayitlari.
9. `docs/WORKLOG.md` - kronolojik calisma gunlugu.
10. Gerekirse urun kaynak kodundaki `docs/MASTER-HANDOFF.md` ve `HANDOFF.md`.

Belgeler celisirse su siralama gecerlidir: calisan kod ve yeni test kaniti,
`PROJECT_MEMORY.md`, kabul edilmis ADR, `CLAUDE-CODE-MASTER-HANDOFF.md`, eski
handoff/gunluk, eski prompt. Gercekte test edilmemis bir ozelligi tamamlanmis sayma.

## Kritik Yollar

- Operasyon/kurulum deposu: `C:\Users\MSI\Documents\HERMESAGENT`
- Ana Sovereign urun kaynagi:
  `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent`
- Eski ayrintili tarihsel gunluk: ana kaynakta `HANDOFF.md`
- Eski ozet devir: ana kaynakta `docs/MASTER-HANDOFF.md`
- Geri donus arsivi:
  `C:\Users\MSI\Documents\HERMESAGENT\backups\sovereign-agent-source-20260717-015654.zip`

Guncel durum (P0-A sonrasi, 19 Temmuz): her iki kaynak agaci da kontrollu Git
baseline altindadir. `HERMESAGENT` ilk commit `152bf9a` (tag
`baseline-hermes-20260719`); ana Sovereign urun kaynagi ayri repo olarak ilk
commit `9ca47c7` (tag `baseline-sovereign-20260719`). 18 Temmuz'daki "her sey
untracked" durumu artik gecerli degildir. Yine de once mevcut veriyi koru;
kullanicinin onayi olmadan silme, resetleme, force-push veya temizleme yapma.
`git add .` yasaktir; yalniz explicit pathspec ile stage'le. Commit yalniz
kullanici acikca isterse yapilir.

## Degismez Urun Kararlari

- Sovereign Control Plane gorev, plan, policy, onay, butce, event, artifact,
  dogrulama ve model yonlendirme otoritesidir. Model yetki sahibi degildir.
- Hermes butun urun degil; kisitli genis arastirma ve uzun-ufuk muhakeme
  worker'idir. Credential sahibi yapilmaz.
- Production dayanikliligi Temporal + PostgreSQL + NATS ile saglanir. Yerel JSON
  modu yalniz gelistirme fallback'idir.
- Playwright deterministik tarayici yurutucusudur. Browser Use gelecekteki tercih
  edilen dogal/visual escalation'dir. Skyvern lisans ve telemetry nedeniyle
  varsayilan degildir.
- Windows host yurutucusu CUA Driver'dir. Mouse, klavye, dis yazma, yayinlama,
  odeme ve benzeri etkili islemler onay kapisindan gecmelidir.
- Claude/Manus urun akisi referanstir; kod veya arayuz kopyalanmaz.
- Kullanicinin AgentOS deposu/gecici klonu YALNIZCA istege bagli karsilastirma/
  referanstir. Kanonik kod veya bagimlilik degildir; kopyalanmaz, import
  edilmez, merge edilmez, bagimlilik olarak eklenmez ve degistirilmez. Incelenen
  snapshot'ta ust duzey LICENSE yoktu ve varsayilan olarak farkli, Claude-merkezli
  bir stack'e dusuyordu; bu nedenle hicbir kod alinmadi. Acik-kaynak/Manus
  arastirmasi iptal degil, planli kalir.
- Claude, Manus ve acik-agirlik model arastirmasini resmi kaynaklarla yeniler;
  model secimini uretici benchmark'i veya tek bir `best` iddiasiyla yapmaz.
- Kullanici aktif model ailesini kesinlestirmistir: urun routing'i yalniz MiMo ve
  DeepSeek uzerinden gelistirilir. Qwen, GLM, Kimi veya baska provider kullanici
  acikca istemeden entegrasyon, satin alma veya replacement adayi degildir.
- Son hedef tek, imzali masaustu urunudur. Bugun yerel Hermes masaustu ve
  Sovereign web yurutme yuzeyi iki ayri ama baglantili hattir; birlestirme
  tamamlanmamistir.

## Ilk Yapilacak Kontroller

Kod degistirmeden once:

```powershell
Set-Location 'C:\Users\MSI\Documents\HERMESAGENT'
git status --short

Set-Location 'C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent'
pnpm typecheck
pnpm test
```

Runtime'in calistigini varsayma. Portlari ve health endpoint'lerini yeniden
kontrol et. 19 Temmuz son olcumunde model gateway'leri 8642/8643/8644 `HTTP 200`,
Docker acik, urun servisleri 4310-4321 kapaliydi. Bu yalniz anlik snapshot'tir.

## Guvenlik ve Calisma Kurallari

- `.env`, API anahtari, parola, session token'i, recovery code veya sentetik test
  credential degerini okuma amaci disinda ekrana/belgeye/loga yazma.
- Loopback bind, tenant izolasyonu, MFA step-up, approval ve evidence sinirlarini
  zayiflatma.
- Gercek kullanici verisi uzerinde test hesabi veya toplu mutasyon olusturma.
- Unsigned executable icin Windows Application Control politikasini kapatma.
- `sensitiveRegions` istenen host desktop isi fiziksel redaction tamamlanana kadar
  fail-closed kalmalidir.
- Kullanici Turkce iletisim, proaktif ilerleme, gercek kullanici gibi E2E test ve
  durust tamamlanma raporu bekliyor. Makul ve geri alinabilir teknik kararlarda
  gereksiz onay isteme; para, kalici veri kaybi, production ve geri dondurulemez
  islemlerde onay iste.

## Rol ve Bagimsiz Itiraz Kurali (Baglayici)

- Kod ve dosya degisikliklerini Claude uygular; Codex yonlendirici ve son
  reviewer'dir.
- Claude kor onayci degildir. Codex'in veya kullanicinin teknik onerisi charter,
  guvenlik, veri butunlugu, kanit disiplini veya daha iyi bir muhendislik
  cozumuyle celisirse Claude DURUR, acikca ITIRAZ eder, kanitini ve daha iyi
  alternatifi yazar.
- Her uygulama raporunda `BAGIMSIZ_INCELEME` bolumu bulunur: varsayimlar,
  itirazlar, kabul edilen kisimlar ve daha iyi alternatif.
- Para, kalici veri kaybi, production etkisi, lisans riski ve geri dondurulemez
  adimlar yine acik kullanici onayi gerektirir.

## Claude Code Model Politikasi (Baglayici, 25 Temmuz 2026)

- Claude Code ile yapilan implementation ve review yalniz **Opus 5, efor Max**
  ile calisir. Fable ve Sonnet bu projede kullanilmaz. Onceki "Fable + Opus"
  politikasi bu maddeyle degistirilmistir.
- Model degisimi kullanici kararidir; ajan kendi basina daha ucuz/hizli bir
  modele dusmez.
- **MiMo ve DeepSeek, HERMES/Sovereign runtime'inin provider'laridir** (planner/
  fast/critic/vision/long-horizon rolleri). Claude Code'un kodlama veya review
  modeli degildirler; iki katman birbirine karistirilmaz.

## Oturum Sonu Zorunlulugu

Her anlamli calisma sonunda `docs/PROJECT_MEMORY.md`, `docs/ROADMAP.md` ve
`docs/WORKLOG.md` guncellenir. Yeni buyuk karar `docs/decisions/` altinda ADR olur.
Test komutlari ve gercek sonuclari kaydedilir; test edilmemis kisim acikca yazilir.
Ayrintili kural ve sablon `docs/MEMORY-PROTOCOL.md` icindedir.
