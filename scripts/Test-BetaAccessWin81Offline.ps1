# Beta Access Windows 8.1/10/11 compatibility lab. Offline, no installer.
# Runs the actual client policy functions with entirely synthetic in-memory values.
# NO production credentials, invitations, requests, telemetry, file writes, or app launch.
# Only run on a computer you own. Does not change Windows security policies.
$ErrorActionPreference='Stop'

function Assert-Lab([bool]$Condition,[string]$Reason) {
    if (-not $Condition) { throw ('BETA ACCESS OFFLINE LAB FAIL: ' + $Reason) }
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This lab requires Windows and Windows PowerShell 5.1.'
}
if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    Write-Output ('STOP: Windows PowerShell '+[string]$PSVersionTable.PSVersion+' detected. Need 5.1 to load actual Beta Access client. No changes made.')
    return
}
$repo=Split-Path -Parent $PSScriptRoot
$module=Join-Path $repo 'src\BetaAccess.ps1'
if (-not (Test-Path -LiteralPath $module -PathType Leaf)) {
    throw 'Missing src\BetaAccess.ps1 beside this lab. Obtain the complete repository source; do not use an EXE installer.'
}

# Disable PowerShell HTTP commands in this session. No actual request is permitted.
# Both the real status/enrollment functions use Invoke-RestMethod.
$script:offlineCalls=0
function Invoke-RestMethod {
    param($Uri,$Method,$Headers,$Body,$ContentType,$TimeoutSec)
    $script:offlineCalls++
    throw 'OFFLINE_LAB_NETWORK_BLOCKED'
}
function Invoke-WebRequest {
    param($Uri,$Method,$Headers,$Body,$ContentType,$TimeoutSec)
    throw 'OFFLINE_LAB_NETWORK_BLOCKED'
}

# Dot-sourcing defines functions but does not create an installation or contact the service.
. $module

# DPAPI transient test uses a synthetic, in-memory 256-bit key.
# Windows itself may use its normal CurrentUser DPAPI key store.
$plain=New-Object byte[] 32
try {
    $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($plain) } finally { $rng.Dispose() }
    $encrypted=[Security.Cryptography.ProtectedData]::Protect(
        $plain,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
    $profile=[pscustomobject]@{
        installation_id=[guid]::NewGuid().ToString()
        protected_key=[Convert]::ToBase64String($encrypted)
        telemetry_consent=$false
        approval_sound=$false
        label='OFFLINE MOCK'
    }
    $ctx=[pscustomobject]@{
        Enabled=$true
        Allowed=$false
        Telemetry=$false
        Profile=$profile
        Version='0.9.0-beta.11'
        InviteToken=('T' * 43)
        Endpoint='https://no-network.example.invalid'
    }
    $key=Get-WEmulDroidBetaSecret $ctx
    $expected=[BitConverter]::ToString($plain).Replace('-','').ToLowerInvariant()
    Assert-Lab ($key -ceq $expected) 'DPAPI temporary secret failed round-trip'

    $localJson=New-WEmulDroidBetaEnrollmentBody $ctx
    $local=ConvertFrom-Json $localJson
    Assert-Lab ($local.app_id -ceq 'wemuldroid') 'Wrong app ID'
    Assert-Lab ($local.platform -ceq 'windows') 'Wrong platform'
    Assert-Lab ($local.invite_token -ceq ('T' * 43)) 'Synthetic invite not serialized'
    Assert-Lab ($local.telemetry_consent -eq $false) 'Diagnostics consent not off by default'

    $now=[datetime]::UtcNow
    $future=$now.AddHours(1).ToString('o')
    $past=$now.AddMinutes(-1).ToString('o')
    $good=[pscustomobject]@{state='approved';approved_until=$future}
    Assert-Lab (Test-WEmulDroidBetaApproval $good $now) 'Future approval refused'
    foreach ($bad in @(
        [pscustomobject]@{state='pending';approved_until=$future},
        [pscustomobject]@{state='denied';approved_until=$future},
        [pscustomobject]@{state='revoked';approved_until=$future},
        [pscustomobject]@{state='expired';approved_until=$past},
        [pscustomobject]@{state='approved';approved_until=$past},
        [pscustomobject]@{state='approved';approved_until='not-a-date'},
        [pscustomobject]@{state='approved';approved_until=$null}
    )) {
        Assert-Lab (-not (Test-WEmulDroidBetaApproval $bad $now)) ('Invalid state unlocked client: '+[string]$bad.state)
    }

    $blocked=$false
    try { [void](Invoke-WEmulDroidBetaStatus $ctx) }
    catch {
        if ($_.Exception.Message -match 'OFFLINE_LAB_NETWORK_BLOCKED') { $blocked=$true }
        else { throw }
    }
    Assert-Lab $blocked 'Network interception not enforced'
    Assert-Lab (-not $ctx.Allowed) 'Offline status accidentally unlocked client'
    Assert-Lab ($script:offlineCalls -eq 1) 'Unexpected network operation count'

    Add-Type -AssemblyName System.Windows.Forms
    $form=New-Object System.Windows.Forms.Form
    try { Assert-Lab (-not $form.IsDisposed) 'WinForms unavailable' }
    finally { $form.Dispose() }
    [byte[]]$chime=New-WEmulDroidBetaApprovalWav
    Assert-Lab ($chime.Length -gt 10000) 'Original confirmation sound not generated'
    Assert-Lab ([Text.Encoding]::ASCII.GetString($chime,0,4) -ceq 'RIFF') 'Bad WAV header'

    Write-Output 'BETA ACCESS - LABORATORIO OFFLINE (NESSUN INSTALLER)'
    Write-Output 'Modulo reale BetaAccess.ps1: PASS'
    Write-Output 'DPAPI con chiave sintetica: PASS'
    Write-Output 'Invito fittizio e consenso OFF: PASS'
    Write-Output 'Stati pending/denied/revoked/expired: BLOCCATI'
    Write-Output 'Approvazione futura simulata: PASS'
    Write-Output 'Errore rete simulato: ACCESSO BLOCCATO'
    Write-Output 'WinForms e WAV sintetico: PASS'
    Write-Output 'Cloudflare/Diagnostics/Android: NON CONTATTATI'
    Write-Output 'Nessun dato personale e nessuna chiave stampati.'
} finally {
    [Array]::Clear($plain,0,$plain.Length)
}
