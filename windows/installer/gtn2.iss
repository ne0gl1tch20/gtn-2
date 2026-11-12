#define MyAppName "GuessTheNumber"
#ifndef AppVersion
  #define AppVersion "2.0.0"
#endif
#define MyAppExeName "gtn_2.exe"

[Setup]
AppId={{B3E3C9B5-4B57-4D5B-9F21-4E2F7B4A6C21}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher=Jarrlyy
DefaultDirName={autopf}\GuessTheNumber
DefaultGroupName=GuessTheNumber
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
OutputDir=..\..\dist\windows
OutputBaseFilename=GuessTheNumber-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\GuessTheNumber"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\GuessTheNumber"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch GuessTheNumber"; Flags: nowait postinstall skipifsilent
