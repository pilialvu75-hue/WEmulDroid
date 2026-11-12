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
            approval_sound = $true
            label = 'Tester WEmulDroid'
        }
        [IO.File]::WriteAllText($profilePath,($profile | ConvertTo-Json -Compress),
            (New-Object Text.UTF8Encoding($false)))
    }
    # Existing installation profiles default to the sound; never overwrite their consent.
    if (-not $profile.PSObject.Properties['approval_sound']) {
        $profile | Add-Member -MemberType NoteProperty -Name 'approval_sound' -Value $true
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
        AwaitingApproval=$false
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
    } -TimeoutSec 5
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
function New-WEmulDroidBetaApprovalWav {
    # Pure function: generate a compact original confirmation chime without external assets.
    $sampleRate = 22050
    $durations = @(0.14, 0.035, 0.18)
    $tones = @(587.33, 0.0, 783.99)
    $totalSamples = [int][Math]::Ceiling(($durations | Measure-Object -Sum).Sum * $sampleRate)
    $stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'))
        $writer.Write([int](36 + $totalSamples * 2))
        $writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
        $writer.Write([int]16)
        $writer.Write([int16]1)
        $writer.Write([int16]1)
        $writer.Write([int]$sampleRate)
        $writer.Write([int]($sampleRate * 2))
        $writer.Write([int16]2)
        $writer.Write([int16]16)
        $writer.Write([Text.Encoding]::ASCII.GetBytes('data'))
        $writer.Write([int]($totalSamples * 2))
        $written = 0
        for ($segment = 0; $segment -lt $durations.Length; $segment++) {
            $count = if ($segment -eq $durations.Length - 1) {
                $totalSamples - $written
            } else { [int][Math]::Round($durations[$segment] * $sampleRate) }
            for ($i = 0; $i -lt $count; $i++) {
                $sample = 0.0
                if ($tones[$segment] -gt 0) {
                    $t = $i / [double]$sampleRate
                    $edge = [Math]::Min(1.0, [Math]::Min($i, $count - $i - 1) / 150.0)
                    $sample = 0.12 * $edge * [Math]::Sin(2.0 * [Math]::PI * $tones[$segment] * $t)
                }
                $writer.Write([int16][Math]::Round([Math]::Max(-1.0,[Math]::Min(1.0,$sample)) * 32767.0))
            }
            $written += $count
        }
        $writer.Flush()
        # Ensure the caller gets a single byte array, not one PowerShell object per sample.
        return ,([byte[]]$stream.ToArray())
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Play-WEmulDroidBetaApprovalChime([object]$Context) {
    # Playback is strictly optional. No missing audio device may block activation.
    if (-not $Context -or -not [bool]$Context.Profile.approval_sound) { return }
    try {
        $wav = [byte[]](New-WEmulDroidBetaApprovalWav)
        $stream = [System.IO.MemoryStream]::new($wav)
        try {
            $player = [System.Media.SoundPlayer]::new($stream)
            $player.PlaySync()
        } finally {
            $stream.Dispose()
        }
    } catch {
        # Approval is authoritative regardless of sound availability.
    }
}

function Test-WEmulDroidBetaApproval([object]$ServerStatus,[datetime]$NowUtc=[datetime]::UtcNow) {
    # Only an authenticated server response with a non-expired lease may unlock a gated client.
    # Never assume approval when the server omits expiry or returns malformed status data.
    if (-not $ServerStatus -or [string]$ServerStatus.state -cne 'approved' -or
        [string]::IsNullOrWhiteSpace([string]$ServerStatus.approved_until)) {
        return $false
    }
    $expires=[datetime]::MinValue
    $parsed=[datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse(
        [string]$ServerStatus.approved_until,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal,
        [ref]$parsed)) { return $false }
    return $parsed.UtcDateTime -gt $NowUtc.ToUniversalTime()
}

function Show-WEmulDroidBetaGate([object]$Context) {
    if (-not $Context.Enabled) { return $Context }
    # The Windows client waits for the server's decision and unlocks automatically.
    # No approval is cached: a signed-in tester must have a valid server-side lease.
    $dialog=New-Object System.Windows.Forms.Form
    $dialog.Text='WEmulDroid - Beta Access'
    $dialog.ClientSize=New-Object Drawing.Size(475,285)
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
    $playChime=New-Object System.Windows.Forms.CheckBox
    $playChime.Text='Suono breve quando l''app si sblocca'
    $playChime.Checked=[bool]$Context.Profile.approval_sound
    $playChime.SetBounds(18,182,435,26);$dialog.Controls.Add($playChime)
    $request=New-Object Windows.Forms.Button
    $request.Text='Richiedi autorizzazione'
    $request.SetBounds(18,222,435,38);$dialog.Controls.Add($request)

    # Poll the authenticated status while the activation window is open.
    # TLS, device-key verification and expiry are enforced on the server.
    # A short timeout bounds the synchronous WinForms call (pilot implementation).
    $timer=New-Object System.Windows.Forms.Timer
    $timer.Interval=8000
    $checking=$false
    $timer.Add_Tick({
        if ($checking -or $dialog.IsDisposed) { return }
        $timer.Interval=8000
        $checking=$true
        try {
            $answer=Invoke-WEmulDroidBetaStatus $Context
            if (Test-WEmulDroidBetaApproval $answer) {
                $Context.Allowed=$true
                $Context.Telemetry=([bool]$answer.telemetry_consent -and [bool]$Context.Profile.telemetry_consent)
                $Context.Profile.approval_sound=[bool]$playChime.Checked
                # Preference persistence and sound are best effort; authorization wins.
                try { Save-WEmulDroidBetaProfile $Context } catch {}
                $timer.Stop()
                if ($Context.AwaitingApproval) {
                    Play-WEmulDroidBetaApprovalChime $Context
                }
                $dialog.DialogResult=[Windows.Forms.DialogResult]::OK
                $dialog.Close()
            } elseif ($answer.state -eq 'pending') {
                $Context.AwaitingApproval=$true
                $status.Text='Richiesta in attesa. Il programma si aprirà automaticamente dopo l''approvazione.'
            } elseif ($answer.state -eq 'denied' -or $answer.state -eq 'revoked') {
                $status.Text='Accesso rifiutato o revocato. Puoi inviare una nuova richiesta.'
            } elseif ($answer.state -eq 'expired') {
                $status.Text='Autorizzazione scaduta. Premi Richiedi autorizzazione per rinnovarla.'
            } else {
                $status.Text='In attesa della prima richiesta di autorizzazione.'
            }
        } catch {
            # Fail closed; do not unlock on an HTTP or network error.
            $status.Text='Verifica automatica non disponibile. Controlla la connessione Internet.'
        } finally {
            $checking=$false
        }
    })
    # Check promptly on first launch, then keep a bounded polling interval.
    $dialog.Add_Shown({ $timer.Interval=500; $timer.Start() })
    $dialog.Add_FormClosed({ $timer.Stop() })
    $request.Add_Click({
        $request.Enabled=$false
        try {
            if ([string]::IsNullOrWhiteSpace($name.Text)) {
                $status.Text='Inserisci un nome tester.'
                return
            }
            $answer=[Windows.Forms.MessageBox]::Show(
                'Acconsenti a inviare soltanto errori classificati e metriche numeriche (RAM, CPU, tempi) a Diagnostics? Nessun logcat, screenshot, nome PC o account. Puoi rifiutare.',
                'Consenso diagnostica','YesNo','Question')
            $Context.Profile.telemetry_consent=($answer -eq [Windows.Forms.DialogResult]::Yes)
            $Context.Profile.approval_sound=[bool]$playChime.Checked
            $Context.Profile.label=$name.Text.Trim()
            Save-WEmulDroidBetaProfile $Context
            [void](Invoke-WEmulDroidBetaEnroll $Context)
            $Context.AwaitingApproval=$true
            $status.Text='Richiesta inviata. Attendi: WEmulDroid si sbloccherà automaticamente.'
        } catch {
            $status.Text='Impossibile inviare. Verifica Internet e riprova.'
        } finally {
            $request.Enabled=$true
        }
    })
    try { [void]$dialog.ShowDialog() }
    finally {
        $timer.Stop()
        $timer.Dispose()
        $dialog.Dispose()
    }
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
