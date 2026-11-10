# WEmulDroid — integrazione con AIVEXUS Beta Access

## Repository separati
- **[Beta-access](https://github.com/pilialvu75-hue/Beta-access)**: servizio Cloudflare Worker, DB D1, pannello Android PWA, QR/link, coda centralizzata e inoltro al repository Diagnostics.
- **WEmulDroid (questo repository)**: launcher ed installer Windows. Il solo adapter client è in `src/BetaAccess.ps1` e `src/BetaUpload.ps1`.
- **[Ai-orchestrator-diagnostics](https://github.com/pilialvu75-hue/Ai-orchestrator-diagnostics)**: storage dei rapporti tecnici filtrati. Namespace separato WEmulDroid nella [PR #3](https://github.com/pilialvu75-hue/Ai-orchestrator-diagnostics/pull/3).

## Modalità di attivazione
L'installer Windows di test è protetto **solo** se viene compilato esplicitamente con la variabile `WEMULDROID_BETA_ACCESS_URL` (origine HTTPS del servizio Beta Access, senza percorso). `installer/Build-Windows.ps1` crea `BETA_ACCESS_URL.txt` all'interno del payload; Inno Setup lo include e il launcher richiede una prima autorizzazione.

Le beta esistenti e le build senza questa variabile **non sono soggette all'attivazione**. Non inserire il gate in una release normale senza collaudo e consenso di distribuzione.

Il tester:
1. apre un link o scansiona il QR dalla console Android del proprietario;
2. installa WEmulDroid su Windows;
3. vede il pulsante `Richiedi autorizzazione` solo su un installer volutamente protetto;
4. invia la richiesta e attende l'approvazione per la durata scelta;
5. clicca `Controlla stato` per accedere.

La decisione è verificata online al lancio. Non esiste ancora una licenza offline firmata. Non vengono conservati credenziali cloud nei pacchetti Windows.

## Log e statistiche
La diagnostica richiede consenso separato. La prima integrazione esporta soltanto: `APP_START`, `APP_EXIT`, `APP_ERROR`, metriche CPU e RAM del launcher, durata avvio e uptime. Il codice invia eventi classificati, **non** logcat grezzo, screenshot, token, chat, email, account, nomi di file o eccezioni complete.

Il modulo ADB di diagnostica completa esistente continua a salvare file **localmente** e non viene uploadato dal pilota. Metriche reali dell'emulatore (CPU/GPU/FPS, rete, I/O, crash specifici) sono priorità successive.

## Stato e blocchi
- Adapter Windows presente nel ramo di sviluppo, non distribuito ai tester.
- Build di sviluppo e test statici disponibili, non prova di funzionamento su ASUS.
- Non sovrascrivere una beta esistente finché il servizio pubblico, il gate, l'attivazione e l'invio Diagnostics non hanno superato test end-to-end.
- Il QR permanente e la console Android sono sviluppati **solo** su Beta-access; non duplicare il backend in WEmulDroid.
