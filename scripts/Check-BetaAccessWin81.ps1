# Read-only Windows 8.1 compatibility preflight for Beta Access.
# Windows PowerShell 4.0+ syntax. This does NOT install anything, connect to
# a network, create files, change policies, or read personal/device identifiers.
$ErrorActionPreference = 'Stop'

function Get-CheckResult([scriptblock]$Action) {
    try { return (& $Action) } catch { return 'NON DISPONIBILE' }
}

$osVersion = Get-CheckResult {
    $system = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    [string]$system.Version
}
$psVersion = [string]$PSVersionTable.PSVersion
$os64 = if ([Environment]::Is64BitOperatingSystem) { 'SI' } else { 'NO' }
$dotNetRelease = Get-CheckResult {
    $framework = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name 'Release' -ErrorAction Stop
    [string]$framework.Release
}
$tls12 = Get-CheckResult {
    $names = [Enum]::GetNames([Net.SecurityProtocolType])
    if ($names -contains 'Tls12') { 'SI' } else { 'NO' }
}
$dpapi = Get-CheckResult {
    Add-Type -AssemblyName System.Security -ErrorAction Stop
    $plain = [byte[]](5,17,23,41)
    $scope = [Security.Cryptography.DataProtectionScope]::CurrentUser
    $encrypted = [Security.Cryptography.ProtectedData]::Protect($plain,$null,$scope)
    $roundtrip = [Security.Cryptography.ProtectedData]::Unprotect($encrypted,$null,$scope)
    if ($roundtrip.Length -eq 4 -and $roundtrip[0] -eq 5 -and $roundtrip[3] -eq 41) { 'PASS' } else { 'FAIL' }
}
$memory = Get-CheckResult {
    $system = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    [math]::Round([double]$system.TotalVisibleMemorySize / 1048576.0,1).ToString('0.0')
}

Write-Output 'BETA ACCESS - COMPATIBILITA WINDOWS - SOLO LETTURA'
Write-Output ('Windows versione: ' + $osVersion)
Write-Output ('Sistema 64 bit: ' + $os64)
Write-Output ('Windows PowerShell: ' + $psVersion)
Write-Output ('Versione registro .NET v4 Release: ' + $dotNetRelease)
Write-Output ('TLS 1.2 disponibile: ' + $tls12)
Write-Output ('DPAPI test in memoria: ' + $dpapi)
Write-Output ('RAM approssimativa GB: ' + $memory)
Write-Output 'Nessun file, installazione, rete, identificativo personale o impostazione modificata.'
