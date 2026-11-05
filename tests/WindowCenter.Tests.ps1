$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\WindowMode.ps1')

function Assert-Centered([Drawing.Rectangle]$old, [Drawing.Rectangle]$area, [bool]$preserveSize) {
    $result = Get-WEmulDroidCenteredBounds -WindowBounds $old -WorkingArea $area
    if ($result.Left -lt $area.Left -or $result.Top -lt $area.Top -or
        $result.Right -gt $area.Right -or $result.Bottom -gt $area.Bottom) {
        throw 'Android window remains outside working area.'
    }
    if ([Math]::Abs(($result.Left + $result.Width / 2) - ($area.Left + $area.Width / 2)) -gt 1 -or
        [Math]::Abs(($result.Top + $result.Height / 2) - ($area.Top + $area.Height / 2)) -gt 1) {
        throw 'Android window is not geometrically centered.'
    }
    if ($preserveSize -and ($result.Width -ne $old.Width -or $result.Height -ne $old.Height)) {
        throw 'Window size changed although it fits in the working area.'
    }
    return $result
}

$screen = [Drawing.Rectangle]::new(0,0,1450,914)
# Real symptom: Android partly outside the top edge on an ASUS desktop.
$offTop = [Drawing.Rectangle]::new(345,-400,415,870)
$centered = Assert-Centered -old $offTop -area $screen -preserveSize $true
if ($centered.Top -le 0) { throw 'Off-screen Android title bar was not recovered.' }
# Oversized window: fit within working area without deleting/altering the AVD.
$large = Assert-Centered -old ([Drawing.Rectangle]::new(-200,-800,1400,1500)) -area $screen -preserveSize $false
if ($large.Height -ge 914) { throw 'Oversized emulator was not constrained to visible height.' }
# Multiple displays with negative coordinates: honor selected monitor working area.
$secondary = [Drawing.Rectangle]::new(-1920,0,1920,1040)
[void](Assert-Centered -old ([Drawing.Rectangle]::new(0,-500,440,860)) -area $secondary -preserveSize $true)
# A window which is already centered stays in place; no cumulative drift.
$again = Get-WEmulDroidCenteredBounds -WindowBounds $centered -WorkingArea $screen
if ($again -ne $centered) { throw 'Repeated center caused unwanted movement.' }

Write-Host 'PASS: Android window centering keeps title visible, preserves size, handles oversized and multi-monitor windows.'
