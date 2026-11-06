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
    Write-Host 'PASS: RAM snapshots work before Android starts, preserve history, require no AVD.'
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
