# WEmulDroid — Android su Windows

**Nuova linea v0.9.0-beta.1 (installer Windows in collaudo).** Progetto indipendente da `Ai-orchestrator-riserva` e `AEmulWin`. Utilizza l'[Android Emulator ufficiale](https://developer.android.com/studio/run/emulator); non redistribuisce immagini Google o Java.

## Prima prova pratica sull'ASUS — beta di sviluppo

Per non rallentare il progetto, abbiamo predisposto un **installer unico per Windows** utilizzabile come beta di sviluppo senza acquistare ora un certificato di firma.

- **Un solo `.exe`** da una release beta GitHub verificata, senza ZIP o copie manuali di `.ps1`.
- Installazione guidata per utente, collegamento sul desktop e accesso dal menu Start.
- Il launcher beta usa `RemoteSigned` per gli script installati localmente, senza cambiare le impostazioni di sicurezza globali.
- La GUI mantiene i profili Android standard e Google Play e può riutilizzare gli SDK/AVD precedenti.
- **Impostazioni → Aggiornamenti** cerca installer ufficiali del repository: download HTTPS, verifica SHA-256, conferma prima di ogni installazione.
- La linea pubblica futura richiederà una firma Authenticode attendibile e i controlli specifici Smart App Control.

**Attenzione:** la beta di sviluppo è **senza firma digitale**; Smart App Control può bloccarla sul tuo PC. Non disattivare le protezioni di Windows per aggirare il blocco. Prima distribuzione e comportamento sull'ASUS devono ancora essere verificati.

[GitHub Releases: beta e installer](https://github.com/pilialvu75-hue/WEmulDroid/releases)

## Importante: distribuzione ufficiale

**La precedente distribuzione ZIP con file .cmd è archiviata, non è più la modalità prevista per nuove installazioni.**

Il nuovo sistema usa **un singolo installer Windows .exe** (Inno Setup, installazione per utente) e l'applicazione **WEmulDroid.exe**, con icona e collegamento Desktop, Start Menu, disinstallazione e aggiornamenti Stabile/Beta dall'app.

**Stato:** compilazione e test automatici Windows reali dell'installer completati, inclusa installazione, secondo installer/upgrade, icona desktop e conservazione SDK/AVD/report. **Le beta di sviluppo possono essere installate senza firma; non sono però installer riconosciuti da Smart App Control.** Manca una firma digitale di editore attendibile, con verifica di tutte le firme su setup, launcher, script e uninstaller. Non pubblicheremo un EXE non firmato presentandolo come sicuro.

- [Architettura, installazione, firma e checklist di rilascio](docs/INSTALLER_ARCHITECTURE.md)
- [Build CI del candidato non firmato (solo test)](https://github.com/pilialvu75-hue/WEmulDroid/actions/workflows/windows-installer-ci.yml)
- [Workflow di release **solo con firme attendibili**](.github/workflows/publish-official-installer.yml)

## Come funzionerà la prima installazione

1. Scaricare il file `WEmulDroid-Setup-vX.Y.Z.exe` da una release ufficiale **firmata** (quando sarà pubblicata).
2. Aprirlo con Windows 11, verificando l'editore nella scheda **Firme digitali**. Procedere con l'installazione guidata.
3. Trovare l'icona **WEmulDroid** sul desktop e i due profili (standard e Google Play) nel menu Start.
4. Avviare l'app dal desktop. Se l'SDK Android non è ancora presente, scegliere **1. Installa strumenti**, che prepara il JDK se necessario, scarica gli strumenti Google con checksum verificato e chiede il consenso alle licenze Android. Questi dati restano salvati fuori dalla cartella del programma.
5. Usare **2. Avvia Android**, poi testare l'AVD, screenshot e applicazioni; la compatibilità del sistema Android su ASUS va ancora verificata.

Se il PC possiede già Java, SDK e AVD installati dalla beta precedente, l'app userà **le cartelle esistenti** senza cancellarle o reinstallarle.

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
- **Non ancora verificato:** avvio completo del sistema Android su PC fisico dopo la correzione.

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
