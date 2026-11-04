$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\AdbProcess.ps1')

$program = (Get-Command pwsh -ErrorAction Stop).Source
$folder = Join-Path ([IO.Path]::GetTempPath()) ('WEmulDroid native smoke ' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $folder -Force | Out-Null
try {
    $okFile = Join-Path $folder 'expected startup.ps1'
    [IO.File]::WriteAllText($okFile, @'
[Console]::Error.WriteLine("* daemon not running; starting now at tcp:5037")
[Console]::Error.WriteLine("* daemon started successfully")
[Console]::Out.WriteLine("List of devices attached")
exit 0
'@)
    $result = Invoke-WEmulDroidNative -Executable $program -Arguments @('-NoProfile','-File',$okFile)
    if ($result.ExitCode -ne 0 -or
        $result.StdErr -notmatch 'daemon not running; starting now' -or
        $result.StdOut -notmatch 'List of devices attached') {
        throw 'Expected ADB daemon bootstrap was not captured correctly.'
    }

    $badFile = Join-Path $folder 'expected failure.ps1'
    [IO.File]::WriteAllText($badFile, @'
[Console]::Error.WriteLine("cannot connect to daemon")
exit 7
'@)
    $failure = Invoke-WEmulDroidNative -Executable $program -Arguments @('-NoProfile','-File',$badFile)
    if ($failure.ExitCode -ne 7 -or $failure.StdErr -notmatch 'cannot connect') {
        throw 'ADB real errors are not visible to the caller.'
    }
    Write-Host 'PASS: ADB first-start stderr is informational; exit codes remain authoritative.'
} finally {
    Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue
}
