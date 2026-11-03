# WEmulDroid - installazione APK da file/cartella/link HTTPS (nessuna installazione silenziosa)
# Funzioni senza effetti collaterali durante l'importazione.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

function Assert-ApkUri([string]$value) {
    $uri = $null
    if (-not [System.Uri]::TryCreate($value, [System.UriKind]::Absolute, [ref]$uri)) {
        throw 'Indirizzo URL non valido. Usa un link HTTPS diretto a APK o a una release GitHub.'
    }
    if ($uri.Scheme -ne 'https' -or -not [string]::IsNullOrEmpty($uri.UserInfo)) {
        throw 'Sono consentiti solo link HTTPS senza credenziali nell URL.'
    }
    if ($uri.Host -eq 'localhost' -or $uri.Host.EndsWith('.local') -or
        $uri.Host.EndsWith('.internal') -or $uri.Host.EndsWith('.localhost')) {
        throw 'Indirizzi locali non ammessi.'
    }
    $ip = $null
    if ([System.Net.IPAddress]::TryParse($uri.Host, [ref]$ip)) {
        throw 'I link diretti a indirizzi IP non sono ammessi.'
    }
    return $uri
}

function Resolve-ApkDownloadUri([string]$value) {
    $uri = Assert-ApkUri $value
    # Solo per URL web GitHub: estrai l APK di una release ufficiale.
    # Non ricreare download di APK da sorgenti, non modificare il repository collegato.
    if ($uri.Host -eq 'github.com' -and
        $uri.AbsolutePath -match '^/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/releases/(latest|tag/([^/]+))/?$') {
        $owner = $Matches[1]
        $repository = $Matches[2]
        $tag = $Matches[4]
        if ($uri.AbsolutePath -match '/releases/latest/?$') {
            $apiUrl = "https://api.github.com/repos/$owner/$repository/releases/latest"
        } else {
            $apiUrl = "https://api.github.com/repos/$owner/$repository/releases/tags/$([uri]::EscapeDataString([uri]::UnescapeDataString($tag)))"
        }
        $headers = @{'User-Agent'='WEmulDroid/0.5';'Accept'='application/vnd.github+json'}
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 30
        if ($release.draft) { throw 'Questa release non e pubblica.' }
        $assets = @($release.assets | Where-Object { $_.name -match '(?i)\.apk$' -and $_.browser_download_url })
        if ($assets.Count -eq 0) {
            throw 'La release non contiene file .apk. Un file AAB non si puo installare direttamente.'
        }
        if ($assets.Count -gt 1) {
            $names = ($assets | ForEach-Object { $_.name }) -join ', '
            throw ('Questa release contiene piu APK. Apri GitHub e copia il link all asset specifico: ' + $names)
        }
        $uri = Assert-ApkUri ([string]$assets[0].browser_download_url)
    }
    if (-not $uri.AbsolutePath.EndsWith('.apk', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Il link deve terminare in .apk oppure essere la pagina releases/latest o releases/tag/... di GitHub.'
    }
    return $uri
}

function Assert-LocalApk([string]$path) {
    $file = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($file.PSIsContainer -or $file.Extension -ine '.apk') {
        throw 'Seleziona un file .apk (i pacchetti .aab/.apks/.xapk non sono installabili singolarmente).'
    }
    if ($file.Length -lt 1024 -or $file.Length -gt 1GB) {
        throw 'Dimensione APK non valida: limite iniziale di 1 GiB.'
    }
    $archive = $null
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($file.FullName)
        if (-not $archive.GetEntry('AndroidManifest.xml')) {
            throw 'APK non valido: manca AndroidManifest.xml.'
        }
    } catch {
        throw ('Il file non sembra un APK valido: ' + $_.Exception.Message)
    } finally {
        if ($archive) { $archive.Dispose() }
    }
    return $file
}

function Get-RemoteApk([string]$value, [string]$folder) {
    $uri = Resolve-ApkDownloadUri $value
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $name = [IO.Path]::GetFileName([uri]::UnescapeDataString($uri.AbsolutePath))
    $name = $name -replace '[^a-zA-Z0-9._-]', '_'
    if (-not $name.EndsWith('.apk', [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Nome APK non valido.' }
    $id = [guid]::NewGuid().ToString('N').Substring(0,8)
    $path = Join-Path $folder ("$id-$name")
    $temp = $path + '.partial'
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $false
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromMinutes(15)
    $stream = $null
    $response = $null
    $output = $null
    try {
        for ($redirects = 0; $redirects -le 6; $redirects++) {
            if ($response) { $response.Dispose(); $response = $null }
            $response = $client.GetAsync($uri, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
            $code = [int]$response.StatusCode
            if ($code -ge 300 -and $code -lt 400) {
                if (-not $response.Headers.Location) { throw 'Redirect senza indirizzo di destinazione.' }
                $next = [System.Uri]::new($uri, $response.Headers.Location)
                $uri = Assert-ApkUri $next.AbsoluteUri
                continue
            }
            if ($code -lt 200 -or $code -ge 300) {
                throw ('Download non riuscito (HTTP ' + $code + ').')
            }
            break
        }
        if ($redirects -gt 6) { throw 'Troppi redirect nel download.' }
        $declared = $response.Content.Headers.ContentLength
        if ($declared -and $declared -gt 1GB) {
            throw 'Il download supera il limite di 1 GiB.'
        }
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $output = [System.IO.File]::Open($temp, [System.IO.FileMode]::CreateNew)
        $buffer = New-Object byte[] 65536
        [long]$received = 0
        while (($n = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $received += $n
            if ($received -gt 1GB) { throw 'Download interrotto: oltre 1 GiB.' }
            $output.Write($buffer, 0, $n)
        }
        $output.Dispose(); $output = $null
        $stream.Dispose(); $stream = $null
        if ($declared -and $received -ne $declared) { throw 'Download incompleto (dimensioni non corrispondenti).' }
        [IO.File]::Move($temp, $path)
        [void](Assert-LocalApk $path)
        return $path
    } catch {
        if ($output) { $output.Dispose(); $output = $null }
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
        throw
    } finally {
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Dispose() }
        $client.Dispose()
        $handler.Dispose()
    }
}

function Install-VerifiedApk([string]$adb, [string]$serial, [string]$path) {
    $file = Assert-LocalApk $path
    $sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $output = (& $adb -s $serial install -r -t $file.FullName 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $output -notmatch '(?im)^Success\s*$') {
        throw ('Installazione rifiutata dal dispositivo: ' + $output.Trim())
    }
    return ('Installato ' + $file.Name + ' (' + [math]::Round($file.Length/1MB,1) + ' MiB; SHA256 ' + $sha256 + ')')
}
