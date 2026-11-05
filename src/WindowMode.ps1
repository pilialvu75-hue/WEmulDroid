# Fullscreen senza dipendere dalle scorciatoie dell'emulatore.
# Sceglie solo una finestra Android Emulator che contiene l'esatto nome del nostro AVD.
# Funzioni da importare tramite dot-sourcing in Lab.ps1.
if (-not ('WEmulDroidNativeWindow' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
public static class WEmulDroidNativeWindow {
  [StructLayout(LayoutKind.Sequential)]
  public struct Rect { public int Left, Top, Right, Bottom; }
  public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lparam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr data);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int maxChars);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
  [DllImport("user32.dll", EntryPoint="GetWindowLongW")] public static extern int GetWindowLong(IntPtr hwnd, int index);
  [DllImport("user32.dll", EntryPoint="SetWindowLongW")] public static extern int SetWindowLong(IntPtr hwnd, int index, int value);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int width, int height, uint flags);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
  public static IntPtr[] FindEmulatorWindow(string avd) {
    var windows = new List<IntPtr>();
    EnumWindows(delegate(IntPtr hwnd, IntPtr data) {
      if (!IsWindowVisible(hwnd)) return true;
      var buf = new StringBuilder(512);
      GetWindowText(hwnd, buf, buf.Capacity);
      string title = buf.ToString();
      if (title.IndexOf(avd, StringComparison.OrdinalIgnoreCase) >= 0 &&
          title.IndexOf("Android Emulator", StringComparison.OrdinalIgnoreCase) >= 0)
        windows.Add(hwnd);
      return true;
    }, IntPtr.Zero);
    return windows.ToArray();
  }
}
'@
}
$script:FullscreenWindowState = $null

function Set-EmulatorWindowFullscreen([string]$avdName) {
    if ($script:FullscreenWindowState) {
        return Restore-EmulatorWindow
    }
    $matches = [WEmulDroidNativeWindow]::FindEmulatorWindow($avdName)
    if ($matches.Count -ne 1) {
        throw 'Non riesco a identificare univocamente la finestra Android di questo AVD. Clicca sulla finestra Android e prova Alt+Invio (se supportato dalla versione Emulator). Nessuna altra finestra e stata modificata.'
    }
    $hwnd = $matches[0]
    $rect = [WEmulDroidNativeWindow+Rect]::new()
    if (-not [WEmulDroidNativeWindow]::GetWindowRect($hwnd, [ref]$rect)) {
        throw 'Impossibile leggere la geometria della finestra Android.'
    }
    $style = [WEmulDroidNativeWindow]::GetWindowLong($hwnd, -16)
    $monitor = [System.Windows.Forms.Screen]::FromHandle($hwnd).Bounds
    $noFrame = $style -band (-bnot 0x00CF0000)
    [void][WEmulDroidNativeWindow]::SetWindowLong($hwnd, -16, $noFrame)
    $width = $monitor.Width
    $height = $monitor.Height
    if (-not [WEmulDroidNativeWindow]::SetWindowPos($hwnd, [IntPtr]::Zero, $monitor.Left, $monitor.Top, $width, $height, 0x0060)) {
        [void][WEmulDroidNativeWindow]::SetWindowLong($hwnd, -16, $style)
        [void][WEmulDroidNativeWindow]::SetWindowPos($hwnd, [IntPtr]::Zero, $rect.Left, $rect.Top, ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top), 0x0060)
        throw 'Impossibile impostare fullscreen: finestra ripristinata.'
    }
    $script:FullscreenWindowState = @{ Handle=$hwnd; Style=$style; Rect=$rect }
    return 'Fullscreen applicato alla finestra Android selezionata. Premere di nuovo per ripristinare.'
}

function Restore-EmulatorWindow {
    if (-not $script:FullscreenWindowState) { return 'Fullscreen non attivo.' }
    $state = $script:FullscreenWindowState
    $script:FullscreenWindowState = $null
    if (-not [WEmulDroidNativeWindow]::IsWindow($state.Handle)) {
        return 'La finestra Android non esiste piu.'
    }
    $r = $state.Rect
    [void][WEmulDroidNativeWindow]::SetWindowLong($state.Handle, -16, $state.Style)
    if (-not [WEmulDroidNativeWindow]::SetWindowPos($state.Handle, [IntPtr]::Zero, $r.Left, $r.Top, ($r.Right-$r.Left), ($r.Bottom-$r.Top), 0x0060)) {
        throw 'Ripristino fullscreen non riuscito; riavvia la finestra Android se necessario.'
    }
    return 'Finestra Android ripristinata al formato originale.'
}


# Center the selected emulator inside the usable monitor area. This calculation
# is pure so CI can test off-screen/oversized windows without Android hardware.
function Get-WEmulDroidCenteredBounds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Drawing.Rectangle]$WindowBounds,
        [Parameter(Mandatory)][System.Drawing.Rectangle]$WorkingArea
    )
    if ($WorkingArea.Width -lt 240 -or $WorkingArea.Height -lt 240) {
        throw 'The usable monitor area is too small for Android.'
    }
    # Reserve margin so window title and close controls remain reachable.
    $margin = 12
    $maxWidth = $WorkingArea.Width - ($margin * 2)
    $maxHeight = $WorkingArea.Height - ($margin * 2)
    $width = [Math]::Min([Math]::Max(1, $WindowBounds.Width), $maxWidth)
    $height = [Math]::Min([Math]::Max(1, $WindowBounds.Height), $maxHeight)
    $left = $WorkingArea.Left + [int][Math]::Floor(($WorkingArea.Width - $width) / 2)
    $top = $WorkingArea.Top + [int][Math]::Floor(($WorkingArea.Height - $height) / 2)
    return [System.Drawing.Rectangle]::new($left, $top, $width, $height)
}

