# Google Play Store ufficiale in WEmulDroid

WEmulDroid supporta un **secondo dispositivo virtuale Google Play**, separato dal profilo tecnico Android standard.

## I due ambienti

| Profilo | Sistema | Store | Uso |
| --- | --- | --- | --- |
| WEmulDroid_API_35 | Android 15, API 35, Google APIs x86_64 | Non incluso | diagnostica e test tecnici |
| WEmulDroid_Play_API_35 | Android 15, API 35, Google Play x86_64 | **Google Play Store ufficiale** | installare e aggiornare app/giochi dal negozio |

I profili hanno dati e app installate separati. Non installiamo pacchetti GApps estranei o APK modificati.

## Quando il PC Windows sarà disponibile

1. Scarica/aggiorna i sorgenti WEmulDroid tramite GitHub, estrai lo ZIP.
2. Esegui **Verifica-PC.cmd** se è la prima volta.
3. Esegui **Installa-PlayStore.cmd** e segui gli avvisi; vengono scaricati gli strumenti e la **system image google_apis_playstore ufficiale Google** da SDK Manager, previo consenso alle licenze. Servono diversi GB di spazio libero.
4. Esegui **Avvia-PlayStore.cmd**; nella finestra premi **Avvia Android**.
5. Premi **Apri Play Store**, oppure tocca l'icona Play Store nel dispositivo virtuale.
6. Accedi al tuo account Google **direttamente nel dispositivo virtuale Google**, mai nelle finestre o negli script WEmulDroid; cerca e installa le app compatibili.
7. Da **Aggiorna elenco** puoi verificare i package utente installati e da **Misura risorse** salvare le diagnostiche.

**Il Play Store potrebbe non mostrare o permettere di installare tutte le app:** compatibilità hardware, versione Android, paese, politiche dello sviluppatore e controlli d'integrità possono impedire disponibilità o avvio.

L'account Google usato per la prova può rimanere nel dispositivo virtuale (dati locali dell'AVD); usa un profilo dedicato se vuoi separare la tua attività personale dai collaudi. Le immagini Google Play non supportano l'accesso root.

### Brawl Stars: attenzione

Brawl Stars è un gioco di Supercell disponibile su Google Play. Le [condizioni d'uso di Supercell](https://supercell.com/en/terms-of-service/) citano esplicitamente gli emulatori tra le pratiche vietate. **Non usarlo come primo benchmark su WEmulDroid e non mettere a rischio il tuo account principale.**

Il nostro primo percorso di test rimane: avvio Android → Impostazioni (senza app esterne) → Play Store si apre → installazione di una piccola app/gioco con utilizzo in emulatore consentito → test RAM, CPU e rendering → benchmark ripetibili.

### Primo confronto di IA: Car Jam Solver (Ladaneta)

Il gioco ufficiale proposto per confrontare Galaxy S24 FE e WEmulDroid
è [Car Jam Solver: Traffic Jam](https://play.google.com/store/apps/details?id=car.parking.jam.solver.puzzle.games),
package `car.parking.jam.solver.puzzle.games`.
Il protocollo dettagliato, incluso il trattamento di pubblicità e
acquisti, si trova in [CAR_JAM_SOLVER_QA.md](CAR_JAM_SOLVER_QA.md).

L'utente sceglie e approva personalmente l'installazione nel Play Store
del dispositivo virtuale; WEmulDroid non entra nell'account Google e
non invia in automatico acquisti, dati personali o tocchi al gioco.
Compatibilità del titolo su Android 15 x86_64 **non ancora verificata**.

### Limiti e privacy

- Google Play necessita connessione Internet, account e accettazione delle condizioni applicabili.
- Non è garantito che app native solo ARM64 funzionino su immagine x86_64, anche quando la traduzione ABI è disponibile.
- RAM, GPU, FPS e batteria osservati in emulazione non equivalgono a misure su hardware Android reale.
- WEmulDroid non automatizza accessi, acquisti, download o interazione con applicazioni del Play Store; l'utente controlla ogni installazione.
- La CI attuale verifica la sintassi del codice ma non installa immagini Android o apre il Play Store.
- Il repository Ai-orchestrator-riserva resta completamente separato e immutato da questo sviluppo.

## Fonti ufficiali
- [Google: creare e gestire Android Virtual Devices](https://developer.android.com/studio/run/managing-avds)
- [Google: Android Emulator](https://developer.android.com/studio/run/emulator)
- [Supercell: Terms of Service](https://supercell.com/en/terms-of-service/)
