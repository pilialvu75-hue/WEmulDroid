$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\WindowMode.ps1')

$areas = @(
 [Drawing.Rectangle]::new(0,0,1920,1040),
 [Drawing.Rectangle]::new(0,0,1366,728),
 [Drawing.Rectangle]::new(-1920,0,1920,1040)
)
foreach ($area in $areas) {
 foreach ($aspect in @(0.5625,1.6,1.7777777778,2.0)) {
    $fit=Get-WEmulDroidFittedBounds -WorkingArea $area -GuestAspect $aspect
    if ($fit.Left -lt $area.Left -or $fit.Top -lt $area.Top -or
        $fit.Right -gt $area.Right -or $fit.Bottom -gt $area.Bottom) {
        throw "Fitted Android window escaped the visible monitor area at aspect $aspect."
    }
    # Window chrome is excluded from the useful content aspect.
    $internalAspect = [double]($fit.Width - 66) / ($fit.Height - 46)
    if ([Math]::Abs($internalAspect-$aspect) -gt 0.02) {
        throw "Fitted Android content distorted at aspect $aspect (got $internalAspect)."
    }
 }
}
$area=[Drawing.Rectangle]::new(0,0,1920,1040)
foreach ($aspect in @(0.5625,1.6,1.3333333)) {
 if ((Get-WEmulDroidPresentationMode -GuestAspect $aspect -MonitorArea $area) -ne 'fit') {
    throw "Unused black desktop will remain for aspect $aspect."
 }
}
if ((Get-WEmulDroidPresentationMode -GuestAspect (16.0/9.0) -MonitorArea $area) -ne 'fullscreen') {
    throw 'Matching landscape display should allow full screen.'
}
Write-Host 'PASS: portrait always leaves desktop visible; landscape fitting preserves aspect; multi-monitor and black-margin avoidance.'
