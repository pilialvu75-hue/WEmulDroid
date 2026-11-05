$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\ScreenProfiles.ps1')

function Assert-Size([int]$index,[int]$w,[int]$h,[int]$dpi,[string]$orientation) {
    $profile=Get-WEmulDroidScreenProfile -Index $index
    if ($profile.Width -ne $w -or $profile.Height -ne $h -or
        $profile.Dpi -ne $dpi -or $profile.Orientation -ne $orientation) {
        throw "Wrong dimensions for screen preset $index: $($profile | Out-String)"
    }
    $commands=@(Get-WEmulDroidScreenCommands -Profile $profile)
    if ($commands.Count -ne 3) { throw "Expected 3 wm commands for profile $index" }
    $expectedRotation = if ($orientation -eq 'landscape') { '1' } else { '0' }
    if (($commands[2].Arguments -join ' ') -ne ('shell wm user-rotation lock ' + $expectedRotation)) {
        throw "Wrong orientation for profile $index"
    }
}
Assert-Size 0 720 1280 320 'portrait'
Assert-Size 1 1080 2400 420 'portrait'
Assert-Size 2 1280 800 200 'landscape'
Assert-Size 3 1600 900 240 'landscape'

foreach ($area in @(
    [Drawing.Rectangle]::new(0,0,1920,1080),
    [Drawing.Rectangle]::new(0,0,1366,768),
    [Drawing.Rectangle]::new(-1920,0,1920,1040),
    [Drawing.Rectangle]::new(0,0,2560,1440)
)) {
    $p=Get-WEmulDroidScreenProfile -Index 4 -MonitorArea $area
    if ($p.Orientation -ne 'landscape' -or $p.Width -le $p.Height -or
        $p.Width -gt [Math]::Min(1600,$area.Width-96) -or
        $p.Height -gt [Math]::Min(900,$area.Height-96) -or
        $p.Dpi -gt 240) {
        throw "Monitor-fit selected oversized or portrait device: $($p | Out-String)"
    }
    # The Android wm size setting is portrait because 90-degree rotation
    # produces landscape. No more 1600x2560 portrait 'tablet'.
    $pair = $p.Size.Split('x')
    if ([int]$pair[0] -ge [int]$pair[1]) {
        throw 'Underlying AVD base size must remain portrait for rotation.'
    }
}
if ((Get-WEmulDroidScreenProfile -Index 4).Width -ne 1600) {
    throw 'Full HD ASUS should choose tablet 1600x900, not 1600x2560.'
}
Write-Host 'PASS: landscape tablet 16:9/16:10, monitor-aware fitting and realistic DPI.'
