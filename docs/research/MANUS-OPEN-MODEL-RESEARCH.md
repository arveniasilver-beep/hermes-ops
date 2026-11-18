# Manus ve Acik Model Arastirma Talimati

Son resmi-kaynak taramasi: 18 Temmuz 2026

Bu belge bir defalik model listesi degil, Claude Code ve sonraki teknik liderler
icin zorunlu arastirma gorevidir. Hermes/Sovereign gelistirilirken Manus'un urun
yaklasimi ve acik agirlikli modeller duzenli olarak yeniden incelenir. Eski bir
benchmark, model adi veya pazarlama iddiasi mimari karar yerine gecmez.

## Claude'un Zorunlu Gorevi

Claude, ilk ciddi urun veya model-routing degisikliginden once:

1. Manus'un guncel resmi dokumantasyon indeksini ve urun notlarini tarar.
2. Hermes'in mevcut davranisini Manus'un yetenekleriyle ozellik ozellik karsilastirir.
3. Eksikleri `docs/ROADMAP.md` icinde test edilebilir kabul olcutlerine donusturur.
4. MiMo ve DeepSeek ailelerindeki guncel model/rol/fiyat seceneklerini resmi repo,
   model karti, teknik rapor ve lisanslarindan yeniden dogrular.
5. Bu iki aile arasindaki rol dagilimini yalniz Hermes'e ait sabit bir eval
   setinin sonucuyla onerir.
6. Arastirma tarihi, kaynak URL, model revision'i, lisans, maliyet ve donanim
   varsayimlarini bu klasorde tarihli bir rapora kaydeder.

Aktif urun karari kesindir: **yalniz MiMo ve DeepSeek kullanilacak.** Diger acik
modeller hakkinda arastirma, Claude'un teknoloji bilgisini guncel tutmasi ve
kullanicinin sordugu "en iyi acik model" sorusuna dogru yanit verebilmesi icindir.
Kullanici acikca istemeden Qwen, GLM, Kimi veya baska provider entegre edilmez,
satin alinmaz, route edilmez ve MiMo/DeepSeek yerine onerilmez.

Bu tarama en gec 30 gunde bir, ayrica MiMo/DeepSeek model varyanti veya routing
degisikligi oncesinde yenilenir. Ucretli benchmark kosulmadan once tahmini
maliyet hesaplanir ve kullanicidan para harcama onayi alinir.

## Manus'ta Incelenecek Urun Davranislari

Manus kodu, gizli promptu veya arayuzu kopyalanmayacak. Resmi olarak gozlenebilen
urun ilkeleri incelenecek:

- sohbetten bagimsiz, uzun sureli ve gorunur ajan gorevi;
- canli plan, adim durumu, event, hata ve sonuc gorunurlugu;
- somut artifact/deliverable uretimi;
- local Browser Operator ile mevcut Chrome/Edge login ve aktif tablarini kullanma;
- her local-browser oturumunda acik yetkilendirme, eylem logu, durdurma ve devralma;
- genel web isleri icin izole Cloud Browser, gercek zamanli goruntu ve CAPTCHA/2FA
  aninda insana devretme;
- masaustu `My Computer` ile izin verilen klasorlerde dosya ve terminal islemleri;
- yerel terminal komutlarinda `Allow Once`/`Always Allow` benzeri acik kontrol;
- gorevi cihazlar arasinda izleme, arka plan calismasi ve zamanlanmis yerel isler;
- basarisizliktan devam, geri verme ve kullaniciya ne oldugunu gosteren kanit.

Hermes icin cikacak sonuc bir "Manus klonu" degil; local-first, Sovereign policy
ve approval sinirlari icinde daha denetlenebilir bir uygulamadir. Ozellikle:

- local authenticated browser ile izole browser iki ayri capability olmalidir;
- kullanici devraldigi anda ajan input'u teknik olarak kilitlenmelidir;
- devralma ownership'i restart sonrasi korunmalidir;
- terminal, dosya yazma, mesaj/yayin, odeme ve dis etki onay kapisindan gecmelidir;
- her tamamlanma iddiasinda event, evidence ve artifact/provenance bulunmalidir.

## "Acik Kaynak Model" Dili

Asagidaki terimler birbirinin yerine kullanilmaz:

- **Acik kaynak:** Kod, agirliklar ve gerekli bilesenler OSI uyumlu veya acikca
  izin veren bir lisansla erisilebilir; her artifact icin lisans yine kontrol edilir.
- **Acik agirlik:** Model agirliklari indirilebilir, fakat veri, egitim kodu veya
  lisans tam acik-kaynak standardini karsilamayabilir.
- **Acik API:** OpenAI/Anthropic uyumlu endpoint sunmak modeli acik yapmaz.

