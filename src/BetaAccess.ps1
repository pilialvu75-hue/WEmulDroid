# Optional Beta Access gate. Not active without BETA_ACCESS_URL.txt in the installed payload.
# Requires PowerShell 5.1 / Windows DPAPI. No personal log text leaves the computer.
function Get-WEmulDroidBetaContext([string]$InstallRoot) {
    $config = Join-Path $InstallRoot 'BETA_ACCESS_URL.txt'
    if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
        return [pscustomobject]@{ Enabled=$false; Allowed=$true; Telemetry=$false }
    }
    $endpoint = ([IO.File]::ReadAllText($config)).Trim().TrimEnd('/')
    $url = $null
    if (-not [Uri]::TryCreate($endpoint,[UriKind]::Absolute,[ref]$url) -or
        $url.Scheme -ne 'https' -or $url.AbsolutePath -ne '/' -or
        -not [string]::IsNullOrEmpty($url.Query) -or -not [string]::IsNullOrEmpty($url.Fragment)) {
        throw 'Invalid HTTPS Beta Access endpoint in installer.'
    }
    $dataRoot = Join-Path $env:LOCALAPPDATA 'WEmulDroid\BetaAccess'
    $outbox = Join-Path $dataRoot 'Outbox'
    New-Item -ItemType Directory -Path $outbox -Force | Out-Null
    $profilePath = Join-Path $dataRoot 'installation.json'
    if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
        $profile = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($profilePath))
        if ([string]$profile.installation_id -notmatch '^[0-9a-f-]{36}$' -or
            [string]::IsNullOrWhiteSpace([string]$profile.protected_key)) {
            throw 'Invalid saved Beta Access installation. No activation possible.'
        }
    } else {
        $generator = [Security.Cryptography.RandomNumberGenerator]::Create()
        $key = New-Object byte[] 32
        try { $generator.GetBytes($key) } finally { $generator.Dispose() }
        $protected = [Security.Cryptography.ProtectedData]::Protect(
            $key, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
        $profile = [pscustomobject]@{
            installation_id = [guid]::NewGuid().ToString()
            protected_key = [Convert]::ToBase64String($protected)
            telemetry_consent = $false
            label = 'Tester WEmulDroid'
        }
        [IO.File]::WriteAllText($profilePath,($profile | ConvertTo-Json -Compress),
            (New-Object Text.UTF8Encoding($false)))
    }
    $versionPath = Join-Path $InstallRoot 'VERSION.txt'
    $version = if (Test-Path -LiteralPath $versionPath) {
        ([IO.File]::ReadAllText($versionPath)).Trim().TrimStart('v')
    } else { '0.0.0' }
    return [pscustomobject]@{
        Enabled=$true; Allowed=$false; Endpoint=$endpoint; DataRoot=$dataRoot
        Outbox=$outbox; Profile=$profile; ProfilePath=$profilePath
        Version=$version; Session=[guid]::NewGuid().ToString()
        Telemetry=[bool]$profile.telemetry_consent
    }
}
function Get-WEmulDroidBetaSecret([object]$Context) {
    $encrypted=[Convert]::FromBase64String([string]$Context.Profile.protected_key)
    $key=[Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [BitConverter]::ToString($key).Replace('-','').ToLowerInvariant()
}
function Save-WEmulDroidBetaProfile([object]$Context) {
    $json=$Context.Profile | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($Context.ProfilePath,$json,(New-Object Text.UTF8Encoding($false)))
}
function Invoke-WEmulDroidBetaStatus([object]$Context) {
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $uri=$Context.Endpoint+'/api/v1/status?installation_id='+$Context.Profile.installation_id
    return Invoke-RestMethod -Method Get -Uri $uri -Headers @{
        'X-Device-Key'=(Get-WEmulDroidBetaSecret $Context)
    } -TimeoutSec 12
}
function Invoke-WEmulDroidBetaEnroll([object]$Context) {
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $body=@{
        app_id='wemuldroid'
        installation_id=$Context.Profile.installation_id
        device_secret=(Get-WEmulDroidBetaSecret $Context)
        platform='windows'
        version=$Context.Version
        label=$Context.Profile.label
        telemetry_consent=[bool]$Context.Profile.telemetry_consent
    } | ConvertTo-Json -Compress
    return Invoke-RestMethod -Method Post -Uri ($Context.Endpoint+'/api/v1/enroll') -Body $body -ContentType 'application/json' -TimeoutSec 15
}
function Show-WEmulDroidBetaGate([object]$Context) {
    if (-not $Context.Enabled) { return $Context }
    $dialog=New-Object System.Windows.Forms.Form
    $dialog.Text='WEmulDroid - Beta Access'
    $dialog.ClientSize=New-Object Drawing.Size(475,260)
    $dialog.StartPosition='CenterScreen'
    $dialog.FormBorderStyle='FixedDialog'
    $dialog.MaximizeBox=$false
    $dialog.Font=New-Object Drawing.Font('Segoe UI',10)
    $info=New-Object Windows.Forms.Label
    $info.Text='Questa beta richiede la tua autorizzazione prima dell''uso.'
    $info.SetBounds(18,15,430,45);$dialog.Controls.Add($info)
    $name=New-Object Windows.Forms.TextBox
    $name.Text=[string]$Context.Profile.label;$name.MaxLength=48
    $name.SetBounds(18,65,435,30);$dialog.Controls.Add($name)
    $status=New-Object Windows.Forms.Label
    $status.Text='Non attiva. Premi Richiedi autorizzazione.'
    $status.SetBounds(18,106,435,54);$dialog.Controls.Add($status)
    $request=New-Object Windows.Forms.Button
    $request.Text='Richiedi autorizzazione'
    $request.SetBounds(18,184,216,38);$dialog.Controls.Add($request)
    $refresh=New-Object Windows.Forms.Button
    $refresh.Text='Controlla stato'
    $refresh.SetBounds(244,184,209,38);$dialog.Controls.Add($refresh)
    $refresh.Add_Click({
        try {
            $status.Text='Controllo autorizzazione…'
            $result=Invoke-WEmulDroidBetaStatus $Context
            if ($result.state -eq 'approved' -and
                ([datetime]::Parse($result.approved_until).ToUniversalTime() -gt [datetime]::UtcNow)) {
                $Context.Allowed=$true
                $Context.Telemetry=([bool]$result.telemetry_consent -and [bool]$Context.Profile.telemetry_consent)
                $dialog.DialogResult=[Windows.Forms.DialogResult]::OK
                $dialog.Close()
            } else {
                $status.Text='Stato: '+[string]$result.state+'. Attendi l''approvazione del proprietario.'
            }
        } catch {
            $status.Text='Autorizzazione non verificabile. Internet necessario per questa beta.'
        }
    })
    $request.Add_Click({
        try {
            if ([string]::IsNullOrWhiteSpace($name.Text)) {$status.Text='Inserisci un nome tester.';return}
            $answer=[Windows.Forms.MessageBox]::Show(
                'Acconsenti a inviare soltanto errori classificati e metriche numeriche (RAM, CPU, tempi) a Diagnostics? Nessun logcat, screenshot, nome PC o account. Puoi rifiutare.',
                'Consenso diagnostica','YesNo','Question')
            $Context.Profile.telemetry_consent=($answer -eq [Windows.Forms.DialogResult]::Yes)
            $Context.Profile.label=$name.Text.Trim()
            Save-WEmulDroidBetaProfile $Context
            [void](Invoke-WEmulDroidBetaEnroll $Context)
            $status.Text='Richiesta inviata. Dopo l''approvazione premi Controlla stato.'
        } catch {
            $status.Text='Impossibile inviare. Verifica Internet e riprova.'
        }
    })
    [void]$dialog.ShowDialog()
    $dialog.Dispose()
    return $Context
}
function Add-WEmulDroidBetaEvent([object]$Context,[string]$Event,[string]$Severity,[hashtable]$Fields) {
    if (-not $Context -or -not $Context.Enabled -or -not $Context.Allowed -or -not $Context.Telemetry) { return }
    if ($Event -notin @('APP_START','APP_EXIT','APP_ERROR','EMULATOR_ERROR','INSTALLER_ERROR','PERF_SAMPLE')) { return }
    if ($Severity -notin @('info','warning','error','critical')) { return }
    $allowed=@('cpu_pct','ram_mb','gpu_pct','fps','startup_ms','duration_ms','io_mb','network_kb','uptime_sec','error_code')
    foreach ($field in @($Fields.Keys)) {
        if ($field -notin $allowed) { return }
        if ($field -eq 'error_code') {
            if ([string]$Fields[$field] -cnotmatch '^[A-Z0-9_-]{1,48}$') { return }
        } else {
            if ($Fields[$field] -isnot [ValueType] -or [double]$Fields[$field] -lt 0) { return }
        }
    }
    $items=@(Get-ChildItem -LiteralPath $Context.Outbox -Filter '*.json' -File -ErrorAction SilentlyContinue)
    if ($items.Count -ge 200 -and $Severity -eq 'info') { return }
    $id=[guid]::NewGuid().ToString()
    $payload=@{
        installation_id=$Context.Profile.installation_id
        event_id=$id
        event=$Event;severity=$Severity;session=$Context.Session
        producer_version=$Context.Version;fields=$Fields
    } | ConvertTo-Json -Compress -Depth 4
    [IO.File]::WriteAllText((Join-Path $Context.Outbox ($id+'.json')),
        $payload,(New-Object Text.UTF8Encoding($false)))
}
function Start-WEmulDroidBetaUpload([object]$Context) {
    if (-not $Context -or -not $Context.Enabled -or -not $Context.Allowed -or -not $Context.Telemetry) { return }
    $script=Join-Path $PSScriptRoot 'BetaUpload.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { return }
    # No token/secret is passed via command line: the uploader reads DPAPI under this user.
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','RemoteSigned',
        '-File',('"' + $script + '"')
    ) | Out-Null
}
