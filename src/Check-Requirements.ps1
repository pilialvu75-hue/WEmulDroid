# WEmulDroid — verifica prerequisiti Windows, non modifica il computer.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$SdkRoot = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Sdk'
$reportRoot = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Reports'
$lines = New-Object System.Collections.Generic.List[string]

function Add-Result([string]$label, [string]$value) {
    $line = $label + ': ' + $value
    $script:lines.Add($line)
    Write-Host $line
}
function Bool-Label($value) {
    if ($null -eq $value) { return 'non rilevabile' }
    if ($value) { return 'si' }
    return 'no'
}
try {
    Add-Result 'Test' 'WEmulDroid - prerequisiti (sola lettura)'
    Add-Result 'Data' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $cpu = @(Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1)[0]
    Add-Result 'Windows' ($os.Caption + ' ' + $os.Version)
    Add-Result 'CPU' $cpu.Name
    Add-Result 'RAM fisica' ('{0:N1} GiB' -f ($cs.TotalPhysicalMemory / 1GB))
    Add-Result 'CPU virtualizzazione da firmware (CIM)' (Bool-Label $cpu.VirtualizationFirmwareEnabled)
    Add-Result 'CPU SLAT (CIM)' (Bool-Label $cpu.SecondLevelAddressTranslationExtensions)
    Add-Result 'Hypervisor presente' (Bool-Label $cs.HypervisorPresent)
    if ($cs.HypervisorPresent -and
        (($false -eq $cpu.VirtualizationFirmwareEnabled) -or
         ($false -eq $cpu.SecondLevelAddressTranslationExtensions))) {
        Add-Result 'NOTA virtualizzazione' 'Hypervisor Windows gia presente: i flag CIM virtualizzazione/SLAT possono essere non affidabili. Non dedurre assenza di supporto hardware.'
        Add-Result 'Verifica firmware' 'Apri Gestione attivita > Prestazioni > CPU > Virtualizzazione: Abilitata/Disabilitata.'
    }

    $whpx = 'non rilevabile; controlla Funzionalita Windows'
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName 'HypervisorPlatform' -ErrorAction Stop
        $whpx = [string]$feature.State
    } catch {
        try {
            $f = Get-CimInstance -ClassName Win32_OptionalFeature -Filter "Name='HypervisorPlatform'" -ErrorAction Stop
            if ($f) {
                $stateLabel = switch ([int]$f.InstallState) {
                    1 { 'abilitata' }
                    2 { 'disabilitata' }
                    3 { 'assente' }
                    default { 'non nota' }
                }
                $whpx = 'InstallState=' + [string]$f.InstallState + ' (' + $stateLabel + ')'
            }
        } catch {}
    }
    Add-Result 'Windows Hypervisor Platform' $whpx
    if ($whpx -like '*InstallState=2*' -or $whpx -eq 'Disabled' -or $whpx -eq 'disabilitata') {
        Add-Result 'Prossimo passo WHPX' 'Win+R > optionalfeatures > Piattaforma Hypervisor Windows > attiva > OK > riavvio.'
    }

    $sdkDrive = [System.IO.Path]::GetPathRoot($SdkRoot)
    $driveId = $sdkDrive.TrimEnd('\')
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='" + $driveId + "'")
    if ($disk) {
        Add-Result 'Spazio libero disco SDK' ('{0:N1} GiB' -f ($disk.FreeSpace / 1GB))
        if ($disk.FreeSpace -lt 12GB) {
            Add-Result 'Avviso disco' 'meno di 12 GiB: l installazione potrebbe non riuscire'
        }
    }
    if ($cs.TotalPhysicalMemory -lt 8GB) {
        Add-Result 'Avviso RAM' 'meno di 8 GiB: Android Emulator potrebbe essere molto lento'
    }
    $javaCmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaVersion = (& $javaCmd.Source -version 2>&1 | Select-Object -First 1 | Out-String).Trim()
        Add-Result 'Java nel PATH' $javaVersion
    } elseif ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        Add-Result 'Java JAVA_HOME' $env:JAVA_HOME
    } else {
        Add-Result 'Java' 'non trovato nel PATH (Setup puo cercare Android Studio JBR)'
    }
    $emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
    $adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
    Add-Result 'SDK installato' (Bool-Label (Test-Path -LiteralPath $emulator))
    Add-Result 'ADB installato' (Bool-Label (Test-Path -LiteralPath $adb))
    if (Test-Path -LiteralPath $emulator) {
        $accel = (& $emulator -accel-check 2>&1 | Out-String).Trim()
        Add-Result 'Risultato accel-check' ($accel -replace '\r?\n',' | ')
    }
    Add-Result 'Conclusione' 'Diagnosi preliminare. Avvio Android e prestazioni restano da verificare sul PC.'
}
catch {
    Add-Result 'Errore diagnostica' $_.Exception.Message
}
finally {
    try {
        New-Item -Path $reportRoot -ItemType Directory -Force | Out-Null
        $filename = 'prerequisiti-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt'
        $reportPath = Join-Path $reportRoot $filename
        [System.IO.File]::WriteAllLines($reportPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Report salvato: $reportPath" -ForegroundColor Cyan
    } catch {
        Write-Warning ('Impossibile salvare il report: ' + $_.Exception.Message)
    }
}
) {
        Add-Result 'Prossimo passo WHPX' 'Win+R > optionalfeatures > Piattaforma Hypervisor Windows > attiva > OK > riavvio.'
    }

    $sdkDrive = [System.IO.Path]::GetPathRoot($SdkRoot)
    $driveId = $sdkDrive.TrimEnd('\')
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='" + $driveId + "'")
    if ($disk) {
        Add-Result 'Spazio libero disco SDK' ('{0:N1} GiB' -f ($disk.FreeSpace / 1GB))
        if ($disk.FreeSpace -lt 12GB) {
            Add-Result 'Avviso disco' 'meno di 12 GiB: l installazione potrebbe non riuscire'
        }
    }
    if ($cs.TotalPhysicalMemory -lt 8GB) {
        Add-Result 'Avviso RAM' 'meno di 8 GiB: Android Emulator potrebbe essere molto lento'
    }
    $javaCmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaVersion = (& $javaCmd.Source -version 2>&1 | Select-Object -First 1 | Out-String).Trim()
        Add-Result 'Java nel PATH' $javaVersion
    } elseif ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        Add-Result 'Java JAVA_HOME' $env:JAVA_HOME
    } else {
        Add-Result 'Java' 'non trovato nel PATH (Setup puo cercare Android Studio JBR)'
    }
    $emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
    $adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
    Add-Result 'SDK installato' (Bool-Label (Test-Path -LiteralPath $emulator))
    Add-Result 'ADB installato' (Bool-Label (Test-Path -LiteralPath $adb))
    if (Test-Path -LiteralPath $emulator) {
        $accel = (& $emulator -accel-check 2>&1 | Out-String).Trim()
        Add-Result 'Risultato accel-check' ($accel -replace '\r?\n',' | ')
    }
    Add-Result 'Conclusione' 'Diagnosi preliminare. Avvio Android e prestazioni restano da verificare sul PC.'
}
catch {
    Add-Result 'Errore diagnostica' $_.Exception.Message
}
finally {
    try {
        New-Item -Path $reportRoot -ItemType Directory -Force | Out-Null
        $filename = 'prerequisiti-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt'
        $reportPath = Join-Path $reportRoot $filename
        [System.IO.File]::WriteAllLines($reportPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Report salvato: $reportPath" -ForegroundColor Cyan
    } catch {
        Write-Warning ('Impossibile salvare il report: ' + $_.Exception.Message)
    }
}
