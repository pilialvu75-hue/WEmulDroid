#ifndef AppVersion
  #error "AppVersion define is required"
#endif
#ifndef AppVersionFile
  #error "AppVersionFile define is required"
#endif
#ifndef Payload
  #error "Payload define is required"
#endif
#ifndef WinFileVersion
  #error "WinFileVersion define is required"
#endif

#define ProductName "WEmulDroid"
#define ProductId "{{41C91813-1E2B-4587-A72B-5EF618CD76AE}"

[Setup]
AppId={#ProductId}
AppName={#ProductName}
AppVersion={#AppVersion}
VersionInfoVersion={#WinFileVersion}
AppVerName={#ProductName} {#AppVersion}
AppPublisher=WEmulDroid
AppPublisherURL=https://github.com/pilialvu75-hue/WEmulDroid
AppSupportURL=https://github.com/pilialvu75-hue/WEmulDroid/issues
AppUpdatesURL=https://github.com/pilialvu75-hue/WEmulDroid/releases
DefaultDirName={localappdata}\Programs\WEmulDroid
DefaultGroupName=WEmulDroid
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
UsePreviousLanguage=yes
UsePreviousTasks=yes
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
Uninstallable=yes
UninstallDisplayIcon={app}\WEmulDroid.exe
SetupIconFile={#Payload}\WEmulDroid.ico
OutputDir={#Payload}\Output
OutputBaseFilename=WEmulDroid-Setup-{#AppVersionFile}
ArchitecturesAllowed=x64
MinVersion=10.0.19041
DisableWelcomePage=no
AllowNoIcons=no
#ifdef WEMULDROID_SIGNED
SignTool=signer
SignedUninstaller=yes
#else
SignedUninstaller=no
#endif

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "{#Payload}\WEmulDroid.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\WEmulDroid.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\CHANNEL.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\src\*.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "{#Payload}\docs\*.md"; DestDir: "{app}\docs"; Flags: ignoreversion
Source: "{#Payload}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
; Android SDK, emulator images, Play Store content, AVDs and diagnostics are
; deliberately outside the installation directory and are never deleted here.

[Icons]
Name: "{group}\WEmulDroid"; Filename: "{app}\WEmulDroid.exe"; IconFilename: "{app}\WEmulDroid.ico"
Name: "{group}\WEmulDroid - Google Play"; Filename: "{app}\WEmulDroid.exe"; Parameters: "--play"; IconFilename: "{app}\WEmulDroid.ico"
Name: "{autodesktop}\WEmulDroid"; Filename: "{app}\WEmulDroid.exe"; IconFilename: "{app}\WEmulDroid.ico"

[Run]
Filename: "{app}\WEmulDroid.exe"; Description: "{cm:LaunchProgram,WEmulDroid}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  // Installation is intentionally per-user. It never changes BIOS/Hyper-V,
  // installs SDK packages silently, or removes Android devices.
  Result := True;
end;
