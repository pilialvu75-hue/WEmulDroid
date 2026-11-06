# WEmulDroid Settings > Updates (Windows PowerShell + WinForms)
# Download/check only after a user clicks; install only after a second confirmation.
. (Join-Path $PSScriptRoot 'InstallerUpdates.ps1')

# Report the Windows policy failure without implying a network or GitHub outage.
# The phase is supplied by the UI action; no security policy is changed here.
function Format-WEmulDroidUpdateError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('check','download','install')][string]$Phase,
        [Parameter(Mandatory)][string]$Message
    )
    $phaseName = switch ($Phase) {
        'check' { 'Ricerca aggiornamenti' }
        'download' { 'Download/verifica aggiornamento' }
        'install' { 'Avvio installer' }
    }
    if ($Message -match '(?i)(criterio di controllo dell.applicazione|application control policy|code integrity policy|enterprise signing level|app control policy|0x800711c7)') {
        return "$phaseName - Blocco di sicurezza Windows (Smart App Control / Code Integrity). Il file potrebbe non soddisfare i requisiti di firma. Apri Visualizzatore eventi > Registri applicazioni e servizi > Microsoft > Windows > CodeIntegrity > Operational e controlla gli eventi 3077/3033 allo stesso orario. Non disattivare le protezioni Windows. Dettaglio: $Message"
    }
    return "$phaseName - $Message"
}

