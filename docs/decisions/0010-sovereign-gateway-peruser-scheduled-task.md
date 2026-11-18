# ADR 0010: Sovereign Gateway Lifecycle per-user Scheduled Task

## Status

Accepted. P0-B Faz 1 (kod + 71/71 test + read-only status) Codex'in ucuncu
review'inde kabul edildi. P0-B Faz 2A (19 Temmuz 2026, kullanici onayli):
uc task GERCEKTEN kuruldu, alan/idempotency kabulu ve profil profil gercek
stop/start dongusu gecti; final 3/3 RUNNING + task owned/config 3/3.
Kalan `KANIT GEREKLI`: Faz 2B Windows reboot acceptance ve kucuk canli
provider probe'lari (Codex'in Faz 2A kanit review'i sonrasi, ayni kullanici
onayi kapsaminda).

## Context

Uc dedicated model gateway'i (MiMo 8642, DeepSeek 8643, restricted Hermes
8644) 17 Temmuz'da canli kabul edildi fakat reboot sonrasi otomatik ve
kanitlanabilir sekilde geri gelmiyordu. Mevcut kaliplar: `owner-*` icin
Startup klasoru `.lnk` kisayollari (introspeksiyon, on-demand stop/start,
receipt ve basarisizlikta yeniden baslatma yok) ve oturum-ici elle baslatma
(`sovereign-gateways.ps1`). Upstream Hermes'in Windows service destegi yok;
unsigned binary nedeniyle Windows Application Control politikasi
zayiflatilamaz.

## Decision

- Uc sovereign gateway per-user Windows **Scheduled Task** olarak yonetilir:
  logon tetikli, `Limited` run level, yukseltme gerektirmez, task action'i
  yalniz `hermes.exe -p <profil> gateway run` tasir; secret task tanimina,
  CLI'ya veya receipt'e girmez (secret'lar profilin kendi `.env` alaninda
  kalir ve hermes tarafindan yuklenir).
- Yeni arayuz `scripts/sovereign-gateway-service.ps1`:
  `plan | install | status | start | stop | uninstall`; varsayilan DRY-RUN,
  gercek mutasyon yalniz `-Execute` + ShouldProcess onayi ile.
- Guvenlik kurallari: tek process snapshot'i; launcher-child agaci ppid ile
  cozulur; onceki receipt PID'leri stale tespiti icin karsilastirilir;
  loopback disi listener ve yabanci port sahibi fail-closed'dur; stop daima
  profil kapsamlidir (`gateway stop --all` yasak); her aksiyon redacted JSON
  receipt uretir (`runtime/sovereign-hermes-gateways/receipts/`, git disi).
