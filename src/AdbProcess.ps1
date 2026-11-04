# Invoke an external CLI without letting Windows PowerShell 5.1 treat harmless
# stderr progress as terminating errors under $ErrorActionPreference = 'Stop'.
# This is used for the ADB bootstrap and AVD identification paths.
# Command success is determined by the exit code, not presence of stderr text.

function ConvertTo-WEmulDroidArgument([AllowEmptyString()][string]$Value) {
    # Windows CreateProcess command-line quoting: double embedded quotes and
    # each run of backslashes preceding quotes / the final closing quote.
    if ($Value -match '^[A-Za-z0-9_./:\\-]+$') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-WEmulDroidNative {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [ValidateRange(1, 300)][int]$TimeoutSeconds = 30
    )
    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        throw "Command-line program not found: $Executable"
    }
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($Arguments | ForEach-Object { ConvertTo-WEmulDroidArgument $_ }) -join ' ')
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    try {
        if (-not $process.Start()) { throw 'Cannot start command-line program.' }
        # Concurrent reads prevent stdout/stderr pipe deadlock.
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill() } catch {}
            throw "Command timed out after $TimeoutSeconds seconds."
        }
        [pscustomobject]@{
            ExitCode = [int]$process.ExitCode
            StdOut = [string]$stdout.GetAwaiter().GetResult()
            StdErr = [string]$stderr.GetAwaiter().GetResult()
        }
    } finally {
        $process.Dispose()
    }
}
