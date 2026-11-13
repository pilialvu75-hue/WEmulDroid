# WEmulDroid — guida primo tester Windows 11

**Prova privata supervisionata, beta sperimentale `v0.9.0-beta.11`.**
Questo documento **non è un'autorizzazione a installare**: ricevi prima conferma dall'organizzatore e un codice invito personale.

## Prima della prova

- Utilizza un tuo PC Windows 11, con connessione Internet e spazio libero sufficiente per i componenti Android.
- Non c'è alcun costo richiesto per il test.
- L'installer di sviluppo è **privo di firma digitale**. Se Windows Smart App Control, Defender o un antivirus lo blocca, **fermati** e comunica il messaggio all'organizzatore. Non disattivare protezioni, firewall, controlli UAC né antivirus.
- Non installare la precedente `v0.9.0-beta.10` per provare Beta Access: non dispone del nuovo gate.
- Non è necessario condividere password, PIN, email di accesso Windows, contenuti personali o log completi.

## Verifica del materiale, quando autorizzato

1. Recupera esclusivamente il file fornito o indicato dall'organizzatore. La versione prevista è **`WEmulDroid-Setup-v0.9.0-beta.11.exe`**.
2. Verifica l'hash SHA-256 confrontandolo con il file `.exe.sha256` incluso nello stesso archivio. Su Windows puoi usare **Proprietà**, o PowerShell con `Get-FileHash` indicando il percorso del file, senza eseguire l'installer.
3. Se Windows consente spontaneamente l'avvio senza richiedere di ridurre le protezioni, installa per il tuo utente con il normale assistente; se un controllo lo blocca, interrompi la prova.
4. Apri WEmulDroid. Nella finestra **Beta Access** inserisci il tuo nome e il **codice personale di 43 caratteri** contenuto nell'invito ricevuto.
5. Scegli liberamente se autorizzare la diagnostica tecnica minimizzata (CPU, RAM, tempi, codici d'errore). Puoi rifiutare; il test di attivazione rimane possibile.
6. Premi **Richiedi autorizzazione**. WEmulDroid deve rimanere bloccato finché l'organizzatore non approva sul proprio telefono. Non è necessario premere un pulsante per controllare lo stato.
7. Quando l'organizzatore approva, la finestra dovrebbe chiudersi automaticamente e può suonare un breve avviso, secondo la tua preferenza.
8. Prova l'avvio di Android, la rotazione e l'apertura di Google Play (se disponibile). Le prestazioni dipendono dall'hardware e dalle impostazioni del PC.

## Cosa comunicarci

- Windows 11 confermato? RAM del PC (facoltativa).
- Installer scaricato e SHA-256 corrispondente?
- Windows permette l'installazione senza modificare le protezioni? Se no, riportaci **solo il testo del messaggio di blocco**.
- Compare la finestra con il codice invito?
- La richiesta risulta in attesa fino all'approvazione?
- Dopo l'approvazione si sblocca da sola? Il suono funziona?
- Android riesce ad avviarsi? Quali funzioni funzionano o presentano problemi?

Non inoltrare l'invito personale ad altri. Non pubblicare screenshot contenenti il codice di invito.

## Fine test

L'organizzatore revocherà l'invito e la sessione beta. Non disinstallare componenti o alterare le impostazioni di sicurezza se non richiesto espressamente per una procedura sicura.
