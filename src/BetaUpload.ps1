# Separate background uploader. Nothing sensitive on command line or in the outbox.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'BetaAccess.ps1')
try {
    $ctx=Get-WEmulDroidBetaContext (Split-Path -Parent $PSScriptRoot)
    if (-not $ctx.Enabled -or -not $ctx.Telemetry) { exit 0 }
    $secret=Get-WEmulDroidBetaSecret $ctx
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $files=@(Get-ChildItem -LiteralPath $ctx.Outbox -Filter '*.json' -File |
        Sort-Object CreationTime | Select-Object -First 25)
    foreach($file in $files) {
        try {
            if ($file.Length -gt 4096) { continue }
            $text=[IO.File]::ReadAllText($file.FullName)
            $res=Invoke-RestMethod -Method Post -Uri ($ctx.Endpoint+'/api/v1/telemetry') -Headers @{'X-Device-Key'=$secret} -Body $text -ContentType 'application/json' -TimeoutSec 12
            if ($res.accepted) { Remove-Item -LiteralPath $file.FullName -Force }
            else { break }
        } catch { break } # Retain for next attempt, no tokens or raw exception logged.
    }
} catch { exit 1 }
