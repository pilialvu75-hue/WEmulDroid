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
    ready='Ready. For first use, select Install tools.';profile='Selected profile:'
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
    ready='Pronto. Prima installazione: clicca Installa strumenti.';profile='Profilo selezionato:'
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
    ready='Pret. Pour commencer, installez les outils.';profile='Profil selectionne :'
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
