# WEmulDroid - external update process, runs only after the GUI exits.
# Copies application sources only; never modifies Android SDK, AVD or diagnostics.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$StagedDir,
    [Parameter(Mandatory)][int]$WaitPid,
    [Parameter(Mandatory)][ValidateSet('Avvia-Android.cmd','Avvia-PlayStore.cmd')][string]$Launcher
)
$ErrorActionPreference = 'Stop'
$logDir = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Updates'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Join-Path $logDir ('update-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')

function Write-UpdateLog([string]$message) {
    $entry = ((Get-Date -Format 'HH:mm:ss') + ' ' + $message)
    Add-Content -LiteralPath $script:log -Value $entry -Encoding UTF8
    Write-Host $entry
}

$backedUp = @()
$created = @()
try {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot 'src\Lab.ps1') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $InstallRoot 'VERSION.txt') -PathType Leaf)) {
        throw 'The target folder is not a WEmulDroid installation.'
    }
    $zip = Join-Path $StagedDir 'release.zip'
    $hashFile = Join-Path $StagedDir 'release.sha256'
    $tagFile = Join-Path $StagedDir 'release.tag'
    foreach ($path in @($zip, $hashFile, $tagFile)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw 'Incomplete staged update.'
        }
    }
    $expected = ([IO.File]::ReadAllText($hashFile) -split '\s+')[0].Trim().ToLowerInvariant()
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expected -notmatch '^[0-9a-f]{64}$' -or $expected -cne $actual) {
        throw 'Staged update checksum mismatch.'
    }

    Write-UpdateLog 'Waiting for the WEmulDroid GUI to close.'
    $deadline = (Get-Date).AddSeconds(90)
    while ((Get-Process -Id $WaitPid -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 600
    }
    if (Get-Process -Id $WaitPid -ErrorAction SilentlyContinue) {
        throw 'The old WEmulDroid process is still running. Update aborted.'
    }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($entry in $archive.Entries) {
            $part = $entry.FullName.Replace('\', '/')
            if ($part.StartsWith('/') -or $part -match '(?i)(^|/)\.\.(/|$)' -or
                $part -match '^[A-Za-z]:' -or $part.Contains([char]0) -or
                $part -notmatch '^(src/|docs/|\.github/|[^/]+$)') {
                throw ('Unsafe update path: ' + $part)
            }
            # Reject Unix symbolic links and any entries other than regular files or directories.
            $unixType = ($entry.ExternalAttributes -shr 16) -band 0xF000
            if ($unixType -eq 0xA000) { throw 'Symlink not allowed in update ZIP.' }
        }
    } finally { $archive.Dispose() }

    $extract = Join-Path $StagedDir 'extracted'
    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract)
    $version = ([IO.File]::ReadAllText((Join-Path $extract 'VERSION.txt'))).Trim()
    $expectedTag = ([IO.File]::ReadAllText($tagFile)).Trim()
    if ($version -cne $expectedTag) { throw 'Update tag/version mismatch.' }

    $backup = Join-Path $logDir ('backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -Path $backup -ItemType Directory -Force | Out-Null
    Write-UpdateLog ('Installing SHA-256 verified GitHub source package: ' + $expectedTag)
    $files = @(Get-ChildItem -LiteralPath $extract -Recurse -File)
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($extract.Length).TrimStart('\','/')
        $target = Join-Path $InstallRoot $relative
        $parent = Split-Path -Parent $target
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $prior = Join-Path $backup $relative
            New-Item -Path (Split-Path -Parent $prior) -ItemType Directory -Force | Out-Null
            Copy-Item -LiteralPath $target -Destination $prior -Force
            $backedUp += [pscustomobject]@{ Old=$prior; Dest=$target }
        } else {
            $created += $target
        }
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
    Write-UpdateLog ('Updated ' + $files.Count + ' files. Preserved Android SDK, AVD, settings and reports.')
    $launch = Join-Path $InstallRoot $Launcher
    if (Test-Path -LiteralPath $launch -PathType Leaf) {
        Start-Process -FilePath $launch
    }
    Write-UpdateLog 'Update completed successfully.'
    exit 0
} catch {
    Write-UpdateLog ('UPDATE FAILED: ' + $_.Exception.Message)
    foreach ($path in $created) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($item in $backedUp) {
        try { Copy-Item -LiteralPath $item.Old -Destination $item.Dest -Force }
        catch { Write-UpdateLog ('Rollback issue: ' + $item.Dest) }
    }
    Write-UpdateLog 'Rollback attempted; inspect the log and the backup folder.'
    exit 1
}
