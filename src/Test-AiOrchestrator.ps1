# Primo collaudo AI-Orchestrator Android su WEmulDroid.
# Non modifica il repository originale e non esegue benchmark pesanti.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Join-Path $env:LOCALAPPDATA 'AivexusAndroidLab'
$sdk = Join-Path $root 'Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$downloadFolder = Join-Path $root 'Downloads'
$reportFolder = Join-Path $root 'Reports'
$avdName = 'Aivexus_API_35'
$package = 'com.aiorchestrator'
$releaseApi = 'https://api.github.com/repos/pilialvu75-hue/Ai-orchestrator-riserva/releases/latest'
$releaseTag = 'non determinata'
$apkPath = ''
$serial = ''
$deviceAbi = ''
$apkAbis = @()
$state = 'NOT_STARTED'
$details = ''
$installOutput = ''
$startOutput = ''
$memOutput = ''
$cpuOutput = ''
$logTail = ''

function Check-LastExit([string]$what) {
    if ($LASTEXITCODE -ne 0) { throw "$what fallito con codice $LASTEXITCODE." }
}

function Find-OwnDevice {
    $output = @(& $script:adb devices 2>&1)
    foreach ($line in $output) {
        if ([string]$line -match '^(emulator-[0-9]+)\s+device\b') {
            $candidate = $Matches[1]
            $avdOutput = (& $script:adb -s $candidate emu avd name 2>&1 | Out-String)
            if ($avdOutput -match [regex]::Escape($script:avdName)) {
                return $candidate
            }
        }
    }
    return ''
}

