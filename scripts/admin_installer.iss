; Mubashir Admin Portal - Inno Setup Script
#define AppName "Mubashir Admin Portal"
#define AppVersion "1.0.0"
#define AppPublisher "Mubashir Real Estate"
#define AppExeName "mubashir_real_estate.exe"
#define BuildPath "..\build\windows\x64\runner\Release"

[Setup]
AppId={{MUBASHIR-ADMIN-PORTAL-GUID}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
OutputBaseFilename=MubashirAdmin_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildPath}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildPath}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildPath}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
