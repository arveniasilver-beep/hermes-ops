# P0-A Kontrollu Git/Veri Baseline Makbuzu

Tarih: 19 Temmuz 2026  
Uygulayan: Claude Code (bagimsiz guvenlik/source-control denetcisi + uygulayici)  
Reviewer: Codex (teknik lider)  
Kapsam: HERMESAGENT operasyon agaci + Sovereign ana urun agaci  
Sinirlar: servis/model cagrisi yok, remote/push yok, dosya silme yok, secret
degeri okunmadi/basilmadi, `git add .` kullanilmadi.  
Guncelleme: Ayni gun Codex salt-okunur review'inin uc bulgusu duzeltildi
(bolum 9); commit hash'leri ve tag'ler degistirilmedi.

## 1. Sonuc Ozeti

| Repo | Dal | Ilk commit | Tag | Dosya | Durum |
| --- | --- | --- | --- | ---: | --- |
| `C:\Users\MSI\Documents\HERMESAGENT` | `master` | `152bf9a98ccb5a48f6b1691fa2751ba197c5c219` | `baseline-hermes-20260719` (annotated `f3368e0`) | 6.212 | working tree temiz |
| `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent` | `master` | `9ca47c7622923b51eaab3fa504de4393153d8771` | `baseline-sovereign-20260719` (annotated `dbb254f`) | 220 | working tree temiz |

Iki repo da yerel-only'dir; remote tanimli degildir. Remote/push ayri kullanici
onayi gerektirir.

## 2. On Olcumler

- **EPERM probu:** Sovereign agacina ilk yazma (`.gitattributes` olusturma)
  basarili; 18 Temmuz'daki sandbox `EPERM` kosulu bu oturumda yok.
- **Satir sonu:** System gitconfig `core.autocrlf=true` idi
  (`C:/Program Files/Git/etc/gitconfig`). Iki repoda repo-lokal
  `core.autocrlf=false` + `* -text` iceren `.gitattributes` ile baseline bayt
  sadakati saglandi; `core.longpaths=true` yapildi (en uzun yol 180 karakter).
- **Kimlik:** Global Git kimligi mevcut ve kullanildi; kimlik degeri bu belgede
  tekrarlanmaz. Commit author metadata'si herhangi bir remote/push oncesinde
  privacy review gerektirir.
- **`.envrc`:** 370 bayt, 0 secret-sekilli satir, yalniz `use flake` /
  `watch_file` direktifleri; upstream tooling dosyasi olarak dahil edildi.
- **`infra/hermes/config.yaml`:** 0 secret-sekilli satir; yalniz config
  anahtarlari; dahil edildi.

## 3. Dahil Edilen Siniflar

**HERMESAGENT (explicit pathspec):** `.gitattributes`, `.gitignore`,
`CLAUDE.md`, `CLAUDE-START-PROMPT.md`, `README.md`, `docs/` (devir seti, ADR
0001-0009, orijinal prompt arsivi, arastirma talimati), `patches/`, `scripts/`
(14 script), `templates/souls|wrappers` (5 profil), `tests/`,
`runtime/hermes-agent` (6.150 dosyalik yonetilen Phase 8 kaynagi).

