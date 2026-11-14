# Windows PowerShell 5.1, no external network, no tester/Cloudflare credentials.
# Test the real BetaAccess.ps1 adapter and its DPAPI/profile/HTTPS schema policies.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-True([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Throws([scriptblock]$Action,[string]$Message) {
    $caught = $false
    try { & $Action } catch { $caught = $true }
    if (-not $caught) { throw $Message }
}

$repo = Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'src\BetaAccess.ps1')
. (Join-Path $repo 'src\UpdateDialog.ps1')
$previousLocalAppData = $env:LOCALAPPDATA
$testDir = Join-Path $env:TEMP ('wemuldroid-beta-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    $env:LOCALAPPDATA = Join-Path $testDir 'local-appdata'
    New-Item -Path $env:LOCALAPPDATA -ItemType Directory -Force | Out-Null

    $ungated = Join-Path $testDir 'normal-installer'
    New-Item -Path $ungated -ItemType Directory -Force | Out-Null
    Assert-True (Test-WEmulDroidPublicUpdaterAllowed $ungated) 'Normal install lost public updater'
    $normal = Get-WEmulDroidBetaContext $ungated
    Assert-True ($normal.Enabled -eq $false -and $normal.Allowed -eq $true) 'Normal installer unexpectedly requires Beta Access'

    $pilot = Join-Path $testDir 'pilot-installer'
    New-Item -Path $pilot -ItemType Directory -Force | Out-Null
    $endpoint = 'https://beta.example.test'
    [IO.File]::WriteAllText((Join-Path $pilot 'BETA_ACCESS_URL.txt'),$endpoint)
    [IO.File]::WriteAllText((Join-Path $pilot 'VERSION.txt'),'v0.9.0-beta.11')
    Assert-True (-not (Test-WEmulDroidPublicUpdaterAllowed $pilot)) 'Gated beta may update into ungated public build'
    $ctx = Get-WEmulDroidBetaContext $pilot
    Assert-True ($ctx.Enabled -and (-not $ctx.Allowed)) 'Gated installer did not fail closed'
    Assert-True ($ctx.Endpoint -ceq $endpoint) 'Unexpected Beta Access HTTPS host'
    Assert-True ($ctx.Version -ceq '0.9.0-beta.11') 'Incorrect gate version'
    $parsed = [guid]::Empty
    Assert-True ([guid]::TryParse([string]$ctx.Profile.installation_id,[ref]$parsed)) 'Missing valid random installation GUID'
    $deviceKey = Get-WEmulDroidBetaSecret $ctx
    Assert-True ($deviceKey -cmatch '^[0-9a-f]{64}$') 'DPAPI device secret is not valid 256-bit hex'
    Assert-True ((Get-WEmulDroidBetaSecret $ctx) -ceq $deviceKey) 'DPAPI roundtrip did not preserve device key'
    $profileText = [IO.File]::ReadAllText($ctx.ProfilePath)
    Assert-True ($profileText.Contains('protected_key')) 'DPAPI protected key missing'
    Assert-True (-not $profileText.Contains($deviceKey)) 'Plaintext device secret written to installation.json'
    Assert-True (-not $profileText.Contains('invite_token')) 'Invitation field must not persist in the profile'

    $ctx.InviteToken = 'P' * 43
    $enrollmentJson = New-WEmulDroidBetaEnrollmentBody $ctx
    $enrollment = ConvertFrom-Json $enrollmentJson
    Assert-True ($enrollment.app_id -ceq 'wemuldroid') 'Enrollment wrong app'
    Assert-True ($enrollment.platform -ceq 'windows') 'Enrollment wrong OS'
    Assert-True ($enrollment.version -ceq '0.9.0-beta.11') 'Enrollment invalid version'
    Assert-True ($enrollment.installation_id -ceq $ctx.Profile.installation_id) 'Enrollment ID differs from profile'
    Assert-True ($enrollment.device_secret -ceq $deviceKey) 'Device credential mismatch'
    Assert-True ($enrollment.invite_token -ceq ('P' * 43)) 'Invitation token missing from HTTPS enrollment payload'
    Assert-True ($enrollment.telemetry_consent -eq $false) 'Telemetry must be opt-in'
    Assert-True (-not ([IO.File]::ReadAllText($ctx.ProfilePath)).Contains(('P' * 43))) 'Invitation token was saved to disk'
    foreach ($bad in @('', 'short', ('A' * 42), ('A' * 44))) {
        $ctx.InviteToken = $bad
        Assert-Throws { [void](New-WEmulDroidBetaEnrollmentBody $ctx) } 'Malformed invitation incorrectly accepted'
    }
    $ctx.InviteToken = 'P' * 43
    # Only stub REST operations against a deliberately nonexistent example.test endpoint.
    $script:restCalls = @()
    $script:simulateOffline = $false
    $script:serverExpiry = ([datetime]::UtcNow.AddHours(1)).ToString('o')
    function Invoke-RestMethod {
        param($Method,$Uri,$Headers,$Body,$ContentType,$TimeoutSec)
        if ($script:simulateOffline) { throw 'Simulated offline network' }
        $script:restCalls += [pscustomobject]@{
            Method=$Method; Uri=$Uri; Headers=$Headers
            Body=$Body; ContentType=$ContentType; TimeoutSec=$TimeoutSec
        }
        if ($Uri -like '*/api/v1/enroll') { return [pscustomobject]@{state='pending'} }
        if ($Uri -like '*/api/v1/status*') {
            return [pscustomobject]@{state='approved';approved_until=$script:serverExpiry;telemetry_consent=$true}
        }
        throw 'Unexpected REST route'
    }
    $enrollReply = Invoke-WEmulDroidBetaEnroll $ctx
    Assert-True ($enrollReply.state -ceq 'pending') 'Enrollment mock did not report pending'
    Assert-True ($script:restCalls[0].Uri -ceq ($endpoint+'/api/v1/enroll')) 'Enrollment sent to unexpected endpoint'
    Assert-True ($script:restCalls[0].Method -ceq 'Post') 'Enrollment must use POST'
    Assert-True (($script:restCalls[0].Body | ConvertFrom-Json).invite_token -ceq ('P' * 43)) 'Private code missing from post body'
    $reply = Invoke-WEmulDroidBetaStatus $ctx
    Assert-True (Test-WEmulDroidBetaApproval $reply) 'Authenticated approved lease was refused'
    Assert-True ($script:restCalls[1].Uri -ceq ($endpoint+'/api/v1/status?installation_id='+$ctx.Profile.installation_id)) 'Status endpoint mismatch'
    Assert-True ($script:restCalls[1].Headers['X-Device-Key'] -ceq $deviceKey) 'Status header does not carry DPAPI credential'
    $ctx.InviteToken = ''
    $ctx.Allowed = $false
    $script:simulateOffline = $true
    Assert-Throws { [void](Invoke-WEmulDroidBetaStatus $ctx) } 'Offline status unexpectedly succeeded'
    Assert-True (-not $ctx.Allowed) 'Offline status must not unlock gated app'
    $script:simulateOffline = $false
    foreach ($badStatus in @(
        [pscustomobject]@{state='pending';approved_until=$script:serverExpiry},
        [pscustomobject]@{state='denied';approved_until=$script:serverExpiry},
        [pscustomobject]@{state='revoked';approved_until=$script:serverExpiry},
        [pscustomobject]@{state='approved';approved_until='2000-01-01T00:00:00Z'},
        [pscustomobject]@{state='approved';approved_until='not a date'},
        [pscustomobject]@{state='approved';approved_until=$null}
    )) {
        Assert-True (-not (Test-WEmulDroidBetaApproval $badStatus)) 'Invalid/expired authorization unlocked app'
    }
    foreach ($unsafe in @('http://beta.example.test','https://beta.example.test/path','https://beta.example.test?x=1')) {
        [IO.File]::WriteAllText((Join-Path $pilot 'BETA_ACCESS_URL.txt'),$unsafe)
        Assert-Throws { [void](Get-WEmulDroidBetaContext $pilot) } 'Unsafe/non-origin Beta Access endpoint accepted'
    }
    # No diagnostics when consent has not been granted.
    $ctx.Allowed=$true
    $ctx.Telemetry=$false
    Add-WEmulDroidBetaEvent $ctx 'APP_START' 'info' @{startup_ms=123}
    Assert-True (@(Get-ChildItem -LiteralPath $ctx.Outbox -Filter '*.json' -File).Count -eq 0) 'Telemetry sent without consent'
    $ctx.Telemetry=$true
    Add-WEmulDroidBetaEvent $ctx 'APP_START' 'info' @{startup_ms=123}
    Add-WEmulDroidBetaEvent $ctx 'APP_ERROR' 'error' @{screenshot='sensitive'}
    Add-WEmulDroidBetaEvent $ctx 'APP_ERROR' 'error' @{error_code='full personal message'}
    $files=@(Get-ChildItem -LiteralPath $ctx.Outbox -Filter '*.json' -File)
    Assert-True ($files.Count -eq 1) 'Invalid telemetry schema was queued'
    $queued=ConvertFrom-Json ([IO.File]::ReadAllText($files[0].FullName))
    Assert-True ($queued.event -ceq 'APP_START' -and $queued.fields.startup_ms -eq 123) 'Missing classified startup event'
    Assert-True (-not ([IO.File]::ReadAllText($files[0].FullName)).Contains($deviceKey)) 'Raw DPAPI secret entered Diagnostics queue'
    Write-Host 'WINDOWS BETA ACCESS OFFLINE INTEGRATION PASS: DPAPI, invitation, approval, fail-closed, consent'
} finally {
    $env:LOCALAPPDATA = $previousLocalAppData
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
