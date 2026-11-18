# Claude Code Canli Devir Kabul Makbuzu

Tarih: 19 Temmuz 2026  
Claude Code: 2.1.206  
Oturum adi: `HERMES resmi devir`  
Sonuc: `DEVIR_KABULU: TAM`

## Yontem

Codex, Claude Code'u `C:\Users\MSI\Documents\HERMESAGENT` kokunde baslatti ve
ana Sovereign kaynak yolunu salt-okunur ek dizin olarak verdi:

`C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent`

Claude'a yalniz `Read`, `Glob` ve `Grep` araclari verildi. `Edit`, `Write`,
`NotebookEdit` ve `Bash` kapatildi. Kod/belge/config degistirmemesi, servis
baslatmamasi, proje provider'larina ucretli cagri yapmamasi ve secret okumamasi
istendi.

Claude su ana kaynaklari bastan sona inceleme talimati aldi:

- `CLAUDE.md`
- `docs/CLAUDE-CODE-MASTER-HANDOFF.md`
- `docs/research/MANUS-OPEN-MODEL-RESEARCH.md`
- `docs/PROJECT_MEMORY.md`
- `docs/AUDIT-2026-07-18.md`
- `docs/ROADMAP.md`
- `docs/MEMORY-PROTOCOL.md`
- `docs/CLAUDE-HANDOFF.md`
- `docs/VALIDATION.md`
- `docs/WORKLOG.md`
- `docs/CLAUDE-CODE-TRANSFER-CHECKLIST.md`
- `docs/decisions/` ADR zinciri
- Sovereign kaynagindaki tarihsel `HANDOFF.md` ve `docs/MASTER-HANDOFF.md`

## Claude'un Geri Anlattigi Ana Gercekler

- Hedef aracli chatbot degil; sohbet, kalici gorev, proje, browser, computer,
  coding, research, approval, budget, evidence, artifact ve recovery'yi tek
  masaustu urununde birlestiren local-first ajan platformudur.
- Kullanici `devam et` dediginde somut uygulama, gercek kullanici gibi test,
  kanit ve hafiza guncellemesi bekler.
- Sovereign Control Plane tek policy/workflow/authorization otoritesidir; Hermes
  restricted reasoning worker'idir.
- Aktif model aileleri yalniz MiMo ve DeepSeek'tir. Diger modeller bilgi takibi
  disinda entegrasyon, routing veya replacement adayi degildir.
- 17 Temmuz 119 test/typecheck/build ve gercek web/computer/takeover kabulu
  tarihsel son tam kanittir. 18 Temmuz yeniden denetimi yeni temiz baseline
  degildir; runtime devir aninda kapaliydi.
- Once Git/veri guvenligi, gateway lifecycle, MCP socket/teardown, temiz test
  baseline'i ve izole smoke E2E; sonra tek native urun entegrasyonu gelmelidir.
- Manus urun davranislari resmi kaynaklardan arastirilir; UI, gizli prompt, kod
  veya kapali implementasyon kopyalanmaz.

## Claude'un Buldugu Dikkat Noktalari

1. Sovereign kaynagindaki 15 Temmuz tarihsel `docs/MASTER-HANDOFF.md`, eski
   topolojide `8642` portunu Hermes Runs API olarak yazar. Guncel otorite:
   `8642=MiMo`, `8643=DeepSeek`, `8644=restricted Hermes`.
2. `docs/PRODUCT_STATUS.md` HERMESAGENT devir kokunde vardir; Sovereign kaynak
   agacinda yoktur. Bu, kaynak agacinda eksik zorunlu dosya degildir.
3. Claude, connected/healthy ile gercek capability-complete durumunu birbirine
   karistirmadigini ve Qwen'i kendiliginden yeniden baglamayacagini acikca teyit
   etti.

## Ilk Devam Taahhudu

Claude, kullanici `devam et` dediginde once iki kaynak agaci, Git, port/health ve
Docker gercegini yeniden olcecek; secret degeri basmadan config-name envanteri
cikaracak. Sonra kontrollu baseline, uc gateway lifecycle, MCP duzeltmesi,
test/typecheck/build ve izole smoke E2E sirasini izleyecek.

