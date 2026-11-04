# WEmulDroid official GitHub Releases update check and package staging.
# No automatic network requests; functions run only when the user opens Settings > Updates.
$script:UpdateRepository = 'pilialvu75-hue/WEmulDroid'
$script:UpdateApi = 'https://api.github.com/repos/pilialvu75-hue/WEmulDroid/releases?per_page=20'
$script:UpdatePrefix = 'https://github.com/pilialvu75-hue/WEmulDroid/releases/download/'
$script:UpdateBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [IO.Path]::GetTempPath() }
$script:UpdateRoot = Join-Path $script:UpdateBase 'WEmulDroid\Updates'

function Compare-WEmulDroidVersion([string]$first, [string]$second) {
    $pattern = '^v?(\d+)\.(\d+)\.(\d+)(?:-(beta|rc)(?:\.(\d+))?)?$'
    if (-not ($first -match $pattern)) { throw "Invalid version: $first" }
    $a = @([long]$Matches[1], [long]$Matches[2], [long]$Matches[3])
    $aRank = if ($Matches[4] -eq 'beta') { 0 } elseif ($Matches[4] -eq 'rc') { 1 } else { 2 }
    $aPatch = if ($Matches[5]) { [long]$Matches[5] } else { 0 }
    if (-not ($second -match $pattern)) { throw "Invalid version: $second" }
    $b = @([long]$Matches[1], [long]$Matches[2], [long]$Matches[3])
    $bRank = if ($Matches[4] -eq 'beta') { 0 } elseif ($Matches[4] -eq 'rc') { 1 } else { 2 }
    $bPatch = if ($Matches[5]) { [long]$Matches[5] } else { 0 }
    for ($i = 0; $i -lt 3; $i++) {
        if ($a[$i] -gt $b[$i]) { return 1 }
        if ($a[$i] -lt $b[$i]) { return -1 }
    }
    if ($aRank -gt $bRank) { return 1 }
    if ($aRank -lt $bRank) { return -1 }
    if ($aPatch -gt $bPatch) { return 1 }
    if ($aPatch -lt $bPatch) { return -1 }
    return 0
}

function Find-WEmulDroidUpdate([string]$Current, [bool]$IncludeBeta) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = @(Invoke-RestMethod -Uri $script:UpdateApi -Headers @{
        'User-Agent'='WEmulDroid-Updater/0.1'; 'Accept'='application/vnd.github+json'
    } -TimeoutSec 25)
    $best = $null
    foreach ($release in $releases) {
        if ($release.draft -or ($release.prerelease -and -not $IncludeBeta)) { continue }
        $tag = [string]$release.tag_name
        if ($tag -notmatch '^v?\d+\.\d+\.\d+(?:-(?:beta|rc)(?:\.\d+)?)?$') { continue }
        if ((Compare-WEmulDroidVersion $tag $Current) -le 0) { continue }
        $zipName = 'WEmulDroid-' + $tag + '.zip'
        $shaName = $zipName + '.sha256'
        $zipAsset = @($release.assets | Where-Object { $_.name -eq $zipName })
        $shaAsset = @($release.assets | Where-Object { $_.name -eq $shaName })
        if ($zipAsset.Count -ne 1 -or $shaAsset.Count -ne 1) { continue }
        $zipUrl = [string]$zipAsset[0].browser_download_url
        $shaUrl = [string]$shaAsset[0].browser_download_url
        if (-not $zipUrl.StartsWith($script:UpdatePrefix, [StringComparison]::Ordinal) -or
            -not $shaUrl.StartsWith($script:UpdatePrefix, [StringComparison]::Ordinal)) { continue }
        $result = [pscustomobject]@{ Tag=$tag; ZipUrl=$zipUrl; ShaUrl=$shaUrl; IsBeta=[bool]$release.prerelease }
        if (-not $best -or (Compare-WEmulDroidVersion $result.Tag $best.Tag) -gt 0) { $best=$result }
    }
    return $best
}

function Save-WEmulDroidUpdate($Release) {
    if (-not $Release -or $Release.Tag -notmatch '^v?\d+\.\d+\.\d+(?:-(?:beta|rc)(?:\.\d+)?)?$') {
        throw 'Invalid release version.'
    }
    if (-not ([string]$Release.ZipUrl).StartsWith($script:UpdatePrefix) -or
        -not ([string]$Release.ShaUrl).StartsWith($script:UpdatePrefix)) {
        throw 'Download URL not from official GitHub repository.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $directory = Join-Path $script:UpdateRoot 'pending'
    New-Item -Path $directory -ItemType Directory -Force | Out-Null
    $zip = Join-Path $directory 'release.zip'
    $checksum = Join-Path $directory 'release.sha256'
    foreach ($file in @($zip,$checksum)) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    try {
        Invoke-WebRequest -Uri $Release.ShaUrl -OutFile $checksum -UseBasicParsing -TimeoutSec 30
        Invoke-WebRequest -Uri $Release.ZipUrl -OutFile $zip -UseBasicParsing -TimeoutSec 120
        if ((Get-Item -LiteralPath $zip).Length -gt 150MB) { throw 'Update exceeds 150 MiB source-package limit.' }
        $expected = ([IO.File]::ReadAllText($checksum) -split '\s+')[0].Trim().ToLowerInvariant()
        if ($expected -notmatch '^[0-9a-f]{64}$') { throw 'Invalid SHA-256 file.' }
        $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -cne $expected) { throw 'Downloaded package SHA-256 mismatch.' }

        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($zip)
        try {
            $names = @($archive.Entries | ForEach-Object { $_.FullName })
            foreach ($name in $names) {
                $part = $name.Replace('\','/')
                if ($part.StartsWith('/') -or $part -match '(?i)(^|/)\.\.(/|$)' -or
                    $part -match '^[A-Za-z]:' -or $part.Contains([char]0)) {
                    throw 'Unsafe file name in update ZIP.'
                }
                if ($part -notmatch '^(src/|docs/|\.github/|[^/]+$)') {
                    throw "Unexpected update path: $part"
                }
            }
            if ($names -notcontains 'VERSION.txt' -or
                $names -notcontains 'Avvia-Android.cmd' -or
                $names -notcontains 'src/Lab.ps1' -or
                $names -notcontains 'src/Updates.ps1') {
                throw 'Update ZIP is missing required launcher files.'
            }
        } finally {
            $archive.Dispose()
        }
        [IO.File]::WriteAllText((Join-Path $directory 'release.tag'), [string]$Release.Tag,
            (New-Object Text.UTF8Encoding($false)))
        return $directory
    } catch {
        foreach ($file in @($zip, $checksum)) {
            if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }
        }
        throw
    }
}
