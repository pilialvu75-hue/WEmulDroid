$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
$setupPath = Join-Path (Join-Path $root 'src') 'Setup-Android.ps1'
$labPath = Join-Path (Join-Path $root 'src') 'Lab.ps1'
$setup = [IO.File]::ReadAllText($setupPath)
$lab = [IO.File]::ReadAllText($labPath)

$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($setupPath, [ref]$tokens, [ref]$errors)
if ($errors -and $errors.Count -gt 0) {
    throw "Android automatic setup contains a PowerShell syntax error: $($errors[0].Message)"
}
foreach ($required in @(
    '[switch]$BothProfiles',
    '[switch]$ConsentConfirmed',
    'WEmulDroid_API_35',
    'WEmulDroid_Play_API_35',
    'system-images;android-35;google_apis;x86_64',
    'system-images;android-35;google_apis_playstore;x86_64',
    '& $sdkManager "--sdk_root=$SdkRoot" --licenses',
    '@imagePackages',
    'Enable-WEmulDroidPhysicalKeyboard'
)) {
    if (-not $setup.Contains($required)) {
        throw "Automatic setup missing requirement: $required"
    }
}
foreach ($required in @(
    '$form.Add_Shown({',
    'setupAllPrompt',
    "'-BothProfiles'",
    'Start-Process -FilePath',
    "'keyboard-android'",
    "'keyboardHideConfirm'",
    '$script:CenterTimerTicks % 4'
)) {
    if (-not $lab.Contains($required)) {
        throw "First-run/keyboard/centering workflow missing: $required"
    }
}
if ($lab -notmatch '(?s)\$btnPcKeyboard\.Add_Click\(\{(?<body>.*?)\n\}\)') {
    throw 'The PC keyboard action was not found.'
}
if ($matches['body'].Contains("-Action 'keyboard-pc'")) {
    throw 'REGRESSION: PC keyboard primary button hides the Android keyboard and blocks sign-in.'
}
if ($setup.Contains('-wipe-data')) {
    throw 'Automatic setup must never wipe existing Android user data.'
}
Write-Host 'PASS: consented dual-profile Google Play provisioning, safe PC keyboard, and repeated window centering.'
