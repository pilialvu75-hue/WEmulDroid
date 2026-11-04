# WEmulDroid GUI localization, offline and dependency-free.
# Only the selected language code is saved locally. No credentials/diagnostics.
$script:UiLanguages = @('en', 'it', 'fr')
$script:UiLanguageNames = @('English', 'Italiano', 'Français')
$script:UiWords = @{
  en = @{
    title='WEmulDroid | Android on Windows';language='Language';device='Device:';notStarted='not started';
    setup='1. Install tools';start='2. Start Android';refresh='3. Refresh apps';stop='Stop Android';
    install='Install APK';measure='Measure resources';reports='Open reports';play='Open Play Store';
    package='Installed app to inspect:';screen='Android display:';screenApply='Apply display';screenReset='Reset display';
    screenshot='Screenshot';touchHelp='Touch / Audio';fullscreen='Fullscreen';exitFullscreen='Exit fullscreen';
    folder='APK from folder';link='APK from HTTPS link';splitTouch='Touchpad + mouse (future)';
    snapshotSave='Save snapshot';snapshotLoad='Restore snapshot';snapshotList='List snapshots';
    diagnostics='Full diagnostics';log='Activity and diagnostics:';
    touchHelpTitle='WEmulDroid - Touch / Audio'; touchHelpText="TOUCH: left click = one tap; double-click = double tap.\nHold left button and drag for swipe.\nCtrl + mouse simulates mirrored multi-touch pinch.\nIndependent touchpad + mouse fingers: NOT IMPLEMENTED.\nType with the PC keyboard.\n\nAUDIO: output goes to PC speakers or headphones.\nVolume: emulator's side buttons.\nMicrophone: emulator Extended controls > Microphone; enable only when needed.\n\nRemote access is not automatically enabled. Diagnostics remain on your PC.";
    ready='Ready. For first use, select Install tools.';profile='Selected profile:';
    snapshotListTitle="Saved Android snapshots";
    snapshotSaveTitle="Confirm snapshot save";
    snapshotSavePrompt="Save the current state of the selected Android device?";
    snapshotOverwriteWarning="An existing baseline with this name may be overwritten. Snapshots can contain personal data and Play Store sessions.";
    snapshotRestoreTitle="Confirm Android data restore";
    snapshotRestorePrompt="Restore the selected device to the saved baseline?";
    snapshotRestoreWarning="Changes to apps, data and sessions since the snapshot may be lost. Restore cannot be undone without another snapshot.";
    diagnosticTitle="Confirm local diagnostics";
    diagnosticPrompt="Collect a screenshot, the last 120 logcat lines and device CPU/RAM/graphics data for the selected emulator?";
    diagnosticWarning="Screenshots and logs may contain personal information. Nothing is uploaded automatically.";
    folderTitle="Select a folder containing independent APK files (top level only).";
    folderEmpty="This folder contains no APK files.";
    folderTooMany="This folder contains more than 30 APKs. Choose a smaller folder.";
    folderConfirmTitle="Confirm APK installation";
    folderConfirmPrompt="Install these APK files in ONLY the selected emulator? Do not select split-APK collections.";
    urlDialogTitle="WEmulDroid - Install APK from link";
    urlDialogPrompt="Paste a direct HTTPS APK URL or GitHub releases/latest or releases/tag/... page:";
    urlConfirmTitle="Confirm APK download and install";
    urlConfirmPrompt="Download and install this APK into the selected emulator?";
    urlWarning="Use only trusted sources. APK validity checks do not prove software safety.";
    chooseApkTitle="Select an APK to install";
    chooseAppFirst="Select an app from the list first (Refresh apps).";
    chooseScreenFirst="Select a display profile first.";
    playNotAvailable="This Android profile does not include Play Store. Start the Google Play profile.";
    playNotFound="Play Store not found in this profile. Check the official Google Play AVD.";
    playOpenFailed="Could not open Play Store:";
    screenshotSaved="Screenshot saved:";
    reportSaved="Report saved:";
    finishedFolder="Folder completed: installed";
    finishedFolderFailures="failed";
    afterRestore="Wait for Android to finish starting, then select Refresh apps.";
    licenseReminder="Respect licenses when using third-party APK files."
  }
  it = @{
    title='WEmulDroid | Android su Windows';language='Lingua';device='Dispositivo:';notStarted='da avviare';
    setup='1. Installa strumenti';start='2. Avvia Android';refresh='3. Aggiorna elenco';stop='Arresta Android';
    install='Installa APK';measure='Misura risorse';reports='Apri report';play='Apri Play Store';
    package='App installata da analizzare:';screen='Schermo Android:';screenApply='Applica schermo';screenReset='Ripristina';
    screenshot='Screenshot';touchHelp='Touch / Audio';fullscreen='Fullscreen';exitFullscreen='Esci fullscreen';
    folder='APK da cartella';link='APK da link HTTPS';splitTouch='Touchpad + mouse (futuro)';
    snapshotSave='Salva snapshot';snapshotLoad='Ripristina snapshot';snapshotList='Elenco snapshot';
    diagnostics='Diagnostica completa';log='Attivita e diagnostica:';
    touchHelpTitle='WEmulDroid - Touch / Audio'; touchHelpText="TOUCH: clic sinistro = tocco; doppio clic = doppio tocco.\nTieni premuto e trascina per lo swipe.\nCtrl + mouse simula il pinch multitouch speculare.\nDue dita indipendenti touchpad + mouse: NON IMPLEMENTATO.\nScrivi con la tastiera del PC.\n\nAUDIO: uscita su casse o cuffie del PC.\nVolume: pulsanti laterali dell'emulatore.\nMicrofono: Extended controls > Microphone; attivalo solo quando serve.\n\nL'accesso remoto non viene attivato automaticamente. I report rimangono sul PC.";
    ready='Pronto. Prima installazione: clicca Installa strumenti.';profile='Profilo selezionato:';
    snapshotListTitle="Snapshot Android salvati";
    snapshotSaveTitle="Conferma salvataggio snapshot";
    snapshotSavePrompt="Salvare lo stato attuale del dispositivo Android selezionato?";
    snapshotOverwriteWarning="Una baseline esistente con lo stesso nome potrebbe essere sovrascritta. Gli snapshot possono contenere dati personali e sessioni Play Store.";
    snapshotRestoreTitle="Conferma ripristino dati Android";
    snapshotRestorePrompt="Ripristinare il dispositivo selezionato alla baseline salvata?";
    snapshotRestoreWarning="Modifiche ad app, dati e sessioni successive allo snapshot possono andare perse. Non è possibile annullare il ripristino senza un altro snapshot.";
    diagnosticTitle="Conferma diagnostica locale";
    diagnosticPrompt="Raccogliere screenshot, ultime 120 righe logcat e dati CPU/RAM/grafica dal solo emulatore selezionato?";
    diagnosticWarning="Screenshot e log possono contenere informazioni personali. Nessun invio automatico.";
    folderTitle="Seleziona una cartella con file APK indipendenti (solo il livello principale).";
    folderEmpty="La cartella non contiene file APK.";
    folderTooMany="La cartella contiene più di 30 APK. Seleziona una cartella più piccola.";
    folderConfirmTitle="Conferma installazione APK";
    folderConfirmPrompt="Installare questi APK soltanto nell'emulatore selezionato? Non usare raccolte di split APK.";
    urlDialogTitle="WEmulDroid - Installa APK da link";
    urlDialogPrompt="Incolla un indirizzo HTTPS diretto a un APK oppure una pagina GitHub releases/latest o releases/tag/...";
    urlConfirmTitle="Conferma download e installazione";
    urlConfirmPrompt="Scaricare e installare questo APK nell'emulatore selezionato?";
    urlWarning="Usa soltanto sorgenti affidabili. La validità del file APK non garantisce la sicurezza del software.";
    chooseApkTitle="Seleziona APK da installare";
    chooseAppFirst="Seleziona un'app dall'elenco (Aggiorna elenco).";
    chooseScreenFirst="Scegli prima un profilo schermo.";
    playNotAvailable="Questo profilo Android non include Play Store. Avvia il profilo Google Play.";
    playNotFound="Play Store non trovato in questo profilo. Controlla il dispositivo virtuale Google Play ufficiale.";
    playOpenFailed="Impossibile aprire Play Store:";
    screenshotSaved="Screenshot salvato:";
    reportSaved="Report salvato:";
    finishedFolder="Cartella completata: installati";
    finishedFolderFailures="falliti";
    afterRestore="Attendi che Android sia pronto, poi scegli Aggiorna elenco.";
    licenseReminder="Per gli APK di terze parti rispetta le relative licenze."
  }
  fr = @{
    title='WEmulDroid | Android sur Windows';language='Langue';device='Appareil :';notStarted='a demarrer';
    setup='1. Installer les outils';start='2. Demarrer Android';refresh='3. Actualiser les applis';stop='Arreter Android';
    install='Installer APK';measure='Mesurer ressources';reports='Ouvrir rapports';play='Ouvrir Play Store';
    package='Application a analyser :';screen='Ecran Android :';screenApply='Appliquer ecran';screenReset='Reinitialiser';
    screenshot='Capture ecran';touchHelp='Tactile / Audio';fullscreen='Plein ecran';exitFullscreen='Quitter plein ecran';
    folder='APK du dossier';link='APK via lien HTTPS';splitTouch='Pave tactile + souris (futur)';
    snapshotSave='Sauver snapshot';snapshotLoad='Restaurer snapshot';snapshotList='Liste snapshots';
    diagnostics='Diagnostic complet';log='Activite et diagnostic :';
    touchHelpTitle='WEmulDroid - Tactile / Audio'; touchHelpText="TACTILE : clic gauche = toucher ; double-clic = double toucher.\nMaintenez et faites glisser pour balayer.\nCtrl + souris simule un pincement multi-tactile symetrique.\nDeux doigts independants pave tactile + souris : NON DISPONIBLE.\nSaisissez du texte avec le clavier du PC.\n\nAUDIO : haut-parleurs ou casque du PC.\nVolume : boutons lateraux de l'emulateur.\nMicro : Extended controls > Microphone, a activer uniquement si besoin.\n\nL'acces a distance n'est pas active automatiquement. Les rapports restent sur le PC.";
    ready='Pret. Pour commencer, installez les outils.';profile='Profil selectionne :';
    snapshotListTitle="Instantanés Android enregistrés";
    snapshotSaveTitle="Confirmer la sauvegarde de l'instantané";
    snapshotSavePrompt="Enregistrer l'état actuel de l'appareil Android sélectionné ?";
    snapshotOverwriteWarning="Une sauvegarde de référence existante peut être remplacée. Les instantanés peuvent contenir des données personnelles et des sessions Play Store.";
    snapshotRestoreTitle="Confirmer la restauration Android";
    snapshotRestorePrompt="Restaurer l'appareil sélectionné à l'instantané de référence ?";
    snapshotRestoreWarning="Les modifications des applis, données et sessions depuis l'instantané peuvent être perdues. Impossible d'annuler sans autre instantané.";
    diagnosticTitle="Confirmer le diagnostic local";
    diagnosticPrompt="Collecter une capture d'écran, les 120 dernières lignes logcat et les données CPU/RAM/graphisme de l'émulateur sélectionné ?";
    diagnosticWarning="Les captures et journaux peuvent contenir des données personnelles. Aucun envoi automatique.";
    folderTitle="Choisissez un dossier contenant des fichiers APK indépendants (niveau supérieur uniquement).";
    folderEmpty="Ce dossier ne contient aucun APK.";
    folderTooMany="Ce dossier contient plus de 30 APK. Choisissez un dossier plus petit.";
    folderConfirmTitle="Confirmer l'installation APK";
    folderConfirmPrompt="Installer ces APK UNIQUEMENT dans l'émulateur sélectionné ? N'utilisez pas de collections split APK.";
    urlDialogTitle="WEmulDroid - Installer APK depuis un lien";
    urlDialogPrompt="Collez une URL HTTPS directe vers un APK ou une page GitHub releases/latest ou releases/tag/...";
    urlConfirmTitle="Confirmer le téléchargement et l'installation";
    urlConfirmPrompt="Télécharger et installer cet APK dans l'émulateur sélectionné ?";
    urlWarning="Utilisez uniquement des sources fiables. La validation d'un APK ne garantit pas la sécurité du logiciel.";
    chooseApkTitle="Choisissez un APK à installer";
    chooseAppFirst="Sélectionnez d'abord une application (Actualiser les applis).";
    chooseScreenFirst="Choisissez d'abord un profil d'écran.";
    playNotAvailable="Ce profil Android n'inclut pas Play Store. Démarrez le profil Google Play.";
    playNotFound="Play Store introuvable dans ce profil. Vérifiez l'appareil virtuel Google Play officiel.";
    playOpenFailed="Impossible d'ouvrir Play Store :";
    screenshotSaved="Capture enregistrée :";
    reportSaved="Rapport enregistré :";
    finishedFolder="Dossier terminé : installés";
    finishedFolderFailures="échecs";
    afterRestore="Attendez qu'Android soit prêt, puis cliquez sur Actualiser les applis.";
    licenseReminder="Respectez les licences des APK tiers."
  }
}
$script:UiLanguage = 'it'
$script:SettingsBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [IO.Path]::GetTempPath() }
$script:LanguageSettingsPath = Join-Path $script:SettingsBase 'WEmulDroid\Settings\language.txt'

