# WEmulDroid — Aggiornamenti da Impostazioni

## Primo utilizzo
La prima distribuzione ufficiale con menu aggiornamenti è [WEmulDroid v0.8.0-beta.1](https://github.com/pilialvu75-hue/WEmulDroid/releases/tag/v0.8.0-beta.1).

Il file ZIP va **scaricato ed estratto una sola volta** nella cartella scelta sul PC. Questo è il bootstrap iniziale; WEmulDroid non è un APK e non utilizza il PackageInstaller Android.

Link diretto:
https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.1/WEmulDroid-v0.8.0-beta.1.zip

## Da questo momento: Impostazioni → Aggiornamenti

1. Avvia **Avvia-Android.cmd** o **Avvia-PlayStore.cmd**.
2. Premi **Impostazioni** e apri **Aggiornamenti**.
3. Scegli il canale: **Stabile** (predefinito) oppure abilita le **Beta**.
4. Premi **Controlla aggiornamenti**. Solo a questo punto avviene la chiamata GitHub.
5. Quando trovi una versione più recente, premi **Scarica aggiornamento** e conferma.
6. WEmulDroid verifica l'hash SHA-256 del pacchetto ufficiale.
7. Premi **Installa aggiornamento** e conferma: la GUI si chiude, un processo separato ne attende l'uscita, salva copie dei file precedenti, installa la nuova versione e prova a riavviare l'app.
8. In caso di errore viene tentato il ripristino dei file precedenti. Consultare il log locale.

Il download riguarda soltanto i file di **WEmulDroid**, non Android SDK, immagini di sistema o app installate nell'emulatore. I profili Android, le impostazioni di lingua, i rapporti e i dispositivi virtuali sono salvati fuori dal repository e **non vengono cancellati**.

## Indirizzi di controllo

- Repository consentito: **pilialvu75-hue/WEmulDroid**.
- Le release devono contenere due asset coerenti: `WEmulDroid-vX.Y.Z[-beta.N].zip` e il relativo `.sha256`.
- Il programma rifiuta versioni inferiori e URL che non appartengono al percorso release del repository.
- I pacchetti sono sorgenti PowerShell/Windows e non eseguibili firmati digitalmente: SHA-256 dimostra che i byte scaricati corrispondono alla release GitHub, **non** che Microsoft abbia firmato il codice.
- La distribuzione GitHub è creata da un workflow dopo test PowerShell leggeri; non comprende componenti Google né APK esterni.

## Collaudo da eseguire sull'ASUS

- [x] Release ufficiale v0.8.0-beta.1, ZIP e checksum pubblicati.
- [x] Test di parsing PowerShell e confronti versioni stabile/beta superati in CI.
- [ ] Avvio reale dell'interfaccia su Windows 11 e apertura del sottomenu.
- [ ] Prova versione più recente (beta o stabile), download, verifica e installazione.
- [ ] Conferma del riavvio dell'app e della conservazione di SDK, AVD, report e impostazioni.
- [ ] Simulazione interruzione download e rollback da copia di backup.
- [ ] Test con directory contenenti spazi, antivirus e account standard Windows.

**Stato attuale:** implementato e verificato staticamente, NON ancora collaudato end-to-end su un PC reale.
