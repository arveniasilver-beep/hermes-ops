# Proje Hafizasi Guncelleme Protokolu

Amac, hesap veya model degisse bile projenin gecmisini tekrar kaybetmemektir.
Bu protokol Claude, Codex veya baska bir teknik lider tarafindan aynen uygulanir.

## Dosyalarin Tek Sorumlulugu

- `CLAUDE.md`: otomatik baslangic, degismez kurallar ve okuma sirasi. Kisa tutulur.
- `CLAUDE-CODE-MASTER-HANDOFF.md`: eksiksiz urun hedefi, kullanici calisma
  sozlesmesi, ana mimari, tarihce ve devam kurallari. Yalniz bu ana sozlesme
  degistiginde guncellenir.
- `PROJECT_MEMORY.md`: bugunku gercek snapshot. Eski durum burada tutulmaz.
- `CLAUDE-HANDOFF.md`: urun hedefi, mimari, tarihce ve detayli devir.
- `ROADMAP.md`: oncelik ve kabul olcutleri. Tamamlaninca durum etiketi degisir.
- `WORKLOG.md`: append-only tarihli calisma ozeti.
- `docs/decisions/*.md`: geri donulmesi maliyetli mimari/guvenlik kararlarinin ADR'i.
- `VALIDATION.md`: gercek test/E2E komutu, tarih, ortam ve sonuc kaniti.
- `docs/research/*.md`: tarihli Manus gap analizi, model/license snapshot'i ve
  yeniden uretilebilir eval sonucu. Eski rapor silinmez; yenisi tarihli eklenir.

Ayni bilgiyi her dosyada ayrintili kopyalama. Current truth Memory'de, tarih
Worklog'da, gerekce ADR'de, kanit Validation'da tutulur ve birbirine link verilir.

## Oturum Baslangici

1. `CLAUDE.md` okuma sirasini uygula.
2. `CLAUDE-CODE-MASTER-HANDOFF.md` dosyasini ilk devirde bastan sona oku.
3. Iki kod tabaninin yol ve durumunu dogrula.
4. Runtime'i varsayma; port + health + readiness kontrol et.
5. Git durumunu kontrol et. Sovereign'de `.git` yoksa varmis gibi komut verme.
6. `.env` degerlerini ciktiya basma. Yalniz eksik/var config adlarini raporla.
7. Son Validation'daki test sayisini bugunku test sonucu gibi sunma.

## Calisma Sirasinda

- Bir backlog maddesi basladiginda `ROADMAP.md` durumunu `KANIT GEREKLI` veya
  `KISMI` yap.
- Yeni buyuk mimari, dependency, veri modeli, guvenlik siniri veya lisans karari
  icin numarali ADR ekle.
- Fixture/mock kullaniyorsan event ve UI bunu acikca `fixture`, `degraded` veya
  `test` olarak gostersin.
- Gercek kullanici data'sinda E2E yapma; izole data dir/DB/profile kullan.
- Kanit artifact'inda model, worker, zaman, input hash, output hash ve kaynak
  provenance'ini mumkun oldugunca sakla; secret saklama.
- Model veya agent framework karari oncesi resmi kaynak URL, revision, lisans,
  donanim, fiyat tarihi ve Hermes eval receipt'ini kaydet. Uretici benchmark'ini
  proje kabul kaniti gibi sunma.

## Oturum Sonu Zorunlu Kayit

1. `WORKLOG.md` sonuna tarihli ozet ekle.
2. `PROJECT_MEMORY.md` icindeki durum, son kanit, aciklar ve kesin sonraki adimi
   guncelle.
3. `ROADMAP.md` durum/acceptance satirlarini guncelle.
4. Test veya E2E yapildiysa `VALIDATION.md` icine su bilgileri ekle:
   - tarih ve ortam/data dir;
   - calistirilan tam komut;
   - pass/fail/test sayisi;
   - kullanici gibi test edilen akis ve viewport;
   - kanit/artifact yolu;
   - test edilmemis kisimlar.
5. Yeni karar varsa ADR status ve rollback yaz.
6. Runtime acik birakildiysa URL, process/receipt ve nasil kapatilacagini; kapaliysa
   bunu acikca kaydet.
7. Secret taramasi yap; `.env`, key, token, parola ve recovery code'un belge veya
   loga girmedigini dogrula.
8. Manus/model arastirmasi yapildiysa tarihli raporu, kaynak tarihini ve bir
   sonraki yenileme tarihini kaydet; routing degistiyse ADR ekle.

## Durum Sozlugu

- `TAMAM`: kod + hedef ortam testi + kullanici akisi + kanit mevcut.
- `KISMI`: kalici kod var fakat kapsam veya hedef ortam kabulü eksik.
- `KANIT GEREKLI`: implementasyon iddiasi var, bugunku kabul tekrarlanmadi.
- `BEKLIYOR`: implementasyon tamamlanmadi.
- `BLOKE`: dis servis/credential/onay olmadan ilerlenemiyor; sebep yazili.

`connected`, `healthy` ve `complete` farklidir. Health yalniz ulasilabilirliktir;
capability'nin gercek bir isi tamamladigini kanitlamaz.

## ADR Sablonu

```markdown
# ADR NNNN: Karar Basligi

## Status
Proposed | Accepted | Superseded

## Context
Hangi gercek problem ve sinir var?

## Decision
Neye karar verildi?

## Consequences
Guvenlik, veri, UX, maliyet ve operasyon etkisi.

## Alternatives
Neler reddedildi ve neden?

## Validation
Hangi test/E2E bu karari kanitladi?

## Rollback
Guvenli geri donus nasil yapilir?
```

## Worklog Sablonu

```markdown
## YYYY-AA-GG - Kisa baslik

- Hedef:
- Degisen dosyalar/bilesenler:
- Alinan karar:
- Test/E2E sonucu:
- Bilinen acik:
- Runtime durumu:
- Kesin sonraki adim:
```

## Celiski Cozumu

1. Canli kod ve yeni yeniden uretilmis test kaniti.
2. `PROJECT_MEMORY.md`.
3. En yeni Accepted ADR.
4. `CLAUDE-CODE-MASTER-HANDOFF.md`.
5. `CLAUDE-HANDOFF.md`.
6. `WORKLOG.md` ve `VALIDATION.md` tarihleri.
7. Sovereign eski handoff'lari ve kullanici prompt arsivi.

Celiski bulursan sessizce birini secme: gercegi test et, Memory'yi duzelt ve
Worklog'a neyin stale oldugunu ekle.
