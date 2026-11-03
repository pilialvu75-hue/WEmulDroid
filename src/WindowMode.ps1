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
    $rect = New-Object WEmulDroidNativeWindow+Rect
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
