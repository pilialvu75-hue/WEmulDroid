# Piano di sviluppo approvato — 8 migliorie WEmulDroid

**Decisione:** tutte e otto le idee sono approvate per il progetto **autonomo** WEmulDroid. Non sono necessariamente tutte implementate. Non modificare, ricompilare o integrare Ai-orchestrator-riserva: il progetto principale è fuori scope.

## Priorità P0 — Affidabilità, prima dei test intensivi

### 1. Snapshot e ripristino
**Stato codice:** prima interfaccia implementata in WEmulDroid v0.6; collaudo Windows ancora da eseguire.
- Elenco, salvataggio e caricamento snapshot AVD tramite comandi ufficiali Android Emulator.
- Nome baseline predefinito per il dispositivo attivo; doppia conferma esplicita per modifiche/ripristino.
- Il ripristino può cancellare modifiche ad app, dati e sessioni dopo lo snapshot.
- Criterio PASS: avviare un AVD, salvare lo stato, modificare un'impostazione, ripristinare e verificare visivamente che torni quella originale.
- Non considerare i dati Google Play come innocui: gli snapshot possono contenere accessi e dati personali. Non caricarli automaticamente su GitHub.

### 7. Diagnostica automatica con un clic
**Stato codice:** primo raccoglitore implementato in v0.6; collaudo Windows da eseguire.
- Salva screenshot, ultime 120 righe logcat, RAM, CPU, rendering opzionale dell'app selezionata e risoluzione Android.
- Report in cartella solo locale, errori parziali evidenziati, nessun invio senza autorizzazione.
- Criterio PASS: report locale completo per un'AVD con Impostazioni aperte; verifica screenshot e log coerenti con l'esito.
- Possibile estensione: raccolta automatica dopo crash, filtri dati sensibili, archivio ZIP generato su richiesta.

### Controlli fondamentali
- Validazione sintassi PowerShell tramite CI leggera.
- Test offline dei parametri snapshot e package; niente Android Emulator nei runner GitHub.
- Obbligatoria la prima prova fisica su Windows prima di attribuire lo stato "funzionante".

## Priorità P1 — Esperienza utente e confronto delle prestazioni

### 2. Registrazione video
- Registrazione del display emulato con comandi Android (limiti di durata/risoluzione e audio da gestire).
- Salvare una timeline con timestamp, screenshot del problema e dati diagnostici.
- Criterio PASS: video riproducibile sincronizzato a un test e allegabile ai report con controllo dell'utente.

### 3. Simulazione condizioni reali
- Profili rete (velocità/ritardo), orientamento, batteria simulata, GPS e sensori disponibili.
- Distinguere batteria simulata e reale, dichiarando impostazioni per confronto ripetibile.
- Criterio PASS: medesima app si comporta come atteso sotto profili diversi, con salvataggio della configurazione.

### 4. Comandi per giochi
- Mappatura WASD, joystick, gamepad, gesture e tasti personalizzati per app.
- Due contatti indipendenti touchpad/mouse solo dopo verifica hardware; fallback Ctrl+mouse.
- Rispetto delle condizioni dei giochi: nessuna automazione contro le regole dei servizi.
- Criterio PASS: gioco/app autorizzato con input ripetibile e senza interferire con altre finestre.

### 5. Cruscotto risorse
- RAM/CPU per-app e host, frame-time/jank, spazio e I/O quando misurabili.
- Distinguere le metriche della macchina Windows e dell'Android virtuale; niente GPU % inventate.
- Storico per release, baseline per categorie e regressioni con soglie adattive.
- Criterio PASS: misurazioni ripetibili, con timestamp e condizioni hardware comparabili.

### 6. Più dispositivi virtuali
- Gestione di profili multipli (standard, Google Play, smartphone, tablet).
- Preset di RAM/CPU/densità e device diversi, con avviso costi RAM e disco.
- Criterio PASS: profili isolati, nessuna modifica accidentale ad altri dispositivi collegati.

## Priorità P2 — Test automatizzati, dopo stabilizzazione

### 8. Modalità collaudo Work
- Adattatore locale opzionale per avviare app, eseguire tap/swipe/scenari e acquisire prove.
- Permessi espliciti, limiti del dispositivo, tracciabilità, risultati PASS/FAIL.
- Distinguere Work Desktop con Computer Use da Work cloud: l'accesso al PC non è implicito.
- Criterio PASS: test indipendente di app autorizzata su Windows, ripristino baseline e report dopo ripetizione.

## Funzionalità trasversale — Ripeti test
Il pulsante «Ripeti test» è un traguardo successivo e non equivale al solo caricamento snapshot. Richiede: baseline, scenario ripetibile, tempi, metrica, acquisizione del risultato, confronto della distribuzione dei risultati su più prove e identificazione delle regressioni.

## Limiti e calendario
- Nessun test fisico disponibile al momento: codice, documentazione e verifiche statiche soltanto.
- L'emulatore ufficiale Android è un motore esterno; immagini Google si scaricano secondo le loro licenze.
- Non chiamare una funzione "verificata" finché non è stato eseguito un test reale sul PC.
- Non usare Actions Android, macOS o Windows per piccoli fix PowerShell; preferire test statici offline di pochi secondi.
