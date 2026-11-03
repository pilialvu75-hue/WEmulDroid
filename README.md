# WEmulDroid — Android su Windows

**Prototipo autonomo v0.5**, indipendente da AI-Orchestrator e da altre applicazioni. Usa [Android Emulator ufficiale](https://developer.android.com/studio/run/emulator) per avviare Android in una finestra Windows, gestire APK autorizzati e raccogliere dati diagnostici.

**Stato:** codice presente e controlli sintattici tramite CI; il funzionamento reale su un PC Windows **non è ancora stato verificato**. Nessun APK, immagine Google o binario di terzi viene redistribuito qui.

## Come iniziare (Windows 10/11 64-bit)

1. Scarica il repository da **Code → Download ZIP** ed estrailo.
2. Avvia **Verifica-PC.cmd**: controllo di sola lettura per RAM, disco, Java, virtualizzazione e WHPX.
3. Avvia **Installa-Android.cmd**: scarica gli strumenti ufficiali Google, controlla SHA-256, richiede le licenze e crea l'AVD WEmulDroid_API_35.
4. Avvia **Prova-Android.cmd**: accende Android e apre **Impostazioni**, app preinstallata. Registra esito, RAM, CPU e rendering.
5. Avvia **Avvia-Android.cmd** per utilizzare la GUI: installa un APK locale, da cartella o da link HTTPS/GitHub, passa in fullscreen, visualizza app e report e arresta solo l'emulatore di questo laboratorio.

Per il primo collaudo **non occorrono APK esterni**. Vedi [guida prima prova](docs/SMOKE_TEST.md).

## Google Play Store ufficiale

È disponibile anche un secondo profilo Android con **Play Store integrato**. Non sostituisce l'emulatore tecnico e non richiede APK di provenienza sconosciuta.

1. Esegui **Installa-PlayStore.cmd** per scaricare l'immagine Google Play dal repository SDK ufficiale.
2. Esegui **Avvia-PlayStore.cmd**, poi premi **Avvia Android** e **Apri Play Store**.
3. Accedi a Google direttamente nell'Android emulato, cerca e installa app/giochi compatibili dal negozio.

Questo ambiente non è ancora stato verificato su un PC reale. Leggi [guida Google Play e limitazioni](docs/GOOGLE_PLAY.md).


## Requisiti e limiti

- Windows 10/11 x64, CPU con virtualizzazione attiva, Windows Hypervisor Platform (WHPX), connessione Internet per la prima installazione.
- Java 17+ (anche il JBR di Android Studio), diversi GB di disco e RAM adeguata.
- Android 15, API 35, Google APIs x86_64, AVD WEmulDroid_API_35.
- Il progetto **non modifica Ai-orchestrator-riserva** né il suo codice, build e canali di aggiornamento.
- La GUI è un prototipo PowerShell + WinForms, non ancora un installer Windows firmato.
- La GUI offre profili di risoluzione, reset, screenshot e guida touch/audio, ancora da testare su PC reale.
- Nuovi comandi: fullscreen reversibile, APK da cartella, APK da URL HTTPS o release GitHub; le app non devono necessariamente comparire nel Play Store.
- Il gesto Ctrl+mouse consente un pinch simulato; touchpad+mouse come due dita autonome resta una funzione sperimentale non ancora disponibile.
- Android x86_64 potrebbe non supportare APK con sole librerie ARM64.
- Le misure in emulatore NON rappresentano direttamente i consumi di uno smartphone fisico.

## Comandi

| File | Funzione |
| --- | --- |
| Verifica-PC.cmd | Diagnosi read-only di prerequisiti Windows |
| Installa-Android.cmd | Installazione SDK/AVD Google con consenso |
| Prova-Android.cmd | Test indipendente con Impostazioni Android |
| Avvia-Android.cmd | Pannello di controllo Android standard |
| Installa-PlayStore.cmd | Scarica e prepara il secondo profilo ufficiale Google Play |
| Avvia-PlayStore.cmd | Pannello Android Google Play, con pulsante Apri Play Store |

## Percorsi Windows

- SDK: %LOCALAPPDATA%\WEmulDroid\Sdk
- Report: %LOCALAPPDATA%\WEmulDroid\Reports
- AVD: %USERPROFILE%\.android\avd (directory Android standard)

La verifica del PC salva solo il report locale; non modifica configurazioni.

## Documentazione

- [Roadmap](docs/ROADMAP.md)
- [Primo test](docs/SMOKE_TEST.md)
- [Play Store ufficiale](docs/GOOGLE_PLAY.md)
- [Schermo, audio, touch e Work](docs/VIDEO_AUDIO_TOUCH_WORK.md)
- [Fullscreen e installazione APK da PC/GitHub](docs/FULLSCREEN_APK_INPUT.md)
- [Download SDK Android](https://developer.android.com/studio)
- [Accelerazione su Windows](https://developer.android.com/studio/run/emulator-acceleration)

Codice launcher sotto licenza MIT; gli strumenti Google e le app di terzi mantengono le rispettive licenze.
