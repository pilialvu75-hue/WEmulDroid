# WEmulDroid v0.6 - Windows PowerShell 5.1 / WinForms
# Independent launcher, no Android runtime binaries bundled.
[CmdletBinding()]
param(
    [ValidateSet('WEmulDroid_API_35', 'WEmulDroid_Play_API_35')]
    [string]$AvdName = 'WEmulDroid_API_35'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
. (Join-Path $PSScriptRoot 'AdbProcess.ps1')
. (Join-Path $PSScriptRoot 'GuestControls.ps1')
. (Join-Path $PSScriptRoot 'ApkInstall.ps1')
. (Join-Path $PSScriptRoot 'WindowMode.ps1')
. (Join-Path $PSScriptRoot 'ScreenProfiles.ps1')
. (Join-Path $PSScriptRoot 'Snapshots.ps1')
. (Join-Path $PSScriptRoot 'Diagnostics.ps1')
. (Join-Path $PSScriptRoot 'Localization.ps1')
. (Join-Path $PSScriptRoot 'Layout.ps1')
. (Join-Path $PSScriptRoot 'UpdateDialog.ps1')
[void](Assert-WEmulDroidTranslations)
[void](Load-WEmulDroidLanguage)

$script:SdkRoot = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Sdk'
$script:ReportsRoot = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Reports'
$script:AvdName = $AvdName
$script:Emulator = Join-Path $script:SdkRoot 'emulator\emulator.exe'
$script:Adb = Join-Path $script:SdkRoot 'platform-tools\adb.exe'

function Write-Log([string]$message) {
    $line = ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $message)
    $script:LogBox.AppendText($line + [Environment]::NewLine)
    $script:LogBox.SelectionStart = $script:LogBox.TextLength
    $script:LogBox.ScrollToCaret()
}

