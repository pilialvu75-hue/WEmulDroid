$ErrorActionPreference = 'Stop'
$labPath = Join-Path (Join-Path $PSScriptRoot '..') 'src\Lab.ps1'
$lab = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $labPath).Path)

$fullscreenStart = $lab.IndexOf('$btnFullscreen.Add_Click({')
$fullscreenEnd = $lab.IndexOf('$btnApkFolder.Add_Click({', $fullscreenStart)
if ($fullscreenStart -lt 0 -or $fullscreenEnd -le $fullscreenStart) {
    throw 'Could not find complete fullscreen event handler.'
}
$fullscreen = $lab.Substring($fullscreenStart, $fullscreenEnd - $fullscreenStart)
if ($fullscreen.Contains('Invoke-DeviceCommand')) {
    throw 'Fullscreen must never execute Android guest WM commands.'
}

$compatStart = $lab.IndexOf('$btnGamesMode.Add_Click({')
$compatEnd = $lab.IndexOf('$btnScreenReset.Add_Click({', $compatStart)
if ($compatStart -lt 0 -or $compatEnd -le $compatStart) { throw 'Game compatibility handler missing.' }
$compat = $lab.Substring($compatStart, $compatEnd - $compatStart)
foreach ($must in @(
    "@('shell','wm','user-rotation','free')",
    "@('shell','wm','size','reset')",
    "@('shell','wm','density','reset')",
    'gamesModeConfirm'
)) {
    if (-not $compat.Contains($must)) {
        throw ('Game compatibility lacks reversible display restore: ' + $must)
    }
}
foreach ($prohibited in @('wipe-data', 'uninstall', 'factory-reset','pm clear')) {
    if ($compat.ToLowerInvariant().Contains($prohibited)) {
        throw 'Game compatibility must never wipe the Google Play profile.'
    }
}
Write-Host 'PASS: fullscreen does not force guest display; game recovery restores defaults without erasing AVD.'