Raporda model ureticisinin "open source" ifadesi tek basina yeterli kanit degildir.
Model kartindaki lisans, repository LICENSE dosyasi, ticari kullanim ve turev
model kosullari revision bazinda kaydedilir.

## 18 Temmuz 2026 Bilgi Snapshot'i

Bu tablo entegrasyon backlog'u veya model secim listesi degildir. MiMo ve DeepSeek
aktif ailelerdir; digerleri yalniz bilgi amacli teknoloji takibidir.

| Model ailesi | Durum | Arastirma amaci |
| --- | --- | --- |
| MiMo | AKTIF | critic, vision, uzun ufuk, hiz/maliyet ve uygun varyant secimi |
| DeepSeek | AKTIF | planner, fast/chat, coding, reasoning ve uygun varyant secimi |
| Qwen | BILGI | Acik model ekosistemini izleme; entegrasyon yok |
| GLM | BILGI | Uzun-context/agentic gelismeleri izleme; entegrasyon yok |
| Kimi | BILGI | Multimodal/agentic gelismeleri izleme; entegrasyon yok |

Bugunku muhendislik karari: MiMo + DeepSeek birlikte kullanilir. Model eval'i bu
iki aile arasinda dogru rol dagilimini bulur. Diger aileler Hermes eval'ine veya
routing'e kullanici acikca istemeden girmez. Hicbir model Control Plane, policy,
approval veya workflow otoritesi olmaz.

## Hermes Model Eval Paketi

MiMo ve DeepSeek'in kullanilacak varyantlari ayni system policy, ayni arac
sozlesmesi ve ayni kaynak snapshot'i ile en az su islerde sinanir:

- plan JSON/Zod semasi ve unsupported capability reddi;
- gercek bir izole repoda bug fix, test, diff ve artifact;
- public web arastirmasi, kaynak provenance'i ve celisen iddia kontrolu;
- Playwright/browser planlama, beklenmeyen UI ve takeover istegi;
- ekran goruntusu anlama ve hassas eylem oncesi onay;
- Turkce niyet, uzun metin, belirsizlik ve kullanici duzeltmesi;
- uzun gorevde checkpoint/resume ve context kaybi;
- tool-call dogrulugu, tekrar deneme, verifier sonucu ve guvensiz eylem sayisi.

Olculer: tamamlama orani, sema gecerliligi, verifier pass, kritik guvenlik hatasi,
latency p50/p95, input/output token, gercek API maliyeti, retry sayisi, peak VRAM/RAM
ve insan mudahale sayisi. Kritik yetkisiz eylem icin kabul sifirdir. Uretici
benchmark'i yalniz aday secmek icindir; Hermes eval'i yerine gecmez.

Her kosu makine-okunur JSON receipt uretir ve sunlari tasir: provider, tam model
ID/revision, tarih, harness commit/hash, prompt/policy hash, task ID, seed/ayar,
token, latency, maliyet, verifier ve artifact hash. Secret ve kullanici verisi
receipt'e girmez.

## Ilk Arastirma Ciktilari

Claude ilk devam oturumunda su iki dosyayi uretir:

1. `docs/research/MANUS-GAP-ANALYSIS-YYYY-MM-DD.md`
2. `docs/research/MIMO-DEEPSEEK-EVAL-YYYY-MM-DD.md`

Ilki `mevcut / kismi / eksik / reddedildi` matrisi ve Hermes kabul testlerini;
ikincisi MiMo/DeepSeek model varyantlarini, fiyat/donanim varsayimlarini, eval
sonucunu ve rol bazli routing onerilerini icerir. Diger acik modeller ayrica bilgi
notu olabilir, fakat aktif routing onerisi olamaz. Kanit olmadan `best`, `SOTA`,
`hazir` veya `tamam` yazilmaz.

## 18 Temmuz 2026 Resmi Baslangic Kaynaklari

Manus:

- https://manus.im/docs/llms.txt
- https://manus.im/docs/features/browser-operator
- https://manus.im/docs/features/cloud-browser
- https://manus.im/desktop
- https://manus.im/blog/manus-my-computer-desktop
- https://help.manus.im/en/articles/11711218-how-can-i-take-over-manus-browser-or-vs-code

Modeller:

- https://github.com/XiaomiMiMo/MiMo-V2-Flash
- https://huggingface.co/deepseek-ai/models
- https://github.com/QwenLM/Qwen3-Coder
- https://huggingface.co/Qwen/Qwen3-Coder-Next
- https://huggingface.co/zai-org/GLM-5.2
- https://github.com/MoonshotAI/Kimi-K2.5

Agent framework referanslari:

- https://github.com/OpenHands/OpenHands
- https://github.com/browser-use/browser-use

Claude bu URL'lerle sinirli degildir; once resmi kaynak, sonra bagimsiz ve yeniden
uretilebilir teknik eval arar. Forum, reklam, aggregator ve tek bir leaderboard
nihai karar kaynagi olamaz.
