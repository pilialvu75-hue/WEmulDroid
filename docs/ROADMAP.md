# Roadmap — AIVEXUS Android Desktop Lab

## P0 — Primo avvio reale su Windows
- [x] Repository separato dal progetto principale
- [x] Installer che usa soltanto gli strumenti Android ufficiali
- [x] GUI autonoma di controllo del dispositivo virtuale
- [x] Comandi di installazione APK / elenco applicazioni / misure diagnostiche
- [ ] Installazione verificata su Windows 11 fisico con WHPX
- [ ] Primo boot AVD completo e screenshot di evidenza
- [ ] Installazione e avvio di un APK di prova, con log ed esito
- [ ] Misure RAM e CPU associate ad una singola app, verificabili
- [ ] Identificare compatibilità APK arm64-only e proporre strategia di test
- [ ] Versione distributiva semplice con aggiornamenti controllati

## P1 — Misurazioni comparabili
- Profili hardware (CPU, RAM, schermo, API, ABI, modalità grafica)
- Scenari di test automatici, warm/cold start e ripetizioni
- RAM: PSS, RSS, picchi, andamento temporale e leak sospetti
- CPU per processo e host, uso thread; GPU: frame timing e indicatori disponibili
- APK size, installed size, dati/cache, I/O, rete, batteria e temperatura ove accessibili
- Report JSON + CSV + HTML e grafici; confronti tra versioni
- Soglie e regressioni; distinguere stime in VM da misure su hardware reale

## P2 — Laboratorio competitivo
- Benchmark app di terze parti con test identici e stessa configurazione
- Standard differenziati per categoria e complessità, baseline realistiche
- Integrazione opzionale con Costruttore e Libreria Aivexus via interfacce isolate
- Integrazione opzionale con device fisici; esperimenti di compatibilità ARM

## Principi
1. Nessuna modifica al repository Ai-orchestrator-riserva durante il progetto indipendente.
2. Nessun binario Android/Google versionato o redistribuito.
3. Niente claim prestazionali prima di una prova ripetibile sul PC reale.
4. Nessuna app di terze parti deve essere analizzata oltre i permessi e le licenze applicabili.
5. Non usare GitHub Actions pesanti solo per test funzionali locali.
