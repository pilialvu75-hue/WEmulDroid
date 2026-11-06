# WEmulDroid — Android su Windows

**Linea 0.9: installer Windows di sviluppo e Android 15/Google Play ufficiale.** Progetto indipendente da `Ai-orchestrator-riserva` e `AEmulWin`. Utilizza l'[Android Emulator ufficiale](https://developer.android.com/studio/run/emulator); non redistribuisce immagini Google o Java.

## Esperimento Microsoft Store MSIX (separato dalle beta EXE)

Il laboratorio [MSIX Store](docs/MSIX_STORE_PILOT.md) costruisce tramite [CI dedicata](.github/workflows/msix-preview-ci.yml) un **pacchetto di test NON FIRMATO e NON INSTALLABILE con Smart App Control**, senza includere o modificare SDK, AVD, Play Store e report dell'utente. Non equivale a una release approvata dallo Store: occorrono riserva del nome, identita publisher Microsoft, certificazione e verifica su ASUS. L'installer Inno Setup non viene sostituito automaticamente.

## Prima prova pratica sull'ASUS — beta di sviluppo

Per non rallentare il progetto, abbiamo predisposto un **installer unico per Windows** utilizzabile come beta di sviluppo senza acquistare ora un certificato di firma.

- **Un solo `.exe`** da una release beta GitHub verificata, senza ZIP o copie manuali di `.ps1`.
- Installazione guidata per utente, collegamento sul desktop e accesso dal menu Start.
- Il launcher beta usa `RemoteSigned` per gli script installati localmente, senza cambiare le impostazioni di sicurezza globali.
- La GUI mantiene i profili Android standard e Google Play e può riutilizzare gli SDK/AVD precedenti.
- **Impostazioni → Aggiornamenti** cerca installer ufficiali del repository: download HTTPS, verifica SHA-256, conferma prima di ogni installazione.
- La linea pubblica futura richiederà una firma Authenticode attendibile e i controlli specifici Smart App Control.

**Attenzione:** la beta di sviluppo è **senza firma digitale**; Smart App Control può bloccarla sul tuo PC. Non disattivare le protezioni di Windows per aggirare il blocco. Prima distribuzione e comportamento sull'ASUS devono ancora essere verificati.

**Installer di sviluppo:** distribuito tramite GitHub Releases dopo i test Windows; non firmato digitalmente. Se Windows lo blocca, annotare il messaggio: non disattivare Smart App Control.

