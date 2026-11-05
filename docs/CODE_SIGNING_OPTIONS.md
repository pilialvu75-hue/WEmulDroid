# WEmulDroid — firma Windows: opzioni e requisiti (6 novembre 2026)

## Problema reale da risolvere

Sul VivoBook ASUS, Windows CodeIntegrity (eventi 3077 e 3033, 5 novembre 2026 ore 23:11:34) ha bloccato `WEmulDroid-Setup-v0.9.0-beta.7.exe` non firmato. Le build unsigned di GitHub Actions non sostituiscono un collaudo con Smart App Control attivo. La beta.6 resta installata: nessuna reinstallazione di Android SDK/AVD/Play Store.

Non tentare di aggirare Smart App Control, WDAC, AppLocker o le impostazioni di sicurezza del PC. Una firma valida non garantisce automaticamente l'accettazione di ogni installer.

## Opzione preferita da valutare: SignPath Foundation (gratuita per OSS idoneo)

- Sito: https://signpath.org/
- Requisiti: https://signpath.org/terms
- Modulo candidatura: https://signpath.org/ (Apply)
- Microsoft riporta SignPath Foundation tra le opzioni per progetti open source: https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options

**Stato: idoneità da valutare, candidatura NON presentata, nessun account o certificato ottenuto.**

WEmulDroid è pubblico, con licenza MIT, codice e release su GitHub, CI Windows e installer Inno Setup. Questi elementi non assicurano l'approvazione. Prima di candidarsi occorre verificare:

1. Licenze OSI di tutto il codice distribuito e assenza di componenti proprietari incorporati nel pacchetto. Android SDK/Play Store vengono scaricati direttamente dall'utente su consenso e non redistribuiti nell'installer.
2. Repository pubblico, release verificabile dalla pipeline, funzionalità e modalità di download documentate.
3. Assenza di funzioni in conflitto con le condizioni di SignPath (in particolare strumenti per aggirare controlli di sicurezza, malware/PUA). La diagnostica WEmulDroid deve restare limitata a manutenzione ordinaria e bug dell'emulatore.
4. Politica pubblica di firma, ruoli e approvatori reali, privacy policy, MFA, approvazione esplicita per ciascuna firma e provenienza riproducibile dei binari.
5. Accettazione da SignPath Foundation: discrezionale; può dipendere dalla reputazione documentata del progetto.
6. Progettazione di una pipeline SignPath dedicata con artefatti creati da GitHub Actions e chiave custodita dal servizio. Il workflow attuale PFX NON è direttamente compatibile con un certificato SignPath/HSM non esportabile.
7. Firma dell'intera catena (launcher EXE, script PowerShell, installer e disinstaller), controllo dell'identità della firma e test effettivo sull'ASUS. Valutare il corretto ordine di creazione e firma dell'uninstaller Inno.

**Nessun certificato, token, password o chiave privata deve essere inserito nel repository o trasmesso tramite issue/chat.**

## Alternativa: Microsoft Store MSIX

La documentazione Microsoft indica la firma del pacchetto MSIX come gratuita attraverso il Microsoft Store, dopo certificazione. Richiede un diverso percorso di packaging/distribuzione e verifiche di compatibilità per WEmulDroid; non è un modo per firmare automaticamente l'attuale installer Inno Setup. Riferimento: https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options

## Alternativa a pagamento

Azure Artifact Signing e certificati code signing commerciali hanno costi e requisiti geografici/di identità. Non acquistare nulla senza confronto e autorizzazione dell'utente. Le condizioni del servizio Azure per account individuali dipendono dal Paese.

## Gate prima di un nuovo collaudo ASUS

- [ ] Scegliere una filiera di firma attendibile, realmente disponibile e con requisiti soddisfatti.
- [ ] Ottenere approvazione del fornitore/identità necessaria.
- [ ] Adattare e testare la pipeline di firma senza falsificare la CA o installare radici di fiducia custom sull'ASUS.
- [ ] Produrre una release NUOVA, non sovrascrivere la beta.7 già pubblicata, e verificare firma, file hash, fonte, versione e continuità della pubblicazione.
- [ ] Installare solo previa autorizzazione dell'utente; verificare con Smart App Control attivo.
- [ ] Controllare che SDK, AVD, account Play Store, APK e report precedenti rimangano intatti.
- [ ] Solo dopo, collaudare fullscreen, rotazione, giochi, RAM/CPU/GPU.

Il workflow ufficiale attuale `.github/workflows/publish-official-installer.yml` richiede un PFX CA attendibile e la relativa password via GitHub Secrets. Non dichiararlo funzionante finché non viene eseguita una vera build firmata e verificata.
