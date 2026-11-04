$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'src' 'Updates.ps1')

$cases = @(
    @('v0.8.0-beta.1','v0.7.0',1),
    @('v0.8.0-beta.1','v0.8.0-beta.1',0),
    @('v0.8.0-beta.2','v0.8.0-beta.1',1),
    @('v0.8.0-rc.1','v0.8.0-beta.8',1),
    @('v0.8.0','v0.8.0-rc.1',1),
    @('v0.8.0','v0.8.0',0),
    @('v0.8.0-beta.1','v0.8.0',-1),
    @('v1.0.0','v0.99.99',1),
    @('v0.7.0','v0.8.0-beta.1',-1)
)
foreach ($test in $cases) {
    $actual = Compare-WEmulDroidVersion $test[0] $test[1]
    if ($actual -ne $test[2]) {
        throw "Unexpected version ordering: $($test[0]) vs $($test[1]): $actual"
    }
}
foreach ($bad in @('http://bad','v1.2','v1.2.3-test','v1.2.3/../../')) {
    $rejected = $false
    try { [void](Compare-WEmulDroidVersion $bad 'v0.0.0') } catch { $rejected=$true }
    if (-not $rejected) { throw "Invalid version accepted: $bad" }
}
Write-Host 'PASS: WEmulDroid official update version sorting and input validation'


# Reproduce real GitHub releases response shape and Windows PowerShell 5.1
# nested-array behavior. Neither test calls GitHub or downloads any package.
$json = @'
[
  {
    "tag_name": "v0.8.0-beta.2", "draft": false, "prerelease": true,
    "assets": [
      {"name": "WEmulDroid-v0.8.0-beta.2.zip", "browser_download_url": "https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.2/WEmulDroid-v0.8.0-beta.2.zip"},
      {"name": "WEmulDroid-v0.8.0-beta.2.zip.sha256", "browser_download_url": "https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.2/WEmulDroid-v0.8.0-beta.2.zip.sha256"}
    ]
  },
  {
    "tag_name": "v0.8.0-beta.1", "draft": false, "prerelease": true,
    "assets": [
      {"name": "WEmulDroid-v0.8.0-beta.1.zip", "browser_download_url": "https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.1/WEmulDroid-v0.8.0-beta.1.zip"},
      {"name": "WEmulDroid-v0.8.0-beta.1.zip.sha256", "browser_download_url": "https://github.com/pilialvu75-hue/WEmulDroid/releases/download/v0.8.0-beta.1/WEmulDroid-v0.8.0-beta.1.zip.sha256"}
    ]
  }
]
'@
$decoded = ConvertFrom-Json -InputObject $json
$nest = ,$decoded
foreach ($payload in @($decoded, $nest)) {
    $result = Select-WEmulDroidRelease -ReleaseData $payload -Current 'v0.8.0-beta.1' -IncludeBeta $true
    if (-not $result -or $result.Tag -ne 'v0.8.0-beta.2' -or
        $result.ZipUrl -notmatch 'v0[.]8[.]0-beta[.]2/[A-Za-z0-9._-]+[.]zip$') {
        throw 'Updater cannot discover beta.2 from beta.1 in actual GitHub JSON shape.'
    }
    if (Select-WEmulDroidRelease -ReleaseData $payload -Current 'v0.8.0-beta.1' -IncludeBeta $false) {
        throw 'Stable channel must not offer prerelease beta assets.'
    }
    if (Select-WEmulDroidRelease -ReleaseData $payload -Current 'v0.8.0-beta.2' -IncludeBeta $true) {
        throw 'Current beta must not be offered as a newer release.'
    }
}
Write-Host 'PASS: GitHub array and nested-array release selection locates v0.8.0-beta.2.'
