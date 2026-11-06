[CmdletBinding()]
param([string]$OutputRoot='')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
if (-not $OutputRoot) { $OutputRoot=Join-Path $repo 'dist-msix' }
$stage=Join-Path $OutputRoot 'staging'
New-Item -ItemType Directory -Force -Path $stage,(Join-Path $stage 'src'),(Join-Path $stage 'Assets') | Out-Null
$tag=([IO.File]::ReadAllText((Join-Path $repo 'VERSION.txt'))).Trim()
if ($tag -notmatch '^v([0-9]+)\.([0-9]+)\.([0-9]+)-beta\.([0-9]+)$') { throw 'Expected beta version.' }
$version="$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
foreach ($file in @('README.md','LICENSE','VERSION.txt')) { Copy-Item -LiteralPath (Join-Path $repo $file) -Destination $stage -Force }
Copy-Item -Path (Join-Path $repo 'src\*.ps1') -Destination (Join-Path $stage 'src') -Force
[IO.File]::WriteAllText((Join-Path $stage 'CHANNEL.txt'),'store-preview')
$ico=Join-Path $stage 'WEmulDroid.ico'
& (Join-Path $repo 'installer\Make-Icon.ps1') -OutputPath $ico
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path $csc)) { throw 'C# compiler missing' }
& $csc /nologo /target:winexe /optimize+ ("/win32icon:$ico") ("/out:$(Join-Path $stage 'WEmulDroid.exe')") /reference:System.Windows.Forms.dll (Join-Path $repo 'installer\WEmulDroidLauncher.cs')
if ($LASTEXITCODE -ne 0) { throw 'Launcher compilation failed' }
Add-Type -AssemblyName System.Drawing
foreach ($item in @(@('StoreLogo.png',50),@('Square44x44Logo.png',44),@('Square150x150Logo.png',150))) {
    $sz=[int]$item[1]
    $bmp=New-Object Drawing.Bitmap($sz,$sz)
    $g=[Drawing.Graphics]::FromImage($bmp)
    try {
        $g.Clear([Drawing.Color]::FromArgb(16,24,44))
        $font=New-Object Drawing.Font('Segoe UI',[float]($sz*0.57),[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
        try { $g.DrawString('W',$font,[Drawing.Brushes]::White,([float]($sz*0.12)),([float]($sz*0.14))) }
        finally { $font.Dispose() }
        $bmp.Save((Join-Path (Join-Path $stage 'Assets') $item[0]),[Drawing.Imaging.ImageFormat]::Png)
    } finally { $g.Dispose(); $bmp.Dispose() }
}
$manifest=@'
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap rescap">
  <Identity Name="WEmulDroid.DesktopPreview" Publisher="CN=WEmulDroidPreview" Version="__VERSION__" ProcessorArchitecture="x64" />
  <Properties>
    <DisplayName>WEmulDroid Preview</DisplayName>
    <PublisherDisplayName>WEmulDroid</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>
  <Resources><Resource Language="en-us" /></Resources>
  <Dependencies><TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0" /></Dependencies>
  <Applications>
    <Application Id="WEmulDroid" Executable="WEmulDroid.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="WEmulDroid Preview" Description="Android virtual device control center"
        Square150x150Logo="Assets\Square150x150Logo.png"
        Square44x44Logo="Assets\Square44x44Logo.png" BackgroundColor="transparent" />
    </Application>
  </Applications>
  <Capabilities><rescap:Capability Name="runFullTrust" /></Capabilities>
</Package>
'@
$manifest=$manifest.Replace('__VERSION__',$version)
[IO.File]::WriteAllText((Join-Path $stage 'AppxManifest.xml'),$manifest,(New-Object Text.UTF8Encoding($false)))
$kits=Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits\10\bin'
$makeappx=Get-ChildItem -Path $kits -Filter makeappx.exe -Recurse -ErrorAction SilentlyContinue |
 Where-Object { $_.FullName -match '\\x64\\makeappx\.exe$' } |
 Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $makeappx) { throw 'Windows SDK MakeAppx.exe missing' }
$package=Join-Path $OutputRoot ('WEmulDroid-StorePreview-'+$tag+'-unsigned.msix')
& $makeappx pack /o /h SHA256 /d $stage /p $package
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $package)) { throw 'MSIX packaging failed' }
Write-Host ('PASS unsigned MSIX preview (CI only): '+$package)
Write-Host 'Not a trusted installer: Store identity and Microsoft certification are still required.'
