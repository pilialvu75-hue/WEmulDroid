# Snapshot e diagnostica WEmulDroid v0.6

**Stato:** implementazione iniziale nel codice. I test automatici PowerShell controllano sintassi e validazione dei parametri, ma **nessun collaudo reale su Windows** è stato eseguito.

## Snapshot

Dopo aver avviato Android nella finestra WEmulDroid:

1. **Elenco snapshot**: mostra gli stati già salvati nel dispositivo virtuale selezionato.
2. **Salva snapshot**: chiede una conferma esplicita e salva lo stato in uno slot chiamato WEmulDroid_baseline.
3. **Ripristina snapshot**: verifica che la baseline esista, mostra una seconda conferma e ne carica lo stato.

Il ripristino è **distruttivo per le modifiche successive** (app, dati, configurazioni, sessioni). Non viene eseguito automaticamente e non equivale a un backup esterno. Prima di ripristinare salva gli eventuali dati necessari in altro modo.

I comandi usano la console ufficiale Android Emulator tramite adb -s SERIAL emu avd snapshot list/save/load NOME; la funzione è limitata al solo AVD selezionato e non ha pulsanti per eliminare snapshot.

Gli snapshot possono occupare diversi GB e contenere dati personali, compresi dati di login del Play Store. Restano nei file locali dell'AVD, non vengono caricati sul repository.

## Diagnostica locale

Il pulsante **Diagnostica completa**:
- chiede il consenso prima di leggere i dati;
- usa il solo emulatore selezionato e, se selezionato, il package dell'app Android;
- salva Android/ABI, dimensioni e densità schermo, meminfo, cpuinfo, gfxinfo app, le ultime 120 righe logcat e uno screenshot;
- crea una cartella con report.txt, logcat-last120.txt e screenshot.png dentro il percorso locale WEmulDroid/Reports;
- indica gli errori parziali: riuscire a creare una cartella non significa che tutte le misure siano disponibili.

**Attenzione privacy:** i report e gli screenshot possono contenere notifiche, messaggi, account, nomi delle app e altri dati personali. Controlla sempre i file prima di condividerli con altre persone o con Work. Nessun report viene inviato automaticamente a Internet.

## Collaudo da fare sul PC Windows

- [ ] Impostazioni Android avviate in WEmulDroid
- [ ] Snapshot salvato, un'impostazione modificata, ripristino effettivo verificato
- [ ] Verificato comportamento su AVD Play Store senza condividere dati personali
- [ ] Report con screenshot PNG leggibile e file logcat valido
- [ ] Chiusura e riavvio del dispositivo senza perdita imprevista del profilo
- [ ] Controllare che i pulsanti non interessino altri dispositivi Android connessi
- [ ] Misurare RAM/CPU e spazio disco aggiuntivi richiesti dagli snapshot

## Prossimo incremento

Dopo il collaudo reale: snapshot con nomi personalizzati, backup prima di test ripetibili, eventuale pulsante Ripeti test che esegua uno scenario e confronti risultati, e diagnostica dei crash con filtri dei dati sensibili.

Fonti ufficiali:
- https://developer.android.com/studio/run/emulator-console
- https://developer.android.com/studio/run/emulator-snapshots
