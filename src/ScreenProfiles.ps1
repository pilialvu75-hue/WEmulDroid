# Display profiles for Android guest. Logical size is stored PORTRAIT
# when target orientation is landscape (Android rotates the base display).
# Pure selection code: does not touch AVD, accounts, or Windows graphics.
function Get-WEmulDroidScreenProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(0,4)][int]$Index,
        [System.Drawing.Rectangle]$MonitorArea = [System.Drawing.Rectangle]::new(0,0,1920,1080)
    )
    $result = switch ($Index) {
        0 { [pscustomobject]@{Name='Phone Lite';Size='720x1280';Dpi=320;Orientation='portrait';Width=720;Height=1280} }
        1 { [pscustomobject]@{Name='Phone High';Size='1080x2400';Dpi=420;Orientation='portrait';Width=1080;Height=2400} }
        2 { [pscustomobject]@{Name='Tablet 16:10';Size='800x1280';Dpi=200;Orientation='landscape';Width=1280;Height=800} }
        3 { [pscustomobject]@{Name='Tablet 16:9';Size='900x1600';Dpi=240;Orientation='landscape';Width=1600;Height=900} }
        4 {
            if ($MonitorArea.Width -lt 640 -or $MonitorArea.Height -lt 480) {
                throw 'Display too small for automatic landscape tablet configuration.'
            }
            # Keep the guest at or below the host's useful resolution.
            # Leave room for emulator toolbar / decorations, no pointless 4K.
            $maxWidth = [Math]::Min(1600, $MonitorArea.Width - 96)
            $maxHeight = [Math]::Min(900, $MonitorArea.Height - 96)
            $landscapeWidth = [int]([Math]::Floor(
                [Math]::Min($maxWidth, $maxHeight * 16.0 / 9.0) / 16.0) * 16)
            $landscapeHeight = [int]([Math]::Floor($landscapeWidth * 9.0 / 16.0 / 8.0) * 8)
            if ($landscapeWidth -lt 640 -or $landscapeHeight -lt 360) {
                throw 'Insufficient display area for automatic tablet profile.'
            }
            $density = if ($landscapeWidth -ge 1456) { 240 } elseif ($landscapeWidth -ge 1120) { 200 } else { 180 }
            [pscustomobject]@{
                Name='Tablet Auto'
                Size=($landscapeHeight.ToString() + 'x' + $landscapeWidth.ToString())
                Dpi=$density
                Orientation='landscape'
                Width=$landscapeWidth
                Height=$landscapeHeight
            }
        }
    }
    return $result
}

function Get-WEmulDroidScreenCommands {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Profile)
    if ([string]$Profile.Size -notmatch '^[0-9]{3,4}x[0-9]{3,4}$') {
        throw 'Invalid Android display size.'
    }
    if ([int]$Profile.Dpi -lt 160 -or [int]$Profile.Dpi -gt 480) {
        throw 'Android display density outside supported range.'
    }
    $rotation = if ($Profile.Orientation -eq 'landscape') { '1' } elseif ($Profile.Orientation -eq 'portrait') { '0' } else {
        throw 'Invalid orientation.'
    }
    return @(
        ,@('shell','wm','size',[string]$Profile.Size)
        ,@('shell','wm','density',[string]$Profile.Dpi)
        ,@('shell','wm','user-rotation','lock',$rotation)
    )
}
