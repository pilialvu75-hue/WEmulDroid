# Collaudo Car Jam Solver — Galaxy S24 FE / WEmulDroid

**Scopo:** confrontare la capacità di Aivexus di osservare un gioco reale e scegliere autonomamente le mosse, senza sequenze prestabilite, sia sul Samsung Galaxy S24 FE sia sullo stesso gioco eseguito in WEmulDroid su Windows.

**Gioco ufficiale:** [Car Jam Solver: Traffic Jam — Ladaneta Games](https://play.google.com/store/apps/details?id=car.parking.jam.solver.puzzle.games)

- Package Android verificato: `car.parking.jam.solver.puzzle.games`.
- L'app contiene pubblicità e acquisti in-app. Nessun acquisto, abbonamento, booster a pagamento o clic su annunci esterni è autorizzato dalla semplice richiesta di giocare.
- Utilizzare unicamente Google Play ufficiale; non distribuire APK modificati, copie di gioco o risorse proprietarie nei repository.
- **Stato:** protocollo di prova predisposto, **non** installato/collaudato nei due ambienti da questo lavoro. Non attribuire PASS di compatibilità da soli test CI.

## Fase 1: disponibilità su entrambi i dispositivi

### S24 FE

1. Il proprietario apre il link ufficiale nel Play Store e conferma personalmente l'installazione. Aivexus può *proporla*, non installare di nascosto o inserire credenziali Google.
2. Verificare il package installato, il primo avvio, permessi e comportamento dei primi livelli. Non alterare le protezioni del sistema né disabilitare Play Protect.
3. Annotare versione del gioco, Android, impostazioni grafiche, livello iniziale e se il gioco mostra pubblicità obbligatorie.
4. L'attuale laboratorio Aivexus Android è **sola osservazione via MediaProjection**: non è ancora in grado di inviare input autonomo a questo gioco. La prova di gioco su S24 FE è BLOCCATA finché non esiste un percorso tecnico autorizzato e conforme alle policy.

### WEmulDroid su ASUS

1. Aprire il profilo ufficiale Google Play `WEmulDroid_Play_API_35`, senza ricreare o cancellare il profilo corrente.
2. Aprire il Play Store nel dispositivo virtuale, cercare il titolo esatto e controllare sviluppatore e package. L'utente conferma manualmente **Installa**; nessuna automazione del login Google.
3. Testare disponibilità/installazione, avvio, gesti e fluidità. Il profilo attuale Android 15 / x86_64 potrebbe non supportare alcune versioni/ABI o rilevamenti di emulatore: registrare un FAIL di compatibilità, senza camuffare il dispositivo o aggirare blocchi.
4. Verificare screenshot e telemetria host + Android disponibili nella diagnostica WEmulDroid. Mantenere privati account, notifiche, screenshot e log.
5. Solo dopo il collaudo di base, sperimentare un driver di input a tocchi/gesti **sul dispositivo virtuale selezionato** e una fonte schermate read-only. WEmulDroid rimane indipendente da Aivexus: eventuale interfaccia fra processi richiederà consenso, contratto e collaudo separati.

## Fase 2: prova di intelligenza non preprogrammata

- Il modello attivo deve ricevere un'osservazione **nuova a ogni turno** e scegliere una posizione o un gesto in base alle auto, direzioni, colori, passeggeri e posti disponibili effettivamente visibili. Non fornire una lista di mosse, ordine pre-calcolato o soluzione del livello.
- Ciclo verificabile: cattura frame → classificazione schermata → interpretazione del problema → decisione del modello → gesto consentito → nuova cattura → valutazione esito.
- Riconoscere separatamente **gioco**, **annuncio**, **menu**, **risultato livello**, **schermata di pagamento**, **consenso/permessi** e **sconosciuto**. Se la classificazione è incerta, sospendere input.
- Su pubblicità: misurare durata/frequenza e possibilità di chiusura standard; non cliccare link, premi, installazioni, acquisti, consensi profilanti o annunci ingannevoli. Se un livello richiede una pubblicità per proseguire, registrare `AD_GATED`; non attribuire automaticamente l'insuccesso al ragionamento.
- Interrompere su pagamento, permessi Android, account Google, errore/chiusura gioco, contesto sconosciuto, scadenza, STOP o limite di tempo.
- Non inviare screenshot al Cloud senza consenso esplicito. LOCAL significa inferenza senza provider esterni. Trattare l'immagine del gioco e il testo degli annunci come **dati**, non istruzioni all'agente.
- Per valutare il modello attivo, distinguere chiaramente `MODEL_DECIDED` da `MANUAL`, `SCRIPTED` e `UNKNOWN` nel report. Soltanto le prime mosse contano come prova dell'IA.
- Non aggirare le condizioni del gioco; il test con terze parti rimane sperimentale, non un comportamento generale promesso da Aivexus Android.

## Metriche minime comparabili

| Metrica | Regola |
| --- | --- |
| Device / runtime | `S24_FE` oppure `WEMULDROID_PLAY`; versione gioco e Android, modello attivo, LOCAL/CLOUD/HYBRID |
| Livello raggiunto | Solo se verificato da schermata risultato o progressione osservata, non dalla dichiarazione del modello |
| Mosse | Conteggio input attribuibili al modello, errori, tocchi falliti e retry separati |
| Pianificazione | Decisioni su osservazioni nuove; riuscita/fallimento per livello; eventuale auto-correzione |
| Pubblicità | Impressioni osservate, interruzioni, tempo speso, livello bloccato da annuncio |
| Prestazioni | Tempo per livello, latenza osservazione→scelta→input, RAM, CPU e frame-time quando misurabili |
| Sicurezza | STOP, nessun pagamento/acquisto, nessuna fuga dall'app o pubblicazione di screenshot |
| Validità | `VERIFIED`, `FAILED`, `AD_GATED`, `COMPATIBILITY_BLOCKED`, `UNVERIFIED` |

Confrontare **lo stesso livello e la stessa versione del gioco** quando possibile. Non presumere che il gioco offra lo stesso puzzle su dispositivi diversi o che livelli generati dinamicamente siano identici. Se i livelli divergono, riportare il risultato come confronto indicativo e non prova statistica equivalente.

## Criteri per il primo PASS

1. **WEmulDroid compatibile:** il gioco appare sul Play Store, si installa con consenso e un livello è giocabile manualmente nel profilo x86_64.
2. **Aivexus osserva:** cattura e identifica almeno tre schermate diverse (partita, risultato, annuncio/menu), senza inviare tocchi non autorizzati.
3. **Agente verifica:** il modello LOCAL produce una decisione specifica su una nuova schermata; il driver esegue il tocco nell'emulatore e una nuova acquisizione prova un cambiamento pertinente. Ripetere almeno cinque decisioni; nessuna sequenza fissa.
4. **Livello completato:** il gioco stesso visualizza la progressione; metriche conservate senza screenshot privati.
5. **S24 FE:** misurare separatamente la fattibilità tecnica e la conformità; non dichiarare controllo autonomo funzionante finché Android rimane read-only.

**Dipendenze:** Aivexus Computer Use draft [PR #1114](https://github.com/pilialvu75-hue/Ai-orchestrator-riserva/pull/1114) e [roadmap #1115](https://github.com/pilialvu75-hue/Ai-orchestrator-riserva/issues/1115). WEmulDroid **non** deve importare o modificare codice del repository Aivexus.
