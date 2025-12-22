#define MyAppName "Onlog Satıcı Paneli"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Onlog"
#define MyAppURL "https://onlog.com"
#define MyAppExeName "onlog_merchant_panel.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\OnlogMerchantPanel
DisableProgramGroupPage=yes
LicenseFile=
OutputDir=C:\onlog_projects\onlog_merchant_panel\build\windows\installer
OutputBaseFilename=OnlogMerchantPanel_Setup_v1.0.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=C:\onlog_projects\onlog_merchant_panel\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\onlog_projects\onlog_merchant_panel\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
