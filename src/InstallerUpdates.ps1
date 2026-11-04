# Verified installer-based update channel. No ZIP source replacement.
# Load version ordering logic, but do not call its legacy ZIP updater.
. (Join-Path $PSScriptRoot 'Updates.ps1')

$script:OfficialInstallerPrefix = 'https://github.com/pilialvu75-hue/WEmulDroid/releases/download/'
$script:OfficialInstallerApi = 'https://api.github.com/repos/pilialvu75-hue/WEmulDroid/releases?per_page=20'
$script:OfficialInstallerMaxBytes = 300MB

function Select-WEmulDroidInstallerUpdate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Releases,
          [Parameter(Mandatory)][string]$Current,
          [bool]$IncludeBeta = $false)
    $pending = New-Object System.Collections.Queue
    $pending.Enqueue($Releases)
    $best = $null
    while ($pending.Count -gt 0) {
        $release = $pending.Dequeue()
        if ($null -eq $release) { continue }
        if ($release -is [array]) {
            foreach ($entry in $release) { $pending.Enqueue($entry) }
            continue
        }
        if ($release.draft -or ($release.prerelease -and -not $IncludeBeta)) { continue }
        $tag = [string]$release.tag_name
        if ($tag -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+(?:-(?:beta|rc)\.[0-9]+)?$') { continue }
        if ((Compare-WEmulDroidVersion $tag $Current) -le 0) { continue }
        $setupName = 'WEmulDroid-Setup-' + $tag + '.exe'
        $shaName = $setupName + '.sha256'
        $exe = @($release.assets | Where-Object { $_.name -eq $setupName })
        $sha = @($release.assets | Where-Object { $_.name -eq $shaName })
        if ($exe.Count -ne 1 -or $sha.Count -ne 1) { continue }
        $exeUrl = [string]$exe[0].browser_download_url
        $shaUrl = [string]$sha[0].browser_download_url
        if (-not $exeUrl.StartsWith($script:OfficialInstallerPrefix, [StringComparison]::Ordinal) -or
            -not $shaUrl.StartsWith($script:OfficialInstallerPrefix, [StringComparison]::Ordinal)) { continue }
        $item = [pscustomobject]@{ Tag=$tag; ExeUrl=$exeUrl; ShaUrl=$shaUrl; IsBeta=[bool]$release.prerelease }
        if (-not $best -or (Compare-WEmulDroidVersion $item.Tag $best.Tag) -gt 0) { $best = $item }
    }
    return $best
}

function Find-WEmulDroidInstallerUpdate([string]$Current, [bool]$IncludeBeta) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest -Uri $script:OfficialInstallerApi -UseBasicParsing -Headers @{
        'User-Agent'='WEmulDroid-InstallerUpdater/1.0'
        'Accept'='application/vnd.github+json'
        'Cache-Control'='no-cache'
    } -TimeoutSec 30
    if ([int]$response.StatusCode -ne 200 -or [string]::IsNullOrWhiteSpace([string]$response.Content)) {
        throw 'GitHub release API unavailable. No update was installed.'
    }
    if ($response.Content.Length -gt 2097152) { throw 'GitHub release metadata exceeded size limit.' }
    $data = ConvertFrom-Json -InputObject ([string]$response.Content) -ErrorAction Stop
    return Select-WEmulDroidInstallerUpdate -Releases $data -Current $Current -IncludeBeta $IncludeBeta
}

