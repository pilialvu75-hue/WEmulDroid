# WEmulDroid: read-only diagnostic bundle for ONE selected AVD.
# No data is uploaded; user reviews local files before sharing.
function Assert-DiagnosticPackage([string]$packageName) {
    if ([string]::IsNullOrWhiteSpace($packageName)) { return $null }
    if ($packageName -notmatch '^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$' -or $packageName.Length -gt 200) {
        throw 'Nome package Android non valido.'
    }
    return $packageName
}

function Collect-WEmulDroidDiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Adb,
        [Parameter(Mandatory)][string]$Serial,
        [Parameter(Mandatory)][string]$ReportsRoot,
        [string]$PackageName
    )
    if ($Serial -notmatch '^emulator-[0-9]+$') { throw 'Diagnostica consentita solo per un emulatore Android.' }
    if (-not (Test-Path -LiteralPath $Adb -PathType Leaf)) { throw 'adb.exe non trovato.' }
    $PackageName = Assert-DiagnosticPackage $PackageName

    $outFolder = Join-Path $ReportsRoot ('diagnostic-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' +
        ([guid]::NewGuid().ToString('N').Substring(0, 6)))
    New-Item -ItemType Directory -Path $outFolder -Force | Out-Null
    $results = New-Object System.Collections.Generic.List[string]
    $results.Add('WEmulDroid - diagnostica locale, NON inviata su internet')
    $results.Add('Data: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $results.Add('Dispositivo: ' + $Serial)
    $results.Add('Package richiesto: ' + $(if ($PackageName) { $PackageName } else { '(nessuno)' }))
    $results.Add('Nota: log, screenshot e nomi delle app possono contenere dati personali.')
    $results.Add('Il comando ADB completato non dimostra che l app funzioni.')
    $failures = 0
    $common = @(
        @{Name='Android'; Args=@('shell','getprop','ro.build.version.release')},
        @{Name='ABI'; Args=@('shell','getprop','ro.product.cpu.abilist')},
        @{Name='Display size'; Args=@('shell','wm','size')},
        @{Name='Display density'; Args=@('shell','wm','density')},
        @{Name='CPU'; Args=@('shell','dumpsys','cpuinfo')},
        @{Name='RAM'; Args=@('shell','dumpsys','meminfo')}
    )
    if ($PackageName) {
        $common += @{Name='RAM app'; Args=@('shell','dumpsys','meminfo',$PackageName)}
        $common += @{Name='Rendering app'; Args=@('shell','dumpsys','gfxinfo',$PackageName)}
    }
    foreach ($check in $common) {
        try {
            $output = (& $Adb -s $Serial @($check.Args) 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) { throw ('ADB exit code ' + $LASTEXITCODE) }
            $results.Add('')
            $results.Add('== ' + $check.Name + ' ==')
            $results.Add($output)
        } catch {
            $failures++
            $results.Add('ERROR ' + $check.Name + ': ' + $_.Exception.Message)
        }
    }

    # Capture only the last 120 log lines, never a full unbounded logcat.
    try {
        $logs = (& $Adb -s $Serial logcat -d -t 120 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'logcat non disponibile.' }
        [IO.File]::WriteAllText((Join-Path $outFolder 'logcat-last120.txt'), $logs,
            (New-Object Text.UTF8Encoding($false)))
    } catch {
        $failures++
        $results.Add('ERROR logcat: ' + $_.Exception.Message)
    }

    # Safe binary screenshot via screencap + adb pull rather than PowerShell stdout redirection.
    $remote = '/sdcard/Download/wemuldroid-diagnostic.png'
    $imagePath = Join-Path $outFolder 'screenshot.png'
    try {
        $capture = (& $Adb -s $Serial shell screencap -p $remote 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw ('screencap: ' + $capture.Trim()) }
        $pull = (& $Adb -s $Serial pull $remote $imagePath 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $imagePath)) {
            throw ('pull screenshot: ' + $pull.Trim())
        }
    } catch {
        $failures++
        $results.Add('ERROR screenshot: ' + $_.Exception.Message)
    } finally {
        try { & $Adb -s $Serial shell rm -f $remote 2>&1 | Out-Null } catch {}
    }
    $results.Add('')
    $results.Add('Numero operazioni non riuscite: ' + $failures)
    $results.Add('Stato: ' + $(if ($failures -eq 0) { 'RACCOLTA COMPLETATA' } else { 'RACCOLTA PARZIALE' }))
    [IO.File]::WriteAllLines((Join-Path $outFolder 'report.txt'), $results,
        (New-Object Text.UTF8Encoding($false)))
    return [pscustomobject]@{ Folder=$outFolder; Failures=$failures }
}
