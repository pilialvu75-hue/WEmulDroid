$ErrorActionPreference='Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\InstallerUpdates.ps1')
$json = @'
[
  {"tag_name":"v0.9.0-beta.2","draft":false,"prerelease":true,
   "assets":[
      {"name":"WEmulDroid-Setup-v0.9.0-beta.2.exe","browser_download_url":"https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.9.0-beta.2/WEmulDroid-Setup-v0.9.0-beta.2.exe"},
      {"name":"WEmulDroid-Setup-v0.9.0-beta.2.exe.sha256","browser_download_url":"https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.9.0-beta.2/WEmulDroid-Setup-v0.9.0-beta.2.exe.sha256"}
    ]},
  {"tag_name":"v0.9.0-beta.1","draft":false,"prerelease":true,
   "assets":[
      {"name":"WEmulDroid-Setup-v0.9.0-beta.1.exe","browser_download_url":"https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.9.0-beta.1/WEmulDroid-Setup-v0.9.0-beta.1.exe"},
      {"name":"WEmulDroid-Setup-v0.9.0-beta.1.exe.sha256","browser_download_url":"https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.9.0-beta.1/WEmulDroid-Setup-v0.9.0-beta.1.exe.sha256"}
    ]},
  {"tag_name":"v0.8.0-beta.3","draft":false,"prerelease":true,"assets":[{"name":"WEmulDroid-v0.8.0-beta.3.zip","browser_download_url":"https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.3/WEmulDroid-v0.8.0-beta.3.zip"}]}
]
'@
$data = ConvertFrom-Json -InputObject $json
foreach ($shape in @($data, (,$data))) {
    $found = Select-WEmulDroidInstallerUpdate -Releases $shape -Current 'v0.9.0-beta.1' -IncludeBeta $true
    if (-not $found -or $found.Tag -ne 'v0.9.0-beta.2' -or $found.ExeUrl -notmatch 'beta[.]2[.]exe$') {
        throw 'Cannot discover beta 2 official installer.'
    }
    if (Select-WEmulDroidInstallerUpdate -Releases $shape -Current 'v0.9.0-beta.1' -IncludeBeta $false) {
        throw 'Stable channel wrongly offers beta installers.'
    }
}
Write-Host 'PASS: official installer discovery recognizes new beta and ignores old source ZIP.'