function Write-Report {
    New-Item -Path $script:reportFolder -ItemType Directory -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $script:reportFolder ("ai-orchestrator-first-test-$stamp.txt")
    $report = @(
        'WEmulDroid - Primo test AI-Orchestrator'
        ('Data: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
        ('Stato: ' + $script:state)
        ('Descrizione: ' + $script:details)
        ('Release: ' + $script:releaseTag)
        ('APK: ' + $script:apkPath)
        ('Architetture librerie APK: ' + ($script:apkAbis -join ', '))
        ('Emulatore: ' + $script:avdName)
        ('Seriale: ' + $script:serial)
        ('ABI emulator: ' + $script:deviceAbi)
        'ATTENZIONE: misurazioni in emulazione non rappresentano consumi reali su smartphone.'
        '=== OUTPUT INSTALLAZIONE ==='
        $script:installOutput
        '=== OUTPUT AVVIO ==='
        $script:startOutput
        '=== MEMORIA APP ==='
        $script:memOutput
        '=== CPU (DIAGNOSTICA) ==='
        $script:cpuOutput
        '=== LOGCAT ULTIME RIGHE ==='
        $script:logTail
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($path, $report, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ''
    Write-Host "Report locale: $path" -ForegroundColor Cyan
}

try {
    Write-Host '=== WEmulDroid: primo test di AI-Orchestrator ===' -ForegroundColor Cyan
    Write-Host 'Usa la release stabile pubblica piu recente del repository originale.'
    Write-Host 'Non installa nulla sul tuo Galaxy S24 FE e non aggiorna Ai-orchestrator-riserva.'
    if (-not (Test-Path -LiteralPath $adb) -or -not (Test-Path -LiteralPath $emulator)) {
        throw 'Non trovo i componenti Android. Avvia prima Installa-Android.cmd.'
    }

    $serial = Find-OwnDevice
    if (-not $serial) {
        Write-Host "Avvio dell'emulatore $avdName..."
        $knownAvds = (& $emulator -list-avds | Out-String)
        if ($knownAvds -notmatch ('(?m)^' + [regex]::Escape($avdName) + '\s*$')) {
            throw 'AVD mancante. Completa prima Installa-Android.cmd.'
        }
        Start-Process -FilePath $emulator -ArgumentList @('-avd', $avdName, '-gpu', 'auto')
        $limit = (Get-Date).AddMinutes(5)
        while ((Get-Date) -lt $limit) {
            Start-Sleep -Seconds 4
            $serial = Find-OwnDevice
            if ($serial) {
                $boot = (& $adb -s $serial shell getprop sys.boot_completed 2>&1 | Out-String).Trim()
                if ($boot -eq '1') { break }
            }
        }
        if (-not $serial) { throw 'Emulatore non collegato entro il limite previsto: verifica WHPX/virtualizzazione.' }
    }

    $bootFlag = (& $adb -s $serial shell getprop sys.boot_completed 2>&1 | Out-String).Trim()
    if ($bootFlag -ne '1') {
        Write-Host 'Android non ha ancora completato avvio. Apri la finestra dellemulatore e completa la configurazione.'
        throw 'Avvio Android non completato. Ripeti dopo la comparsa della schermata iniziale.'
    }
    $deviceAbi = (& $adb -s $serial shell getprop ro.product.cpu.abilist 2>&1 | Out-String).Trim()
    Write-Host ("Emulatore attivo: $serial; ABI dichiarate: $deviceAbi") -ForegroundColor Green

    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'WEmulDroid-FirstTest' }
    if ($release.draft -or $release.prerelease) { throw 'La release restituita non e una stabile pubblicata.' }
    $releaseTag = [string]$release.tag_name
    $apk = @($release.assets | Where-Object { $_.name -eq 'app-release.apk' } | Select-Object -First 1)
    if ($apk.Count -ne 1 -or -not $apk[0].browser_download_url) {
        throw "Release $releaseTag: APK non trovato. Non utilizzare AAB come APK."
    }
    $releaseUrl = [string]$apk[0].browser_download_url
    if (-not $releaseUrl.StartsWith('https://github.com/pilialvu75-hue/Ai-orchestrator-riserva/releases/download/', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'URL APK inatteso: download bloccato.'
    }
    $safeTag = $releaseTag -replace '[^a-zA-Z0-9._+-]', '_'
    New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null
    $apkPath = Join-Path $downloadFolder ("ai-orchestrator-$safeTag.apk")
    $bytes = [long]$apk[0].size
    $approxMb = [Math]::Round($bytes / 1MB, 1)
    Write-Host "Release: $releaseTag; APK: $approxMb MB"
    if (-not (Test-Path -LiteralPath $apkPath) -or (Get-Item -LiteralPath $apkPath).Length -ne $bytes) {
        Write-Host 'Il download iniziale richiede connessione a Internet e spazio su disco.'
        $consent = Read-Host "Vuoi scaricare $approxMb MB da GitHub e installare l'APK nell'emulatore? Digita SI"
        if ($consent -ne 'SI') { throw 'Test annullato prima del download.' }
        $part = "$apkPath.partial"
        try {
            Invoke-WebRequest -Uri $releaseUrl -OutFile $part -UseBasicParsing
            if ((Get-Item -LiteralPath $part).Length -ne $bytes) {
                throw 'Dimensione APK non corrispondente alla release GitHub.'
            }
            Move-Item -LiteralPath $part -Destination $apkPath -Force
        } finally {
            if (Test-Path -LiteralPath $part) {
                Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host ('APK SHA-256 locale: ' + (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)
    try {
        $apkAbis = @($zip.Entries |
            Where-Object { $_.FullName -match '^lib/([^/]+)/[^/]+\.so$' } |
            ForEach-Object { [regex]::Match($_.FullName, '^lib/([^/]+)/').Groups[1].Value } |
            Sort-Object -Unique)
    } finally { $zip.Dispose() }
    Write-Host ('Architetture APK: ' + ($apkAbis -join ', '))
    if ($apkAbis.Count -eq 1 -and $apkAbis[0] -eq 'arm64-v8a' -and $deviceAbi -notmatch 'arm64-v8a') {
        Write-Warning 'App solo ARM64 e emulatore non dichiara ARM64: potrebbe apparire INSTALL_FAILED_NO_MATCHING_ABIS.'
    }

    Write-Host 'Installazione APK nell emulatore...'
    $installOutput = (& $adb -s $serial install -r $apkPath 2>&1 | Out-String)
    Check-LastExit 'adb install'
    Write-Host $installOutput.Trim()

    $startOutput = (& $adb -s $serial shell am start -n 'com.aiorchestrator/.MainActivity' 2>&1 | Out-String)
    Check-LastExit 'Avvio AI-Orchestrator'
    Write-Host $startOutput.Trim()

    Start-Sleep -Seconds 5
    $memOutput = (& $adb -s $serial shell dumpsys meminfo $package 2>&1 | Out-String)
    $cpuOutput = (& $adb -s $serial shell dumpsys cpuinfo 2>&1 | Out-String)
    $logTail = ((& $adb -s $serial logcat -d -t 120 2>&1) | Out-String)
    $state = 'INSTALL_AND_LAUNCH_COMMAND_OK'
    $details = 'adb install e am start completati. Serve conferma visiva che UI e funzioni siano operative.'
    Write-Host ''
    Write-Host 'Comando di avvio riuscito. Verifica ora la finestra Android: l interfaccia dell app compare?' -ForegroundColor Green
}
catch {
    $state = 'FAILED_OR_CANCELLED'
    $details = $_.Exception.Message
    Write-Host ''
    Write-Host ('Test non completato: ' + $details) -ForegroundColor Red
    if ($serial -and (Test-Path -LiteralPath $adb)) {
        try { $logTail = ((& $adb -s $serial logcat -d -t 120 2>&1) | Out-String) } catch {}
    }
}
finally {
    try { Write-Report } catch { Write-Warning ("Impossibile salvare il report: " + $_.Exception.Message) }
}
if ($state -ne 'INSTALL_AND_LAUNCH_COMMAND_OK') { exit 1 }
exit 0