[Releases WEmulDroid (installer beta)](https://github.com/pilialvu75-hue/WEmulDroid/releases)

**Code signing policy:** [policy pubblica di firma, ruolo approvatore e privacy](docs/CODE_SIGNING_POLICY.md). **Stato: candidatura SignPath non ancora presentata; nessuna release attualmente firmata.**

**Percorso di firma attendibile:** [opzioni, requisiti SignPath Foundation e condizioni per una nuova release](docs/CODE_SIGNING_OPTIONS.md). La candidatura e la firma non sono ancora state effettuate; non disabilitare Smart App Control per utilizzare gli installer non firmati.

## Importante: distribuzione ufficiale

**La precedente distribuzione ZIP con file .cmd è archiviata, non è più la modalità prevista per nuove installazioni.**

Il nuovo sistema usa **un singolo installer Windows .exe** (Inno Setup, installazione per utente) e l'applicazione **WEmulDroid.exe**, con icona e collegamento Desktop, Start Menu, disinstallazione e aggiornamenti Stabile/Beta dall'app.

**Stato:** compilazione e test automatici Windows reali dell'installer completati, inclusa installazione, secondo installer/upgrade, icona desktop e conservazione SDK/AVD/report. **Le beta di sviluppo possono essere installate senza firma; non sono però installer riconosciuti da Smart App Control.** Manca una firma digitale di editore attendibile, con verifica di tutte le firme su setup, launcher, script e uninstaller. Non pubblicheremo un EXE non firmato presentandolo come sicuro.

- [Architettura, installazione, firma e checklist di rilascio](docs/INSTALLER_ARCHITECTURE.md)
- [Build CI del candidato non firmato (solo test)](https://github.com/pilialvu75-hue/WEmulDroid/actions/workflows/windows-installer-ci.yml)
- [Workflow di release **solo con firme attendibili**](.github/workflows/publish-official-installer.yml)

## Primo avvio: Android e Play Store pronti insieme

1. Installa il singolo `WEmulDroid-Setup-vX.Y.Z-beta.N.exe` da GitHub Releases (beta di sviluppo non firmata; Windows Smart App Control potrebbe bloccarla).
2. Al primo avvio dall'icona Desktop, WEmulDroid controlla **entrambi** i profili: Android standard e `WEmulDroid_Play_API_35`.
3. Se manca un profilo, propone **una sola configurazione guidata**: dopo il consenso scarica SDK, emulatore e immagini Android ufficiali direttamente da Google. Devi esaminare e accettare le licenze Android SDK e servono diversi GB e Internet. La verifica SHA-256 del downloader resta obbligatoria.
4. I dispositivi già esistenti non vengono cancellati o ricreati; il programma preserva Java, APK, accessi Play Store e dati AVD.
5. Per Play Store apri il collegamento **WEmulDroid - Google Play** in Start: il primo accesso all'account Google è personale e avviene **dentro Android**, mai tramite ADB o l'app Windows.
6. Per la tastiera premi **Tastiera PC + Android**: abilita la tastiera fisica e mantiene Gboard sullo schermo. Se viene richiesto, arresta e riavvia Android una volta per applicare `hw.keyboard=yes`. Nella scheda Schermo/Comandi puoi nascondere la tastiera Android **solo dopo** aver testato quella fisica.
7. **Home**, **Indietro**, **Centra Android** e **Avvio pulito** restano disponibili. Il centraggio viene ripetuto durante il primo avvio perché Qt può riposizionare la finestra più volte.

La procedura di installazione automatica e i controlli della tastiera hanno test di regressione su PowerShell Windows 5.1. **Il login Google, la digitazione reale con tastiera ASUS e il centraggio finale richiedono ancora collaudo sul tuo PC.**

## Smartphone, tablet e fullscreen intelligente

Dalla scheda **Schermo / Comandi** puoi scegliere:

- **Telefono leggero / HD**: risoluzioni verticali. Il comando «Fullscreen intelligente» usa una finestra stretta e proporzionata, lasciando visibile il desktop invece di coprirlo con bande nere.
- **Tablet 16:10**: `1280x800` orizzontale, 200 dpi.
- **Tablet 16:9**: `1600x900` orizzontale, 240 dpi.
- **Tablet automatico**: adatta la risoluzione al monitor (senza calcolare più pixel del necessario).

Premi **Applica schermo**, quindi **Adatta finestra al monitor** per adeguare anche la finestra Qt. Per proporzioni tablet compatibili con lo schermo è disponibile «Fullscreen intelligente». Quando il formato differisce, l'app preferisce una finestra proporzionata, senza occupare inutilmente il resto del desktop. **Ripristina** riporta dimensioni, densità e rotazione alle impostazioni originali Android.

Il vecchio «Tablet 1600x2560 @ 320 dpi» non era un vero tablet landscape: impostava un'immagine verticale molto grande e il Play Store rimaneva minuscolo nella finestra. Le modifiche alla risoluzione non cancellano app o account, ma possono rendere instabili alcuni giochi: in quel caso premi **Ripristina**.

**Collaudo reale ancora richiesto:** Google Play Store e giochi tablet landscape sul PC ASUS. I test CI verificano calcoli, opzioni e installer Windows ma non possono garantire il comportamento grafico Qt sul tuo monitor.

## Aggiornamenti Stabile / Beta

**Impostazioni → Aggiornamenti** cerca le nuove release ufficiali dell'installer sul repository GitHub. Il canale stabile è quello predefinito, beta opzionale. Ogni installazione richiede approvazione:

- HTTPS da GitHub ufficiale e verifica SHA-256.
- Firma Authenticode valida del nuovo installer, **identica al certificato del launcher già installato**.
- Download e apertura del nuovo installer; Inno Setup aggiorna i file dell'app, senza sostituire direttamente i sorgenti PowerShell.
- SDK, immagini Android, AVD, report e preferenze conservati fra versioni.

Il nuovo sistema **non utilizza più ZIP di sorgenti per gli aggiornamenti**. Il corretto aggiornamento end-to-end attraverso il menu sul PC dell'utente resta da collaudare dopo la prima release firmata.

## Progresso delle prove sull'ASUS — 4 novembre 2026

- `Verifica-PC.cmd` eseguito correttamente: Windows 11, i7-12700H, RAM 15,6 GiB.
- Virtualizzazione hardware e Windows Hypervisor Platform abilitate.
- Installazione JDK 17 e Android SDK/AVD completata secondo il test dell'utente.
- La vecchia GUI v0.8 si è aperta, ma al primo avvio ADB mostrava `* daemon not running; starting now at tcp:5037`, erroneamente interpretato da PowerShell come errore.
- **Correzione implementata** in `src/AdbProcess.ps1`: controllo di uscita del processo, test regressione Windows PowerShell 5.1 PASS.
- **Confermato il 5 novembre 2026:** Android standard e Play Store si avviano sul vero ASUS; login Google raggiunto. Rimangono da collaudare la tastiera fisica/virtuale e la stabilità della schermata Android.

## Funzioni dell'app

Interfaccia English / Italiano / Français; risoluzioni e fullscreen; mouse, touch simulato, tastiera; audio del PC; profilo Android standard e profilo Google Play separati; import APK da cartella o URL HTTPS/GitHub; snapshot, screenshot, diagnostica e report locali.

Limiti: emulatore Android 15 API 35 x86_64, quindi alcune APK esclusivamente ARM64 potrebbero non essere compatibili. Funzionalità touchpad+mouse come due dita autonome ancora da sviluppare e collaudare.

## Architettura cartelle

| Percorso | Contenuto | Rimosso durante upgrade/uninstall |
|---|---|---|
| `%LOCALAPPDATA%\Programs\WEmulDroid` | Launcher e codice applicativo | Sostituito in upgrade; rimosso all'uninstall |
| `%LOCALAPPDATA%\WEmulDroid\Sdk` | Android SDK, adb, emulator | **No** |
| `%LOCALAPPDATA%\WEmulDroid\Reports` | Report e diagnostica | **No** |
| `%LOCALAPPDATA%\WEmulDroid\Settings` | Preferenze / lingue | **No** |
| `%USERPROFILE%\.android\avd` | Dispositivi virtuali Android | **No** |

## Documentazione

[Installer e sicurezza](docs/INSTALLER_ARCHITECTURE.md) · [Roadmap](docs/ROADMAP.md) · [Test](docs/SMOKE_TEST.md) · [Google Play](docs/GOOGLE_PLAY.md) · [Display, audio e touch](docs/VIDEO_AUDIO_TOUCH_WORK.md) · [Snapshot e diagnostica](docs/SNAPSHOTS_DIAGNOSTICS.md) · [Storico aggiornamenti ZIP](docs/UPDATES.md).

Licenza del codice originale MIT. Componenti Google, Wine e terze parti conservano le proprie licenze. Nessun codice o repository di `Ai-orchestrator-riserva` è stato modificato.
