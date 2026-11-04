[CmdletBinding()]
param([switch]$Signed, [string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $OutputRoot) { $OutputRoot = Join-Path $repo 'dist' }
$payload = Join-Path $OutputRoot 'payload'
New-Item -ItemType Directory -Path $payload -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $payload 'src') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $payload 'docs') -Force | Out-Null

$version = ([IO.File]::ReadAllText((Join-Path $repo 'VERSION.txt'))).Trim()
if ($version -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+(?:-(?:beta|rc)\.[0-9]+)?$') {
    throw "Installer version is invalid: $version"
}
$displayVersion = $version.Substring(1)
foreach ($name in @('VERSION.txt','README.md','LICENSE')) {
    Copy-Item -LiteralPath (Join-Path $repo $name) -Destination $payload -Force
}
Copy-Item -Path (Join-Path $repo 'src\*.ps1') -Destination (Join-Path $payload 'src') -Force
Copy-Item -Path (Join-Path $repo 'docs\*.md') -Destination (Join-Path $payload 'docs') -Force
$ico = Join-Path $payload 'WEmulDroid.ico'
& (Join-Path $PSScriptRoot 'Make-Icon.ps1') -OutputPath $ico

$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $framework)) { throw "Windows C# compiler not found: $framework" }
$launcher = Join-Path $payload 'WEmulDroid.exe'
& $framework '/nologo' '/target:winexe' '/optimize+' ("/win32icon:$ico") ("/out:$launcher") '/reference:System.Windows.Forms.dll' (Join-Path $PSScriptRoot 'WEmulDroidLauncher.cs')
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $launcher)) {
    throw 'Cannot compile WEmulDroid desktop launcher.'
}

$programFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
$iscc = @((Join-Path $programFilesX86 'Inno Setup 6\ISCC.exe'),
          (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')) |
    Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 compiler not installed on Windows runner.' }

$extraArgs = @()
if ($Signed) {
    foreach ($secret in @('WEMULDROID_PFX_BASE64','WEMULDROID_PFX_PASSWORD')) {
        if (-not [Environment]::GetEnvironmentVariable($secret)) {
            throw "Trusted publisher certificate missing: $secret"
        }
    }
    $keyBytes = [Convert]::FromBase64String($env:WEMULDROID_PFX_BASE64)
    $pfx = Join-Path $env:RUNNER_TEMP 'WEmulDroid-signing.pfx'
    [IO.File]::WriteAllBytes($pfx, $keyBytes)
    $env:WEMULDROID_SIGN_PFX = $pfx
    $env:WEMULDROID_SIGN_PWD = $env:WEMULDROID_PFX_PASSWORD
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx, $env:WEMULDROID_PFX_PASSWORD, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
    if (-not $cert.HasPrivateKey) { throw 'Signing certificate has no private key.' }
    if ($cert.Subject -eq $cert.Issuer) {
        throw 'Self-signed certificate not accepted for official Windows releases.'
    }
    if ($cert.NotAfter -lt [DateTime]::UtcNow.AddDays(30)) {
        throw 'Signing certificate is expired or too close to expiry.'
    }
    $codeSigningOid = '1.3.6.1.5.5.7.3.3'
    $eku = $cert.Extensions | Where-Object {
        $_ -is [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]
    }
    $validPurpose = $false
    foreach ($extension in $eku) {
        foreach ($usage in $extension.EnhancedKeyUsages) {
            if ($usage.Value -eq $codeSigningOid) { $validPurpose = $true }
        }
    }
    if (-not $validPurpose) {
        throw 'Certificate is not issued for Code Signing.'
    }
    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = [Security.Cryptography.X509Certificates.X509RevocationMode]::Online
    if (-not $chain.Build($cert)) { throw 'Code signing certificate is not trusted by Windows.' }
    foreach ($script in (Get-ChildItem -LiteralPath (Join-Path $payload 'src') -Filter '*.ps1')) {
        $signature = Set-AuthenticodeSignature -FilePath $script.FullName -Certificate $cert -HashAlgorithm SHA256 -TimestampServer 'http://timestamp.digicert.com'
        if ($signature.Status -ne 'Valid') {
            throw "Cannot code-sign script $($script.Name): $($signature.Status)"
        }
    }
    $tool = Get-ChildItem -Path 'C:\Program Files (x86)\Windows Kits\10\bin' -Filter 'signtool.exe' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\signtool[.]exe$' } |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $tool) { throw 'Windows SDK signtool.exe not available.' }
    $env:WEMULDROID_SIGNTOOL = $tool
    & $tool sign /f $pfx /p $env:WEMULDROID_PFX_PASSWORD /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $launcher
    if ($LASTEXITCODE -ne 0) { throw 'Launcher code signing failed.' }
    & $tool verify /pa /v $launcher
    if ($LASTEXITCODE -ne 0) { throw 'Launcher signature verification failed.' }
    $extraArgs += '/DWEMULDROID_SIGNED=1'
    # Inno signs the installer AND the uninstaller while compiling.
    $signingScript = (Join-Path $PSScriptRoot 'Sign-Inno-File.cmd')
    $extraArgs += ('/Ssigner=$q' + $signingScript + '$q $f')
}

$inno = Join-Path $PSScriptRoot 'WEmulDroid.iss'
$arguments = @("/DAppVersion=$displayVersion", "/DAppVersionFile=$version", "/DPayload=$payload") + $extraArgs + @($inno)
& $iscc @arguments
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }

$setupPath = Join-Path (Join-Path $payload 'Output') ("WEmulDroid-Setup-$version.exe")
if (-not (Test-Path -LiteralPath $setupPath)) { throw 'Installer output not found.' }
if ($Signed) {
    & $env:WEMULDROID_SIGNTOOL verify /pa /v $setupPath
    if ($LASTEXITCODE -ne 0) { throw 'Official installer is not signed by a trusted publisher.' }
}
$hash = (Get-FileHash -LiteralPath $setupPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText("$setupPath.sha256", ("$hash  " + [IO.Path]::GetFileName($setupPath) + [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))
Write-Host "Installer build completed. Signed=$Signed Path=$setupPath"
