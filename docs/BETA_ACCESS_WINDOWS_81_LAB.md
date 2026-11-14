# Laboratorio Windows 8.1 — alternativa di test per Beta Access

**Stato: solo valutazione tecnica, NON Windows 8.1 supportato per WEmulDroid.** Nessun installer o tester Windows 8.1 è stato eseguito sul PC reale.

## Confini e compatibilità

- WEmulDroid distribuito come EXE Inno richiede attualmente Windows 10 build 19041 o successiva e x64. **Non abbassare** `MinVersion` nella build principale per avviare il pilota.
- Android Emulator ufficiale moderno raccomanda Windows 10 x64 o più recente e 16 GB di RAM. Le vecchie configurazioni AEHD <= 1.7 su Windows 8.1 non sono supportate da Google e non sono una scorciatoia per il collaudo Android 15.
- Beta Access usa Windows PowerShell/WinForms, DPAPI e TLS 1.2. Windows 8.1 nasce con PowerShell 4.0, ma WMF 5.1 è disponibile storicamente; non installarlo automaticamente.
- Windows 8.1 non riceve aggiornamenti di sicurezza Microsoft dal 10 gennaio 2023. Non inserire credenziali tester vere o inviti reali, non disabilitare protezioni e non usare il sistema come punto di distribuzione affidabile.

## Fase A — verifica locale non invasiva (primo passo)

File: [scripts/Check-BetaAccessWin81.ps1](../scripts/Check-BetaAccessWin81.ps1).

Il file verifica **soltanto in lettura** la versione di Windows, l'architettura, la versione PowerShell, il livello .NET v4, la presenza di TLS 1.2, un test DPAPI in memoria e la RAM approssimativa. Non scrive files, non esegue download, non tocca registro/impostazioni, non usa account o token, non accende VM e non contatta Internet.

Per eseguirlo in modo controllato, quando il proprietario è davanti al PC Windows 8.1:

1. Aprire la pagina GitHub del file, selezionare il testo e copiarlo (senza scaricare un EXE o ZIP).
2. Aprire **Windows PowerShell** dal menu Start, senza 'Esegui come amministratore'.
3. Incollare il testo e premere Invio se richiesto. Se Windows blocca l'operazione per una policy, **non** disabilitarla.
4. Condividere soltanto le sette righe tecniche finali. Non servono screenshot, identificativi, seriali o nomi utente.

**Nota:** la CI esegue questo stesso script su un runner Windows recente, non su Windows 8.1. Un PASS CI non dimostra la compatibilità del sistema legacy.

## Fase B — test offline solo se il preflight è compatibile

- Preparare in un ramo distinto un adapter portatile che testi WinForms/DPAPI e i passaggi pending/approved/revoked contro risposte HTTPS simulate, senza installare WEmulDroid o Android.
- Non toccare l'installazione preesistente di AIVEXUS né i dati utente, driver di virtualizzazione, Hyper-V o BIOS.
- Se manca PowerShell 5.1, registrare l'incompatibilità; valutare l'eventuale upgrade soltanto dopo consenso esplicito e valutazione dei rischi.

## Fase C — confronto con Windows 11

Solo successivamente, e solo se utile, valutare una prova con rete reale sotto consenso, sapendo che Windows 8.1 è fuori supporto. Questa strada non sostituisce il test Windows 11 con Smart App Control attivo. Il collaudo finale WEmulDroid Android/Play Store deve avvenire su sistema ufficialmente compatibile.

Riferimenti: [Google Emulator](https://developer.android.com/studio/run/emulator), [Google AEHD legacy](https://developer.android.com/studio/run/emulator-acceleration), [Microsoft WMF 5.1](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/setup/install-configure), [fine supporto Windows 8.1](https://support.microsoft.com/en-us/windows/experience/windows-8-1-support-ended-on-january-10-2023).
