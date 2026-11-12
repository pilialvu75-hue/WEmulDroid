# WEmulDroid — roadmap autonoma

**Vincolo assoluto:** WEmulDroid non deve modificare, ricompilare o integrare codice da Ai-orchestrator-riserva. L'eventuale integrazione sarà una decisione futura e separata, dopo il collaudo indipendente.

## P0 — Funzionamento minimo su Windows
- [x] Repository e progetto indipendenti
- [x] Installer con checksum SHA-256 degli strumenti ufficiali Google
- [x] GUI Windows (avvio/arresto AVD, installazione APK locale, elenco app, report)
- [x] Diagnosi preliminare read-only dei requisiti Windows
- [x] Script di test iniziale indipendente con Impostazioni Android (nessun APK esterno)
- [x] Profilo aggiuntivo ufficiale Google Play Store (installazione e avvio disponibili da script)
- [x] Interfaccia Play Store separata dal profilo Android tecnico
- [x] Controlli GUI per profili di risoluzione, ripristino e screenshot
- [x] Guida rapida per touch e audio
- [x] Menu English / Italiano / Français, scelta persistente e controlli GUI tradotti (test CI PASS)
- [ ] Verificare il cambio lingua, il layout dei pulsanti e la persistenza su Windows reale
- [x] Fullscreen reversibile sulla finestra dell'AVD selezionato (da collaudare)
- [x] Importazione APK da cartella locale e link HTTPS/GitHub con consenso, limite e SHA-256 (da collaudare)
- [x] Test offline delle regole di importazione APK (CI)
- [x] Funzioni snapshot list/save/load e conferma esplicita in GUI (da collaudare)
- [x] Diagnostica con report locale e logcat limitato (da collaudare)
- [x] Test offline dei nomi snapshot e package app
- [ ] Verificare effettivamente ripristino snapshot e diagnostica su Windows
- [ ] Verificare fullscreen, ripristino, installazione singola/cartella/link sul PC fisico
- [ ] Gestione split APK / AAB / XAPK solo se giustificata dai casi d'uso
- [ ] Collaudo video, speaker, microfono e gesti multitouch su Windows
- [ ] Validare futuro collaudo Work con Computer Use locale, senza accesso implicito al PC
- [x] CI leggera che verifica la sintassi PowerShell
- [x] Esecuzione reale del downloader, JDK 17 e installazione SDK Android su ASUS Windows 11 (screenshot test 4 novembre 2026)
- [x] Avvio completo AVD Android 15 e schermata iniziale visibile su ASUS (foto test 4 novembre 2026)
- [ ] Test Impostazioni Android, conferma UI e report RAM/CPU
- [x] Google Play Store ufficiale avviato sull'ASUS, schermata di autenticazione Google raggiunta (5 novembre 2026). **Non memorizzare credenziali in WEmulDroid**.
- [ ] Verifica download/installazione e avvio app compatibile autorizzata dal Play Store
- [ ] **Car Jam Solver (Ladaneta):** verifica compatibilità sul profilo Play Store Android 15 x86_64, installazione con approvazione, avvio, 1 livello manuale, screenshot e diagnostica. Poi prova di decisioni IA su dispositivo virtuale solo dopo un driver autorizzato e verificato. Protocollo: [Car Jam QA](CAR_JAM_SOLVER_QA.md).
- [ ] Installazione e avvio di una piccola applicazione indipendente x86_64
- [ ] Verifica Windows PowerShell, WHPX, Java, GPU, spazio su disco
- [ ] Rifinitura GUI e gestione dei problemi emersi su hardware reale

## Otto migliorie approvate
Il programma completo, con priorita e criteri PASS/FAIL, e in [APPROVED_IMPROVEMENTS.md](APPROVED_IMPROVEMENTS.md). Tutte le funzionalita non ancora collaudate restano marcate come tali.

## P0.8 — Aggiornamenti dall'app

- [x] Impostazioni → Aggiornamenti, lingua EN/IT/FR, canali stabile/beta
- [x] Ricerca release ufficiali, ZIP e hash SHA-256
- [x] Pacchetto v0.8.0-beta.1 pubblicato come release GitHub
- [x] Installazione prevista alla chiusura GUI, backup e tentativo rollback
- [x] CI leggera per sintassi, confronto versioni e packaging
- [ ] Verificare su Windows download e installazione di un vero aggiornamento più recente
- [ ] Verificare che SDK/AVD/report/preferenze non vengano modificati
- [ ] Verificare ripristino e comportamento in caso di aggiornamento interrotto

