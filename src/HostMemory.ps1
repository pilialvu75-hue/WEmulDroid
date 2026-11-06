# Read-only Windows host memory snapshots, including when no AVD is running.
# Does not change AVD RAM, Windows services or security settings.
function Get-WEmulDroidHostMemorySnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('prima','android','gioco')][string]$Phase)
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $total = [long]$os.TotalVisibleMemorySize * 1024
    $free = [long]$os.FreePhysicalMemory * 1024
    if ($total -le 0 -or $free -lt 0 -or $free -gt $total) { throw 'Windows returned invalid physical memory values.' }
    $emulators = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^(emulator|qemu-system.*)$'
    })
    $processRows = @($emulators | ForEach-Object {
        [pscustomobject]@{
            Name = [string]$_.ProcessName
            Pid = [int]$_.Id
            WorkingSetMiB = [math]::Round(([double]$_.WorkingSet64 / 1MB),1)
            PrivateMiB = [math]::Round(([double]$_.PrivateMemorySize64 / 1MB),1)
            CpuSecondsTotal = [math]::Round(([double]$_.CPU),1)
        }
    })
    [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        Phase = $Phase
        TotalRamMiB = [math]::Round($total / 1MB,1)
        AvailableRamMiB = [math]::Round($free / 1MB,1)
        UsedRamMiB = [math]::Round(($total-$free) / 1MB,1)
        MemoryPressurePercent = [math]::Round((100.0*($total-$free)/$total),1)
        EmulatorWorkingSetMiB = [math]::Round((@($processRows | Measure-Object -Property WorkingSetMiB -Sum)[0].Sum),1)
        EmulatorProcesses = $processRows
    }
}

function Save-WEmulDroidHostMemorySnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('prima','android','gioco')][string]$Phase,
        [Parameter(Mandatory)][string]$ReportsRoot
    )
    $snapshot = Get-WEmulDroidHostMemorySnapshot -Phase $Phase
    $out = Join-Path $ReportsRoot 'memory-checkpoints'
    New-Item -Path $out -ItemType Directory -Force | Out-Null
    $name = 'memory-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $Phase + '-' + [guid]::NewGuid().ToString('N').Substring(0,6)
    $path = Join-Path $out ($name + '.json')
    $snapshot | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
    $csv = Join-Path $out 'memory-history.csv'
    $row = [pscustomobject]@{
        Timestamp=$snapshot.Timestamp
        Phase=$snapshot.Phase
        TotalRamMiB=$snapshot.TotalRamMiB
        AvailableRamMiB=$snapshot.AvailableRamMiB
        UsedRamMiB=$snapshot.UsedRamMiB
        MemoryPressurePercent=$snapshot.MemoryPressurePercent
        EmulatorWorkingSetMiB=$snapshot.EmulatorWorkingSetMiB
    }
    if (Test-Path -LiteralPath $csv) {
        $row | Export-Csv -LiteralPath $csv -NoTypeInformation -Append -Encoding UTF8
    } else {
        $row | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    }
    return [pscustomobject]@{ Path=$path; Csv=$csv; Snapshot=$snapshot }
}

# Compare the most recent ordered checkpoints. This is a MEMORY trend only:
# it cannot attribute a specific game crash to RAM without Android crash logs.
function Get-WEmulDroidMemoryComparison {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$CsvPath,
          [int]$MaxMinutes = 30)
    if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) {
        return [pscustomobject]@{ Comparable=$false; Reason='No memory history available.' }
    }
    $samples = @(Import-Csv -LiteralPath $CsvPath)
    if ($samples.Count -lt 3) {
        return [pscustomobject]@{ Comparable=$false; Reason='Three checkpoints are required: prima, android, gioco.' }
    }
    $gameIndex = -1
    for ($i=$samples.Count-1; $i -ge 0; $i--) {
        if ($samples[$i].Phase -eq 'gioco') { $gameIndex=$i; break }
    }
    if ($gameIndex -lt 2) {
        return [pscustomobject]@{ Comparable=$false; Reason='No completed three-phase sequence.' }
    }
    $game=$samples[$gameIndex]
    $androidIndex=-1
    for ($i=$gameIndex-1; $i -ge 0; $i--) {
        if ($samples[$i].Phase -eq 'android') { $androidIndex=$i; break }
        if ($samples[$i].Phase -eq 'gioco') { break }
    }
    if ($androidIndex -lt 1) {
        return [pscustomobject]@{ Comparable=$false; Reason='Android checkpoint missing before game checkpoint.' }
    }
    $android=$samples[$androidIndex]
    $beforeIndex=-1
    for ($i=$androidIndex-1; $i -ge 0; $i--) {
        if ($samples[$i].Phase -eq 'prima') { $beforeIndex=$i; break }
        if ($samples[$i].Phase -eq 'android' -or $samples[$i].Phase -eq 'gioco') { break }
    }
    if ($beforeIndex -lt 0) {
        return [pscustomobject]@{ Comparable=$false; Reason='Baseline checkpoint missing before Android.' }
    }
    $before=$samples[$beforeIndex]
    try {
        $culture=[Globalization.CultureInfo]::InvariantCulture
        $t0=[datetimeoffset]::Parse($before.Timestamp,$culture)
        $t1=[datetimeoffset]::Parse($android.Timestamp,$culture)
        $t2=[datetimeoffset]::Parse($game.Timestamp,$culture)
        if ($t0 -gt $t1 -or $t1 -gt $t2 -or ($t2-$t0).TotalMinutes -gt $MaxMinutes) {
            return [pscustomobject]@{ Comparable=$false; Reason='Checkpoints are out of order or over 30 minutes apart.' }
        }
        $m0=[double]::Parse($before.AvailableRamMiB,$culture)
        $m1=[double]::Parse($android.AvailableRamMiB,$culture)
        $m2=[double]::Parse($game.AvailableRamMiB,$culture)
        if ($m0 -lt 0 -or $m1 -lt 0 -or $m2 -lt 0) { throw 'Negative RAM sample' }
        return [pscustomobject]@{
            Comparable=$true
            AvailableBeforeMiB=$m0
            AvailableAndroidMiB=$m1
            AvailableGameMiB=$m2
            AndroidDeltaMiB=[math]::Round($m1-$m0,1)
            GameDeltaMiB=[math]::Round($m2-$m1,1)
            TotalDeltaMiB=[math]::Round($m2-$m0,1)
            Warning=$(if ($m2 -lt 1024) { 'Less than 1 GiB available; memory pressure is possible, not proven as crash cause.' } else { 'No cause assigned: also inspect Android crash diagnostics.' })
        }
    } catch {
        return [pscustomobject]@{ Comparable=$false; Reason=('Invalid memory history: ' + $_.Exception.Message) }
    }
}
