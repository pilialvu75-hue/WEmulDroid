# AIVEXUS Android Desktop Lab — Windows

**Prototipo indipendente (v0.1)** per avviare Android in una finestra Windows, installare APK e raccogliere primi dati diagnostici. Non importa codice da `Ai-orchestrator-riserva` e non modifica il suo repository.

> **Stato:** codice iniziale pubblicato; avvio reale dell'emulatore e collaudo su PC Windows **non ancora verificati**.

## Come iniziare (Windows 11 x64)

1. Scarica questo repository da **Code → Download ZIP** ed estrailo.
2. Fai doppio clic su **`Installa-Android.cmd`**. Leggi e accetta i termini dell'SDK Google quando richiesto. Verranno scaricati gli strumenti Android ufficiali, un'immagine Android 15 (API 35) e configurato il dispositivo `Aivexus_API_35`.
3. Fai doppio clic su **`Avvia-Android.cmd`**, poi premi **Avvia Android**.
4. Dopo il primo avvio, usa **Aggiorna elenco** per vedere le applicazioni, **Installa APK** per installarne una e **Misura risorse** per creare un report testuale.

**Dipendenze:** Windows 10/11 64-bit con virtualizzazione CPU, Windows Hypervisor Platform (WHPX), Java 17+ (può essere usato quello già incluso con Android Studio), connessione Internet per la prima installazione, diversi GB di spazio libero. Al primo avvio Android può essere lento. I comandi non installano né modificano Android Studio e non richiedono Python o Flutter.

**Separazione dei dati:** l'SDK viene installato in `%LOCALAPPDATA%\AivexusAndroidLab\Sdk`, i report in `%LOCALAPPDATA%\AivexusAndroidLab\Reports`; l'AVD si trova nella directory Android standard dell'utente (`%USERPROFILE%\.android\avd`). Il codice dell'applicazione resta in questo repository.

**Nota sulle APK:** le applicazioni con sole librerie native ARM/ARM64 potrebbero non essere compatibili con l'immagine x86_64 usata dall'emulatore. Le prove di compatibilità e di consumo energetico reale richiedono anche un dispositivo fisico.

## Funzioni implementate nel prototipo

- Installazione guidata del motore Android ufficiale tramite `sdkmanager`; download verificato tramite checksum SHA-256 delle command-line tools
- Interfaccia Windows semplice (PowerShell + Windows Forms), separata dal motore Android
- Avvio di un AVD dedicato e arresto dello stesso, senza terminare emulatori non appartenenti al laboratorio
- Installazione di file APK e elenco dei package utente
- Report con `dumpsys meminfo`, `dumpsys cpuinfo`, `dumpsys gfxinfo` e informazioni sui processi dell'host

## Limiti v0.1

Il report contiene dati diagnostici, **non** una misura affidabile del consumo energetico reale, della percentuale di utilizzo GPU o degli FPS aggregati. L'installer richiede interazione e l'accettazione delle licenze Google; i componenti Google vengono scaricati direttamente dal produttore e **non** sono distribuiti nel repository. Mancano ancora benchmark automatici ripetibili, CI Windows, gestione di più profili e pacchetto .exe firmato.

## Documentazione

- [Roadmap e criteri di collaudo](docs/ROADMAP.md)
- [Android Emulator](https://developer.android.com/studio/run/emulator)
- [SDK Command-line tools](https://developer.android.com/studio)
- [Accelerazione hardware Windows](https://developer.android.com/studio/run/emulator-acceleration)

## Licenza

Il codice di questo progetto è distribuito sotto licenza MIT (vedi `LICENSE`). Android SDK ed eventuali immagini di sistema seguono le proprie licenze, che non sono incluse in questa licenza.
