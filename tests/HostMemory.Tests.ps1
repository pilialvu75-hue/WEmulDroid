$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\HostMemory.ps1')

$root = Join-Path ([IO.Path]::GetTempPath()) ('WEmulDroid-MemoryTest-' + [guid]::NewGuid().ToString('N'))
try {
    $report = Save-WEmulDroidHostMemorySnapshot -Phase 'prima' -ReportsRoot $root
    if (-not (Test-Path -LiteralPath $report.Path)) { throw 'Missing snapshot JSON.' }
    if (-not (Test-Path -LiteralPath $report.Csv)) { throw 'Missing RAM history CSV.' }
    if ($report.Snapshot.TotalRamMiB -le 0) { throw 'Invalid total physical RAM.' }
    if ($report.Snapshot.AvailableRamMiB -lt 0 -or
        $report.Snapshot.AvailableRamMiB -gt $report.Snapshot.TotalRamMiB) {
        throw 'Invalid available physical RAM.'
    }
    $report2 = Save-WEmulDroidHostMemorySnapshot -Phase 'android' -ReportsRoot $root
    $report3 = Save-WEmulDroidHostMemorySnapshot -Phase 'gioco' -ReportsRoot $root
    $rows = @(Import-Csv -LiteralPath $report.Csv)
    if ($rows.Count -ne 3) { throw 'Memory checkpoints were not appended.' }
    if (($rows | Select-Object -ExpandProperty Phase) -join ',' -ne 'prima,android,gioco') {
        throw 'Memory phases were not recorded in order.'
    }
    foreach ($row in $rows) {
        if ([double]$row.TotalRamMiB -le 0) { throw 'Invalid CSV sample.' }
    }
    $comparison = Get-WEmulDroidMemoryComparison -CsvPath $report.Csv
    if (-not $comparison.Comparable) { throw ('Three-phase comparison unexpectedly failed: ' + $comparison.Reason) }
    if ([math]::Abs(($comparison.AvailableGameMiB-$comparison.AvailableBeforeMiB)-$comparison.TotalDeltaMiB) -gt 0.11) {
        throw 'Comparison delta is incorrect.'
    }

    # A lone, old or incorrectly ordered checkpoint must not produce a verdict.
    $badCsv = Join-Path $root 'invalid-history.csv'
    @(
        [pscustomobject]@{ Timestamp='2026-11-06T00:00:00+01:00'; Phase='prima'; AvailableRamMiB='8000' },
        [pscustomobject]@{ Timestamp='2026-11-06T02:00:00+01:00'; Phase='android'; AvailableRamMiB='5000' },
        [pscustomobject]@{ Timestamp='2026-11-06T02:02:00+01:00'; Phase='gioco'; AvailableRamMiB='4500' }
    ) | Export-Csv -LiteralPath $badCsv -NoTypeInformation
    $bad = Get-WEmulDroidMemoryComparison -CsvPath $badCsv
    if ($bad.Comparable) { throw 'Stale checkpoints must not be compared.' }
    Write-Host 'PASS: RAM snapshots, delta comparisons and stale checkpoint guard.'
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
