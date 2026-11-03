# Test puramente offline delle regole di importazione APK. Nessun emulator o rete.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'src' 'ApkInstall.ps1')

function Expect-Reject([string]$value) {
    $rejected = $false
    try { [void](Assert-ApkUri $value) } catch { $rejected = $true }
    if (-not $rejected) { throw ("URL pericoloso non rifiutato: " + $value) }
}
foreach ($blocked in @(
    'http://example.com/legit.apk',
    'file:///tmp/legit.apk',
    'https://localhost/test.apk',
    'https://127.0.0.1/test.apk',
    'https://192.168.1.20/test.apk',
    'https://intranet.local/legit.apk',
    'https://user:pass@example.com/download.apk'
)) {
    Expect-Reject $blocked
}
$uri = Resolve-ApkDownloadUri 'https://github.com/someone/some-project/releases/download/v1.0/test.apk'
if ($uri.Host -ne 'github.com' -or -not $uri.AbsolutePath.EndsWith('/test.apk')) {
    throw 'GitHub asset HTTPS non riconosciuto.'
}
$uri = Resolve-ApkDownloadUri 'https://example.com/releases/latest.apk?token=redacted'
if ($uri.AbsolutePath -ne '/releases/latest.apk') {
    throw 'URL APK con query string non riconosciuto.'
}
$rejected = $false
try { [void](Resolve-ApkDownloadUri 'https://example.com/app.aab') } catch { $rejected=$true }
if (-not $rejected) { throw 'AAB erroneamente considerato APK.' }

$base = Join-Path ([IO.Path]::GetTempPath()) ("wemuldroid-apktest-" + [Guid]::NewGuid().ToString('N'))
$folder = Join-Path $base 'archive'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
try {
    $bytes = New-Object byte[] 4096
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $random.GetBytes($bytes) } finally { $random.Dispose() }
    [IO.File]::WriteAllBytes((Join-Path $folder 'AndroidManifest.xml'), $bytes)
    $apkPath = Join-Path $base 'valid.apk'
    [IO.Compression.ZipFile]::CreateFromDirectory($folder, $apkPath)
    $info = Assert-LocalApk $apkPath
    if ($info.Extension -ne '.apk') { throw 'APK locale non riconosciuto.' }
    $notApk = Join-Path $base 'bad.apk'
    [IO.File]::WriteAllBytes($notApk,$bytes)
    $rejected = $false
    try { [void](Assert-LocalApk $notApk) } catch { $rejected=$true }
    if (-not $rejected) { throw 'Archivio APK malformato accettato.' }
    Write-Host 'PASS: controlli URL, estensione e formato APK (test offline).'
}
finally {
    Remove-Item -LiteralPath $base -Recurse -Force -ErrorAction SilentlyContinue
}
