# WEmulDroid v0.2 — smoke test leggero, autonomo, SENZA APK esterni.
# Prova esclusivamente l'app di sistema Impostazioni Android.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$SdkRoot = Join-Path $env:LOCALAPPDATA 'AivexusAndroidLab\Sdk'
$ReportsRoot = Join-Path $env:LOCALAPPDATA 'AivexusAndroidLab\Reports'
$Adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
$Emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
$AvdName = 'Aivexus_API_35'
$serial = $null
$state = 'NOT_STARTED'
$message = ''
$meminfo = ''
$cpuinfo = ''
$gfxinfo = ''
$abi = ''
$settingsOutput = ''
$emulatorInfo = ''

function Own-Serial {
    $lines = @(& $script:Adb devices 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'Impossibile comunicare con adb.' }
    foreach ($line in $lines) {
        if ($line -match '^(emulator-[0-9]+)\s+device\b') {
            $candidate = $Matches[1]
            $name = (& $script:Adb -s $candidate emu avd name 2>&1 | Out-String)
            if ($LASTEXITCODE -eq 0 -and $name -match [regex]::Escape($script:AvdName)) {
                return $candidate
            }
        }
    }
    return $null
}
function Is-Boot-Complete([string]$device) {
    $boot = (& $script:Adb -s $device shell getprop sys.boot_completed 2>&1 | Out-String).Trim()
    return ($LASTEXITCODE -eq 0 -and $boot -eq '1')
}
function Save-Results {
    New-Item -ItemType Directory -Path $script:ReportsRoot -Force | Out-Null
    $filename = 'android-smoke-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt'
    $path = Join-Path $script:ReportsRoot $filename
    $content = @(
        'WEMULDROID - TEST DI BASE INDIPENDENTE'
        ('Data: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
        ('Risultato comandi: ' + $script:state)
        ('Dettagli: ' + $script:message)
        ('AVD: ' + $script:AvdName)
        ('Seriale: ' + $script:serial)
        ('ABI dichiarate: ' + $script:abi)
        'Test eseguito: avvio Android + applicazione Impostazioni preinstallata'
        'IMPORTANTE: i dati dell emulatore NON sono consumi reali su smartphone.'
        'IMPORTANTE: comando am start riuscito NON certifica che la UI sia visualizzata.'
        ''
        '=== EMULATORE ==='
        $script:emulatorInfo
        '=== AVVIO IMPOSTAZIONI ==='
        $script:settingsOutput
        '=== RAM (dumpsys meminfo com.android.settings) ==='
        $script:meminfo
        '=== CPU (dumpsys cpuinfo) ==='
        $script:cpuinfo
        '=== FRAME / RENDERING (dumpsys gfxinfo com.android.settings) ==='
        $script:gfxinfo
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Report salvato in: $path" -ForegroundColor Cyan
}

try {
    Write-Host ''
    Write-Host 'WEmulDroid — Prova leggera Android + Impostazioni' -ForegroundColor Cyan
    Write-Host 'Nessun APK esterno, nessuna compilazione, nessun accesso ai progetti Aivexus.'
    if (-not (Test-Path -LiteralPath $Adb) -or -not (Test-Path -LiteralPath $Emulator)) {
        throw 'SDK mancante: avvia prima Installa-Android.cmd.'
    }
    $serial = Own-Serial
    if (-not $serial) {
        $avds = (& $Emulator -list-avds | Out-String)
        if ($avds -notmatch ('(?m)^' + [regex]::Escape($AvdName) + '\s*$')) {
            throw 'Dispositivo Aivexus_API_35 mancante: completa Installa-Android.cmd.'
        }
        Write-Host 'Avvio dell emulatore...'
        Start-Process -FilePath $Emulator -ArgumentList @('-avd', $AvdName, '-gpu', 'auto', '-memory', '2048', '-cores', '2')
    } else {
        Write-Host "Emulatore gia collegato: $serial"
    }
    $deadline = (Get-Date).AddMinutes(5)
    $bootOk = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 4
        $serial = Own-Serial
        if ($serial -and (Is-Boot-Complete $serial)) {
            $bootOk = $true
            break
        }
    }
    if (-not $bootOk) { throw 'Android non e pronto entro 5 minuti. Controlla virtualizzazione e WHPX.' }
    Write-Host 'Android avviato.' -ForegroundColor Green
    $abi = (& $Adb -s $serial shell getprop ro.product.cpu.abilist 2>&1 | Out-String).Trim()
    $emulatorInfo = (& $Emulator -version 2>&1 | Out-String)
    Write-Host 'Avvio della app Impostazioni Android...'
    $settingsOutput = (& $Adb -s $serial shell am start -a android.settings.SETTINGS 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $settingsOutput -match '(?i)(Error:|Exception:)') {
        throw ('Impossibile aprire Impostazioni: ' + $settingsOutput)
    }
    Start-Sleep -Seconds 3
    $meminfo = (& $Adb -s $serial shell dumpsys meminfo com.android.settings 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Errore nella raccolta della RAM.' }
    $cpuinfo = (& $Adb -s $serial shell dumpsys cpuinfo 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Errore nella raccolta della CPU.' }
    $gfxinfo = (& $Adb -s $serial shell dumpsys gfxinfo com.android.settings 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Errore nella raccolta dei dati di rendering.' }
    $state = 'COMMANDS_OK'
    $message = 'Boot completato, am start Impostazioni riuscito, meminfo/cpuinfo/gfxinfo raccolti. Richiesta conferma visiva.'
    Write-Host 'Comandi completati. Guarda la finestra Android: appare Impostazioni?' -ForegroundColor Green
}
catch {
    $state = 'FAILED'
    $message = $_.Exception.Message
    Write-Host ('PROBLEMA: ' + $message) -ForegroundColor Red
}
finally {
    try { Save-Results } catch { Write-Warning ('Report non salvato: ' + $_.Exception.Message) }
}
if ($state -ne 'COMMANDS_OK') { exit 1 }
exit 0