Dettagli: [UPDATES.md](UPDATES.md). La versione è distribuita come sorgenti PowerShell e non come applicazione Windows firmata.

## P0.9 — Primo Android avviato e revisione interfaccia

- [x] Windows 11 ASUS i7-12700H: emulatore Android 15 realmente avviato con schermata iniziale visibile
- [x] Regressione ADB `daemon not running; starting now at tcp:5037` non blocca più l'avvio sul PC reale
- [x] Installer unico Windows v0.9.0-beta.1 avviato con successo, collegamento Desktop e GUI funzionanti
- [x] Nuova GUI a schede: Applicazioni/APK, Schermo/Comandi, Diagnostica/Snapshot; lingua senza sovrapposizioni (test WinForms CI)
- [x] Pulsanti Avvia, Arresta, Aggiorna elenco e Impostazioni sempre visibili
- [x] Pannello ridotto a icona quando si avvia Android; test sintassi e GUI Windows CI
- [ ] Collaudare la GUI riorganizzata sul PC reale e confermare facilità d'uso
- [x] Aggiornamento beta.1 → beta.2 confermato con schermata utente, nonostante Windows abbia bloccato un tentativo di riavvio automatico dell'eseguibile non firmato
- [x] Avvio quieto dell'emulatore: stdout/stderr su report locali, senza console tecnica invadente (CI Windows PASS; verifica GUI Qt sul vero ASUS da completare)
- [x] Comandi Android sempre visibili: Home, Indietro, Tastiera PC / Android, Avvio pulito senza snapshot; test ADB e config AVD
- [x] Tastiera fisica ASUS e comando tastiera Android collaudati dall'utente con beta.5 (5 novembre 2026)
- [ ] Confermare che la finestra console non appaia nella nuova beta; i log devono comunque rimanere consultabili
- [ ] Verificare gli avvisi di caricamento snapshot (il sistema si avvia, gli avvisi da soli non rappresentano fallimento)
- [x] Correzione geometria finestra Android: centraggio automatico nel monitor attivo, riduzione se eccede area utile, pulsante manuale «Centra Android» (test Windows PowerShell 5.1 PASS)
- [x] Centraggio automatico Android verificato dall'utente sull'ASUS con beta.5 (5 novembre 2026)
- [x] Riprova del centraggio durante i primi ~50 s del boot per contrastare il riposizionamento Qt (sintassi e test geometria Windows)
- [x] Unico setup guidato di Android standard e Google Play ufficiale dopo consenso esplicito, nessuna sovrascrittura di AVD esistenti (CI Windows)
- [ ] Collaudo reale di prima installazione completa su Windows vergine (download SDK+2 immagini, licenze Google e Google Play)
- [x] Google Play Store raggiunto, login eseguito e contenuti Play Store visibili nel profilo dedicato. Tastiera fisica ASUS e Gboard collaudati.
- [ ] Provare APK reali, Google Play, mouse/audio, fullscreen e screenshot su ASUS

Non confondere popup Google Search/tastiera Android del primo avvio con elementi della GUI WEmulDroid. Tenere separati dati dell'AVD, codice applicativo e aggiornamenti.

## P0.10 — Modalità tablet nitida e spazio desktop visibile

- [x] Correzione del vecchio tablet erroneamente verticale `1600x2560 @ 320 dpi`: preset tablet orizzontali 16:10 (`1280x800 @ 200 dpi`) e 16:9 (`1600x900 @ 240 dpi`)
- [x] Profilo automatico che limita dimensioni e densità a quelle utili del monitor; niente 4K superfluo
- [x] Pulsante **Adatta finestra al monitor**: regola la finestra Qt senza ingrandire/ritagliare Android, preservando le proporzioni
- [x] Fullscreen intelligente: in verticale o se il monitor ha un altro rapporto di forma mantiene desktop visibile e adatta soltanto la finestra Android, evitando bande nere grandi
- [x] Controlli Schermo tradotti in italiano, inglese e francese e test Windows del fit multi-monitor
- [ ] Collaudo su ASUS di Play Store tablet in orizzontale e fullscreen con adattamento effettivo dell'immagine (i test CI verificano geometria/installer, non rendering Qt sul dispositivo reale)
- [ ] Misurare fluidità, testo, RAM/GPU e comportamento dopo l'uscita da fullscreen; nessuna regressione smartphone

