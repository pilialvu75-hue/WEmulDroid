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
