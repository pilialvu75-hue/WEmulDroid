# WEmulDroid navigation, physical keyboard and quiet emulator launcher.
# Operations confined to selected AVD. Never delete Android userdata.
function Get-WEmulDroidAvdConfig([string]$AvdName) {
    if ($AvdName -notin @('WEmulDroid_API_35','WEmulDroid_Play_API_35')) { throw 'Unsupported WEmulDroid profile.' }
    return Join-Path $env:USERPROFILE ('.android\avd\' + $AvdName + '.avd\config.ini')
}
function Enable-WEmulDroidPhysicalKeyboard([string]$AvdName) {
    $path = Get-WEmulDroidAvdConfig $AvdName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw 'AVD config.ini not found. Configure the selected Android profile first.'
    }
    $config = [IO.File]::ReadAllText($path)
    if ($config -match '(?m)^hw\.keyboard\s*=\s*yes\s*$') { return $false }
    $newConfig = if ($config -match '(?m)^hw\.keyboard\s*=.*$') {
        [regex]::Replace($config, '(?m)^hw\.keyboard\s*=.*$', 'hw.keyboard=yes')
    } else {
        $config.TrimEnd([char[]]@([char]13,[char]10)) + [Environment]::NewLine + 'hw.keyboard=yes' + [Environment]::NewLine
    }
    $backup = $path + '.wemuldroid-before-keyboard.bak'
    if (-not (Test-Path -LiteralPath $backup)) { [IO.File]::Copy($path, $backup) }
    [IO.File]::WriteAllText($path, $newConfig, (New-Object Text.UTF8Encoding($false)))
    return $true
}
function Invoke-WEmulDroidGuestControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Adb,
        [Parameter(Mandatory)][string]$Serial,
        [ValidateSet('home','back','keyboard-pc','keyboard-android')]
        [Parameter(Mandatory)][string]$Action
    )
    if ($Serial -notmatch '^emulator-[0-9]+$') { throw 'ADB target must be the selected emulator serial.' }
    $arguments = switch ($Action) {
        'home'             { @('-s',$Serial,'shell','input','keyevent','KEYCODE_HOME') }
        'back'             { @('-s',$Serial,'shell','input','keyevent','KEYCODE_BACK') }
        'keyboard-pc'      { @('-s',$Serial,'shell','settings','put','secure','show_ime_with_hard_keyboard','0') }
        'keyboard-android' { @('-s',$Serial,'shell','settings','put','secure','show_ime_with_hard_keyboard','1') }
    }
    $result = Invoke-WEmulDroidNative -Executable $Adb -Arguments $arguments
    if ($result.ExitCode -ne 0) {
        throw ('Android control ' + $Action + ' failed: ' + ($result.StdErr + ' ' + $result.StdOut).Trim())
    }
    return $true
}
function Start-WEmulDroidQuietEmulator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EmulatorExe,
        [Parameter(Mandatory)][string]$AvdName,
        [Parameter(Mandatory)][string]$ReportsRoot,
        [switch]$ColdBoot
    )
    if ($AvdName -notin @('WEmulDroid_API_35','WEmulDroid_Play_API_35')) { throw 'Unsupported profile.' }
    if (-not (Test-Path -LiteralPath $EmulatorExe -PathType Leaf)) { throw 'Android emulator missing.' }
    New-Item -Path $ReportsRoot -ItemType Directory -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outFile = Join-Path $ReportsRoot ('emulator-' + $AvdName + '-' + $stamp + '.stdout.log')
    $errFile = Join-Path $ReportsRoot ('emulator-' + $AvdName + '-' + $stamp + '.stderr.log')
    $arguments = @('-avd', $AvdName, '-gpu', 'auto')
    if ($ColdBoot -or $AvdName -eq 'WEmulDroid_Play_API_35') { $arguments += '-no-snapshot-load' }
    # Keep the Android Qt GUI visible; redirect console diagnostic output.
    $process = Start-Process -FilePath $EmulatorExe -ArgumentList $arguments -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru
    if (-not $process) { throw 'Android emulator process did not start.' }
    return [pscustomobject]@{ ProcessId=$process.Id; StdOutLog=$outFile; StdErrLog=$errFile; ColdBoot=[bool]$ColdBoot }
}
