# WEmulDroid GUI localization, offline and dependency-free.
# Only the selected language code is saved locally. No credentials/diagnostics.
$script:UiLanguages = @('en', 'it', 'fr')
$script:UiLanguageNames = @('English', 'Italiano', 'Français')
$script:UiWords = @{
  en = @{
    tabApps='Applications / APK';tabDisplay='Display / Touch';tabDiagnostics='Diagnostics / Snapshots';
    centerAndroid='Center Android';centered='Android window centered on your monitor.';centerNotFound='Android window not visible yet. Start Android first.';centerError='Unable to center Android:';
    home='Home';back='Back';keyboardPc='PC keyboard';keyboardAndroid='Android keyboard';coldBoot='Cold boot';
    setupAllTitle='Set up Android and Google Play';setupAllPrompt='Set up the standard Android and official Google Play devices now? WEmulDroid will download several GB directly from Google. This requires Internet access and review/acceptance of Google SDK licenses. Existing devices and data will be preserved. Terms: https://developer.android.com/studio/terms';setupAllDeclined='Automatic setup postponed. You can choose Install tools later.';setupAllStarted='Preparing standard Android and Google Play together. Accept the SDK licenses in the setup window.';keyboardHardwareReady='Physical PC keyboard enabled for next Android boot; Gboard remains available.';
    keyboardPcBoth='PC + Android keyboards';keyboardHideSoft='Hide Android keyboard';keyboardShowSoft='Show Android keyboard';
    keyboardBothDone='PC hardware keyboard enabled; Android on-screen keyboard remains available for sign-in.';
    keyboardHideConfirm='Hide the Android on-screen keyboard? Only choose Yes after confirming that typing on the PC works. You can restore it here.';
    keyboardSoftHidden='Android on-screen keyboard hidden by explicit request.';
    homeDone='Android Home key sent.';backDone='Android Back key sent.';
    keyboardPcDone='PC keyboard enabled; click a text field in the emulator and type on your computer.';
    keyboardAndroidDone='On-screen Android keyboard enabled again.';
    keyboardRestart='Hardware keyboard was enabled for this AVD. Close and restart Android once for the physical keyboard to take effect.';
    coldBootStopFirst='Stop Android before cold boot; current apps and data will be preserved.';
    coldBootConfirm='Start Android without loading its previous snapshot? This can recover a black/gray screen. No apps or data will be erased.';
    coldBootStarted='Cold boot started. Diagnostic log:';
    emulatorLogSaved='Android emulator diagnostics saved:';
    title='WEmulDroid | Android on Windows';language='Language';device='Device:';notStarted='not started';
    setup='1. Install tools';start='2. Start Android';refresh='3. Refresh apps';stop='Stop Android';
    install='Install APK';measure='Measure resources';reports='Open reports';play='Open Play Store';
    package='Installed app to inspect:';screen='Android display:';screenApply='Apply display';screenReset='Reset display';
    screenPhoneLite='Phone lightweight 720 x 1280 (320 dpi)';screenPhoneHigh='Phone high 1080 x 2400 (420 dpi)';screenTablet1610='Tablet landscape 1280 x 800 (200 dpi)';screenTablet169='Tablet wide 1600 x 900 (240 dpi)';screenTabletAuto='Tablet auto - fit to monitor';
    gamesMode='Game compatibility';gamesModeConfirm='Restore Android native resolution, density and automatic rotation to let games control their own orientation? Installed apps and Google Play data are preserved.';gamesModeDone='Game compatibility: restored original resolution and automatic rotation; no app data deleted.';
    screenFitWindow='Fit window to desktop';screenWindowFitted='Android window fitted to monitor without extra black areas.';screenFitUnavailable='Android window is not available for resizing yet.';screenSmartFit='Portrait or nonmatching aspect: kept desktop visible instead of black fullscreen.';
    screenProfileApplied='Android display profile applied:';screenProfileNotice='Tablet uses landscape orientation. Window follows Android device aspect ratio; fullscreen cannot add pixels to the monitor.';screenProfileRestored='Original Android resolution, density and automatic rotation restored.';
    screenshot='Screenshot';touchHelp='Touch / Audio';fullscreen='Smart fullscreen';exitFullscreen='Exit fullscreen';
    folder='APK from folder';link='APK from HTTPS link';splitTouch='Touchpad + mouse (future)';
    snapshotSave='Save snapshot';snapshotLoad='Restore snapshot';snapshotList='List snapshots';
    diagnostics='Full diagnostics';ramBefore='RAM: Before';ramAndroid='RAM: Android';ramGame='RAM: Game';log='Activity and diagnostics:';
    touchHelpTitle='WEmulDroid - Touch / Audio'; touchHelpText="TOUCH: left click = one tap; double-click = double tap.\nHold left button and drag for swipe.\nCtrl + mouse simulates mirrored multi-touch pinch.\nIndependent touchpad + mouse fingers: NOT IMPLEMENTED.\nType with the PC keyboard.\n\nAUDIO: output goes to PC speakers or headphones.\nVolume: emulator's side buttons.\nMicrophone: emulator Extended controls > Microphone; enable only when needed.\n\nRemote access is not automatically enabled. Diagnostics remain on your PC.";
    ready='Ready. For first use, select Install tools.';readyInstalled='Android SDK detected. Select Start Android to open your device.';
    settings="Settings";
    updatesTitle="WEmulDroid - Settings / Updates";
    updatesVersion="Installed version";
    updatesBeta="Include beta releases";
    updatesCheck="Check updates";
    updatesDownload="Download update";
    updatesApply="Install update";
    updatesClose="Close";
    updatesDescription="No automatic downloads. Official GitHub releases only. DEVELOPMENT builds are unsigned and Windows may block them. Never disable security protections.";
    updatesFound="New release:";
    updatesNoNew="No newer release available for this channel.";
    updatesError="Update problem:";
    updatesConfirmDownload="Download this official update and verify SHA-256?";
    updatesDownloaded="Downloaded and verified. Inno Setup will replace app files after confirmation; Android data stays untouched.";
    updatesConfirmApply="Start this update installer? Development EXEs are unsigned and may be blocked by Windows. Application files change; Android SDK, virtual devices and reports are preserved.";profile='Selected profile:';
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
    tabApps='Applicazioni / APK';tabDisplay='Schermo / Comandi';tabDiagnostics='Diagnostica / Snapshot';
    centerAndroid='Centra Android';centered='Finestra Android centrata sullo schermo.';centerNotFound='Finestra Android non ancora visibile. Avvia prima Android.';centerError='Impossibile centrare Android:';
    home='Home';back='Indietro';keyboardPc='Tastiera PC';keyboardAndroid='Tastiera Android';coldBoot='Avvio pulito';
    setupAllTitle='Prepara Android e Google Play';setupAllPrompt='Configurare ora Android standard e Google Play ufficiale? WEmulDroid scaricherà diversi GB direttamente da Google. Servono Internet e accettazione delle licenze Android SDK. I dispositivi e dati già presenti restano intatti. Termini: https://developer.android.com/studio/terms';setupAllDeclined='Configurazione automatica rinviata. Puoi scegliere Installa strumenti quando vuoi.';setupAllStarted='Preparazione unica di Android standard e Google Play. Accetta le licenze SDK nella finestra di installazione.';keyboardHardwareReady='Tastiera fisica del PC abilitata per il prossimo avvio. Gboard rimane disponibile.';
    keyboardPcBoth='Tastiera PC + Android';keyboardHideSoft='Nascondi tastiera Android';keyboardShowSoft='Mostra tastiera Android';
    keyboardBothDone='Tastiera fisica configurata e tastiera Android disponibile per autenticarsi.';
    keyboardHideConfirm='Nascondere la tastiera Android? Conferma solo dopo aver provato a scrivere con la tastiera ASUS. Potrai ripristinarla qui.';
    keyboardSoftHidden='Tastiera Android nascosta su richiesta esplicita.';
    homeDone='Comando Home inviato ad Android.';backDone='Comando Indietro inviato ad Android.';
    keyboardPcDone='Tastiera PC abilitata. Clicca un campo di testo dentro Android e scrivi con la tastiera ASUS.';
    keyboardAndroidDone='Tastiera virtuale Android riabilitata.';
    keyboardRestart='La tastiera fisica è stata abilitata per questo dispositivo. Arresta e riavvia Android una volta per applicare la configurazione.';
    coldBootStopFirst='Arresta Android prima di avviarlo senza snapshot: app e dati saranno conservati.';
    coldBootConfirm='Avviare Android senza caricare lo snapshot precedente? Può risolvere una schermata nera/grigia. App e dati non saranno cancellati.';
    coldBootStarted='Avvio pulito richiesto. Log diagnostico:';
    emulatorLogSaved='Log del motore Android salvato:';
    title='WEmulDroid | Android su Windows';language='Lingua';device='Dispositivo:';notStarted='da avviare';
    setup='1. Installa strumenti';start='2. Avvia Android';refresh='3. Aggiorna elenco';stop='Arresta Android';
    install='Installa APK';measure='Misura risorse';reports='Apri report';play='Apri Play Store';
    package='App installata da analizzare:';screen='Schermo Android:';screenApply='Applica schermo';screenReset='Ripristina';
    screenPhoneLite='Telefono leggero 720 x 1280 (320 dpi)';screenPhoneHigh='Telefono HD 1080 x 2400 (420 dpi)';screenTablet1610='Tablet orizzontale 1280 x 800 (200 dpi)';screenTablet169='Tablet panoramico 1600 x 900 (240 dpi)';screenTabletAuto='Tablet automatico - adatta al monitor';
    gamesMode='Compatibilita giochi';gamesModeConfirm='Ripristinare la risoluzione, la densita e la rotazione automatica Android per lasciare al gioco il controllo dello schermo? App e dati Google Play rimangono intatti.';gamesModeDone='Compatibilita giochi: schermo originale e rotazione automatica ripristinati; dati conservati.';
    screenFitWindow='Adatta finestra al monitor';screenWindowFitted='Finestra Android adattata senza superfici nere inutilizzate.';screenFitUnavailable='Finestra Android non ancora disponibile per il ridimensionamento.';screenSmartFit='Schermo verticale o proporzioni diverse: desktop mantenuto visibile, niente fullscreen nero.';
    screenProfileApplied='Profilo schermo Android applicato:';screenProfileNotice='Tablet in orizzontale: la finestra mantiene le proporzioni Android. Il fullscreen non aumenta i pixel del monitor.';screenProfileRestored='Risoluzione, densita e rotazione automatica Android ripristinate.';
    screenshot='Screenshot';touchHelp='Touch / Audio';fullscreen='Fullscreen intelligente';exitFullscreen='Esci fullscreen';
    folder='APK da cartella';link='APK da link HTTPS';splitTouch='Touchpad + mouse (futuro)';
    snapshotSave='Salva snapshot';snapshotLoad='Ripristina snapshot';snapshotList='Elenco snapshot';
    diagnostics='Diagnostica completa';ramBefore='RAM: Prima';ramAndroid='RAM: Android';ramGame='RAM: Gioco';log='Attivita e diagnostica:';
    touchHelpTitle='WEmulDroid - Touch / Audio'; touchHelpText="TOUCH: clic sinistro = tocco; doppio clic = doppio tocco.\nTieni premuto e trascina per lo swipe.\nCtrl + mouse simula il pinch multitouch speculare.\nDue dita indipendenti touchpad + mouse: NON IMPLEMENTATO.\nScrivi con la tastiera del PC.\n\nAUDIO: uscita su casse o cuffie del PC.\nVolume: pulsanti laterali dell'emulatore.\nMicrofono: Extended controls > Microphone; attivalo solo quando serve.\n\nL'accesso remoto non viene attivato automaticamente. I report rimangono sul PC.";
    ready='Pronto. Prima installazione: clicca Installa strumenti.';readyInstalled='Strumenti Android rilevati. Premi Avvia Android per aprire il dispositivo.';
    settings="Impostazioni";
    updatesTitle="WEmulDroid - Impostazioni / Aggiornamenti";
    updatesVersion="Versione installata";
    updatesBeta="Includi versioni beta";
    updatesCheck="Controlla aggiornamenti";
    updatesDownload="Scarica aggiornamento";
    updatesApply="Installa aggiornamento";
    updatesClose="Chiudi";
    updatesDescription="Nessun download automatico. Solo release GitHub ufficiali. Le versioni DI SVILUPPO non sono firmate e Windows potrebbe bloccarle. Non disattivare le protezioni.";
    updatesFound="Nuova release:";
    updatesNoNew="Non ci sono versioni più recenti per il canale selezionato.";
    updatesError="Problema aggiornamento:";
    updatesConfirmDownload="Scaricare questo aggiornamento ufficiale e verificare SHA-256?";
    updatesDownloaded="Scaricato e verificato. Inno Setup aggiornerà i file dell'app dopo la conferma; i dati Android resteranno intatti.";
    updatesConfirmApply="Avviare l'installer di aggiornamento? Le beta di sviluppo non sono firmate e Windows potrebbe bloccarle. SDK Android, dispositivi virtuali e report restano intatti.";profile='Profilo selezionato:';
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
    tabApps='Applications / APK';tabDisplay='Écran / Commandes';tabDiagnostics='Diagnostic / Instantanés';
    centerAndroid='Centrer Android';centered='Fenêtre Android centrée sur votre écran.';centerNotFound='Fenêtre Android pas encore visible. Démarrez Android.';centerError='Impossible de centrer Android :';
    home='Accueil';back='Retour';keyboardPc='Clavier PC';keyboardAndroid='Clavier Android';coldBoot='Démarrage à froid';
    setupAllTitle='Installer Android et Google Play';setupAllPrompt='Installer maintenant Android standard et Google Play officiel ? WEmulDroid téléchargera plusieurs Go directement depuis Google. Internet et acceptation des licences SDK sont nécessaires. Les appareils et leurs données seront conservés. Conditions : https://developer.android.com/studio/terms';setupAllDeclined='Installation automatique reportée. Vous pouvez choisir Installer les outils plus tard.';setupAllStarted='Préparation des deux profils Android et Google Play. Acceptez les licences SDK dans la fenêtre de configuration.';keyboardHardwareReady='Clavier PC activé pour le prochain démarrage. Gboard reste disponible.';
    keyboardPcBoth='Claviers PC + Android';keyboardHideSoft='Masquer le clavier Android';keyboardShowSoft='Afficher le clavier Android';
    keyboardBothDone='Clavier physique configuré et clavier Android conservé pour la connexion.';
    keyboardHideConfirm='Masquer le clavier Android ? Acceptez seulement si le clavier PC fonctionne. Vous pouvez le réactiver ici.';
    keyboardSoftHidden='Clavier Android masqué sur demande explicite.';
    homeDone='Commande Accueil envoyée à Android.';backDone='Commande Retour envoyée à Android.';
    keyboardPcDone='Clavier du PC activé. Cliquez dans un champ Android et tapez sur votre clavier.';
    keyboardAndroidDone='Clavier virtuel Android réactivé.';
    keyboardRestart='Le clavier physique a été activé pour cet appareil. Arrêtez et redémarrez Android une fois pour appliquer le changement.';
    coldBootStopFirst='Arrêtez Android avant un démarrage à froid. Les applications et données seront conservées.';
    coldBootConfirm='Démarrer Android sans charger le dernier instantané ? Cela peut corriger un écran noir/gris sans effacer les applications ni les données.';
    coldBootStarted='Démarrage à froid lancé. Journal :';
    emulatorLogSaved='Journal de diagnostic Android enregistré :';
    title='WEmulDroid | Android sur Windows';language='Langue';device='Appareil :';notStarted='a demarrer';
    setup='1. Installer les outils';start='2. Demarrer Android';refresh='3. Actualiser les applis';stop='Arreter Android';
    install='Installer APK';measure='Mesurer ressources';reports='Ouvrir rapports';play='Ouvrir Play Store';
    package='Application a analyser :';screen='Ecran Android :';screenApply='Appliquer ecran';screenReset='Reinitialiser';
    screenPhoneLite='Telephone leger 720 x 1280 (320 dpi)';screenPhoneHigh='Telephone HD 1080 x 2400 (420 dpi)';screenTablet1610='Tablette paysage 1280 x 800 (200 dpi)';screenTablet169='Tablette large 1600 x 900 (240 dpi)';screenTabletAuto='Tablette auto - adaptee au moniteur';
    gamesMode='Compatibilite jeux';gamesModeConfirm='Restaurer la resolution, la densite et la rotation automatique Android pour laisser le jeu choisir son orientation ? Applications et donnees Google Play conservees.';gamesModeDone='Compatibilite jeux : ecran et rotation automatique restaures sans effacer les donnees.';
    screenFitWindow='Adapter la fenetre au moniteur';screenWindowFitted='Fenetre Android adaptee sans zones noires inutiles.';screenFitUnavailable='Fenetre Android indisponible pour le redimensionnement.';screenSmartFit='Portrait ou proportions differentes : bureau visible au lieu du plein ecran noir.';
    screenProfileApplied="Profil d'affichage Android applique :";screenProfileNotice="Tablette en mode paysage : la fenetre conserve les proportions Android. Le plein ecran n'augmente pas les pixels de l'ecran.";screenProfileRestored="Resolution, densite et rotation automatique Android restaurees.";
    screenshot='Capture ecran';touchHelp='Tactile / Audio';fullscreen='Plein ecran intelligent';exitFullscreen='Quitter plein ecran';
    folder='APK du dossier';link='APK via lien HTTPS';splitTouch='Pave tactile + souris (futur)';
    snapshotSave='Sauver snapshot';snapshotLoad='Restaurer snapshot';snapshotList='Liste snapshots';
    diagnostics='Diagnostic complet';ramBefore='RAM : Avant';ramAndroid='RAM : Android';ramGame='RAM : Jeu';log='Activite et diagnostic :';
    touchHelpTitle='WEmulDroid - Tactile / Audio'; touchHelpText="TACTILE : clic gauche = toucher ; double-clic = double toucher.\nMaintenez et faites glisser pour balayer.\nCtrl + souris simule un pincement multi-tactile symetrique.\nDeux doigts independants pave tactile + souris : NON DISPONIBLE.\nSaisissez du texte avec le clavier du PC.\n\nAUDIO : haut-parleurs ou casque du PC.\nVolume : boutons lateraux de l'emulateur.\nMicro : Extended controls > Microphone, a activer uniquement si besoin.\n\nL'acces a distance n'est pas active automatiquement. Les rapports restent sur le PC.";
    ready='Pret. Pour commencer, installez les outils.';readyInstalled='Outils Android détectés. Cliquez sur Démarrer Android pour ouvrir votre appareil.';
    settings="Paramètres";
    updatesTitle="WEmulDroid - Paramètres / Mises à jour";
    updatesVersion="Version installée";
    updatesBeta="Inclure les versions bêta";
    updatesCheck="Rechercher les mises à jour";
    updatesDownload="Télécharger la mise à jour";
    updatesApply="Installer la mise à jour";
    updatesClose="Fermer";
    updatesDescription="Aucun téléchargement automatique. Versions officielles GitHub uniquement. Les versions DE DÉVELOPPEMENT ne sont pas signées et peuvent être bloquées par Windows. Ne désactivez pas la sécurité.";
    updatesFound="Nouvelle version :";
    updatesNoNew="Aucune version plus récente pour ce canal.";
    updatesError="Problème de mise à jour :";
    updatesConfirmDownload="Télécharger cette mise à jour officielle et vérifier SHA-256 ?";
    updatesDownloaded="Téléchargée et vérifiée. Inno Setup remplacera les fichiers de l'application après confirmation sans supprimer les données Android.";
    updatesConfirmApply="Démarrer cet installateur de mise à jour ? Les versions de développement ne sont pas signées et peuvent être bloquées par Windows. SDK, appareils virtuels et rapports restent préservés.";profile='Profil selectionne :';
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
