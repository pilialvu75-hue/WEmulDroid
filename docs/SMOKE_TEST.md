## Primo avvio Android — ADB daemon tcp:5037 (4 novembre 2026)

Sul primo ASUS Windows 11, la GUI v0.8.0-beta.1 si apre correttamente, ma il pulsante **«2. Avvia Android»** può mostrare:

`* daemon not running; starting now at tcp:5037`

**Non è da solo un errore di ADB.** Su Windows PowerShell 5.1, `$ErrorActionPreference='Stop'` insieme a `adb devices 2>&1` poteva trattare il normale messaggio su STDERR come terminante **prima di verificare l'exit code**.

- Correzione sorgente: `src/AdbProcess.ps1` con esecuzione tramite `System.Diagnostics.Process`, lettura simultanea di stdout/stderr ed esito determinato da `ExitCode`.
- `Get-LabSerial` riconosce il normale messaggio di bootstrap, segnala errori solo con exit code diverso da zero e interroga il nome dell'AVD prima di usare un seriale.
- Test di regressione: `tests/AdbStartup.Tests.ps1` simula STDERR di avvio del daemon ed errori reali.
- Correzione destinata a `v0.8.0-beta.2`. La CI è verde, ma il boot reale Android sul PC è ancora da confermare.

Per la vecchia beta1 si può anche provare **OK → «2. Avvia Android»** una seconda volta: se il daemon è già partito, il secondo tentativo può funzionare. Non reinstallare l'SDK. Per la beta2: **Impostazioni → Aggiornamenti → Includi beta → Controlla → Scarica → Installa**. Il processo aggiorna solo i file WEmulDroid, non SDK/AVD.

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

## Primo collaudo reale ASUS — 4 novembre 2026

La verifica `Verifica-PC.cmd` è partita dopo aver sbloccato ed estratto lo ZIP. Prima diagnosi reale:

- Windows 11 Home, Intel Core i7-12700H, 15,6 GiB RAM e circa 227,7 GiB di spazio SDK disponibile.
- Windows segnala un hypervisor già presente, ma **Windows Hypervisor Platform (HypervisorPlatform) risulta InstallState=2 = disabilitata**.
- Le proprietà CIM mostrano `VirtualizationFirmwareEnabled=no` e `SecondLevelAddressTranslationExtensions=no`. Questi due valori non devono essere interpretati come una mancanza certa del processore quando è già attivo un hypervisor: il Core i7-12700H supporta ufficialmente Intel VT-x e EPT/SLAT.
- Java, SDK ed ADB non risultano ancora installati/rilevati; normale prima della procedura di installazione.

### Gate prima di installare Android
1. **Ctrl+Maiusc+Esc → Gestione attività → Prestazioni → CPU**: leggere il campo **Virtualizzazione**.
2. Se **Abilitata**, aprire `Win+R → optionalfeatures`, selezionare **Piattaforma Hypervisor Windows**, confermare e riavviare. Non modificare BIOS o disattivare Core Isolation senza una prova specifica.
3. Se **Disabilitata**, non installare ancora SDK: verificare nel firmware UEFI ASUS l'impostazione Intel Virtualization Technology, preservando le altre impostazioni.
4. Rilanciare `Verifica-PC.cmd` e controllare **Windows Hypervisor Platform = abilitata**. Soltanto dopo l'installazione emulator Google, usare `emulator.exe -accel-check` come prova diretta del funzionamento WHPX.
5. Non attribuire PASS di compatibilità Android finché l'emulatore non si avvia davvero e l'app Impostazioni non è visibile.

Fonti ufficiali: https://developer.android.com/studio/run/emulator-acceleration ; https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-optionalfeature ; https://www.intel.com/content/www/us/en/products/sku/132228/intel-core-i712700h-processor-24m-cache-up-to-4-70-ghz/specifications.html

## Criteri
- PASS tecnico: Android completa il boot; meminfo/cpuinfo/gfxinfo leggibili.
- PASS funzionale: Impostazioni è visibile e utilizzabile.
- FAIL: boot bloccato, errore WHPX, fallimento SDK o arresto improvviso.
- Fuori scopo: consumi energetici reali, GPU %, app ARM64-only.

## Privacy e report
I report sono salvati soltanto sul PC. Possono contenere dettagli sulla macchina; controllali prima di condividerli. I test non caricano log su servizi esterni.

## Situazione
Senza PC Windows disponibile, si possono migliorare sorgenti, documentazione e CI. **Il collaudo dell'emulatore rimane non verificato**.