## P0.11 — Collaudo ASUS e memoria (unico fronte successivo)

1. Installare dalla funzione **Impostazioni → Aggiornamenti** la beta correttiva successiva alla 0.9.0-beta.6. Nessuna cancellazione AVD/SDK, Play Store o account; non disattivare Smart App Control.
2. Verificare sull'ASUS: pulsante **Compatibilità giochi** visibile, rotazione automatica del gioco senza `wm user-rotation lock` forzato dal fullscreen, visualizzazione senza bande nere superflue, finestre non deformate, ripristino fullscreen.
3. In caso di crash o ANR, usare **Diagnostica completa** con consenso esplicito (screenshot, RAM Android, crash-buffer e rotazione); distinguere incompatibilità del singolo gioco da difetto generale. Brawl Stars è solo stress test di rotazione/grafica, non prova obbligatoria di compatibilità.
4. **Analisi memoria ASUS:** hardware già documentato: VivoBook 16X FX3605ZV-RP209W, i7-12700H, 16 GB DDR4 (15,6 GB utilizzabili), RTX 4060 Laptop 8 GB VRAM. In verifiche Windows precedenti erano disponibili circa 4,7 GB con carico elevato, circa 8,4 GB dopo alleggerimento. Questi valori NON sono misurazioni di WEmulDroid: raccogliere nuova baseline prima di proporre un upgrade.
5. Rilevare RAM Windows usata/disponibile/commit prima di avvio, dopo avvio AVD e con app di test; GPU VRAM, processi emulator/qemu e consumo Android `dumpsys meminfo`; confrontare cold boot e warm boot con profili identici. Provare solo modifiche reversibili a `hw.ramSize`, risoluzione e processi residenti, con backup configurazione. Non ridurre memoria a caso né confondere VRAM dedicata con RAM di sistema.
6. Verificare espandibilità RAM fisica **dello SKU esatto** prima di ogni acquisto; non aprire il portatile per prova prima di aver verificato documentazione/garanzia. Misurare il beneficio atteso: se la RAM non è satura, cercare invece cause grafiche/driver e incompatibilità x86_64.

**Gate di completamento:** WEmulDroid operativo e ripetibile sul vero ASUS con Play Store, display smartphone/tablet corretto e diagnostica utile; senza crash di sistema riproducibili. In assenza di collaudo reale non dichiarare stabilità 1.0 né supporto garantito di giochi specifici. Non aprire Ads Kill o Freebox Secure durante questo gate.

## P0.12 — Prima la memoria (Brawl Stars non parte sull'ASUS; diagnosi aperta)

Il 6 novembre 2026 l'utente ha confermato la beta.8 installata da Impostazioni > Aggiornamenti, con Android 15, Google Play, fullscreen e rotazione funzionanti. Brawl Stars non si avvia: **non attribuire il problema alla RAM senza misure reali**. Possibili cause alternative sono APK/ABI, driver grafici, crash Android o incompatibilita dell'emulatore; il titolo e solo uno stress test tecnico.

- [x] Implementati tre checkpoint Windows manuali, prima dell'avvio di Android, con Android acceso e dopo il tentativo di avvio gioco; nessuna modifica automatica dell'AVD.
- [x] Registrazione RAM totale, disponibile, occupata, pressione RAM, processi emulator/qemu; JSON per campione e CSV storico locale. Test Windows PowerShell 5.1.
- [ ] Raccogliere i tre campioni reali dell'ASUS in condizioni comparabili. Chiudere Android per il primo checkpoint; evitare altri carichi variabili.
- [ ] Usare Diagnostica completa Android dopo crash (logcat crash buffer, meminfo, stato rotazione); **nessun upload automatico**.
- [ ] Confrontare pressione RAM e crash logs: solo in presenza di indizi RAM valutare profilo AVD alternativo con backup e rollback.
- [ ] Testare un'altra app consentita su emulatore per distinguere causa generale da blocco specifico del gioco.
- [ ] Valutare 16 GB -> eventuale upgrade fisico solo dopo misurazioni e verifica espandibilita SKU, senza acquistare prima.
- [ ] Collaudare la beta successiva sul vero ASUS e verificare che Play Store e app esistenti siano preservati.