- **Task sahipligi (r2):** sahiplik `\Sovereign\` dedicated TaskPath +
  Description icindeki ownership marker + current-user principal uclusuyle ve
  exe/args/workdir/trigger/RunLevel tam dogrulamasiyla kanitlanir. Kanitsiz
  ayni isimli task `FOREIGN_TASK` fail-closed'dur: asla silinmez/degistirilmez;
  uninstall yalniz kanitli sahip task'i kaldirir; farkli path'teki ayni isimli
  task'lara hicbir kosulda dokunulmaz.
- **Process kimligi (r2):** launcher tespiti substring degil, Windows
  quoting'e saygili token-level eslesmedir: exact `-p <profil>`/`--profile
  <profil>` token cifti VE ardisik `gateway` `run` tokenlari.
- **Receipt gercegi (r2):** sema v1.1 `requestedExecute / whatIfRequested /
  appliedCount / declinedCount / failedCount / effectiveDryRun / outcome` ve
  adim-sonuclarini (applied/declined/failed/refused/skipped) yazar; -WhatIf
  veya ShouldProcess reddi `declined` olarak gorunur ve `effectiveDryRun=true`
  kalir; hata/fail-closed yolu da redacted receipt birakir; dosya adi UTC
  milisaniye + nonce ile benzersizdir. Stale kiyasi icin yalniz `treePids`
  tasiyan en yeni GECERLI gozlem receipt'i secilir; bozuk/uyumsuz sema atlanir.
- **Secret siniri (r2):** health probe SECRETSIZ'dir; hicbir env/credential
  okunmaz. Authenticated health probe ihtiyaci ayri tasarim/onay konusudur ve
  bilincli olarak BLOKE'dur (canli olcumde `/health` auth'suz `HTTP 200`).
- **NONLOOPBACK (r2):** start fail-closed; stop, loopback disi listener'i
  calisir birakmamak icin yalniz KANITLI exact-owned tree uzerinde
  `containment-stop` olarak calisir ve receipt'te boyle etiketlenir.
- **Start sahiplik kurali (r3):** start yalniz `IdentityOwned VE ConfigMatches`
  task'i, exact TaskPath ile baslatir. Dedicated path'te foreign/drift task
  varken start fail-closed'dur (bypass engeli). Dedicated path'te task HIC
  yoksa dogrudan `Start-Process` fallback'i BILINCLI davranistir ve receipt'te
  `start-direct` olarak etiketlenir; farkli path'teki ayni isimli task hicbir
  kosulda baslatilmaz.
- **Recreate bagimliligi (r3):** owned-drift zincirinde register yalniz
  unregister adimi APPLIED ise calisir; decline/hata register'i atlatir ve
  step log `skipped/failed` gercegini yazar.
- **Tam alan dogrulama (r3):** sahiplik principal'i SID-canonical kiyaslanir
  (NTAccount->SID cevirisi; cevrilemeyen hesap fail-closed; yalniz kullanici
  adi/EndsWith YETMEZ). Config dogrulamasi tek action + tek trigger + trigger
  enabled + trigger-user SID + LogonType (Interactive/InteractiveToken) +
  RunLevel + logon trigger sinifi + exe/args/workdir'in tamamidir. Register
  tarafi explicit `New-ScheduledTaskPrincipal` (current user, Interactive,
  Limited) ve `-AtLogOn -User <current>` kullanir.
- **Receipt v1.2 (r3):** toplam sonuc step log'dan turetilir (oncelik:
  fail-closed > failed > declined > ok) ve acik `applied/declined/failed`
  boolean'lari + sayilarla yazilir. Receipt yazimi .NET
  `FileMode.CreateNew` ile atomiktir ve -WhatIf'ten ETKILENMEZ (audit kaydi
  hedef mutasyon degildir). `-Execute` + `-NoReceipt` audit bypass'i olarak
  reddedilir ve zorunlu refusal receipt yazilir; `-NoReceipt` yalniz
  execute-disi kullanim icindir.
- **Arg parser (r3):** ev yapimi tokenizer kaldirildi; resmi Win32
  `CommandLineToArgvW` P/Invoke kullanilir (backslash-before-quote kurallari
  dahil). Windows disi ortamda parser acik fail-closed'dur.
- **Hidden launcher mimarisi (r4, Codex Faz 2A bulgusu):** task action'i
  hermes.exe'yi dogrudan calistirmaz. Zincir:
  `conhost.exe --headless "<powershell>" -NoProfile -NonInteractive
  -WindowStyle Hidden -ExecutionPolicy Bypass -File "<launcher>"
  -GatewayProfile <exact>`. Launcher (`sovereign-gateway-launch.ps1`)
  secret tasimaz/okumaz; profil basina dosya kilidi (FileShare::None; named
  mutex ayni thread'de reentrant oldugu icin bilincli reddedildi) ile cift
  calismayi engeller; mevcut status mantigini SALT-OKUNUR kullanir: RUNNING
  => idempotent exit 0, FOREIGN/NONLOOPBACK/PARTIAL => fail-closed exit 2 ve
  hicbir process baslatilmaz, DOWN => hermes `conhost --headless` altinda
  gizli baslar, stdout/stderr gitignore'lu `runtime/.../logs` altina gider,
  timeoutlu RUNNING+loopback kabulu yapilir (timeout'ta yalniz token-kanitli
  kendi agacimiz temizlenir, exit 3). Her sonuc redacted launcher receipt'i
  birakir; wrapper kabulden sonra biter, gateway child gizli calisir.
  Powershell'i dogrudan Execute yapmak canli olcumde Windows Terminal
  default-terminal tab'i actigi icin `conhost --headless` sarmali zorunludur.
  Launcher, servis scriptini dot-source ederken param-clobber'a karsi
  parametrelerini once ayri adlara kopyalar ve 'all'/gecersiz profili
  fail-closed reddeder (canli yakalanan bug).
- **r5 hardening (Codex r4 review):** (1) TUM gercek start yollari tek ortak
  konsolsuz primitive'e indirildi (`Invoke-SgsStartHermesConsoleless`:
  conhost --headless + hidden + logs yonlendirme); `start-direct` fallback'i
  ve launcher ayni contract'i kullanir, eski gorunur `Start-Process
  hermes.exe` yolu tamamen kaldirildi, recursive launcher/task cagrisi yok.
  (2) Child komut satiri CommandLineToArgvW round-trip'i testle KANITLI
  Windows quoting helper'iyla uretilir (bosluklu/tirnakli/backslash'li
  yollar exact ayrisir; mevcut bosluksuz yolda bayt-ayni cikti - task
  tanimi degismedi, drift olusmadi). (3) Launcher'da beklenmeyen
  status/lock/IO exception'lari disari kacamaz: fail-closed exit 4, dosya
  kilidi finally ile kesin birakilir, TEK denemelik redacted outcome=error
  receipt yazilir; receipt yazimi da basarisizsa recursion yapilmaz ve exit
  5 (nonzero) olur.
- Eski `sovereign-gateways.ps1` tarihsel referans olarak korunur.

## Consequences

- Gateway durumu sorgulanabilir kanonik kayda kavusur (task + receipt);
  reboot acceptance olculebilir hale gelir.
- Mutasyonlar cift kapilidir (-Execute + onay); yanlislikla calistirma ve
  test sirasinda yan etki riski dusuktur.
- Turkce locale'de regex IgnoreCase'in current-culture katlamasi (buyuk I /
  noktasiz i) redaction'i deldigi mock testle bulundu; tum case-insensitive
  redaction desenleri `CultureInvariant` ile calisir.

## Alternatives

- **Startup `.lnk` kisayolu:** mevcut kalip; introspeksiyon/receipt/on-demand
  yonetim yok. Reddedildi (sovereign gateway'ler icin).
- **Windows Service:** admin gerektirir, upstream installer systemd/launchd
  hedefler, unsigned wrapper policy riski. Reddedildi.
- **NSSM/ucuncu parti service wrapper:** yeni dis bagimlilik ve lisans/kurulum
  yuku. Reddedildi.

## Validation

Faz 1 (19 Temmuz 2026): PowerShell parser temiz; 40/40 mock test; canli
read-only status 3x RUNNING, loopback-only, `HTTP 200`.

Review-fix r2 (ayni gun, Codex bulgulari sonrasi): parser temiz; **70/70 mock
test** — ek kapsam: FOREIGN_TASK sahiplik fail-closed (ayni isimli yabanci
task'ta install/uninstall 0 mutasyon; farkli path'e dokunulmaz; owned-drift
recreate hedef dogrulugu), Execute+ShouldProcess-red/WhatIf gercekligi
(0 wrapper cagrisi, declined step, `effectiveDryRun=true`), hata yolunda
failed-step + redacted receipt, ayni-saniye receipt benzersizligi,
gecerli-gozlem receipt secimi (plan/bozuk receipt atlanir), token-level decoy
testleri ve NONLOOPBACK containment execute-akisi (yalniz exact-owned tree
pid'leri). Mock testler uc gercek bug yakaladi: (1) tr-TR IgnoreCase
katlamasi redaction'i deliyordu -> CultureInvariant; (2) PS 5.1'de
`@(komut)` sarmasi `,()` idiomlu diziyi cift paketleyip Count=1 yapiyordu ->
enumerated donus; (3) `@()` sarmasi List[object] uzerinde ArgumentException
uretiyordu -> duz dizi step log. Canli read-only status (secretsiz probe):
3x RUNNING, loopback-only, `HTTP 200`, schema 1.1 receipt, secret-tarama
temiz. Gercek install/uninstall/start/stop/reboot bu fazda CALISTIRILMADI.

Review-fix r3 (ayni gun, Codex ikinci review'i sonrasi): parser temiz; **71/71
test**. Yeni kanitlar: start sahiplik bypass'i kapali (same-path foreign/drift
task + DOWN + execute => 0 start wrapper; exact-owned yalniz exact TaskPath;
farkli path'teki task asla baslatilmaz; task yoksa bilincli start-direct),
recreate zinciri bagimli (unregister declined/failed => register 0 ve step
log gercegi), receipt agregat gercegi (declined=>declined, failed=>failed,
fail-closed onceligi) ve GERCEK dispatcher kanitlari: `-Execute -WhatIf`
altinda benzersiz receipt DOSYASI yazildi + `\Sovereign\` task sayisi
degismedi (0 mutasyon), `-Execute -NoReceipt` reddedilip zorunlu refusal
receipt'i yazildi. Tam alan dogrulama testleri: ikinci action, baska trigger
user, disabled trigger, LogonType farki => drift; ayni kullanici adi farkli
domain/SID ve SID'e cevrilemeyen principal => FOREIGN. Resmi
CommandLineToArgvW parser testleri: quoted bosluk, escaped quote,
backslash-before-quote, bos arguman, escaped-quote decoy. Canli read-only
status: 3x RUNNING, loopback-only, HTTP 200, schema 1.2 receipt, secret
taramasi temiz. Gercek install/uninstall/start/stop/reboot yine
CALISTIRILMADI (Faz 2, kullanici onayi).

Faz 2A canli kabul (19 Temmuz 2026, kullanici onayli): preflight uc gateway'i
DOWN ve eski PID'leri stale buldu (oturum-baslatmali sureclerin reboot'a
dayanmadiginin canli kaniti). Ilk gercek install, mock'larin uretmedigi bir
scope bug'ini yakaladi: `GetNewClosure()` closure'u dinamik modul scope'unda
kosup script fonksiyonlarini goremedi; fail-safe tuttu (0 mutasyon, failed
receipt) ve cozum parametreli `-Body`/`-BodyArgs` oldu. Sonra: 3/3 register
applied; raw alan yeniden-okumasi (tek action/trigger, exact exe/args/
workdir, logon trigger enabled + current-user, principal Interactive/Limited,
marker) gecti; ikinci install 3/3 idempotent skip. Uc profil icin sirali
gercek donguler: task-owned start -> RUNNING/loopback/secretsiz HTTP 200 ->
profil kapsamli stop -> DOWN + port kapali + stale tespiti -> task-owned
start -> RUNNING/HTTP 200; diger route'lara dokunulmadi. Final: 3/3 RUNNING,
`\Sovereign\` task 3/3 owned/config, receipt'ler redacted/temiz. Reboot ve
provider probe'lari bilincli olarak Faz 2B'ye birakildi.

## Rollback

`-Action uninstall -Execute` yalniz `Sovereign Gateway *` adli task'lari
kaldirir; profil verisine dokunmaz. Script'i geri almak icin git revert
yeterlidir; eski `sovereign-gateways.ps1` calisir durumda korunmustur.
