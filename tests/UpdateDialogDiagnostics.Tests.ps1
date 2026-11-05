$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..') 'src\UpdateDialog.ps1')

$blocked = Format-WEmulDroidUpdateError -Phase 'install' -Message "Impossibile eseguire il comando: Un criterio di controllo dell'applicazione ha bloccato il file."
if ($blocked -notmatch 'Avvio installer' -or $blocked -notmatch 'CodeIntegrity' -or $blocked -notmatch 'Non disattivare') {
    throw 'Policy-block diagnostic did not explain phase and safe next steps.'
}
$english = Format-WEmulDroidUpdateError -Phase 'download' -Message 'The file did not meet the Enterprise signing level requirements.'
if ($english -notmatch 'Download/verifica' -or $english -notmatch 'CodeIntegrity') {
    throw 'English Code Integrity error is not recognized.'
}
$ordinary = Format-WEmulDroidUpdateError -Phase 'check' -Message 'HTTP 503'
if ($ordinary -notmatch 'Ricerca aggiornamenti' -or $ordinary -match 'CodeIntegrity') {
    throw 'Ordinary network errors must not be misdiagnosed as policy blocks.'
}
Write-Host 'PASS: Windows policy-block update diagnostics classified by stage.'
