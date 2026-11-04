# WEmulDroid Settings > Updates (Windows PowerShell + WinForms)
# Download/check only after a user clicks; install only after a second confirmation.
. (Join-Path $PSScriptRoot 'Updates.ps1')

function Show-WEmulDroidUpdateSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Windows.Forms.Form]$MainForm,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][ValidateSet('Avvia-Android.cmd','Avvia-PlayStore.cmd')][string]$Launcher
    )
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

    $pending = $null
    $candidate = $null

    $beta.Add_CheckedChanged({
        $folder = Split-Path -Parent $betaPath
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($betaPath, $(if ($beta.Checked) { 'true' } else { 'false' }),
            (New-Object Text.UTF8Encoding($false)))
        $candidate = $null
        $pending = $null
        $download.Enabled = $false
        $apply.Enabled = $false
        $status.Text = (T 'updatesDescription')
    })

    $check.Add_Click({
        $check.Enabled = $false
        $dialog.Cursor = [Windows.Forms.Cursors]::WaitCursor
        try {
            $candidate = Find-WEmulDroidUpdate -Current $version -IncludeBeta $beta.Checked
            $download.Enabled = ($null -ne $candidate)
            $apply.Enabled = $false
            $status.Text = if ($candidate) { (T 'updatesFound') + ' ' + $candidate.Tag }
                           else { T 'updatesNoNew' }
        } catch {
            $status.Text = (T 'updatesError') + ' ' + $_.Exception.Message
        } finally {
            $check.Enabled = $true
            $dialog.Cursor = [Windows.Forms.Cursors]::Default
        }
    })

    $download.Add_Click({
        if (-not $candidate) { return }
        $msg = (T 'updatesConfirmDownload') + [Environment]::NewLine +
            $candidate.Tag + [Environment]::NewLine + $script:UpdateRepository
        if ([Windows.Forms.MessageBox]::Show($msg, (T 'updatesTitle'),
            'YesNo', 'Warning') -ne 'Yes') { return }
        $download.Enabled = $false
        $dialog.Cursor = [Windows.Forms.Cursors]::WaitCursor
        try {
            $pending = Save-WEmulDroidUpdate $candidate
            $apply.Enabled = $true
            $status.Text = (T 'updatesDownloaded') + [Environment]::NewLine + $pending
        } catch {
            $status.Text = (T 'updatesError') + ' ' + $_.Exception.Message
            $download.Enabled = $true
        } finally { $dialog.Cursor = [Windows.Forms.Cursors]::Default }
    })

    $apply.Add_Click({
        if (-not $pending) { return }
        $msg = (T 'updatesConfirmApply') + [Environment]::NewLine +
            $candidate.Tag
        if ([Windows.Forms.MessageBox]::Show($msg, (T 'updatesTitle'),
            'YesNo', 'Warning') -ne 'Yes') { return }
        try {
            $updater = Join-Path $InstallRoot 'src\Apply-Update.ps1'
            if (-not (Test-Path -LiteralPath $updater)) { throw 'Updater script missing.' }
            $args = @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                ('"' + $updater + '"'),
                '-InstallRoot', ('"' + $InstallRoot + '"'),
                '-StagedDir', ('"' + $pending + '"'),
                '-WaitPid', [string]$PID,
                '-Launcher', $Launcher
            )
            Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Normal
            $dialog.Close()
            $MainForm.Close() # External process waits for this PowerShell process to exit.
        } catch {
            $status.Text = (T 'updatesError') + ' ' + $_.Exception.Message
        }
    })

    [void]$dialog.ShowDialog($MainForm)
}
