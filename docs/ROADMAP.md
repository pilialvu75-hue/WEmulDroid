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
- [ ] Esecuzione reale del downloader e dell'installazione su PC Windows
- [ ] Avvio completo AVD e UI Android visualizzata
- [ ] Test Impostazioni Android, conferma UI e report RAM/CPU
- [ ] Primo avvio Google Play Store su Windows, login nel dispositivo virtuale
- [ ] Verifica download/installazione e avvio app compatibile autorizzata dal Play Store
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
- Finché il PC non è disponibile: migliorie statiche/CI soltanto; collaudo rinviato

**Nota giochi Supercell:** Brawl Stars non è il benchmark iniziale: le condizioni d'uso Supercell limitano l'impiego di emulatori. Per la prima prova usare un gioco consentito e leggero. Vedi [Google Play](GOOGLE_PLAY.md).
