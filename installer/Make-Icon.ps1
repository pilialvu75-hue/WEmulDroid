[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WEmulDroidIconNative {
  [DllImport("user32.dll", CharSet = CharSet.Auto)]
  public static extern bool DestroyIcon(IntPtr iconHandle);
}
'@
$bitmap = New-Object System.Drawing.Bitmap(64,64)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(16,24,44))
    $border = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(65,215,233), 4)
    $graphics.DrawRectangle($border, 3,3,58,58)
    $border.Dispose()
    $font = New-Object System.Drawing.Font('Segoe UI',35,[System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(244,247,254))
    $graphics.DrawString('W',$font,$brush,4,4)
    $font.Dispose()
    $brush.Dispose()
    $graphics.FillEllipse([System.Drawing.Brushes]::DodgerBlue,45,45,10,10)
    $handle = $bitmap.GetHicon()
    try {
        $icon = [System.Drawing.Icon]::FromHandle($handle)
        try {
            $folder = Split-Path -Parent $OutputPath
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            $stream = [IO.File]::Create($OutputPath)
            try { $icon.Save($stream) } finally { $stream.Dispose() }
        } finally { $icon.Dispose() }
    } finally {
        [void][WEmulDroidIconNative]::DestroyIcon($handle)
    }
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
if ((Get-Item -LiteralPath $OutputPath).Length -lt 200) { throw 'Icon output invalid' }
Write-Host "Desktop icon generated: $OutputPath"