**Sovereign (explicit pathspec):** `.gitattributes`, `.gitignore`,
`.dockerignore`, `.env.example`, `CLAUDE.md`, `HANDOFF.md`, `README.md`,
`package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, `docs/`, `apps/` (85),
`packages/` (13), `workers/` (75), `scripts/` (22), `infra/` (11;
`.env.production.example` sablonu dahil), `data/.gitkeep`.

## 4. Haric Tutulan Siniflar ve Gerekce

**Iki repoda ortak:** gercek `.env`/env varyantlari, `*.key/pem/pfx/token`,
`node_modules/`, log/db/pid/tmp, editor/OS dosyalari.

**HERMESAGENT:** `backups/` (ZIP + bundle'lar), `artifacts/` (36M ekran
kanitlari), `runtime/sovereign-audit-data/` (kullanici/audit verisi),
`runtime/sovereign-hermes-gateways/` (gateway loglari), `runtime/*.png`,
desktop `build/dist/release` (unsigned exe + korunan win-unpacked paketleri),
`__pycache__`/`.pytest*`/`.vite-cache`, `.agents/` ve `.claude/` yerel ajan
durumu (bu turda `.gitignore`'a eklendi).

**Sovereign (bu turda sertlestirilen `.gitignore` ile):** `data/*`
(identity/task/event JSON, `durable-live.pid`, `runtime/local-processes.json`;
yalniz `data/.gitkeep` istisna), kok + `qa/` loglari, **`qa/` uretilmis PNG
kanitlari** (ornegin auth-recovery goruntusu sentetik recovery degerleri
tasiyor), `dist/build/coverage/cache`, `*.tsbuildinfo`, `artifacts/`,
`outputs/`, `/{console.error(e.code)` komut artigi.

**Kanit saklama duzeltmesi (review bulgusu 2):** Commit disi birakilan QA PNG
kanitlari **yalniz mevcut yerel diskte** korunur. Git bundle'lari yalniz
tracked source/history tasir; ignored/untracked dosyalari icermez. 17 Temmuz
kaynak ZIP'inin bu kanitlari kapsadigi dogrulanmamistir ve iddia edilmez.

## 5. Staged Dogrulama Kaniti

- HERMES: 6.212 staged; sinif dagilimi allowlist ile birebir; stage disi
  kalan/untracked artik: 0. Yasak ad deseni taramasi: 0. Yasak dizin deseni
  taramasi: 0. En buyuk dosya 3.8MB upstream gorseli.
- Sovereign: 220 staged; gercek `.env` staged degil; env-example sayisi 2;
  `qa/`, junk artigi, dist/log/pid/tsbuildinfo: 0. `git check-ignore` 8/8 kanit:
  `.env`, `qa/auth-recovery-mobile.png`, `{console.error(e.code)`,
  `data/durable-live.pid`, `data/runtime/local-processes.json`,
  `apps/web/tsconfig.tsbuildinfo`, `node_modules/x`,
  `apps/control-plane/dist/x` -> hepsi IGNORED.
- Secret-sekilli icerik taramasi (deger basilmadan, maskeli):
  - HERMES: eslesmeler yalniz upstream test/doc/i18n + `.env.example`;
    `.env.example` icindeki 4 eslesmenin 4'u yorumlanmis placeholder satiri.
  - Sovereign: `.env.example` 7/7 ve `infra/compose.core.yml` 6/6
    guvenli-desenli (dev-default/sablon); `runtime-config.test.ts` 3 sabitten
    2'si guvenli-desenli, 1'i isaretsiz -> kod baglami dogrulandi: dosya
    basindaki "complete production API configuration" sentetik test fixture'i
    (uzunluk 43-48, production preflight'i gecmek icin uretilmis).

## 6. Kalinti Riskler

1. `runtime-config.test.ts` fixture sabitleri sentetik siniflandirildi fakat
   herhangi bir gelecek remote push oncesinde rotate edilmeli/yenilenmeli ve
   hicbir gercek ortam degeriyle eslesmedigi teyit edilmelidir.
2. Kanit PNG/ZIP'leri bilincli olarak repo disindadir; QA PNG kanitlari yalniz
   yerel diskte korunur (bolum 4'teki duzeltme).
3. Commit author metadata'sinda global Git kimligi gomuludur; ayni kimlik bu
   makbuzun git gecmisindeki ilk surumunde ve orijinal (canonical olmayan)
   bundle'larda da yer alir. Herhangi bir remote/push oncesinde privacy review
   zorunludur; gerekirse kullanici onayli history yeniden yazimi ayri karardir.
4. Test/typecheck/build bu dilimde kosulmadi (P0-C kapsami); baseline yalnizca
   source-control kabuludur.
5. Orijinal `hermes-baseline-20260719.bundle` beklenmeyen bir
   `refs/codex/turn-diffs/checkpoints/...` ref'i tasir (bolum 9); dosya silme
   yasagi geregi diskte birakildi. Temizligi kullanici onayli ayri bir istir.

## 7. Rollback

- Canonical tasinabilir yedekler (bolum 9):
  `backups/hermes-baseline-20260719-canonical.bundle` ve
  `backups/sovereign-baseline-20260719-canonical.bundle`
  (`git clone <bundle>` ile geri alinabilir). Ayrica 17 Temmuz kaynak ZIP'i
  SHA-256 `31d0d84b6f0e9274d4041d3d98c59ac1c99148ff05b5a166eb7ddd7d8a5ede0a`.
- Orijinal ilk bundle'lar (`hermes-baseline-20260719.bundle`,
  `sovereign-baseline-20260719.bundle`) silinmedi; canonical surumler esas
  alinmalidir.
- Ilk commit'i geri alma (working tree'ye dokunmaz):
  `git update-ref -d refs/heads/master`
- Tag silme: `git tag -d baseline-hermes-20260719` /
  `git tag -d baseline-sovereign-20260719`
- Sovereign'de git'i tamamen kaldirma: yalniz bu turda olusan `.git` klasoru
  silinir (icinde yalniz yeni metadata vardir) - kullanici onayi ile.
- HERMES docs guncellemeleri ayri commit'lerdedir; `git revert <docs-sha>` ile
  geri alinabilir.

## 8. Tag-Commit Iliskisi

`baseline-hermes-20260719` tag'i **ilk baseline commit'ini** (`152bf9a`)
isaret eder. Bu makbuz ve hafiza guncellemeleri, baseline'i degistirmemek icin
ayri docs commit'lerindedir; bu commit'ler tag'lenmemistir.

## 9. Canonical Bundle Kaydi (Codex Review Duzeltmesi, 19 Temmuz 2026)

Codex review'i orijinal HERMES bundle'inda beklenmeyen
`refs/codex/turn-diffs/checkpoints/...` ref'ini buldu (Codex CLI'nin kendi
turn-diff checkpoint ref'i `--all` ile pakete girmisti). Sovereign orijinal
bundle'i olcumde zaten temizdi (yalniz HEAD/master/tag). Iki repo icin de
`--all` kullanilmadan, explicit ref listesiyle canonical bundle'lar uretildi;
eski dosyalar silinmedi.

| Bundle | Boyut | SHA-256 |
| --- | ---: | --- |
| `backups/hermes-baseline-20260719-canonical.bundle` | 58.001.865 B | `092501d07fef85a12fc6edc89dcd5b3a5fcf24accac2fa57fbab3abf81d762b1` |
| `backups/sovereign-baseline-20260719-canonical.bundle` | 530.466 B | `bcedac1bfcee6afcc13cfdf8e283e95baacdfb76f5a2dcf9e42ffe73c849ca92` |

`git bundle verify` her ikisi icin `The bundle records a complete history`
sonucunu verdi. `git bundle list-heads` ref listeleri:

```text
hermes-baseline-20260719-canonical.bundle
  f81fa5ed076ecef7548429adeb842471e372b6a4 HEAD
  f81fa5ed076ecef7548429adeb842471e372b6a4 refs/heads/master
  f3368e0bf9b4ec68ea79383d1b974af1e2567c8a refs/tags/baseline-hermes-20260719

sovereign-baseline-20260719-canonical.bundle
  9ca47c7622923b51eaab3fa504de4393153d8771 HEAD
  9ca47c7622923b51eaab3fa504de4393153d8771 refs/heads/master
  dbb254f15e163441a3775e84d09a642e1a3c601e refs/tags/baseline-sovereign-20260719
```

Not: HERMES canonical bundle'i docs commit'lerini iceren `master` ucunu ve
`152bf9a` baseline'ini isaret eden annotated tag'i birlikte tasir; tag hedefi
degistirilmedi. HERMES deposundaki `refs/codex/...` ref'leri Codex CLI'ye
aittir, bundle disinda birakilmistir ve silinmemistir.