Bu makbuz uygulama ozelligi kabul kaniti degildir. Claude'un proje bilgisini
salt-okunur canli oturumda geri anlatabildiginin devir kanitidir.

## Claude Desktop Gorunur Oturum Dogrulamasi

19 Temmuz'da Claude masaustu Code arayuzunde proje kokunun yanlislikla `C:`
oldugu goruldu. Bu nedenle CLI'da olusan devir oturumu soldaki eski `C:`
oturumlari arasinda gorunmuyordu. Arayuzden local proje klasoru
`C:\Users\MSI\Documents\HERMESAGENT` secildi ve `HERMES resmi devri` adli
gorunur oturum olusturuldu.

Claude bu oturumda `CLAUDE.md` okuma sirasini uyguladi, yedi ana devir dosyasini
okudu ve iki kaynak agacini salt-okunur komutlarla dogruladi. Kod/config/dokuman
degistirmeden urun hedefini, 17/18 Temmuz kanit ayrimini, tamamlananlari, P0/P1/P2
aciklarini, MiMo + DeepSeek sinirini ve ilk P0 paketini dogru geri anlatti.
Masaustu oturumu da `DEVIR_KABULU: TAM` sonucuyla tamamlandi.

## Derin Ogretim ve Nihai Sozlesme Kabulu

Ayni gorunur `HERMES resmi devri` oturumunda Claude'a bu kez master devir
kitabinin tamami, dort ozgun prompt (toplam 5.441 satir) ve SHA indeksi,
`PRODUCT_STATUS`, `SECURITY`, `MODEL-ROUTING`, `VALIDATION`, `ROADMAP`, Memory
Protocol, transfer checklist, Worklog, ADR 0001-0009, Manus/model arastirma
talimati, eski Sovereign handoff/architecture/vision belgeleri ve iki kaynak
agacinin uygulama/package/worker yapisi salt-okunur capraz inceletildi.

Claude 12 bolumlu nihai urun ve uygulama sozlesmesi verdi. Kullanici niyeti ve
calisma tarzi, degismez ilkeler, ozellik durum matrisi, iki kod tabani ownership
haritasi, yalniz MiMo + DeepSeek model karari, Manus/acik kaynak plani,
guvenlik/onay/tenant/butce/evidence/recovery sinirlari, masaustu UX, test/release
matrisi, P0-P3 sira/rollback, celiski/risk kaydi ve `basla/devam et` uygulama
dizisi dogru geri anlatildi. Sonuc: `OGRETIM_TAM: EVET`.

Bu derin inceleme iki guncel gercegi ortaya cikardi ve Codex yeniden dogruladi:

1. `scripts/sovereign-gateways.ps1` uc gateway icin idempotent, profil-kapsamli
   `status|start|stop` uygular. Eski `script yok` kaydi bayattir. Install/service
   receipt ve reboot acceptance olmadigi icin is `KISMI/KANIT GEREKLI`dir.
2. 19 Temmuz snapshot'inda 8642 MiMo, 8643 DeepSeek ve 8644 restricted Hermes
   loopback'te `HTTP 200`; Docker Desktop acik; urun servisleri 4310-4321
   kapalidir. Bu anlik gateway health kanitidir, tam urun acceptance'i degildir.

Baglayici uygulama kararlari ve kesin sira
`docs/CLAUDE-CODE-EXECUTION-CHARTER.md` dosyasina kalici olarak yazildi.

## Son Uygulama Hazirligi Teyidi

Claude guncellenen Execution Charter, Project Memory, Roadmap ve bu makbuzu
yeniden okudu. Urunun chatbot olmadigini ve Control Plane otoritesini, yalniz
MiMo + DeepSeek model sinirini, gateway scriptinin mevcut fakat
install/receipt/reboot kabulunun eksik oldugunu ve P0-A -> P0-B -> P0-C -> P0-D
-> P1 sirasini kesin olarak teyit etti.

Claude'un son beyanlari:

- `Eksik baglam: Yok`
- `BASLAMAYA_HAZIR: EVET`

P0-A basinda Sovereign agacinda 18 Temmuzda gorulen `EPERM` yazma kosulu yeniden
olculecek; bu yeni bir baglam eksigi degil, charter'in salt-okunur ilk kontrol
adiminin bir parcasidir.
