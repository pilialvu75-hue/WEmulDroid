# WEmulDroid — Aggiornamenti Windows (stato: 6 novembre 2026)

## Procedura attuale

WEmulDroid e un'app Windows distribuita tramite installer Inno Setup, non piu tramite ZIP con launcher CMD. La procedura corrente e **Impostazioni > Aggiornamenti > Includi beta (facoltativo) > Controlla > Scarica > Installa**. Controllo e download avvengono soltanto dopo un'interazione dell'utente e l'installazione richiede un'ulteriore conferma. L'app scarica l'installer e il suo checksum dalla sezione release ufficiali GitHub; la verifica SHA-256 non equivale a una firma digitale riconosciuta da Windows.

L'installazione conserva i dati persistenti fuori dal programma: SDK Android, AVD, applicazioni, dati Play Store, configurazioni e report. Non disinstallare o cancellare queste cartelle per risolvere un problema dell'updater.

## Collaudo ASUS: beta.6 -> beta.7

Il 5 novembre 2026, ore 23:11:34, Windows CodeIntegrity/Operational ha registrato eventi **3077** e **3033** che indicano un blocco sul file di staging `%LOCALAPPDATA%\WEmulDroid\Updates\installer-pending\WEmulDroid-Setup-v0.9.0-beta.7.exe`, con processo PowerShell. Il file non rispettava i requisiti richiesti dai criteri di firma/integrita del codice Windows.

Questo prova il blocco della policy e la presenza del file, **non** dimostra da solo quale istruzione PowerShell abbia scatenato l'evento e non prova che il file possa essere eseguito con successo da un percorso diverso. La beta.7 pubblicata e non firmata. Non disattivare Smart App Control, WDAC, antivirus o controlli di sicurezza per installarla.

## Correzioni gia sul ramo main, non presenti nella beta.6 installata

- `1606f868`: messaggi distinti per ricerca, download e installazione quando Windows segnala un blocco.
- `9f9cf532`: nel canale *development*, dopo il controllo SHA-256, non viene piu invocato `Get-AuthenticodeSignature` sull'installer unsigned; il controllo firma continua nel canale *production*.
- `e9132aec`: test di regressione che simula l'eccezione CodeIntegrity durante il controllo Authenticode, verifica il rifiuto per hash modificato e preserva il gate delle firme in produzione.
- `1683d4a2`: test integrato nel workflow Windows; CI PASS al run https://github.com/pilialvu75-hue/WEmulDroid/actions/runs/42131613134.

La correzione **non** e una prova di compatibilita con Smart App Control sull'ASUS. Il rilascio gia pubblicato beta.7 non e stato modificato e non va sovrascritto. Non pubblicare una nuova beta solo perche il test CI e verde.

## Diagnosi in caso di nuovo errore

1. Leggere la fase mostrata nell'app (*Controlla*, *Scarica* o *Installa*); non dedurre la fase soltanto dall'evento Windows.
2. Controllare in sola lettura il Visualizzatore eventi > Registri applicazioni e servizi > Microsoft > Windows > CodeIntegrity > Operational. Annotare orario, ID evento e nome del file senza copiare informazioni private non necessarie.
3. Distinguere *download fallito*, *verifica SHA-256 fallita*, *verifica firma produzione fallita*, *blocco CodeIntegrity* e *Start-Process negato*. Un SHA-256 corretto non certifica l'idoneita all'esecuzione.
4. Se il blocco permane, non aggirare la policy: utilizzare una filiera attendibile di firma/distribuzione e validare l'installer su un vero dispositivo con protezioni attive.

## Test obbligatori prima di dichiarare risolto

- [x] Test CI Windows dell'updater e della conservazione dati su runner.
- [x] Test con errore simulato di Authenticode nel canale sviluppo e verifica della policy in produzione.
- [ ] Installazione e aggiornamento sull'ASUS con policy Windows attiva.
- [ ] Conferma SDK, AVD, Play Store e APK preservati dopo aggiornamento.
- [ ] Test fullscreen, rotazione, giochi e misurazione RAM/CPU/GPU sull'ASUS.

Documenti di riferimento: [Architettura installer](INSTALLER_ARCHITECTURE.md), [opzioni firma](CODE_SIGNING_OPTIONS.md), [issue P0](https://github.com/pilialvu75-hue/WEmulDroid/issues/5).

## Storico: vecchie beta ZIP

Le istruzioni per `v0.8.0-beta.1` e `beta.3` basate su file `.cmd` e sostituzione manuale di `Updates.ps1` sono **obsolete** per le versioni installer `v0.9.x` e **non devono essere utilizzate** sulla beta.6 dell'ASUS. Non sostituire manualmente gli script dell'installazione corrente.