function Show-WEmulDroidUpdateSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Windows.Forms.Form]$MainForm,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][ValidateSet('Avvia-Android.cmd','Avvia-PlayStore.cmd')][string]$Launcher
    )
    $channelFile = Join-Path $InstallRoot 'CHANNEL.txt'
    if ((Test-Path -LiteralPath $channelFile -PathType Leaf) -and
        ([IO.File]::ReadAllText($channelFile)).Trim() -eq 'store-preview') {
        [Windows.Forms.MessageBox]::Show(
            'La versione Microsoft Store riceve aggiornamenti soltanto dallo Store. Questo pacchetto di prova non e ancora certificato o installabile su Smart App Control.',
            'WEmulDroid - Microsoft Store', 'OK', 'Information') | Out-Null
        return
    }
    $versionFile = Join-Path $InstallRoot 'VERSION.txt'
    if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) { throw 'WEmulDroid VERSION.txt not found.' }
    $version = ([IO.File]::ReadAllText($versionFile)).Trim()

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = (T 'updatesTitle')
    $dialog.ClientSize = New-Object System.Drawing.Size(570, 390)
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.StartPosition = 'CenterParent'
    $dialog.MaximizeBox = $false
    $dialog.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = (T 'updatesVersion') + ': ' + $version
    $versionLabel.SetBounds(20, 20, 535, 26)
    $dialog.Controls.Add($versionLabel)

    $beta = New-Object System.Windows.Forms.CheckBox
    $beta.Text = (T 'updatesBeta')
    $beta.SetBounds(20, 54, 530, 34)
    $betaPath = Join-Path $env:LOCALAPPDATA 'WEmulDroid\Settings\updates-beta.txt'
    $beta.Checked = (Test-Path -LiteralPath $betaPath) -and
        (([IO.File]::ReadAllText($betaPath)).Trim() -eq 'true')
    $dialog.Controls.Add($beta)

    $check = New-Object System.Windows.Forms.Button
    $check.Text = (T 'updatesCheck')
    $check.SetBounds(20, 112, 170, 38)
    $dialog.Controls.Add($check)
    $download = New-Object System.Windows.Forms.Button
    $download.Text = (T 'updatesDownload')
    $download.SetBounds(199, 112, 170, 38)
    $download.Enabled = $false
    $dialog.Controls.Add($download)
    $apply = New-Object System.Windows.Forms.Button
    $apply.Text = (T 'updatesApply')
    $apply.SetBounds(378, 112, 170, 38)
    $apply.Enabled = $false
    $dialog.Controls.Add($apply)

    $status = New-Object System.Windows.Forms.TextBox
    $status.Multiline = $true
    $status.ReadOnly = $true
    $status.ScrollBars = 'Vertical'
    $status.SetBounds(20, 170, 528, 140)
    $status.Text = (T 'updatesDescription')
    $dialog.Controls.Add($status)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = (T 'updatesClose')
    $close.SetBounds(378, 329, 170, 36)
    $close.Add_Click({ $dialog.Close() })
    $dialog.Controls.Add($close)

    $script:WEmulDroidUpdatePending = $null
    $script:WEmulDroidUpdateCandidate = $null

    $beta.Add_CheckedChanged({
        $folder = Split-Path -Parent $betaPath
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($betaPath, $(if ($beta.Checked) { 'true' } else { 'false' }),
            (New-Object Text.UTF8Encoding($false)))
        $script:WEmulDroidUpdateCandidate = $null
        $script:WEmulDroidUpdatePending = $null
        $download.Enabled = $false
        $apply.Enabled = $false
        $status.Text = (T 'updatesDescription')
    })

    $check.Add_Click({
        $check.Enabled = $false
        $dialog.Cursor = [Windows.Forms.Cursors]::WaitCursor
        try {
            $script:WEmulDroidUpdateCandidate = Find-WEmulDroidInstallerUpdate -Current $version -IncludeBeta $beta.Checked
            $download.Enabled = ($null -ne $script:WEmulDroidUpdateCandidate)
            $apply.Enabled = $false
            $status.Text = if ($script:WEmulDroidUpdateCandidate) { (T 'updatesFound') + ' ' + $script:WEmulDroidUpdateCandidate.Tag }
                           else { T 'updatesNoNew' }
        } catch {
            $status.Text = (T 'updatesError') + ' ' + (Format-WEmulDroidUpdateError -Phase 'check' -Message $_.Exception.Message)
        } finally {
            $check.Enabled = $true
            $dialog.Cursor = [Windows.Forms.Cursors]::Default
        }
    })

    $download.Add_Click({
        if (-not $script:WEmulDroidUpdateCandidate) { return }
        $msg = (T 'updatesConfirmDownload') + [Environment]::NewLine +
            $script:WEmulDroidUpdateCandidate.Tag + [Environment]::NewLine + $script:UpdateRepository
        if ([Windows.Forms.MessageBox]::Show($msg, (T 'updatesTitle'),
            'YesNo', 'Warning') -ne 'Yes') { return }
        $download.Enabled = $false
        $dialog.Cursor = [Windows.Forms.Cursors]::WaitCursor
        try {
            $script:WEmulDroidUpdatePending = Save-WEmulDroidInstallerUpdate -Release $script:WEmulDroidUpdateCandidate -InstalledLauncher (Join-Path $InstallRoot 'WEmulDroid.exe')
            $apply.Enabled = $true
            $status.Text = (T 'updatesDownloaded') + [Environment]::NewLine + $script:WEmulDroidUpdatePending
        } catch {
            $status.Text = (T 'updatesError') + ' ' + (Format-WEmulDroidUpdateError -Phase 'download' -Message $_.Exception.Message)
            $download.Enabled = $true
        } finally { $dialog.Cursor = [Windows.Forms.Cursors]::Default }
    })

    $apply.Add_Click({
        if (-not $script:WEmulDroidUpdatePending) { return }
        $msg = (T 'updatesConfirmApply') + [Environment]::NewLine +
            $script:WEmulDroidUpdateCandidate.Tag
        if ([Windows.Forms.MessageBox]::Show($msg, (T 'updatesTitle'),
            'YesNo', 'Warning') -ne 'Yes') { return }
        try {
            $exe = $script:WEmulDroidUpdatePending
            [void](Assert-WEmulDroidInstallerSignature -Installer $exe -InstalledLauncher (Join-Path $InstallRoot 'WEmulDroid.exe'))
            # Inno Setup handles in-use files, version replacement and uninstall
            # registration. No direct writes into the program directory.
            Start-Process -FilePath $exe -ArgumentList @('/CLOSEAPPLICATIONS','/NORESTART')
            $dialog.Close()
            $MainForm.Close()
        } catch {
            $status.Text = (T 'updatesError') + ' ' + (Format-WEmulDroidUpdateError -Phase 'install' -Message $_.Exception.Message)
        }
    })

    [void]$dialog.ShowDialog($MainForm)
}
