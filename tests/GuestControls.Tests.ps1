$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\GuestControls.ps1')

$oldUserProfile = $env:USERPROFILE
$fakeHome = Join-Path ([IO.Path]::GetTempPath()) ('wemuldroid-input-' + [guid]::NewGuid().ToString('N'))
try {
    $env:USERPROFILE = $fakeHome
    $path = Get-WEmulDroidAvdConfig 'WEmulDroid_API_35'
    New-Item -Path (Split-Path -Parent $path) -ItemType Directory -Force | Out-Null
    [IO.File]::WriteAllText($path, ('hw.keyboard=no' + [Environment]::NewLine + 'showDeviceFrame=yes' + [Environment]::NewLine))
    if (-not (Enable-WEmulDroidPhysicalKeyboard 'WEmulDroid_API_35')) {
        throw 'Expected to enable the physical keyboard for existing AVD.'
    }
    if (([IO.File]::ReadAllText($path)) -notmatch '(?m)^hw\.keyboard=yes$') {
        throw 'AVD keyboard setting was not enabled.'
    }
    if (([IO.File]::ReadAllText($path)) -notmatch '(?m)^showDeviceFrame=yes$') {
        throw 'Unrelated AVD config setting was modified.'
    }
    if (Enable-WEmulDroidPhysicalKeyboard 'WEmulDroid_API_35') {
        throw 'Keyboard configuration must be idempotent.'
    }
    if (-not (Test-Path -LiteralPath ($path + '.wemuldroid-before-keyboard.bak'))) {
        throw 'Original AVD keyboard configuration backup missing.'
    }
    $rejected = $false
    try { [void](Get-WEmulDroidAvdConfig '..\bad-profile') } catch { $rejected = $true }
    if (-not $rejected) { throw 'Unsafe AVD name was accepted.' }

    $script:LastGuestArguments = @()
    function Invoke-WEmulDroidNative {
        param([string]$Executable,[string[]]$Arguments)
        $script:LastGuestArguments = @($Arguments)
        return [pscustomobject]@{ ExitCode=0; StdOut=''; StdErr='' }
    }
    $expected = @{
        home = 'input keyevent KEYCODE_HOME'
        back = 'input keyevent KEYCODE_BACK'
        'keyboard-pc' = 'settings put secure show_ime_with_hard_keyboard 0'
        'keyboard-android' = 'settings put secure show_ime_with_hard_keyboard 1'
    }
    foreach ($action in $expected.Keys) {
        [void](Invoke-WEmulDroidGuestControl -Adb 'test-adb.exe' -Serial 'emulator-5554' -Action $action)
        $actual = ($script:LastGuestArguments -join ' ')
        if ($actual -notmatch '^-s emulator-5554 shell ') { throw "ADB target isolation failed for $action." }
        if (-not $actual.EndsWith($expected[$action],[StringComparison]::Ordinal)) {
            throw "Incorrect ADB command for $action : $actual"
        }
    }
    $invalid = $false
    try { [void](Invoke-WEmulDroidGuestControl -Adb 'test' -Serial 'malicious' -Action home) } catch { $invalid = $true }
    if (-not $invalid) { throw 'Invalid device serial accepted.' }
    Write-Host 'PASS: PC keyboard config, reversible Android keyboard, Home/Back, AVD isolation.'
} finally {
    $env:USERPROFILE = $oldUserProfile
    Remove-Item -LiteralPath $fakeHome -Recurse -Force -ErrorAction SilentlyContinue
}
