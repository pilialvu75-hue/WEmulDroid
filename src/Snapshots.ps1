# WEmulDroid - snapshot AVD official commands, no Google/Android images bundled.
# This file defines functions only and does not run ADB when imported.

function Assert-WEmulDroidSnapshotName([string]$name) {
    if ($name -cnotmatch '^[A-Za-z][A-Za-z0-9_-]{0,31}$') {
        throw 'Nome snapshot non valido: usa 1-32 caratteri alfanumerici, _ o -, iniziando con lettera.'
    }
    return $name
}

function Invoke-WEmulDroidSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Adb,
        [Parameter(Mandatory)][string]$Serial,
        [Parameter(Mandatory)][ValidateSet('list','save','load')][string]$Action,
        [string]$Name
    )
    if ($Serial -notmatch '^emulator-[0-9]+$') {
        throw 'Operazione consentita esclusivamente su un seriale emulator-<porta>.'
    }
    if (-not (Test-Path -LiteralPath $Adb -PathType Leaf)) { throw 'adb.exe non trovato.' }
    $argList = @('-s', $Serial, 'emu', 'avd', 'snapshot', $Action)
    if ($Action -ne 'list') { $argList += (Assert-WEmulDroidSnapshotName $Name) }

    $result = (& $Adb @argList 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $result -match '(?im)^\s*(KO|ERROR|FAIL(?:ED)?)\b|snapshot.*not found|not supported') {
        throw ("Comando snapshot $Action fallito: " + $result.Trim())
    }
    return $result.Trim()
}
