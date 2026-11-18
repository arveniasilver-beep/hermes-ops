# Claude Code Taşıma Kontrol Listesi

Bu liste proje aynı makinedeki Claude Code'a veya başka bir makine/Cloud workspace'e
taşınırken bağlam ve kaynak kaybını önler.

## Aynı Makinede

- Claude Code ana çalışma dizini: `C:\Users\MSI\Documents\HERMESAGENT`.
- Sovereign kaynak yolu ayrıca erişilebilir olmalı:
  `C:\Users\MSI\Documents\Codex\2026-07-10\n\work\sovereign-agent`.
- Kök `CLAUDE.md` otomatik okunmalı.
- İlk cevap vermeden önce `docs/CLAUDE-CODE-MASTER-HANDOFF.md` okunmalı.
- AppData profile `.env` ve auth dosyaları yalnız yerel runtime tarafından okunur;
  Claude çıktısına basılmaz.

## Başka Makine veya Cloud Workspace

İki kaynak ağacını birlikte taşı:

1. `HERMESAGENT` kontrol/native kaynak ağacı.
2. `sovereign-agent` ana yürütme kaynak ağacı.

Şunları taşıma:

- gerçek `.env` dosyaları;
- `AppData\Local\hermes\profiles` credential/auth/state;
- session cookie, token, recovery code;
- `runtime/sovereign-audit-data` içindeki identity/task verisi;
- database/log/PID/lock dosyaları;
- `node_modules`, build cache ve unsigned release çıktıları, gerekli değilse;
- kullanıcıya ait browser profile/cookie verisi.

Taşı:

- kaynak kod;
- lockfile ve package manifestleri;
- `CLAUDE.md` ve bütün `docs/`;
- ADR, test ve scriptler;
- template/patch dosyaları;
- secret içermeyen `.env.example`;
- gerekli rollback hash/manifest bilgisi.

## Yeni Ortamda İlk Kurulum

1. Mutlak yolları yeni ortama göre Memory ve master handoff'ta güncelle.
2. Node, pnpm, Python, Docker, PowerShell ve CUA uygunluğunu denetle.
3. Dependency'leri lockfile ile kur.
4. Secret'ları masked prompt veya secret manager ile yeniden gir; eski dosyayı taşıma.
5. Loopback bind ve firewall durumunu doğrula.
6. Dedicated gateway lifecycle scriptini çalıştır.
7. Typecheck, test ve build.
8. İzole data dir ile smoke E2E.
9. Sonuçları `VALIDATION.md` ve `PROJECT_MEMORY.md` içine yaz.

## Taşıma Sonrası Kabul

- Claude Code ürün hedefini ve “chatbot değil” sınırını doğru özetleyebiliyor.
- İki kaynak ağacını görebiliyor.
- Git status ve aktif branch/commit net.
- Secret dosyası source control dışında.
- Model gateway route'ları health probe'dan geçiyor.
- Runtime start/status/stop tekrar üretilebilir.
- Chat, task, Computer takeover ve artifact smoke akışı geçiyor.
- Memory/Worklog yeni ortam yolu ve sonuçlarıyla güncel.

Taşıma tamamlandı sayılmadan gerçek kullanıcı verisi veya production side effect
üzerinde çalışma başlatma.
