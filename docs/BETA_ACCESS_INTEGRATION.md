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
5. attende: WEmulDroid controlla lo stato automaticamente ogni circa 8 secondi e si avvia subito dopo l'approvazione (non esiste più il pulsante `Controlla stato`).

La decisione è verificata online al lancio. Non esiste ancora una licenza offline firmata. Non vengono conservati credenziali cloud nei pacchetti Windows.

## Log e statistiche
La diagnostica richiede consenso separato. La prima integrazione esporta soltanto: `APP_START`, `APP_EXIT`, `APP_ERROR`, metriche CPU e RAM del launcher, durata avvio e uptime. Il codice invia eventi classificati, **non** logcat grezzo, screenshot, token, chat, email, account, nomi di file o eccezioni complete.

Il modulo ADB di diagnostica completa esistente continua a salvare file **localmente** e non viene uploadato dal pilota. Metriche reali dell'emulatore (CPU/GPU/FPS, rete, I/O, crash specifici) sono priorità successive.

## Stato e blocchi
- Adapter Windows presente nel ramo di sviluppo, non distribuito ai tester.
- Build di sviluppo e test statici disponibili, non prova di funzionamento su ASUS.
- Non sovrascrivere una beta esistente finché il servizio pubblico, il gate, l'attivazione e l'invio Diagnostics non hanno superato test end-to-end.
- Il QR permanente e la console Android sono sviluppati **solo** su Beta-access; non duplicare il backend in WEmulDroid.

## Sblocco automatico e avviso Android

La finestra Beta Access appare **al primo avvio dopo l'installazione**, prima dell'interfaccia principale, e soltanto nelle nuove beta compilate con gate esplicito. Dopo aver premuto `Richiedi autorizzazione`, il tester può lasciare la finestra aperta: il programma verifica il server (primo controllo dopo circa mezzo secondo, poi ogni circa otto secondi) e si sblocca da solo quando l'approvazione non è scaduta. Un errore di rete non sblocca mai una beta protetta. Se il tester chiude l'app, alla riapertura una nuova verifica lo autorizzerà se il consenso è ancora valido.

Le notifiche push riguardano invece il **telefono Android dell'amministratore** e si configurano nel repository [Beta-access](https://github.com/pilialvu75-hue/Beta-access/pull/7). La consegna è best-effort e richiede che il proprietario scelga `Attiva notifiche push` in Chrome/PWA.

Attualmente il controllo Windows avviene tramite WinForms Timer e chiamate HTTPS sincrone con `-TimeoutSec 5`; l'interfaccia di attivazione può temporaneamente rallentare con Internet instabile. Da verificare su Windows reale prima di pubblicare la beta gated.

## Conferma sonora dell'attivazione

Quando il server approva una richiesta e il blocco viene rimosso, una **breve sequenza originale di due note** (D5/G5) può confermare lo sblocco prima di mostrare l'interfaccia WEmulDroid. La checkbox **«Suono breve quando l'app si sblocca»** è attivata per impostazione predefinita e salvata nelle preferenze locali del tester; si può deselezionare. La sequenza è generata localmente in memoria come WAV PCM, senza file audio distribuiti e senza invio di dati. Il tentativo di riprodurla è *best effort*: l'assenza di un dispositivo audio non deve mai impedire l'accesso autorizzato. Deve essere verificata su un computer Windows reale prima di pubblicare l'installer beta.

## Invito privato obbligatorio per nuove beta tester

Quando la distribuzione tester sarà autorizzata, ogni primo avvio richiederà il **codice di invito personale** (43 caratteri) presente nel link HTTPS creato sul Galaxy S24 FE dal pannello Beta Access. Senza un codice valido, scaduto oppure già usato da un altro PC, il backend non accetterà la richiesta. Il codice è mantenuto **solo in memoria durante l'attivazione** e non viene scritto in `installation.json`, nei log o in Diagnostics. L'installazione resta bloccata finché il proprietario non l'approva: dopo l'approvazione, il gate verifica automaticamente lo stato e apre WEmulDroid con il suono facoltativo. Gli inviti non provano automaticamente la proprietà dell'email dichiarata; è una fase futura.

L'interfaccia richiede esplicitamente il codice da incollare, ma le release pubbliche già distribuite **non sono aggiornate**: occorrerà compilare e collaudare la nuova beta gated prima di abilitare `PUBLIC_TESTERS_ENABLED`.
