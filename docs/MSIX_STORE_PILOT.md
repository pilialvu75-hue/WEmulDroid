# WEmulDroid — Microsoft Store MSIX pilot (6 novembre 2026)

## Risultato del laboratorio

Un percorso indipendente `msix/Build-MSIX.ps1` crea con Windows SDK MakeAppx un pacchetto x64 **non firmato** per il controllo CI. Il manifest dichiara un'app Win32 full-trust e il launcher esistente; non sono inclusi Android SDK, immagini, AVD, login Google, giochi o report dell'utente. L'installer Inno Setup e l'updater GitHub precedenti rimangono separati.

Workflow: `.github/workflows/msix-preview-ci.yml`. L'artefatto ha nome esplicito `UNSIGNED-NOT-INSTALLABLE` ed e destinato solo alla verifica strutturale: **non va installato sull'ASUS con Smart App Control**.

## Passaggi necessari prima di una release installabile

1. Il proprietario apre un account Microsoft Partner Center, verifica condizioni e idoneita, e riserva il nome dell'app WEmulDroid. La disponibilita del nome non e verificata. Non acquistare servizi o accettare contratti per conto dell'utente.
2. Recuperare dal Partner Center la vera **Package Identity Name** e il **Publisher**. Nel manifest CI attuale sono soltanto valori di prova `WEmulDroid.DesktopPreview` / `CN=WEmulDroidPreview`; non usare per una submission finale.
3. Integrare l'identita assegnata da Microsoft nella build Store e verificare su un Windows di prova, in modalita ufficialmente autorizzata, la GUI WinForms, l'avvio del processo PowerShell 5.1 figlio e l'accesso a SDK/AVD esterni. **La compilazione del MSIX non prova che il launcher funzioni con le policy del dispositivo.**
4. Verificare le limitazioni di packaging per gli eseguibili esterni `adb.exe` e `emulator.exe`, il download SDK tramite setup, il lancio di processi figli e le funzionalita consentite dal Microsoft Store. Non presupporre l'accettazione in certificazione.
5. Completare materiali Store, privacy policy, descrizione delle dipendenze Android Google e consensi. Prima della pubblicazione, usare il percorso di test ufficiale e verificare la certificazione.
6. **Soltanto dopo la certificazione**, Microsoft potra firmare il MSIX per la distribuzione Store. Non serve acquistare un certificato CA per questa via. Le nuove versioni MSIX andranno aggiornate tramite Store; nel pacchetto pilota il controllo aggiornamenti Inno e esplicitamente disabilitato.
7. Collaudo ASUS con Smart App Control attivo: apertura, Android standard/Google Play, continuita di account, app e report. Non cancellare l'installazione Inno, il contenuto di `%LOCALAPPDATA%\WEmulDroid` o `%USERPROFILE%\.android\avd` durante la migrazione.

## Fonti ufficiali

- https://learn.microsoft.com/en-us/windows/apps/publish/get-started
- https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options
- https://learn.microsoft.com/en-us/windows/msix/package/create-app-package-with-makeappx-tool
- https://learn.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-application

**Non e ancora una release pubblicabile o eseguibile su ASUS.** Un successo CI conferma solo formato, contenuto e costruzione del pacchetto di prova.

## Verifica blocchi di sicurezza del 6 novembre

Sull'ASUS un evento Windows CodeIntegrity 3077 blocca la beta 10, per politica di firma. McAfee ha inoltre messo in quarantena `AI-Orchestrator-Runtime.exe` il 20 ottobre, episodio distinto: il rilevamento McAfee non dimostra che McAfee abbia bloccato anche WEmulDroid. Non disabilitare antivirus, Smart App Control, controlli enterprise o ripristinare file sospetti per collaudare.

## Due rischi tecnici da certificare, non solo da compilare

- Il launcher MSIX e una app desktop full-trust Win32 che avvia Windows PowerShell 5.1 e processi Android da percorso esterno al package. Anche se `runFullTrust` consente app desktop, verificare che la certificazione Store accetti questo flusso e che Windows avvii realmente il processo figlio.
- I pacchetti MSIX hanno isolamento e virtualizzazione di alcune cartelle (AppData). Sulla macchina di prova verificare che `%LOCALAPPDATA%\WEmulDroid\Sdk` e `%USERPROFILE%\.android\avd` continuino a puntare ai dati preesistenti. Non eseguire migrazioni, reset, copia distruttiva, uninstall o modifica account automaticamente.

Riferimenti Microsoft:
- https://learn.microsoft.com/en-us/windows/apps/distribute-through-store/how-to-distribute-your-win32-app-through-microsoft-store
- https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-behind-the-scenes
- https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/app-capability-declarations

Criterio di completamento: certificazione Store piu prova reale su ASUS con protezioni attive; CI di struttura non e sufficiente.

## Gate automatico aggiunto: launcher e continuita dati (6 novembre)

Nel workflow MSIX e stato aggiunto uno smoke test Windows reale sul **launcher estratto nella staging directory**: verifica che l'EXE avvii il processo PowerShell/WinForms e che file sentinella nei percorsi SDK, AVD e Reports rimangano invariati. In GitHub Actions, questi test hanno esito PASS nel run https://github.com/pilialvu75-hue/WEmulDroid/actions/runs/42167907352 . Non equivale a lanciare un MSIX installato, che richiede identita publisher corretta, firma e policy del dispositivo. Il test non modifica account, app o SDK sull'ASUS.

La documentazione MSIX ufficiale indica che alcuni file AppData nuovi possono essere virtualizzati nel contenitore per applicazione. Il recupero del medesimo SDK/AVD preesistente sotto Store **rimane da provare**, non si presume dal test dei file sentinella. Riferimento: https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-behind-the-scenes