function Set-WEmulDroidWindowCentered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AvdName,
        [System.Windows.Forms.Form]$OwnerForm
    )
    # Never change another app, another emulator profile, or fullscreen mode.
    if ($script:FullscreenWindowState) { return $false }
    $matches = @([WEmulDroidNativeWindow]::FindEmulatorWindow($AvdName))
    if ($matches.Count -eq 0) { return $false }
    if ($matches.Count -ne 1) {
        throw 'Più finestre Android corrispondono al dispositivo selezionato. Nessuna finestra modificata.'
    }
    $handle = $matches[0]
    $bounds = [WEmulDroidNativeWindow+Rect]::new()
    if (-not [WEmulDroidNativeWindow]::GetWindowRect($handle, [ref]$bounds)) {
        throw 'Impossibile leggere la posizione della finestra Android.'
    }
    $windowRectangle = [System.Drawing.Rectangle]::new(
        $bounds.Left, $bounds.Top, $bounds.Right - $bounds.Left, $bounds.Bottom - $bounds.Top)
    $screen = if ($OwnerForm) {
        [System.Windows.Forms.Screen]::FromControl($OwnerForm)
    } else {
        [System.Windows.Forms.Screen]::FromHandle($handle)
    }
    $target = Get-WEmulDroidCenteredBounds -WindowBounds $windowRectangle -WorkingArea $screen.WorkingArea
    # 0x0014 = SWP_NOZORDER | SWP_NOACTIVATE: do not steal focus or
    # unexpectedly put this Android window above the user's other apps.
    if (-not [WEmulDroidNativeWindow]::SetWindowPos($handle, [IntPtr]::Zero,
            $target.Left, $target.Top, $target.Width, $target.Height, 0x0014)) {
        throw 'Windows non ha consentito di centrare la finestra Android.'
    }
    return $true
}


# Resize a normal Qt emulator window to use the monitor without
# stretching pixels or modifying another application's window.
function Get-WEmulDroidFittedBounds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Drawing.Rectangle]$WorkingArea,
        [Parameter(Mandatory)][ValidateRange(0.45,3.0)][double]$GuestAspect
    )
    if ($WorkingArea.Width -lt 640 -or $WorkingArea.Height -lt 480) {
        throw 'Monitor area too small to fit Android.'
    }
    # Approximate Windows title bar / emulator side-toolbar allowances.
    # Qt retains the device's own aspect ratio when the outer window resizes.
    $toolbar = 66
    $chrome = 46
    $maxGuestWidth = [Math]::Max(320, $WorkingArea.Width - $toolbar - 36)
    $maxGuestHeight = [Math]::Max(300, $WorkingArea.Height - $chrome - 28)
    $guestWidth = [int][Math]::Floor([Math]::Min($maxGuestWidth, $maxGuestHeight * $GuestAspect))
    $guestHeight = [int][Math]::Floor($guestWidth / $GuestAspect)
    $outerWidth = $guestWidth + $toolbar
    $outerHeight = $guestHeight + $chrome
    $left = $WorkingArea.Left + [int][Math]::Floor(($WorkingArea.Width - $outerWidth) / 2)
    $top = $WorkingArea.Top + [int][Math]::Floor(($WorkingArea.Height - $outerHeight) / 2)
    return [System.Drawing.Rectangle]::new($left,$top,$outerWidth,$outerHeight)
}

function Set-WEmulDroidWindowFitted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AvdName,
        [Parameter(Mandatory)][ValidateRange(0.45,3.0)][double]$GuestAspect,
        [System.Windows.Forms.Form]$OwnerForm
    )
    if ($script:FullscreenWindowState) { return $false }
    $matches = @([WEmulDroidNativeWindow]::FindEmulatorWindow($AvdName))
    if ($matches.Count -eq 0) { return $false }
    if ($matches.Count -ne 1) {
        throw 'Ambiguous Android Emulator window. Other windows were not modified.'
    }
    $hwnd = $matches[0]
    $screen = if ($OwnerForm) {
        [System.Windows.Forms.Screen]::FromControl($OwnerForm)
    } else {
        [System.Windows.Forms.Screen]::FromHandle($hwnd)
    }
    $target = Get-WEmulDroidFittedBounds -WorkingArea $screen.WorkingArea -GuestAspect $GuestAspect
    if (-not [WEmulDroidNativeWindow]::SetWindowPos($hwnd,[IntPtr]::Zero,
        $target.Left,$target.Top,$target.Width,$target.Height,0x0014)) {
        throw 'Qt Android window could not be resized. No AVD data was changed.'
    }
    return $true
}


# Smart presentation: never paint the unused desktop black when the Android
# content is portrait or does not match the monitor aspect ratio.
function Get-WEmulDroidPresentationMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(0.45,3.0)][double]$GuestAspect,
        [Parameter(Mandatory)][System.Drawing.Rectangle]$MonitorArea
    )
    if ($MonitorArea.Width -le 0 -or $MonitorArea.Height -le 0) {
        throw 'Invalid display geometry.'
    }
    $monitorAspect = [double]$MonitorArea.Width / [double]$MonitorArea.Height
    if ($GuestAspect -lt 1.20 -or
        [Math]::Abs($GuestAspect - $monitorAspect) -gt 0.12) {
        return 'fit'
    }
    return 'fullscreen'
}
