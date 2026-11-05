# WEmulDroid desktop layout — responsive three-tab control center.
# Called after existing buttons are created. Reparents controls without
# changing their existing event handlers or Android runtime behavior.

function Initialize-WEmulDroidLayout {
    $form.ClientSize = New-Object System.Drawing.Size(960, 715)
    $form.MinimumSize = New-Object System.Drawing.Size(965, 690)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $form.MaximizeBox = $true

    $titleLabel.SetBounds(20, 14, 608, 43)
    $languageLabel.SetBounds(638, 23, 88, 26)
    $script:LanguageCombo.SetBounds(734, 18, 204, 32)
    $script:DeviceLabel.SetBounds(22, 65, 685, 26)
    $btnSettings.SetBounds(750, 60, 188, 38)

    # High-priority Android lifecycle controls stay visible on every tab.
    $btnSetup.SetBounds(20, 114, 218, 44)
    $btnStart.SetBounds(253, 114, 218, 44)
    $btnRefresh.SetBounds(486, 114, 218, 44)
    $btnStop.SetBounds(719, 114, 219, 44)

    $script:WorkTabs = New-Object System.Windows.Forms.TabControl
    # Android navigation and PC keyboard remain visible above all tabs.
    $btnHome.SetBounds(20, 168, 218, 40)
    $btnBack.SetBounds(253, 168, 218, 40)
    $btnPcKeyboard.SetBounds(486, 168, 218, 40)
    $btnColdBoot.SetBounds(719, 168, 219, 40)

    $script:WorkTabs.SetBounds(20, 224, 918, 270)
    $script:WorkTabs.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
        [System.Windows.Forms.AnchorStyles]::Left -bor
        [System.Windows.Forms.AnchorStyles]::Right

    $script:AppsTab = New-Object System.Windows.Forms.TabPage
    $script:DisplayTab = New-Object System.Windows.Forms.TabPage
    $script:DiagnosticsTab = New-Object System.Windows.Forms.TabPage

    [void]$script:WorkTabs.TabPages.Add($script:AppsTab)
    [void]$script:WorkTabs.TabPages.Add($script:DisplayTab)
    [void]$script:WorkTabs.TabPages.Add($script:DiagnosticsTab)
    $form.Controls.Add($script:WorkTabs)

    # Applications and APK imports.
    $script:AppsTab.Controls.Add($packageLabel)
    $packageLabel.SetBounds(22, 25, 255, 29)
    $script:AppsTab.Controls.Add($script:PackageCombo)
    $script:PackageCombo.SetBounds(272, 21, 612, 32)
    $appControls = @(
        @($btnInstall, 22, 91, 202),
        @($btnApkFolder, 241, 91, 202),
        @($btnApkLink, 460, 91, 202),
        @($btnPlay, 679, 91, 202)
    )
    foreach ($entry in $appControls) {
        $script:AppsTab.Controls.Add($entry[0])
        $entry[0].SetBounds($entry[1], $entry[2], $entry[3], 42)
    }

    # Display, touch, audio and window controls.
    $script:DisplayTab.Controls.Add($screenLabel)
    $screenLabel.SetBounds(22, 24, 160, 29)
    $script:DisplayTab.Controls.Add($script:ScreenCombo)
    $script:ScreenCombo.SetBounds(195, 20, 310, 32)
    $screenControls = @(
        @($btnScreen, 525, 18, 164),
        @($btnScreenReset, 706, 18, 175),
        @($btnCapture, 22, 93, 202),
        @($btnTouchHelp, 241, 93, 202),
        @($btnFullscreen, 460, 93, 202),
        @($btnSplitTouch, 679, 93, 202)
    )
    foreach ($entry in $screenControls) {
        $script:DisplayTab.Controls.Add($entry[0])
        $entry[0].SetBounds($entry[1], $entry[2], $entry[3], 42)
    }
    $script:DisplayTab.Controls.Add($btnCenter)
    $btnCenter.SetBounds(22, 158, 202, 42)
    $script:DisplayTab.Controls.Add($btnToggleSoftKeyboard)
    $btnToggleSoftKeyboard.SetBounds(241, 158, 255, 42)
    $script:DisplayTab.Controls.Add($btnFit)
    $btnFit.SetBounds(514, 158, 367, 42)

    # Diagnostics and destructive snapshot actions are separate from daily use.
    $diagnosticControls = @(
        @($btnMeasure, 22, 27, 202),
        @($btnReports, 241, 27, 202),
        @($btnDiagnostics, 460, 27, 202),
        @($btnSnapshotList, 679, 27, 202),
        @($btnSnapshotSave, 22, 91, 202),
        @($btnSnapshotLoad, 241, 91, 202)
    )
    foreach ($entry in $diagnosticControls) {
        $script:DiagnosticsTab.Controls.Add($entry[0])
        $entry[0].SetBounds($entry[1], $entry[2], $entry[3], 42)
    }

    $logLabel.SetBounds(22, 511, 880, 29)
    $script:LogBox.SetBounds(20, 540, 918, 151)
    $script:LogBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
        [System.Windows.Forms.AnchorStyles]::Right -bor
        [System.Windows.Forms.AnchorStyles]::Bottom -bor
        [System.Windows.Forms.AnchorStyles]::Top
    $logLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
        [System.Windows.Forms.AnchorStyles]::Top
    $script:WorkTabs.SelectedIndex = 0

    # Minimum-size layout: the logs resize with the window and are kept below
    # the tabs. No app, session or screenshot data is cleared when switching.
    $form.Add_Resize({
        $script:LogBox.Height = [Math]::Max(90, $form.ClientSize.Height - $script:LogBox.Top - 24)
    })
}
