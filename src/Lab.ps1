# WEmulDroid v0.5 - Windows PowerShell 5.1 / WinForms
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
. (Join-Path $PSScriptRoot 'ApkInstall.ps1')
. (Join-Path $PSScriptRoot 'WindowMode.ps1')

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
        throw 'Motore Android non trovato. Esegui Installa-Android.cmd o premi Installa strumenti.'
    }
    if (-not (Test-Path -LiteralPath $script:Adb)) {
        throw 'adb.exe non trovato. Esegui Installa-Android.cmd.'
    }
}

function Get-LabSerial {
    Assert-ToolsInstalled
    $devices = @(& $script:Adb devices 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw 'adb non risponde.'
    }
    foreach ($line in $devices) {
        if ([string]$line -match '^(emulator-[0-9]+)\s+device\b') {
            $serial = $Matches[1]
            $avdDetails = (& $script:Adb -s $serial emu avd name 2>&1 | Out-String)
            if ($avdDetails -match [regex]::Escape($script:AvdName)) {
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
$form.Text = 'WEmulDroid - Android Desktop Lab v0.5'
$form.ClientSize = New-Object System.Drawing.Size(810, 766)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'WEmulDroid | Android su Windows'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.SetBounds(20, 15, 760, 40)
$form.Controls.Add($titleLabel)

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
[void]$script:ScreenCombo.Items.Add('Tablet 1600 x 2560 (320 dpi)')
$script:ScreenCombo.SelectedIndex = 0
$form.Controls.Add($script:ScreenCombo)

$btnScreen = New-LabButton 'Applica schermo' 406 267
$btnScreenReset = New-LabButton 'Ripristina' 599 267
$btnCapture = New-LabButton 'Screenshot' 20 320
$btnTouchHelp = New-LabButton 'Touch / Audio' 213 320
$btnFullscreen = New-LabButton 'Fullscreen' 406 320
$btnApkFolder = New-LabButton 'APK da cartella' 599 320
$btnApkLink = New-LabButton 'APK da link HTTPS' 20 373
$btnSplitTouch = New-LabButton 'Touchpad + mouse (futuro)' 213 373 274
$btnSplitTouch.Enabled = $false
$tip = New-Object System.Windows.Forms.ToolTip
$tip.SetToolTip($btnSplitTouch, 'Richiede due puntatori hardware indipendenti. Windows Precision Touchpad puo nascondere i contatti raw. Funzione sperimentale non ancora attiva.')


$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = 'Attivita e diagnostica:'
$logLabel.SetBounds(20, 459, 750, 26)
$form.Controls.Add($logLabel)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ReadOnly = $true
$script:LogBox.ScrollBars = 'Vertical'
$script:LogBox.SetBounds(20, 489, 770, 248)
$script:LogBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($script:LogBox)


function Invoke-DeviceCommand([string]$serial, [string[]]$arguments, [string]$what) {
    $out = (& $script:Adb -s $serial @arguments 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $out -match '(?i)\bException\b|\bSecurityException\b|\bError:') {
        throw ($what + ' non riuscito: ' + $out.Trim())
    }
    return $out.Trim()
}


$btnFullscreen.Add_Click({
    try {
        $serial = Require-RunningDevice
        # Il nome AVD/seriale viene verificato prima di intervenire sulla finestra.
        $msg = Set-EmulatorWindowFullscreen $script:AvdName
        Write-Log $msg
        if ($script:FullscreenWindowState) {
            $btnFullscreen.Text = 'Esci fullscreen'
        } else {
            $btnFullscreen.Text = 'Fullscreen'
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnApkFolder.Add_Click({
    try {
        $serial = Require-RunningDevice
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'Seleziona la cartella che contiene file APK indipendenti (solo livello principale).'
        $dialog.ShowNewFolderButton = $false
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $apks = @(Get-ChildItem -LiteralPath $dialog.SelectedPath -Filter '*.apk' -File -ErrorAction Stop | Sort-Object Name)
        if ($apks.Count -eq 0) { throw 'La cartella non contiene APK.' }
        if ($apks.Count -gt 30) { throw 'La cartella contiene piu di 30 APK. Seleziona una cartella piu piccola.' }
        $prompt = "Vuoi installare $($apks.Count) APK nel SOLO emulatore $($script:AvdName)? Ogni APK verra trattato come app indipendente; non usare cartelle di split APK."
        if ([System.Windows.Forms.MessageBox]::Show($prompt, 'Conferma installazione APK', 'YesNo', 'Question') -ne 'Yes') { return }
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
            Write-Log ("Cartella completata: successi $ok; falliti $failed.")
            Refresh-Packages
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    } catch { Show-Error $_.Exception.Message }
})

$btnApkLink.Add_Click({
    try {
        $serial = Require-RunningDevice
        Add-Type -AssemblyName Microsoft.VisualBasic
        $url = [Microsoft.VisualBasic.Interaction]::InputBox(
            'Incolla URL HTTPS di un APK oppure pagina GitHub releases/latest o releases/tag/...',
            'WEmulDroid - Installa APK da link',
            ''
        )
        if ([string]::IsNullOrWhiteSpace($url)) { return }
        # Una pagina GitHub viene risolta prima del consenso; nessun APK scaricato.
        $resolved = Resolve-ApkDownloadUri $url.Trim()
        $display = $resolved.Host + $resolved.AbsolutePath
        $prompt = "Scaricare e installare nell emulatore $($script:AvdName) questo APK?" + [Environment]::NewLine +
            $display + [Environment]::NewLine + 'Usa soltanto sorgenti affidabili. Gli APK non sono automaticamente certificati.'
        if ([System.Windows.Forms.MessageBox]::Show($prompt, 'Conferma download e installazione', 'YesNo', 'Warning') -ne 'Yes') { return }
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
        $selected = $script:ScreenCombo.SelectedIndex
        if ($selected -lt 0) { throw 'Scegli un profilo di schermo.' }
        $sizes = @('720x1280', '1080x2400', '1600x2560')
        $dpis = @('320', '420', '320')
        $size = $sizes[$selected]
        $dpi = $dpis[$selected]
        # Modifica reversibile del solo display Android emulato.
        [void](Invoke-DeviceCommand $serial @('shell', 'wm', 'size', $size) 'Risoluzione')
        [void](Invoke-DeviceCommand $serial @('shell', 'wm', 'density', $dpi) 'Densita')
        Write-Log ('Schermo Android simulato: ' + $size + ' @ ' + $dpi + ' dpi.')
        Write-Log 'La dimensione della finestra Windows resta indipendente dalla risoluzione Android.'
    } catch { Show-Error $_.Exception.Message }
})

$btnScreenReset.Add_Click({
    try {
        $serial = Require-RunningDevice
        [void](Invoke-DeviceCommand $serial @('shell', 'wm', 'size', 'reset') 'Ripristino risoluzione')
        [void](Invoke-DeviceCommand $serial @('shell', 'wm', 'density', 'reset') 'Ripristino densita')
        Write-Log 'Dimensioni e densita Android riportate ai valori originali dell AVD.'
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
            Write-Log ('Screenshot salvato: ' + $path)
        } finally {
            & $script:Adb -s $serial shell rm -f $remote | Out-Null
        }
    } catch { Show-Error $_.Exception.Message }
})

$btnTouchHelp.Add_Click({
    $help = @(
        'GESTI: clic sinistro = tocco; doppio clic = doppio tocco.'
        'Tieni premuto e trascina il mouse per simulare swipe e drag.'
        'CTRL + mouse = due dita speculari (pinch) nell emulatore Google.'
        'Touchpad + mouse come due dita indipendenti: NON disponibile oggi.'
        'Richiede accesso ai contatti raw del touchpad e iniezione multitouch.'
        'Nel pannello questa opzione rimane disabilitata per evitare falsi test.'
        'Puoi digitare con la tastiera Windows.'
        ''
        'AUDIO: la riproduzione usa le casse o cuffie del PC.'
        'VOLUME: usa i pulsanti laterali della finestra Android.'
        'MICROFONO: nell emulatore apri Extended controls > Microphone'
        'e abilita host microphone access solo quando ti serve.'
        'Il microfono resta disattivato per impostazione predefinita.'
        ''
        'WORK: i test grafici richiedono Computer Use locale autorizzato.'
        'Screenshot e report rimangono sul PC fino a condivisione esplicita.'
    ) -join [Environment]::NewLine
    [System.Windows.Forms.MessageBox]::Show(
        $help, 'WEmulDroid - Comandi touch e audio',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$btnSetup.Add_Click({
    try {
        $root = Split-Path -Parent $PSScriptRoot
        $installerName = if ($script:AvdName -eq 'WEmulDroid_Play_API_35') { 'Installa-PlayStore.cmd' } else { 'Installa-Android.cmd' }
        $installer = Join-Path $root $installerName
        if (-not (Test-Path -LiteralPath $installer)) { throw ($installerName + ' non trovato.') }
        Start-Process -FilePath $installer -WorkingDirectory $root
        Write-Log 'Finestra di installazione aperta; segui le istruzioni e riavvia il laboratorio alla fine.'
    } catch { Show-Error $_.Exception.Message }
})

$btnStart.Add_Click({
    try {
        Assert-ToolsInstalled
        $existing = Get-LabSerial
        if ($existing) {
            Write-Log ('Android e gia avviato: ' + $existing)
            return
        }
        $avds = (& $script:Emulator -list-avds | Out-String)
        if ($avds -notmatch ('(?m)^' + [regex]::Escape($script:AvdName) + '\s*$')) {
            throw 'Dispositivo virtuale non presente. Completa prima il comando Installa strumenti.'
        }
        Start-Process -FilePath $script:Emulator -ArgumentList @('-avd', $script:AvdName, '-gpu', 'auto')
        Write-Log 'Avvio Android richiesto. Attendi la schermata iniziale e premi Aggiorna elenco.'
    } catch { Show-Error $_.Exception.Message }
})

$btnRefresh.Add_Click({
    try { Refresh-Packages } catch { Show-Error $_.Exception.Message }
})

$btnInstall.Add_Click({
    try {
        $serial = Require-RunningDevice
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = 'Seleziona APK da installare'
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
            throw 'Seleziona prima una applicazione dalla lista (Aggiorna elenco).'
        }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            $path = Collect-Report -serial $serial -packageName $package
            Write-Log ('Report salvato: ' + $path)
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
            throw 'Questo profilo Android non include Play Store. Avvia il profilo Google Play.'
        }
        $serial = Require-RunningDevice
        $packagePath = (& $script:Adb -s $serial shell pm path com.android.vending 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $packagePath -notmatch '(?m)^package:') {
            throw 'Play Store non trovato nel profilo corrente. Reinstalla il profilo Google Play senza cancellare quello standard.'
        }
        $result = (& $script:Adb -s $serial shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.android.vending 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0 -or $result -match '(?i)Error:|Exception:') {
            throw ('Non riesco ad aprire Play Store: ' + $result.Trim())
        }
        Write-Log 'Comando Play Store inviato. Accedi con il tuo account Google solo nel dispositivo virtuale ufficiale.'
    } catch { Show-Error $_.Exception.Message }
})

$form.Add_FormClosing({
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
            $btnFullscreen.Text = 'Fullscreen'
        }
        $result = (& $script:Adb -s $serial emu kill 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw ('Arresto non riuscito: ' + $result) }
        $script:DeviceLabel.Text = 'Dispositivo: arrestato'
        $script:PackageCombo.Items.Clear()
        Write-Log ('Arresto richiesto solo per ' + $script:AvdName + '.')
    } catch { Show-Error $_.Exception.Message }
})

Write-Log ('Profilo selezionato: ' + $script:AvdName)
Write-Log 'Pronto. Prima installazione: clicca Installa strumenti.'
Write-Log 'Per usare APK di terze parti, rispetta le relative licenze.'
[void]$form.ShowDialog()