Nota: un test verde su GitHub non dimostra che Brawl Stars sia compatibile con un emulatore Android. Non aggirare limitazioni del gioco o le sue condizioni d'uso.

## P0.13 — Recupero grafico e report unificati (6 novembre)

- [x] Analizzati log ASUS: mismatch gfxstream degli snapshot, errori OpenGL e RAM Windows ancora disponibile; nessuna prova di OOM Android del gioco.
- [x] Profilo Google Play avviato senza recupero di Quick Boot precedente, senza eliminare dati Android, account o APK. Il primo avvio sara piu lento; questa mitigazione va rivalutata dopo collaudo.
- [x] Diagnostica completa registra anche host-memory.json nella cartella dei log Android, dopo il consenso gia previsto.
- [ ] Verificare su ASUS avvio, tempo, Play Store, giochi e dati persistenti.
- [ ] Verificare la causa effettiva del crash Android tramite logcat-crashes.txt.
- [ ] Valutare un renderer grafico alternativo in un collaudo separato e reversibile.
- [ ] Non dichiarare risolto un crash specifico sulla sola base della CI.

## P1 — Gestione input evoluta
- [ ] Verificare se il touchpad ASUS espone contatti separati leggibili dal software
- [ ] Esperimento dito 1 da touchpad + dito 2 da mouse, senza driver invasivi
- [ ] Traduzione in due tocchi Android indipendenti, con latenza accettabile e rilascio affidabile
- [ ] Fallback Ctrl+mouse e controllo WASD/gamepad se impossibile il vero multi-pointer

## P1 — Benchmark e misurazioni
- RAM: PSS, RSS, picchi, andamento temporale, possibili leak
- CPU per processo e host, thread e throttling ove disponibili
- GPU: frame timing e jank misurabili; non inventare la percentuale GPU
- APK size, spazio installato, cache, I/O, rete e cold/warm start
- Scenari ripetibili, report JSON/CSV/HTML, confronti tra versioni
- Profili dispositivi virtuali configurabili e confronti con hardware fisico

## P2 — Standard da app di terze parti
- Benchmark di app di riferimento con prove e profili identici
- Soglie realistiche per categoria e complessità applicativa
- Identificazione delle regressioni e degli scostamenti
- Eventuale integrazione opzionale, mai automatica, con Aivexus

## Regole di sviluppo
- Prima un emulatore realmente avviabile, poi funzioni avanzate
- Niente test pesanti su GitHub Actions; la CI attuale controlla solo la sintassi
- Niente commit di APK, SDK, immagini Google, credenziali e log
- Non dichiarare funzionamento sul PC o prestazioni senza prove reali
- Rispettare licenze e permessi delle app di terze parti
- ASUS Windows 11 ora disponibile: proseguire con collaudi reali, GUI, APK e aggiornamenti senza reinstallare SDK/AVD

**Collaudo orientamento / giochi (5 novembre 2026):** l'utente ha scelto Brawl Stars come *stress test tecnico*, non per giocare. Il gioco richiede normalmente l'orientamento landscape: il passaggio a 90 gradi rispetto allo smartphone verticale è atteso. Non confondere questo comportamento con un bug. Sono invece difetti da diagnosticare: immagine o testo che restano ruotati rispetto alla finestra Windows, schermo non adattato, errore "keeps stopping" o "isn't responding". La diagnostica deve separare incompatibilità del gioco, driver GPU/emulatore, eventuale problema di memoria e rotazione forzata da WEmulDroid; senza logs non attribuire la causa. Le condizioni d'uso di Supercell limitano l'impiego di emulatori: non richiedere login all'account di gioco, né dare per garantita la compatibilità. Per escludere errori generali di WEmulDroid confrontare un'app di gioco che autorizzi l'emulazione. Vedi [Google Play](GOOGLE_PLAY.md).

- [x] Modalità **Compatibilità giochi** nel pannello Schermo/Comandi: ripristina rotazione automatica e dimensioni Android originali, senza wipe di APK, account o AVD.
- [x] Fullscreen non deve modificare in alcun modo `wm size`, `wm density`, `wm user-rotation`. Sono comandi separati, espliciti e reversibili.
- [x] Diagnostica dei crash: ultimi eventi del buffer `logcat -b crash` e stato rotazione, salvati solo localmente con consenso.
- [ ] Verifica sul vero ASUS dei giochi landscape, delle schermate ANR/crash, dei driver grafici e del fit senza bande nere.

