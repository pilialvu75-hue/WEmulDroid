# Run with Windows PowerShell 5.1 on the Windows Actions runner.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\Layout.ps1')

$form = New-Object System.Windows.Forms.Form
$titleLabel = New-Object System.Windows.Forms.Label
$languageLabel = New-Object System.Windows.Forms.Label
$script:LanguageCombo = New-Object System.Windows.Forms.ComboBox
$script:DeviceLabel = New-Object System.Windows.Forms.Label
$packageLabel = New-Object System.Windows.Forms.Label
$screenLabel = New-Object System.Windows.Forms.Label
$script:PackageCombo = New-Object System.Windows.Forms.ComboBox
$script:ScreenCombo = New-Object System.Windows.Forms.ComboBox
$logLabel = New-Object System.Windows.Forms.Label
$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true

$buttonNames = @(
    'btnSettings','btnSetup','btnStart','btnRefresh','btnStop',
    'btnHome','btnBack','btnPcKeyboard','btnColdBoot','btnToggleSoftKeyboard',
    'btnInstall','btnApkFolder','btnApkLink','btnPlay',
    'btnScreen','btnScreenReset','btnCapture','btnTouchHelp','btnFullscreen',
    'btnSplitTouch','btnCenter','btnFit','btnGamesMode','btnMeasure','btnReports','btnDiagnostics',
    'btnSnapshotList','btnSnapshotSave','btnSnapshotLoad'
)
foreach ($name in $buttonNames) {
    $control = New-Object System.Windows.Forms.Button
    Set-Variable -Name $name -Value $control -Scope Script
    $form.Controls.Add($control)
}
foreach ($item in @($titleLabel,$languageLabel,$script:LanguageCombo,
    $script:DeviceLabel,$packageLabel,$script:PackageCombo,$screenLabel,
    $script:ScreenCombo,$logLabel,$script:LogBox)) {
    $form.Controls.Add($item)
}

try {
    Initialize-WEmulDroidLayout

    if ($script:WorkTabs.TabPages.Count -ne 3) {
        throw 'Expected exactly three GUI tabs.'
    }
    if ($titleLabel.Right -gt $languageLabel.Left) {
        throw 'Language header overlaps WEmulDroid title.'
    }
    if ($languageLabel.Right -gt $script:LanguageCombo.Left) {
        throw 'Language label overlaps language dropdown.'
    }
    foreach ($button in @($btnHome,$btnBack,$btnPcKeyboard,$btnColdBoot)) {
        if ($button.Parent -ne $form -or $button.Top -ge $script:WorkTabs.Top) {
            throw 'Android navigation and keyboard control not permanently visible.'
        }
    }
    if ($btnStart.Parent -ne $form -or $btnStop.Parent -ne $form -or
        $btnSettings.Parent -ne $form) {
        throw 'Android launch, stop and settings must stay on the main screen.'
    }
    foreach ($button in @($btnInstall,$btnApkFolder,$btnApkLink,$btnPlay)) {
        if ($button.Parent -ne $script:AppsTab) {
            throw "APK or Play button must be on the Applications tab: $($button.Name)"
        }
    }
    foreach ($button in @($btnScreen,$btnScreenReset,$btnCapture,
        $btnTouchHelp,$btnFullscreen,$btnSplitTouch,$btnCenter,$btnToggleSoftKeyboard,$btnFit,$btnGamesMode)) {
        if ($button.Parent -ne $script:DisplayTab) {
            throw 'Display control is missing from the Display tab.'
        }
    }
    foreach ($button in @($btnMeasure,$btnReports,$btnDiagnostics,
        $btnSnapshotList,$btnSnapshotSave,$btnSnapshotLoad)) {
        if ($button.Parent -ne $script:DiagnosticsTab) {
            throw 'Diagnostics or snapshots button is missing from Diagnostics tab.'
        }
    }
    if ($btnGamesMode.Bottom -gt ($script:WorkTabs.Height - 35)) {
        throw 'Game compatibility button is clipped by the tab page.'
    }
    if ($script:PackageCombo.Parent -ne $script:AppsTab -or
        $script:ScreenCombo.Parent -ne $script:DisplayTab) {
        throw 'App and resolution selectors were placed on the wrong tab.'
    }
    $form.ClientSize = New-Object System.Drawing.Size(960,780)
    if ($script:LogBox.Height -lt 150) {
        throw 'Activity log failed to resize with the desktop window.'
    }
    Write-Host 'PASS: WEmulDroid three-tab layout, header spacing, key buttons and resize.'
} finally {
    $form.Dispose()
}
