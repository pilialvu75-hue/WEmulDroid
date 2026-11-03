# Windows PowerShell 5.1+. Run through Installa-Android.cmd.
[CmdletBinding()]
param(
    [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA 'AivexusAndroidLab\Sdk')
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$avdName = 'Aivexus_API_35'
$imagePackage = 'system-images;android-35;google_apis;x86_64'
$toolsUrl = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
$toolsSha256 = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'

function Find-JavaHome {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($env:JAVA_HOME) { $candidates.Add($env:JAVA_HOME) }
    if ($env:ProgramFiles) {
        $candidates.Add((Join-Path $env:ProgramFiles 'Android\Android Studio\jbr'))
        foreach ($base in @('Eclipse Adoptium', 'Java', 'Microsoft')) {
            $folder = Join-Path $env:ProgramFiles $base
            if (Test-Path -LiteralPath $folder) {
                Get-ChildItem -LiteralPath $folder -Directory -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending | ForEach-Object { $candidates.Add($_.FullName) }
            }
        }
    }
    $javaCmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $candidates.Add((Split-Path -Parent (Split-Path -Parent $javaCmd.Source)))
    }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'bin\java.exe'))) {
            return $candidate
        }
    }
    return $null
}

function Assert-ExitCode([string]$step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$step non riuscito (codice $LASTEXITCODE). Consulta i messaggi sopra."
    }
}

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' AIVEXUS Android Desktop Lab - Setup Android 15' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "SDK dedicato: $SdkRoot"
Write-Host 'I componenti vengono scaricati direttamente da Google.'
Write-Host 'Leggi i termini Android SDK: https://developer.android.com/studio/terms'
Write-Host "Saranno scaricati diversi GB di dati. Verifica lo spazio disponibile."
$answer = Read-Host "Dopo avere letto i termini, vuoi continuare? Digita SI"
if ($answer -ne 'SI') {
    Write-Host 'Installazione annullata senza modificare il sistema.'
    exit 1
}

try {
    $javaHome = Find-JavaHome
    if (-not $javaHome) {
        Write-Warning 'Java JDK 17+ non trovato.'
        $installJava = Read-Host 'Vuoi provare a installare Temurin JDK 17 con winget? Digita SI'
        if ($installJava -eq 'SI' -and (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
            & winget.exe install -e --id EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements
            Assert-ExitCode 'Installazione Java'
            $javaHome = Find-JavaHome
        }
        if (-not $javaHome) {
            throw 'Installa JDK 17 o successivo da https://adoptium.net/ e ripeti Installa-Android.cmd'
        }
    }
    $env:JAVA_HOME = $javaHome
    $env:PATH = (Join-Path $javaHome 'bin') + ';' + $env:PATH
    Write-Host "Java: $javaHome" -ForegroundColor Green

    $cmdlineRoot = Join-Path $SdkRoot 'cmdline-tools\latest'
    $sdkManager = Join-Path $cmdlineRoot 'bin\sdkmanager.bat'
    New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null

    if (-not (Test-Path -LiteralPath $sdkManager)) {
        $work = Join-Path ([System.IO.Path]::GetTempPath()) ('aivexus-sdk-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        try {
            $archive = Join-Path $work 'cmdline-tools.zip'
            Write-Host 'Scaricamento strumenti Android ufficiali...'
            Invoke-WebRequest -Uri $toolsUrl -OutFile $archive -UseBasicParsing
            $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant()
            if ($actual -ne $toolsSha256) {
                throw "Checksum errato! Atteso $toolsSha256, trovato $actual. Download rifiutato."
            }
            Write-Host 'Checksum SHA-256 verificato.' -ForegroundColor Green
            $expanded = Join-Path $work 'unpacked'
            Expand-Archive -LiteralPath $archive -DestinationPath $expanded -Force
            $source = Join-Path $expanded 'cmdline-tools'
            if (-not (Test-Path -LiteralPath (Join-Path $source 'bin\sdkmanager.bat'))) {
                throw 'Struttura imprevista nello ZIP Android.'
            }
            New-Item -ItemType Directory -Path $cmdlineRoot -Force | Out-Null
            Copy-Item -Path (Join-Path $source '*') -Destination $cmdlineRoot -Recurse -Force
        } finally {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $env:ANDROID_SDK_ROOT = $SdkRoot
    Write-Host ''
    Write-Host 'Accetta esplicitamente le licenze richieste da Google (y/n):' -ForegroundColor Yellow
    & $sdkManager "--sdk_root=$SdkRoot" --licenses
    Assert-ExitCode 'Accettazione licenze SDK'

    Write-Host ''
    Write-Host 'Installazione emulator, platform-tools e immagine Android 15 (x86_64)...'
    & $sdkManager "--sdk_root=$SdkRoot" 'platform-tools' 'emulator' $imagePackage
    Assert-ExitCode 'Installazione pacchetti Android'

    $emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
    $avdManager = Join-Path $cmdlineRoot 'bin\avdmanager.bat'
    if (-not (Test-Path -LiteralPath $emulator)) { throw 'emulator.exe non trovato.' }
    if (-not (Test-Path -LiteralPath $avdManager)) { throw 'avdmanager.bat non trovato.' }

    $avds = (& $emulator -list-avds | Out-String)
    if ($avds -notmatch ('(?m)^' + [regex]::Escape($avdName) + '\s*$')) {
        Write-Host "Creazione dispositivo virtuale $avdName..."
        'no' | & $avdManager create avd -n $avdName -k $imagePackage -d 'pixel_6'
        Assert-ExitCode 'Creazione AVD'
    } else {
        Write-Host "Dispositivo virtuale gia presente: $avdName"
    }

    Write-Host ''
    Write-Host 'Verifica accelerazione hardware (WHPX):'
    & $emulator -accel-check
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Accelerazione non disponibile. Attiva Windows Hypervisor Platform nelle funzionalita Windows e riavvia il PC. Controlla anche la virtualizzazione nel BIOS/UEFI.'
    }
    Write-Host ''
    Write-Host 'Setup terminato. Avvia Avvia-Android.cmd.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('ERRORE: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
