# Tests pure functions only; do not run emulator, ADB or network.
$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\Snapshots.ps1')
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\Diagnostics.ps1')

foreach ($valid in @('baseline', 'WEmulDroid_baseline', 'a-01_2')) {
    if ((Assert-WEmulDroidSnapshotName $valid) -cne $valid) {
        throw ("Nome snapshot alterato: " + $valid)
    }
}
foreach ($invalid in @('', 'nome con spazi', '../escape', 'a;b', '--bad', ('x' * 33), 'ç')) {
    $rejected = $false
    try { [void](Assert-WEmulDroidSnapshotName $invalid) } catch { $rejected = $true }
    if (-not $rejected) { throw ("Nome snapshot non rifiutato: " + $invalid) }
}
if ((Assert-DiagnosticPackage 'com.example.app') -ne 'com.example.app') {
    throw 'Package Android valido non accettato.'
}
foreach ($invalid in @('a', 'spazi app', '; rm -rf', '../bad', 'com.package/thing')) {
    $rejected = $false
    try { [void](Assert-DiagnosticPackage $invalid) } catch { $rejected = $true }
    if (-not $rejected) { throw ("Package non rifiutato: " + $invalid) }
}
if ($null -ne (Assert-DiagnosticPackage $null)) {
    throw 'Il package diagnostico facoltativo deve accettare null.'
}
Write-Host 'PASS: nomi snapshot e package diagnostici validati offline.'
