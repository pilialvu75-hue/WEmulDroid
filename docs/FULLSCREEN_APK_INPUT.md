# Fullscreen, touch e installazione APK

Le funzioni descritte sono disponibili nei sorgenti WEmulDroid v0.5, ma non sono ancora state collaudate su un PC Windows fisico.

## Schermo intero

Nella GUI Avvia-Android.cmd (oppure Avvia-PlayStore.cmd), avvia Android e premi **Fullscreen**.
Il programma cerca esclusivamente la finestra Android Emulator che contiene il nome dell'AVD selezionato, poi prova ad estenderla senza bordi sul monitor corrente.

- Premi **Esci fullscreen** per tornare alla finestra normale.
- Per recuperare il pannello WEmulDroid usa **Alt+Tab**.
- Alla chiusura del pannello viene tentato il ripristino automatico.
- Se la finestra non viene identificata univocamente, nessuna altra finestra viene modificata. Come alternativa puoi provare **Alt+Invio** nell'emulatore; è una scorciatoia documentata nelle versioni storiche, non garantita in quelle nuove.
- Fullscreen della finestra non significa maggiore risoluzione Android. Una proporzione da telefono può lasciare bande laterali.

## Installazione APK al di fuori del Play Store

| Pulsante | Funzione |
| --- | --- |
| Installa APK | Seleziona un solo APK sul PC |
| APK da cartella | Sceglie una cartella; installa fino a 30 APK presenti al primo livello |
| APK da link HTTPS | Scarica e installa un APK da URL HTTPS, previa conferma |

Esempi di URL GitHub:
- https://github.com/OWNER/REPO/releases/latest
- https://github.com/OWNER/REPO/releases/tag/VERSIONE
- https://github.com/OWNER/REPO/releases/download/VERSIONE/FILE.apk

Sono ammessi anche URL HTTPS diretti a .apk di altri siti. Se una release GitHub contiene più APK, WEmulDroid chiede di scegliere il link dell'asset specifico anziché indovinare. Le release contenenti soltanto AAB non sono installabili direttamente.

**Controlli:** download solo HTTPS, conferma esplicita, limite iniziale di 1 GiB, archivio APK contenente AndroidManifest.xml, hash SHA-256 e installazione mirata al solo AVD selezionato. I file scaricati sono salvati nella cartella locale WEmulDroid/Downloads. Questi controlli non certificano la sicurezza del codice dell'app: utilizza soltanto fonti affidabili.

Ogni APK presente nella cartella viene installato **separatamente**. Split APK, AAB, APKS e XAPK non sono supportati dalla prima versione. APK con sole librerie ARM64 potrebbero non funzionare sul dispositivo virtuale x86_64.

## Due dita: mouse e touchpad

**Supporto già fornito dall'Android Emulator:** premi Ctrl e usa il mouse per simulare due punti speculari, adatti a pinch e zoom.

**Proposta sperimentale:** touchpad come primo dito, mouse come secondo, indipendenti e simultanei. Questo non è ancora realizzato: molti driver Windows Precision Touchpad espongono al software soltanto un puntatore o gesti elaborati, non le coordinate separate dei contatti. Serve un controllo del supporto hardware e una via di iniezione multitouch Android.

Nel pannello l'opzione appare **disabilitata** finché non sarà funzionale. Il supporto mouse/touchpad sarà verificato su hardware reale, senza dichiarare già risolto un problema di driver.

## Primo collaudo

1. Android si avvia, Impostazioni funziona, la GUI torna da fullscreen.
2. Verificare tocchi, swipe, pinch Ctrl+mouse e tastiera.
3. Provare un APK indipendente da file, cartella e link, registrando PASS/FAIL.
4. Controllare screenshot e report RAM/CPU, evitando altri dispositivi Android collegati.
5. Solo dopo, esperimenti su input multitouch da due dispositivi separati.

Ai-orchestrator-riserva rimane intatto e non è necessario per questi test.

## Fonti
- https://developer.android.com/studio/run/emulator
- https://developer.android.com/tools/adb
- https://developer.android.com/studio/run/emulator-console
