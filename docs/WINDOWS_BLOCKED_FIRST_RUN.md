# Windows 11 blocca WEmulDroid — primo avvio da ZIP

## Messaggio riconoscibile
> Controllo intelligente delle app ha bloccato un file che potrebbe non essere sicuro. Il file è stato bloccato perché i file di questo tipo da Internet possono essere pericolosi.

Il blocco può verificarsi **prima** che un comando `.cmd` o uno script `.ps1` venga eseguito. **Non prova che il codice WEmulDroid sia stato avviato o che Android SDK abbia un problema.**

### Il primo dettaglio da controllare
Se in Esplora file vedi colonne come **Dimensione compressa** o **Protetto da password**, potresti essere **ancora dentro la visualizzazione dello ZIP**. Non avviare `.cmd` direttamente da quella finestra; il progetto deve essere estratto in una cartella normale.

## Prima prova, senza modificare le impostazioni di sicurezza generali

1. Premi **OK** sul blocco Windows e torna nella cartella che contiene il file ZIP originale `WEmulDroid-v0.8.0-beta.1.zip`.
2. Verifica che provenga dalla **release ufficiale**: https://github.com/pilialvu75-hue/WEmulDroid/releases/tag/v0.8.0-beta.1
3. Esegui una scansione con Microsoft Defender sullo ZIP. Per una verifica riproducibile puoi confrontare lo SHA-256 dello ZIP con `WEmulDroid-v0.8.0-beta.1.zip.sha256` pubblicato nella stessa release.
4. Dopo la verifica, fai clic destro sullo ZIP → **Proprietà** → **Generale**. Se appare **Sblocca**, selezionalo → **Applica** → **OK**.
5. Ora fai clic destro sullo ZIP → **Estrai tutto** e scegli una cartella normale, ad esempio `Documenti\WEmulDroid`.
6. **Apri la cartella estratta**, non lo ZIP. Da lì avvia **Verifica-PC.cmd** per il primo controllo di sola lettura.

Se lo ZIP era **già stato estratto prima di essere sbloccato**, ripeti l'estrazione dopo lo sblocco in una cartella nuova. Windows può aver propagato il contrassegno «scaricato da Internet» ai file estratti.

**Non disattivare Smart App Control, SmartScreen, Microsoft Defender o la protezione antivirus del PC.** «Sblocca» agisce sul singolo file scelto: fallo solo se ne hai verificato provenienza e contenuto.

## Se il blocco compare anche dopo l'estrazione

- Verifica di non aver aperto accidentalmente la **cartella compressa**.
- Controlla nelle **Proprietà del singolo file `.cmd`** se compare il contrassegno di Internet. Se la fonte è stata verificata, può essere sbloccato individualmente. Questo **non garantisce** che Smart App Control lo autorizzi.
- Controlla **Sicurezza di Windows → Controllo delle app e del browser → Controllo intelligente delle app** per capire quale protezione è attiva; **non modificarla**.
- Riporta la foto del messaggio e il nome esatto del file bloccato. Se Smart App Control rifiuta il progetto perché è uno script non firmato, bisogna rendere la distribuzione affidabile attraverso una firma valida / un pacchetto firmato, non chiedere di spegnere la sicurezza globale.

## Perché serve una soluzione definitiva
WEmulDroid v0.8.0-beta.1 è un **prototipo PowerShell + WinForms**, distribuito come ZIP di script `.cmd`/`.ps1`. **Non è un'app Windows firmata**; il checksum SHA-256 pubblicato per la release **non equivale a una firma digitale dell'editore** e non conferisce fiducia a Windows Smart App Control. I test CI sul codice controllano sintassi e struttura, non attestano reputazione o firma.

La roadmap prevede packaging più semplice, un avvio Windows verificato e, quando necessario, una firma riconosciuta prima di dichiarare risolto definitivamente il blocco.

## Fonti Microsoft
- Attachment Manager e sblocco dei file scaricati: https://support.microsoft.com/en-us/windows/security/information-about-the-attachment-manager-in-microsoft-windows
- Smart App Control e codice firmato: https://learn.microsoft.com/windows/apps/develop/smart-app-control/overview
- Sicurezza Windows e Smart App Control: https://support.microsoft.com/en-us/windows/security/windows-security/app-browser-control-in-the-windows-security-app