function Set-WEmulDroidLanguage([string]$lang, [bool]$persist = $true) {
    if ($script:UiLanguages -cnotcontains $lang) { throw 'Unsupported language code.' }
    $script:UiLanguage = $lang
    if ($persist) {
        $dir = Split-Path -Parent $script:LanguageSettingsPath
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [IO.File]::WriteAllText($script:LanguageSettingsPath, $lang, [Text.UTF8Encoding]::new($false))
    }
}
function Load-WEmulDroidLanguage() {
    if (Test-Path -LiteralPath $script:LanguageSettingsPath -PathType Leaf) {
        try {
            $lang = ([IO.File]::ReadAllText($script:LanguageSettingsPath)).Trim()
            if ($script:UiLanguages -ccontains $lang) {
                Set-WEmulDroidLanguage $lang $false
            }
        } catch {
            $script:UiLanguage = 'it'
        }
    }
    return $script:UiLanguage
}
function T([string]$key) {
    if (-not $script:UiWords[$script:UiLanguage].ContainsKey($key)) {
        throw "Localization key not found: $key"
    }
    # Decode explicit newlines for long help content.
    return $script:UiWords[$script:UiLanguage][$key].Replace('\n', [Environment]::NewLine)
}
function Assert-WEmulDroidTranslations() {
    $reference = @($script:UiWords['it'].Keys | Sort-Object)
    foreach ($lang in $script:UiLanguages) {
        $keys = @($script:UiWords[$lang].Keys | Sort-Object)
        if (($reference -join ',') -cne ($keys -join ',')) {
            throw "Language $lang has missing or additional translation keys."
        }
        foreach ($key in $reference) {
            if ([string]::IsNullOrWhiteSpace($script:UiWords[$lang][$key])) {
                throw "Empty localized string $lang/$key"
            }
        }
    }
    return $true
}
