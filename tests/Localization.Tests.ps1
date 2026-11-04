$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'src' 'Localization.ps1')
if (-not (Assert-WEmulDroidTranslations)) { throw 'Missing translations' }
if ($script:UiLanguages.Count -ne 3) { throw 'Expected exactly EN, IT and FR' }
foreach ($language in @('en', 'it', 'fr')) {
    Set-WEmulDroidLanguage $language $false
    if ([string]::IsNullOrWhiteSpace((T 'setup'))) { throw 'Setup label missing' }
    if ([string]::IsNullOrWhiteSpace((T 'language'))) { throw 'Language menu missing' }
    if ([string]::IsNullOrWhiteSpace((T 'snapshotLoad'))) { throw 'Snapshot label missing' }
    if ([string]::IsNullOrWhiteSpace((T 'touchHelpText'))) { throw 'Help text missing' }
}
$rejected = $false
try { Set-WEmulDroidLanguage 'de' $false } catch { $rejected = $true }
if (-not $rejected) { throw 'Unexpected language accepted' }
Write-Host 'PASS EN/IT/FR: all GUI keys present and unknown languages rejected'
