# WEmulDroid 0.9 — Architettura dell'installer ufficiale

## Stato e criteri di rilascio

La distribuzione **ZIP + .cmd** è stata ritirata. Non pubblicare una nuova versione ufficiale finché la firma di un editore attendibile e il collaudo completo non sono verificati.

1. **Installer Windows Inno Setup** in un unico file .exe, associato sempre allo stesso AppId: installazione per utente, senza privilegi amministrativi.
2. **Layout immutabile**: `%LOCALAPPDATA%\Programs\WEmulDroid` contiene il launcher, le librerie dell'app e la documentazione. Gli aggiornamenti sostituiscono questa applicazione usando lo stesso installer.
3. **Dati persistenti**: `%LOCALAPPDATA%\WEmulDroid\Sdk`, `Reports`, `Settings`, `Updates` e i dispositivi AVD dentro la cartella utente Android restano **fuori** dal programma e **non vengono cancellati** né dall'installer né dall'uninstaller.
4. **Icone vere**: collegamento WEmulDroid sul Desktop, più Start Menu standard e Google Play. L'icona è generata dal progetto, il collegamento punta a `WEmulDroid.exe`, non ai vecchi script .cmd.
5. **Configurazione Android**: primo avvio dalla GUI → **Installa strumenti**. Apre il setup ufficiale Android / Java e chiede esplicitamente le licenze Google; non scarica SDK di nascosto e non lo ripete ad ogni aggiornamento dell'app.
6. **Aggiornamenti stabile/beta**: Impostazioni → Aggiornamenti → Controlla → Scarica → Installa. La GUI cerca **solo** file `WEmulDroid-Setup-vX.Y.Z[-beta.N].exe` e il corrispondente `.sha256` tra le release GitHub ufficiali. Il download non parte finché l'utente non lo conferma.
7. **Verifica doppia**: hash SHA-256 della release + firma Authenticode `Valid`, con **stesso certificato** del launcher installato. Se una verifica fallisce, non avvia l'installer. L'installazione è gestita da Inno Setup, senza scrittura diretta da PowerShell nelle directory protette.
8. **ADB**: il messaggio `daemon not running; starting now at tcp:5037` è un evento informativo, non un errore; l'esito effettivo viene ricavato dall'exit code del processo. Test Windows PowerShell 5.1 obbligatorio.

## Sicurezza: firma di Windows indispensabile

La build di test CI è volutamente **NON FIRMATA, NON DISTRIBUIBILE**. Inno Setup da solo NON risolve Smart App Control.

La release ufficiale richiede un certificato **Code Signing / Authenticode emesso da un'autorità attendibile per Windows**, con relativa chiave privata conservata in GitHub Actions **Secrets**. Senza tale credenziale, il workflow ufficiale blocca la pubblicazione. Certificati self-signed creati per prova non rendono un installer riconosciuto da Windows.

Segreti previsti:
- `WEMULDROID_PFX_BASE64` — archivio PFX privato codificato base64 (mai in Git)
- `WEMULDROID_PFX_PASSWORD` — password del PFX (mai in Git)

La pipeline di firma:
- Firma **tutti** gli script PowerShell installati con Authenticode e timestamp.
- Firma `WEmulDroid.exe` con Microsoft SignTool.
- Usa il `SignTool` di Inno Setup per firmare **setup, uninstaller e copie temporanee**.
- Verifica `Get-AuthenticodeSignature.Status=Valid`, la catena del certificato e `signtool verify /pa` in CI.
- Rifiuta di pubblicare anche in caso di una sola firma mancante.

**Nota:** per il livello di protezione Smart App Control / SmartScreen è necessaria una verifica effettiva su un PC con queste protezioni attive. Anche una firma riconosciuta non garantisce immediatamente reputazione SmartScreen universale.

La chiave di firma NON va inviata per chat, issue, allegati o repository. Va conservata con accessi minimi e un backup sicuro. Se il fornitore usa chiavi non esportabili/HSM, il workflow va adattato a quel servizio invece di creare un certificato falso.

## Verifiche tecniche previste

- [x] Compilazione di un .exe Windows con Inno Setup in Windows GitHub Actions.
- [x] Installazione automatizzata e seconda installazione sulla stessa cartella.
- [x] Creazione collegamento Desktop e controllo del percorso di destinazione.
- [x] Disinstallazione con conservazione di dati SDK e report.
- [x] Selezione beta/stabile e rifiuto delle vecchie release ZIP testata su Windows PowerShell 5.1.
- [x] Regressione ADB daemon 5037 simulata e verificata su Windows PowerShell 5.1.
- [ ] Verifica reale **upgrade fra due installer con versioni differenti** (CI dedicata).
- [ ] Firma CA attendibile configurata nei segreti GitHub; pacchetto, launcher, scripts e uninstaller firmati.
- [ ] Prova Smart App Control / SmartScreen su ASUS dell'utente con firma reale.
- [ ] Primo avvio completo del sistema Android emulato dopo la correzione ADB e conferma dei dati preservati.
- [ ] Pubblicazione come **release ufficiale firmata** e secondo test beta → beta/stabile da menu.

## Policy di rilascio

**Non presentare l'artefatto unsigned dei test come installer ufficiale per l'utente.** Pubblicare il vero .exe soltanto quando il workflow firmato e i controlli reali saranno superati.

Microsoft Smart App Control: https://support.microsoft.com/en-us/windows/security/threat-malware-protection/smart-app-control-frequently-asked-questions

Inno Setup: https://jrsoftware.org/isinfo.php