function Show-Error([string]$message) {
    Write-Log ('ERRORE: ' + $message)
    [System.Windows.Forms.MessageBox]::Show(
        $message, 'WEmulDroid',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

function Assert-ToolsInstalled {
    if (-not (Test-Path -LiteralPath $script:Emulator)) {
        throw 'Motore Android non trovato. premi «Installa strumenti» per configurarlo.'
    }
    if (-not (Test-Path -LiteralPath $script:Adb)) {
        throw 'adb.exe non trovato. premi «Installa strumenti» per configurarlo.'
    }
}

function Get-LabSerial {
    Assert-ToolsInstalled
    $result = Invoke-WEmulDroidNative -Executable $script:Adb -Arguments @('devices')
    if ($result.ExitCode -ne 0) {
        $detail = ($result.StdErr + ' ' + $result.StdOut).Trim()
        throw ('adb non risponde (codice ' + $result.ExitCode + '): ' + $detail)
    }
    # ADB's first-start progress is written to stderr even on success.
    if ($result.StdErr -match '(?i)daemon not running; starting now') {
        Write-Log 'ADB: primo avvio del servizio completato.'
    }
    foreach ($line in ($result.StdOut -split '\r?\n')) {
        if ($line -match '^(emulator-[0-9]+)\s+device\b') {
            $serial = $Matches[1]
            $details = Invoke-WEmulDroidNative -Executable $script:Adb -Arguments @('-s', $serial, 'emu', 'avd', 'name')
            if ($details.ExitCode -eq 0 -and
                $details.StdOut -match ('(?m)^' + [regex]::Escape($script:AvdName) + '\s*$')) {
                return $serial
            }
        }
    }
    return $null
}

function Require-RunningDevice {
    $serial = Get-LabSerial
    if (-not $serial) {
        throw 'Android non ancora pronto. Premi Avvia Android, attendi la schermata iniziale e poi Aggiorna elenco.'
    }
    return $serial
}

function Refresh-Packages {
    $script:PackageCombo.Items.Clear()
    $serial = Require-RunningDevice
    $script:DeviceLabel.Text = ('Dispositivo attivo: ' + $script:AvdName + ' (' + $serial + ')')
    $output = @(& $script:Adb -s $serial shell pm list packages -3 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'Impossibile leggere le applicazioni installate.' }
    foreach ($line in $output) {
        if ([string]$line -match '^package:(.+)$') {
            [void]$script:PackageCombo.Items.Add($Matches[1].Trim())
        }
    }
    if ($script:PackageCombo.Items.Count -gt 0) { $script:PackageCombo.SelectedIndex = 0 }
    Write-Log ("Android collegato; trovate {0} applicazioni utente." -f $script:PackageCombo.Items.Count)
}

function Collect-Report([string]$serial, [string]$packageName) {
    New-Item -ItemType Directory -Path $script:ReportsRoot -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safePackage = $packageName -replace '[^a-zA-Z0-9._-]', '_'
    $path = Join-Path $script:ReportsRoot ('report-' + $safePackage + '-' + $stamp + '.txt')

    $memInfo = (& $script:Adb -s $serial shell dumpsys meminfo $packageName 2>&1 | Out-String)
    $memExit = $LASTEXITCODE
    $cpuInfo = (& $script:Adb -s $serial shell dumpsys cpuinfo 2>&1 | Out-String)
    $cpuExit = $LASTEXITCODE
    $gfxInfo = (& $script:Adb -s $serial shell dumpsys gfxinfo $packageName 2>&1 | Out-String)
    $gfxExit = $LASTEXITCODE
    $resolution = (& $script:Adb -s $serial shell wm size 2>&1 | Out-String).Trim()
    $density = (& $script:Adb -s $serial shell wm density 2>&1 | Out-String).Trim()
    if ($memExit -ne 0 -or $cpuExit -ne 0 -or $gfxExit -ne 0) {
        throw 'adb ha restituito un errore durante la raccolta dei dati.'
    }
    $appCpuLines = @($cpuInfo -split '\r?\n' | Where-Object { $_ -match [regex]::Escape($packageName) })
    $pssLabel = 'non disponibile'
    if ($memInfo -match '(?mi)^\s*TOTAL PSS:\s*(\d+)') {
        $pssLabel = ('{0} KiB' -f $Matches[1])
    }

    $hostMem = [System.GC]::GetTotalMemory($false)
    $hostProcesses = @(Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match '^(emulator|qemu-system)' } |
        Select-Object ProcessName, Id, CPU, WorkingSet64, PrivateMemorySize64)
    $hostText = if ($hostProcesses.Count -gt 0) {
        $hostProcesses | Format-Table -AutoSize | Out-String
    } else {
        'Nessun processo emulator/qemu trovato dalla sessione utente.'
    }

    $report = @(
        'WEMULDROID ANDROID LAB - DIAGNOSTICA v0.1'
        ('Data: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
        ('AVD: ' + $script:AvdName)
        ('Seriale: ' + $serial)
        ('Package: ' + $packageName)
        ('RAM app: TOTAL PSS = ' + $pssLabel)
        ('Schermo Android: ' + $resolution)
        ('Densita Android: ' + $density)
        'NOTA: RAM e CPU vengono osservate in un emulatore, non sono misure equivalenti ad hardware reale.'
        'NOTA: gfxinfo fornisce statistiche di rendering, non una percentuale attendibile di utilizzo GPU.'
        ''
        '=== PROCESSI EMULATORE SU WINDOWS (CPU cumulativa in secondi; memoria in byte) ==='
        $hostText
        '=== DUMPSYS MEMINFO (APP) ==='
        $memInfo
        '=== RIGHE CPUINFO RELATIVE ALL APP ==='
        ($appCpuLines -join [Environment]::NewLine)
        '=== DUMPSYS CPUINFO (COMPLETO) ==='
        $cpuInfo
        '=== DUMPSYS GFXINFO (APP) ==='
        $gfxInfo
    ) -join [Environment]::NewLine

    [System.IO.File]::WriteAllText($path, $report, (New-Object System.Text.UTF8Encoding($false)))
    return $path
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'WEmulDroid - Android Desktop Lab v0.9'
$form.ClientSize = New-Object System.Drawing.Size(810, 836)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'WEmulDroid | Android su Windows'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.SetBounds(20, 15, 510, 40)
$form.Controls.Add($titleLabel)

$languageLabel = New-Object System.Windows.Forms.Label
$languageLabel.Text = 'Lingua'
$languageLabel.SetBounds(520, 21, 65, 26)
$form.Controls.Add($languageLabel)

$script:LanguageCombo = New-Object System.Windows.Forms.ComboBox
$script:LanguageCombo.DropDownStyle = 'DropDownList'
$script:LanguageCombo.SetBounds(596, 17, 194, 29)
foreach ($langName in $script:UiLanguageNames) {
    [void]$script:LanguageCombo.Items.Add($langName)
}
$script:LanguageCombo.SelectedIndex = [array]::IndexOf($script:UiLanguages, $script:UiLanguage)
$form.Controls.Add($script:LanguageCombo)

$script:DeviceLabel = New-Object System.Windows.Forms.Label
$script:DeviceLabel.Text = ('Dispositivo: da avviare (' + $script:AvdName + ')')
$script:DeviceLabel.SetBounds(20, 60, 770, 26)
$form.Controls.Add($script:DeviceLabel)

function New-LabButton([string]$text, [int]$x, [int]$y, [int]$width = 178) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.SetBounds($x, $y, $width, 38)
    $form.Controls.Add($b)
    return $b
}

$btnSetup = New-LabButton '1. Installa strumenti' 20 100
$btnStart = New-LabButton '2. Avvia Android' 213 100
$btnRefresh = New-LabButton '3. Aggiorna elenco' 406 100
$btnStop = New-LabButton 'Arresta Android' 599 100
$btnHome = New-LabButton 'Home Android' 20 162
$btnBack = New-LabButton 'Indietro' 213 162
$btnPcKeyboard = New-LabButton 'Tastiera PC + Android' 406 162
$btnColdBoot = New-LabButton 'Avvio pulito' 599 162
$btnToggleSoftKeyboard = New-LabButton 'Nascondi tastiera Android' 213 485
$script:SoftKeyboardHidden = $false

$btnInstall = New-LabButton 'Installa APK' 20 162
$btnMeasure = New-LabButton 'Misura risorse' 213 162
$btnReports = New-LabButton 'Apri report' 406 162
$btnPlay = New-LabButton 'Apri Play Store' 599 162
$btnPlay.Enabled = ($script:AvdName -eq 'WEmulDroid_Play_API_35')

$packageLabel = New-Object System.Windows.Forms.Label
$packageLabel.Text = 'App installata da analizzare:'
$packageLabel.SetBounds(20, 225, 260, 26)
$form.Controls.Add($packageLabel)

$script:PackageCombo = New-Object System.Windows.Forms.ComboBox
$script:PackageCombo.DropDownStyle = 'DropDownList'
$script:PackageCombo.SetBounds(280, 222, 510, 30)
$form.Controls.Add($script:PackageCombo)


$screenLabel = New-Object System.Windows.Forms.Label
$screenLabel.Text = 'Schermo Android:'
$screenLabel.SetBounds(20, 273, 135, 26)
$form.Controls.Add($screenLabel)

$script:ScreenCombo = New-Object System.Windows.Forms.ComboBox
$script:ScreenCombo.DropDownStyle = 'DropDownList'
$script:ScreenCombo.SetBounds(153, 270, 245, 30)
[void]$script:ScreenCombo.Items.Add('Leggero 720 x 1280 (320 dpi)')
[void]$script:ScreenCombo.Items.Add('Smartphone 1080 x 2400 (420 dpi)')
[void]$script:ScreenCombo.Items.Add('Tablet 16:10 — 1280 x 800 (200 dpi)')
[void]$script:ScreenCombo.Items.Add('Tablet 16:9 — 1600 x 900 (240 dpi)')
[void]$script:ScreenCombo.Items.Add('Tablet automatico — adatta al monitor')
$script:ScreenCombo.SelectedIndex = 0
$form.Controls.Add($script:ScreenCombo)

$btnScreen = New-LabButton 'Applica schermo' 406 267
$btnScreenReset = New-LabButton 'Ripristina' 599 267
$btnCapture = New-LabButton 'Screenshot' 20 320
$btnTouchHelp = New-LabButton 'Touch / Audio' 213 320
$btnFullscreen = New-LabButton 'Fullscreen' 406 320
$btnFullscreen.Tag = 'smart'
$btnCenter = New-LabButton 'Centra Android' 20 485
$btnFit = New-LabButton 'Adatta finestra al monitor' 406 485
$btnApkFolder = New-LabButton 'APK da cartella' 599 320
$btnApkLink = New-LabButton 'APK da link HTTPS' 20 373
$btnSettings = New-LabButton 'Impostazioni' 599 373
$btnSplitTouch = New-LabButton 'Touchpad + mouse (futuro)' 213 373 274
$btnSplitTouch.Enabled = $false
$tip = New-Object System.Windows.Forms.ToolTip
$tip.SetToolTip($btnSplitTouch, 'Richiede due puntatori hardware indipendenti. Windows Precision Touchpad puo nascondere i contatti raw. Funzione sperimentale non ancora attiva.')

$btnSnapshotSave = New-LabButton 'Salva snapshot' 20 439
$btnSnapshotLoad = New-LabButton 'Ripristina snapshot' 213 439
$btnSnapshotList = New-LabButton 'Elenco snapshot' 406 439
$btnDiagnostics = New-LabButton 'Diagnostica completa' 599 439
$script:BaselineSnapshot = 'WEmulDroid_baseline'


$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = 'Attivita e diagnostica:'
$logLabel.SetBounds(20, 529, 750, 26)
$form.Controls.Add($logLabel)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ReadOnly = $true
$script:LogBox.ScrollBars = 'Vertical'
$script:LogBox.SetBounds(20, 559, 770, 248)
$script:LogBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($script:LogBox)

Initialize-WEmulDroidLayout


# Android Emulator remembers old window positions, including off-screen ones.
# Poll only during first launch. Never alter other apps or fullscreen mode.
$script:CenterTimer = $null
$script:CenterTimerTicks = 0
function Start-WEmulDroidAutoCenter {
    if (-not $script:CenterTimer) {
        $script:CenterTimer = New-Object System.Windows.Forms.Timer
        $script:CenterTimer.Interval = 1500
        $script:CenterTimer.Add_Tick({
            $script:CenterTimerTicks++
            # Qt may resize/reposition the window during the first few seconds.
            if ($script:CenterTimerTicks -lt 3) { return }
            try {
                # Qt can reposition/resize the virtual device AGAIN while
                # loading Android. Recenter periodically until boot stabilizes.
                # Do not touch the emulator when the user chose fullscreen.
                if (($script:CenterTimerTicks % 4) -eq 3 -and
                    -not $script:FullscreenWindowState) {
                    if (Set-WEmulDroidWindowCentered -AvdName $script:AvdName) {
                        if (-not $script:CenterSucceeded) {
                            Write-Log (T 'centered')
                            $script:CenterSucceeded = $true
                        }
                    }
                }
                if ($script:CenterTimerTicks -ge 33) {
                    $script:CenterTimer.Stop()
                    if (-not $script:CenterSucceeded) { Write-Log (T 'centerNotFound') }
                }
            } catch {
                $script:CenterTimer.Stop()
                Write-Log ((T 'centerError') + ' ' + $_.Exception.Message)
            }
        })
    }
    $script:CenterTimer.Stop()
    $script:CenterTimerTicks = 0
    $script:CenterSucceeded = $false
    $script:CenterTimer.Start()
}


function Invoke-DeviceCommand([string]$serial, [string[]]$arguments, [string]$what) {
    $out = (& $script:Adb -s $serial @arguments 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $out -match '(?i)\bException\b|\bSecurityException\b|\bError:') {
        throw ($what + ' non riuscito: ' + $out.Trim())
    }
    return $out.Trim()
}


$btnSettings.Add_Click({
    try {
        $root = Split-Path -Parent $PSScriptRoot
        $launcher = if ($script:AvdName -eq 'WEmulDroid_Play_API_35') {
            'Avvia-PlayStore.cmd'
        } else {
            'Avvia-Android.cmd'
        }
        Show-WEmulDroidUpdateSettings -MainForm $form -InstallRoot $root -Launcher $launcher
    } catch { Show-Error $_.Exception.Message }
})

$btnSnapshotList.Add_Click({
    try {
        $serial = Require-RunningDevice
        $items = Invoke-WEmulDroidSnapshot -Adb $script:Adb -Serial $serial -Action list
        if (-not $items) { $items = '(Nessuno snapshot disponibile)' }
        [void][System.Windows.Forms.MessageBox]::Show(
            $items, (T 'snapshotListTitle'), 'OK', 'Information'
        )
    } catch { Show-Error $_.Exception.Message }
})

$btnSnapshotSave.Add_Click({
    try {
        $serial = Require-RunningDevice
        $msg = (T 'snapshotSavePrompt') + [Environment]::NewLine +
            $script:AvdName + ' / ' + $script:BaselineSnapshot + [Environment]::NewLine +
            (T 'snapshotOverwriteWarning')
        if ([System.Windows.Forms.MessageBox]::Show($msg, (T 'snapshotSaveTitle'), 'YesNo', 'Warning') -ne 'Yes') { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $output = Invoke-WEmulDroidSnapshot -Adb $script:Adb -Serial $serial -Action save -Name $script:BaselineSnapshot
            Write-Log ('Snapshot salvato: ' + $script:BaselineSnapshot + '. ' + $output)
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnSnapshotLoad.Add_Click({
    try {
        $serial = Require-RunningDevice
        $existing = Invoke-WEmulDroidSnapshot -Adb $script:Adb -Serial $serial -Action list
        if ($existing -notmatch [regex]::Escape($script:BaselineSnapshot)) {
            throw ('Snapshot baseline non trovato sul dispositivo: ' + $script:AvdName)
        }
        $msg = (T 'snapshotRestorePrompt') + [Environment]::NewLine +
            $script:AvdName + ' / ' + $script:BaselineSnapshot + [Environment]::NewLine +
            (T 'snapshotRestoreWarning')
        if ([System.Windows.Forms.MessageBox]::Show($msg, (T 'snapshotRestoreTitle'), 'YesNo', 'Warning') -ne 'Yes') { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $output = Invoke-WEmulDroidSnapshot -Adb $script:Adb -Serial $serial -Action load -Name $script:BaselineSnapshot
            $script:PackageCombo.Items.Clear()
            Write-Log ('Ripristino snapshot richiesto: ' + $script:BaselineSnapshot + '. ' + $output)
            Write-Log (T 'afterRestore')
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnDiagnostics.Add_Click({
    try {
        $serial = Require-RunningDevice
        $pkg = [string]$script:PackageCombo.SelectedItem
        $warning = (T 'diagnosticPrompt') + [Environment]::NewLine + (T 'diagnosticWarning')
        if ([System.Windows.Forms.MessageBox]::Show($warning, (T 'diagnosticTitle'), 'YesNo', 'Warning') -ne 'Yes') { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $report = Collect-WEmulDroidDiagnostics -Adb $script:Adb -Serial $serial -ReportsRoot $script:ReportsRoot -PackageName $pkg
            Write-Log ('Diagnostica ' + $(if ($report.Failures -eq 0) { 'completata' } else { 'parziale' }) +
                ': ' + $report.Folder)
            if ($report.Failures -gt 0) {
                Write-Log ('Operazioni non riuscite: ' + $report.Failures + '. Leggi report.txt.')
            }
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})


$btnFit.Add_Click({
    try {
        $serial = Require-RunningDevice
        $working = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
        $profile = Get-WEmulDroidScreenProfile -Index $script:ScreenCombo.SelectedIndex -MonitorArea $working
        if (Set-WEmulDroidWindowFitted -AvdName $script:AvdName -GuestAspect ([double]$profile.Width/$profile.Height) -OwnerForm $form) {
            Write-Log (T 'screenWindowFitted')
        } else {
            Write-Log (T 'screenFitUnavailable')
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnCenter.Add_Click({
    try {
        if (Set-WEmulDroidWindowCentered -AvdName $script:AvdName -OwnerForm $form) {
            Write-Log (T 'centered')
        } else {
            throw (T 'centerNotFound')
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnFullscreen.Add_Click({
    try {
        $serial = Require-RunningDevice
        # On first fullscreen entry, ensure a landscape tablet actually has
        # a matching guest aspect ratio, otherwise Qt letterboxes a tall
        # portrait framebuffer in a widescreen host window.
        if (-not $script:FullscreenWindowState -and
            $script:ScreenCombo.SelectedIndex -ge 2) {
            $working = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
            $profile = Get-WEmulDroidScreenProfile -Index $script:ScreenCombo.SelectedIndex -MonitorArea $working
            foreach ($command in @(Get-WEmulDroidScreenCommands -Profile $profile)) {
                [void](Invoke-DeviceCommand $serial $command.Arguments $command.Label)
            }
            Write-Log ((T 'screenProfileApplied') + ' ' + $profile.Width + 'x' + $profile.Height)
            # Establish a monitor-fit window before entering borderless
            # fullscreen, so exiting fullscreen restores a useful tablet size.
            [void](Set-WEmulDroidWindowFitted -AvdName $script:AvdName -GuestAspect ([double]$profile.Width/$profile.Height) -OwnerForm $form)
        }
        # Smartphone portrait or mismatched monitor aspect must not paint
        # the unused desktop black. Fit just the useful Android window.
        if (-not $script:FullscreenWindowState) {
            $area = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
            $profile = Get-WEmulDroidScreenProfile -Index $script:ScreenCombo.SelectedIndex -MonitorArea $area
            $aspect = [double]$profile.Width / [double]$profile.Height
            if ((Get-WEmulDroidPresentationMode -GuestAspect $aspect -MonitorArea $area) -eq 'fit') {
                [void](Set-WEmulDroidWindowFitted -AvdName $script:AvdName -GuestAspect $aspect -OwnerForm $form)
                Write-Log (T 'screenSmartFit')
                return
            }
        }
        # Only the exact selected AVD's Qt emulator window is modified.
        $msg = Set-EmulatorWindowFullscreen $script:AvdName
        Write-Log $msg
        if ($script:FullscreenWindowState) {
            $btnFullscreen.Text = (T 'exitFullscreen')
        } else {
            $btnFullscreen.Text = (T 'fullscreen')
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnApkFolder.Add_Click({
    try {
        $serial = Require-RunningDevice
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = (T 'folderTitle')
        $dialog.ShowNewFolderButton = $false
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $apks = @(Get-ChildItem -LiteralPath $dialog.SelectedPath -Filter '*.apk' -File -ErrorAction Stop | Sort-Object Name)
        if ($apks.Count -eq 0) { throw (T 'folderEmpty') }
        if ($apks.Count -gt 30) { throw (T 'folderTooMany') }
        $prompt = (T 'folderConfirmPrompt') + [Environment]::NewLine + ('APK: ' + $apks.Count + ' / ' + $script:AvdName)
        if ([System.Windows.Forms.MessageBox]::Show($prompt, (T 'folderConfirmTitle'), 'YesNo', 'Question') -ne 'Yes') { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $ok = 0
            $failed = 0
            foreach ($apk in $apks) {
                try {
                    $message = Install-VerifiedApk $script:Adb $serial $apk.FullName
                    Write-Log $message
                    $ok++
                } catch {
                    $failed++
                    Write-Log ('APK non installato: ' + $apk.Name + ' - ' + $_.Exception.Message)
                }
            }
            Write-Log ((T 'finishedFolder') + ' ' + $ok + '; ' + (T 'finishedFolderFailures') + ' ' + $failed)
            Refresh-Packages
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnApkLink.Add_Click({
    try {
        $serial = Require-RunningDevice
        Add-Type -AssemblyName Microsoft.VisualBasic
        $url = [Microsoft.VisualBasic.Interaction]::InputBox(
            (T 'urlDialogPrompt'),
            (T 'urlDialogTitle'),
            ''
        )
        if ([string]::IsNullOrWhiteSpace($url)) { return }
        # Una pagina GitHub viene risolta prima del consenso; nessun APK scaricato.
        $resolved = Resolve-ApkDownloadUri $url.Trim()
        $display = $resolved.Host + $resolved.AbsolutePath
        $prompt = (T 'urlConfirmPrompt') + [Environment]::NewLine +
            $script:AvdName + ': ' + $display + [Environment]::NewLine +
            (T 'urlWarning')
        if ([System.Windows.Forms.MessageBox]::Show($prompt, (T 'urlConfirmTitle'), 'YesNo', 'Warning') -ne 'Yes') { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $folder = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Downloads'
            $downloaded = Get-RemoteApk $resolved.AbsoluteUri $folder
            $message = Install-VerifiedApk $script:Adb $serial $downloaded
            Write-Log ('Download HTTPS: ' + $display)
            Write-Log $message
            Refresh-Packages
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnScreen.Add_Click({
    try {
        $serial = Require-RunningDevice
        $index = $script:ScreenCombo.SelectedIndex
        if ($index -lt 0) { throw (T 'chooseScreenFirst') }
        $area = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
        $profile = Get-WEmulDroidScreenProfile -Index $index -MonitorArea $area
        # Apply the natural PORTRAIT base size and then rotate the Android
        # display for landscape tablet mode. Prevent old portrait tablet bug.
        foreach ($command in @(Get-WEmulDroidScreenCommands -Profile $profile)) {
            [void](Invoke-DeviceCommand $serial $command.Arguments $command.Label)
        }
        Write-Log ((T 'screenProfileApplied') + ' ' + $profile.Name + ': ' +
            $profile.Width + 'x' + $profile.Height + ' @ ' + $profile.Dpi + ' dpi.')
        Write-Log (T 'screenProfileNotice')
        # Qt may initially retain a tiny virtual-screen window even when
        # Android uses tablet resolution. Fit the host window as well.
        if (-not $script:FullscreenWindowState) {
            [void](Set-WEmulDroidWindowFitted -AvdName $script:AvdName -GuestAspect ([double]$profile.Width/$profile.Height) -OwnerForm $form)
            Start-WEmulDroidAutoCenter
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnScreenReset.Add_Click({
    try {
        $serial = Require-RunningDevice
        [void](Invoke-DeviceCommand $serial @('shell','wm','user-rotation','free') 'Ripristino orientamento')
        [void](Invoke-DeviceCommand $serial @('shell','wm','size','reset') 'Ripristino risoluzione')
        [void](Invoke-DeviceCommand $serial @('shell','wm','density','reset') 'Ripristino densita')
        $script:ScreenCombo.SelectedIndex = 0
        if (-not $script:FullscreenWindowState) { Start-WEmulDroidAutoCenter }
        Write-Log (T 'screenProfileRestored')
    } catch { Show-Error $_.Exception.Message }
})

$btnCapture.Add_Click({
    try {
        $serial = Require-RunningDevice
        $folder = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Screenshots'
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        $path = Join-Path $folder ('screen-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.png')
        # Su Windows PowerShell 5.1 la redirezione di adb exec-out puo danneggiare PNG binari.
        # Si salva prima nell AVD e poi si usa adb pull (trasferimento binario sicuro).
        $remote = '/sdcard/Download/wemuldroid-screenshot.png'
        [void](Invoke-DeviceCommand $serial @('shell', 'screencap', '-p', $remote) 'Cattura screenshot')
        try {
            [void](Invoke-DeviceCommand $serial @('pull', $remote, $path) 'Download screenshot')
            if (-not (Test-Path -LiteralPath $path)) { throw 'Il file screenshot non e stato creato.' }
            Write-Log ((T 'screenshotSaved') + ' ' + $path)
        } finally {
            & $script:Adb -s $serial shell rm -f $remote | Out-Null
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnHome.Add_Click({
    try {
        $serial = Require-RunningDevice
        [void](Invoke-WEmulDroidGuestControl -Adb $script:Adb -Serial $serial -Action home)
        Write-Log (T 'homeDone')
    } catch { Show-Error $_.Exception.Message }
})

$btnBack.Add_Click({
    try {
        $serial = Require-RunningDevice
        [void](Invoke-WEmulDroidGuestControl -Adb $script:Adb -Serial $serial -Action back)
        Write-Log (T 'backDone')
    } catch { Show-Error $_.Exception.Message }
})

$btnPcKeyboard.Add_Click({
    try {
        # SAFETY: Never disable Android's on-screen keyboard simply because
        # hardware input is enabled. The user must always be able to sign in
        # without needing an ADB text-injection command.
        $serial = Require-RunningDevice
        $restartNeeded = Enable-WEmulDroidPhysicalKeyboard -AvdName $script:AvdName
        [void](Invoke-WEmulDroidGuestControl -Adb $script:Adb -Serial $serial -Action 'keyboard-android')
        $script:SoftKeyboardHidden = $false
        $btnToggleSoftKeyboard.Text = (T 'keyboardHideSoft')
        Write-Log (T 'keyboardBothDone')
        if ($restartNeeded) {
            [System.Windows.Forms.MessageBox]::Show(
                (T 'keyboardRestart'), (T 'keyboardPcBoth'), 'OK', 'Information') | Out-Null
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnToggleSoftKeyboard.Add_Click({
    try {
        $serial = Require-RunningDevice
        if ($script:SoftKeyboardHidden) {
            [void](Invoke-WEmulDroidGuestControl -Adb $script:Adb -Serial $serial -Action 'keyboard-android')
            $script:SoftKeyboardHidden = $false
            Write-Log (T 'keyboardAndroidDone')
        } else {
            $question = (T 'keyboardHideConfirm')
            if ([System.Windows.Forms.MessageBox]::Show($question, (T 'keyboardHideSoft'),
                    'YesNo','Question') -ne 'Yes') { return }
            [void](Invoke-WEmulDroidGuestControl -Adb $script:Adb -Serial $serial -Action 'keyboard-pc')
            $script:SoftKeyboardHidden = $true
            Write-Log (T 'keyboardSoftHidden')
        }
        $btnToggleSoftKeyboard.Text = (T $(if ($script:SoftKeyboardHidden) {
            'keyboardShowSoft'
        } else { 'keyboardHideSoft' }))
    } catch { Show-Error $_.Exception.Message }
})

$btnColdBoot.Add_Click({
    try {
        Assert-ToolsInstalled
        if (Get-LabSerial) { throw (T 'coldBootStopFirst') }
        $question = (T 'coldBootConfirm')
        if ([System.Windows.Forms.MessageBox]::Show($question, (T 'coldBoot'), 'YesNo', 'Question') -ne 'Yes') { return }
        $startup = Start-WEmulDroidQuietEmulator -EmulatorExe $script:Emulator -AvdName $script:AvdName -ReportsRoot $script:ReportsRoot -ColdBoot
        Write-Log ((T 'coldBootStarted') + ' ' + $startup.StdErrLog)
        Start-WEmulDroidAutoCenter
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    } catch { Show-Error $_.Exception.Message }
})

$btnTouchHelp.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        (T 'touchHelpText'), (T 'touchHelpTitle'),
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$btnSetup.Add_Click({
    try {
        $installer = Join-Path $PSScriptRoot 'Setup-Android.ps1'
        if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
            throw 'Installazione incompleta: Setup-Android.ps1 non trovato.'
        }
        $channelFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'CHANNEL.txt'
        $channel = if (Test-Path -LiteralPath $channelFile) { ([IO.File]::ReadAllText($channelFile)).Trim() } else { 'development' }
        $scriptPolicy = if ($channel -eq 'production') { 'AllSigned' } else { 'RemoteSigned' }
        $arguments = @('-NoProfile', '-ExecutionPolicy', $scriptPolicy, '-File', ('"' + $installer + '"'), '-BothProfiles')
        if ($script:SetupConsentConfirmed) { $arguments += '-ConsentConfirmed' }
        # Interactive setup is permitted only after the user clicks the GUI.
        # It requests explicit acceptance of Google SDK licenses.
        Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments
        Write-Log (T 'setupAllStarted')
    } catch { Show-Error $_.Exception.Message }
})

$btnStart.Add_Click({
    try {
        Assert-ToolsInstalled
        $existing = Get-LabSerial
        if ($existing) {
            Write-Log ('Android e gia avviato: ' + $existing)
            Start-WEmulDroidAutoCenter
            return
        }
        $avds = (& $script:Emulator -list-avds | Out-String)
        if ($avds -notmatch ('(?m)^' + [regex]::Escape($script:AvdName) + '\s*$')) {
            throw 'Dispositivo virtuale non presente. Completa prima il comando Installa strumenti.'
        }
        # Enable the physical keyboard BEFORE AVD boot; do not hide Gboard.
        try {
            $physicalKeyboardPrepared = Enable-WEmulDroidPhysicalKeyboard -AvdName $script:AvdName
            if ($physicalKeyboardPrepared) { Write-Log (T 'keyboardHardwareReady') }
        } catch {
            Write-Log ('Nota tastiera: ' + $_.Exception.Message)
        }
        $startup = Start-WEmulDroidQuietEmulator -EmulatorExe $script:Emulator -AvdName $script:AvdName -ReportsRoot $script:ReportsRoot
        Write-Log ((T 'emulatorLogSaved') + ' ' + $startup.StdErrLog)
        Start-WEmulDroidAutoCenter
        Write-Log 'Avvio Android richiesto. WEmulDroid passa nella barra delle applicazioni; puoi riaprirlo quando vuoi.'
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    } catch { Show-Error $_.Exception.Message }
})

$btnRefresh.Add_Click({
    try { Refresh-Packages } catch { Show-Error $_.Exception.Message }
})

$btnInstall.Add_Click({
    try {
        $serial = Require-RunningDevice
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = (T 'chooseApkTitle')
        $dialog.Filter = 'Applicazioni Android (*.apk)|*.apk'
        $dialog.CheckFileExists = $true
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        Write-Log ('Installazione APK: ' + $dialog.FileName)
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $result = Install-VerifiedApk $script:Adb $serial $dialog.FileName
            Write-Log $result
            Refresh-Packages
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnMeasure.Add_Click({
    try {
        $serial = Require-RunningDevice
        $package = [string]$script:PackageCombo.SelectedItem
        if ([string]::IsNullOrWhiteSpace($package)) {
            throw (T 'chooseAppFirst')
        }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $path = Collect-Report -serial $serial -packageName $package
            Write-Log ((T 'reportSaved') + ' ' + $path)
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnReports.Add_Click({
    try {
        New-Item -ItemType Directory -Path $script:ReportsRoot -Force | Out-Null
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $script:ReportsRoot + '"')
    } catch { Show-Error $_.Exception.Message }
})

$btnPlay.Add_Click({
    try {
        if ($script:AvdName -ne 'WEmulDroid_Play_API_35') {
            throw (T 'playNotAvailable')
        }
        $serial = Require-RunningDevice
        $packagePath = (& $script:Adb -s $serial shell pm path com.android.vending 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $packagePath -notmatch '(?m)^package:') {
            throw (T 'playNotFound')
        }
        $result = (& $script:Adb -s $serial shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.android.vending 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0 -or $result -match '(?i)Error:|Exception:') {
            throw ((T 'playOpenFailed') + ' ' + $result.Trim())
        }
        Write-Log 'Comando Play Store inviato. Accedi con il tuo account Google solo nel dispositivo virtuale ufficiale.'
    } catch { Show-Error $_.Exception.Message }
})

$form.Add_FormClosing({
    if ($script:CenterTimer) { $script:CenterTimer.Stop(); $script:CenterTimer.Dispose() }
    if ($script:FullscreenWindowState) {
        try { [void](Restore-EmulatorWindow) } catch {}
    }
})
$btnStop.Add_Click({
    try {
        $serial = Get-LabSerial
        if (-not $serial) { Write-Log 'Nessun dispositivo WEmulDroid attivo.'; return }
        if ($script:FullscreenWindowState) {
            [void](Restore-EmulatorWindow)
            $btnFullscreen.Text = (T 'fullscreen')
        }
        $result = (& $script:Adb -s $serial emu kill 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw ('Arresto non riuscito: ' + $result) }
        $script:DeviceLabel.Text = 'Dispositivo: arrestato'
        $script:PackageCombo.Items.Clear()
        Write-Log ('Arresto richiesto solo per ' + $script:AvdName + '.')
    } catch { Show-Error $_.Exception.Message }
})

function Update-WEmulDroidLanguage {
    $script:AppsTab.Text = (T 'tabApps')
    $script:DisplayTab.Text = (T 'tabDisplay')
    $script:DiagnosticsTab.Text = (T 'tabDiagnostics')
    $titleLabel.Text = (T 'title')
    $languageLabel.Text = (T 'language')
    $script:DeviceLabel.Text = (T 'device') + ' ' + $script:AvdName
    $btnSetup.Text = (T 'setup')
    $btnStart.Text = (T 'start')
    $btnRefresh.Text = (T 'refresh')
    $btnStop.Text = (T 'stop')
    $btnHome.Text = (T 'home')
    $btnBack.Text = (T 'back')
    $btnPcKeyboard.Text = (T 'keyboardPcBoth')
    $btnToggleSoftKeyboard.Text = (T $(if ($script:SoftKeyboardHidden) { 'keyboardShowSoft' } else { 'keyboardHideSoft' }))
    $btnColdBoot.Text = (T 'coldBoot')
    $btnInstall.Text = (T 'install')
    $btnMeasure.Text = (T 'measure')
    $btnReports.Text = (T 'reports')
    $btnPlay.Text = (T 'play')
    $packageLabel.Text = (T 'package')
    $screenLabel.Text = (T 'screen')
    $btnScreen.Text = (T 'screenApply')
    $btnScreenReset.Text = (T 'screenReset')

    # Preserve selected profile when switching English / Italian / French.
    $selectedProfile = $script:ScreenCombo.SelectedIndex
    $script:ScreenCombo.BeginUpdate()
    try {
        $script:ScreenCombo.Items.Clear()
        foreach ($key in @('screenPhoneLite','screenPhoneHigh',
                'screenTablet1610','screenTablet169','screenTabletAuto')) {
            [void]$script:ScreenCombo.Items.Add((T $key))
        }
        $script:ScreenCombo.SelectedIndex = if ($selectedProfile -ge 0 -and $selectedProfile -lt 5) {
            $selectedProfile
        } else { 0 }
    } finally {
        $script:ScreenCombo.EndUpdate()
    }

    $btnCapture.Text = (T 'screenshot')
    $btnTouchHelp.Text = (T 'touchHelp')
    $btnFullscreen.Text = (T $(if ($script:FullscreenWindowState) { 'exitFullscreen' } else { 'fullscreen' }))
    $btnCenter.Text = (T 'centerAndroid')
    $btnFit.Text = (T 'screenFitWindow')
    $btnApkFolder.Text = (T 'folder')
    $btnApkLink.Text = (T 'link')
    $btnSplitTouch.Text = (T 'splitTouch')
    $btnSettings.Text = (T 'settings')
    $btnSnapshotSave.Text = (T 'snapshotSave')
    $btnSnapshotLoad.Text = (T 'snapshotLoad')
    $btnSnapshotList.Text = (T 'snapshotList')
    $btnDiagnostics.Text = (T 'diagnostics')
    $logLabel.Text = (T 'log')
}

$script:LanguageCombo.Add_SelectedIndexChanged({
    $index = $script:LanguageCombo.SelectedIndex
    if ($index -ge 0) {
        Set-WEmulDroidLanguage $script:UiLanguages[$index]
        Update-WEmulDroidLanguage
    }
})
Update-WEmulDroidLanguage
# After installer launch, offer one coherent setup for BOTH Android profiles.
# Requires explicit user consent for Google's SDK terms and multi-GB downloads.
# Never delete already installed SDKs, AVDs or Play Store session data.
$script:SetupConsentConfirmed = $false
$form.Add_Shown({
    try {
        $avdFiles = @('WEmulDroid_API_35','WEmulDroid_Play_API_35') |
            ForEach-Object { Get-WEmulDroidAvdConfig $_ }
        $missing = @($avdFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
        if ($missing.Count -eq 0) { return }
        $prompt = (T 'setupAllPrompt')
        $choice = [System.Windows.Forms.MessageBox]::Show(
            $prompt, (T 'setupAllTitle'), 'YesNo', 'Question')
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            $script:SetupConsentConfirmed = $true
            try { $btnSetup.PerformClick() }
            finally { $script:SetupConsentConfirmed = $false }
        } else {
            Write-Log (T 'setupAllDeclined')
        }
    } catch { Write-Log ('Setup iniziale: ' + $_.Exception.Message) }
})
Write-Log ((T 'profile') + ' ' + $script:AvdName)
if ((Test-Path -LiteralPath $script:Emulator -PathType Leaf) -and
    (Test-Path -LiteralPath $script:Adb -PathType Leaf)) {
    Write-Log (T 'readyInstalled')
} else {
    Write-Log (T 'ready')
}
Write-Log (T 'licenseReminder')
[void]$form.ShowDialog()
