# Primo collaudo indipendente di WEmulDroid

**Primo obiettivo:** avviare Android su Windows e aprire **Impostazioni**, l'applicazione di sistema preinstallata. Non serve alcun APK esterno.

## Sequenza

1. Scarica WEmulDroid da GitHub, estrai lo ZIP.
2. Avvia **Verifica-PC.cmd**, che salva un report sulla virtualizzazione, WHPX, RAM e disco. Non modifica Windows.
3. Avvia **Installa-Android.cmd**. Accetta, se desideri, le licenze Google e lascia configurare WEmulDroid_API_35, Android 15 API 35.
4. Avvia **Prova-Android.cmd**. Attende fino a cinque minuti il boot, apre Impostazioni e registra RAM, CPU e dati di rendering.
5. **Controlla visivamente** che Impostazioni sia aperta e utilizzabile. Un messaggio COMMANDS_OK non dimostra che la GUI funzioni.
6. Apri il report in %LOCALAPPDATA%\WEmulDroid\Reports.
7. Solo dopo questa prova, utilizza **Avvia-Android.cmd → Installa APK** con una piccola app indipendente e autorizzata compatibile con x86_64.

## Criteri
- PASS tecnico: Android completa il boot; meminfo/cpuinfo/gfxinfo leggibili.
- PASS funzionale: Impostazioni è visibile e utilizzabile.
- FAIL: boot bloccato, errore WHPX, fallimento SDK o arresto improvviso.
- Fuori scopo: consumi energetici reali, GPU %, app ARM64-only.

## Privacy e report
I report sono salvati soltanto sul PC. Possono contenere dettagli sulla macchina; controllali prima di condividerli. I test non caricano log su servizi esterni.

## Situazione
Senza PC Windows disponibile, si possono migliorare sorgenti, documentazione e CI. **Il collaudo dell'emulatore rimane non verificato**.
