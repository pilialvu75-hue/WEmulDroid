$ErrorActionPreference='Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\InstallerUpdates.ps1')

# Simulate the Windows 11 CodeIntegrity exception seen when PowerShell
# attempts to inspect an unsigned EXE. Development must not inspect it.
$root=Join-Path ([IO.Path]::GetTempPath()) ('WEmulDroid-DevSignatureTest-' + [Guid]::NewGuid().ToString('N'))
New-Item -Path $root -ItemType Directory -Force | Out-Null
try {
    $installer=Join-Path $root 'WEmulDroid-Setup-v0.9.0-beta.7.exe'
    $launcher=Join-Path $root 'WEmulDroid.exe'
    [IO.File]::WriteAllBytes($installer,[byte[]](1,2,3,4,5))
    [IO.File]::WriteAllBytes($launcher,[byte[]](9,8,7))
    $sha=(Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
    [IO.File]::WriteAllText(($installer+'.sha256'),$sha)
    [IO.File]::WriteAllText((Join-Path $root 'CHANNEL.txt'),'development')

    function Get-AuthenticodeSignature {
        throw 'A Windows application control policy has blocked this file.'
    }
    $pass=Assert-WEmulDroidInstallerSignature -Installer $installer -InstalledLauncher $launcher
    if (-not $pass) { throw 'Development SHA-256 validation should pass without Authenticode.' }

    # A modified installer must still be rejected, regardless of channel.
    [IO.File]::AppendAllText($installer,'tampered')
    $rejected=$false
    try { [void](Assert-WEmulDroidInstallerSignature -Installer $installer -InstalledLauncher $launcher) }
    catch { $rejected=$true }
    if (-not $rejected) { throw 'Tampered development installer passed SHA-256 validation.' }

    # Production must always inspect Authenticode; no downgrade of verification.
    [IO.File]::WriteAllBytes($installer,[byte[]](1,2,3,4,5))
    [IO.File]::WriteAllText((Join-Path $root 'CHANNEL.txt'),'production')
    $policyRejected=$false
    try { [void](Assert-WEmulDroidInstallerSignature -Installer $installer -InstalledLauncher $launcher) }
    catch {
        if ($_.Exception.Message -match 'application control policy') { $policyRejected=$true }
    }
    if (-not $policyRejected) { throw 'Production did not enforce signature inspection.' }
    Write-Host 'PASS: dev avoids unsigned Authenticode inspection; SHA-256 and production trust remain enforced.'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