function Assert-WEmulDroidInstallerSignature {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Installer,
          [Parameter(Mandatory)][string]$InstalledLauncher)

    if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) {
        throw 'Installer is missing.'
    }
    if (-not (Test-Path -LiteralPath $InstalledLauncher -PathType Leaf)) {
        throw 'Current WEmulDroid launcher is missing.'
    }
    $channelFile = Join-Path (Split-Path -Parent $InstalledLauncher) 'CHANNEL.txt'
    if (-not (Test-Path -LiteralPath $channelFile -PathType Leaf)) {
        throw 'Installed WEmulDroid has no update channel marker.'
    }
    $channel = ([IO.File]::ReadAllText($channelFile)).Trim()
    if ($channel -notin @('development','production')) {
        throw 'Unknown installed update channel.'
    }
    # The SHA-256 check is repeated before every launch. In development
    # builds this guards against a changed/incomplete download. It does not
    # establish a Windows publisher identity.
    $shaFile = $Installer + '.sha256'
    if (-not (Test-Path -LiteralPath $shaFile -PathType Leaf)) {
        throw 'No SHA-256 checksum for downloaded installer.'
    }
    $expected = ([IO.File]::ReadAllText($shaFile) -split '\s+')[0].Trim()
    if ($expected -notmatch '^[0-9a-fA-F]{64}$') {
        throw 'Invalid release SHA-256.'
    }
    $actual = (Get-FileHash -LiteralPath $Installer -Algorithm SHA256).Hash
    if ($actual -cne $expected.ToUpperInvariant()) {
        throw 'Installer SHA-256 changed after download.'
    }
    $newSignature = Get-AuthenticodeSignature -LiteralPath $Installer
    if ($channel -eq 'development') {
        # The user opted into the explicitly labelled unsigned development
        # channel. No system-wide protection is altered to execute this file.
        # Official GitHub release URL + SHA-256 + confirmation are required.
        # A future CA-signed release may be installed from this channel.
        return $true
    }

    # Once a CA-signed production version is installed, unsigned installers
    # and changes of publisher identity must be rejected.
    $installed = Get-AuthenticodeSignature -LiteralPath $InstalledLauncher
    if ($installed.Status -ne 'Valid' -or -not $installed.SignerCertificate) {
        throw 'Production WEmulDroid launcher lacks a trusted signature.'
    }
    if ($newSignature.Status -ne 'Valid' -or -not $newSignature.SignerCertificate) {
        throw 'Downloaded installer lacks a trusted publisher signature.'
    }
    if ($installed.SignerCertificate.Thumbprint -cne $newSignature.SignerCertificate.Thumbprint) {
        throw 'Downloaded installer publisher differs from the installed product.'
    }
    return $true
}

function Save-WEmulDroidInstallerUpdate {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Release,
          [Parameter(Mandatory)][string]$InstalledLauncher)
    if ($Release.Tag -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+(?:-(?:beta|rc)\.[0-9]+)?$') {
        throw 'Invalid installer release version.'
    }
    if (-not ([string]$Release.ExeUrl).StartsWith($script:OfficialInstallerPrefix, [StringComparison]::Ordinal) -or
        -not ([string]$Release.ShaUrl).StartsWith($script:OfficialInstallerPrefix, [StringComparison]::Ordinal)) {
        throw 'Update URL outside official GitHub Releases.'
    }
    $dir = Join-Path $script:UpdateRoot 'installer-pending'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $setup = Join-Path $dir ('WEmulDroid-Setup-' + [string]$Release.Tag + '.exe')
    $sha = $setup + '.sha256'
    foreach ($file in @($setup, $sha)) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Release.ShaUrl -OutFile $sha -UseBasicParsing -TimeoutSec 30
        Invoke-WebRequest -Uri $Release.ExeUrl -OutFile $setup -UseBasicParsing -TimeoutSec 180
        $bytes = (Get-Item -LiteralPath $setup).Length
        if ($bytes -lt 1024 -or $bytes -gt $script:OfficialInstallerMaxBytes) { throw 'Unexpected installer size.' }
        $expected = ([IO.File]::ReadAllText($sha) -split '\s+')[0].Trim()
        if ($expected -notmatch '^[0-9a-fA-F]{64}$') { throw 'Invalid SHA-256 metadata.' }
        $real = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash
        if ($real -cne $expected.ToUpperInvariant()) { throw 'SHA-256 mismatch, installer rejected.' }
        [void](Assert-WEmulDroidInstallerSignature -Installer $setup -InstalledLauncher $InstalledLauncher)
        return $setup
    } catch {
        foreach ($file in @($setup,$sha)) {
            if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }
        }
        throw
    }
}
