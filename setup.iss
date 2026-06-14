[Setup]
AppName=game_2048
AppVersion=1.0
DefaultDirName={pf}\game_2048
DefaultGroupName=game_2048
OutputBaseFilename=game_2048_Setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\2048 game"; Filename: "{app}\game_2048.exe"
Name: "{commondesktop}\2048 game"; Filename: "{app}\game_2048.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительно:"

[Run]
Filename: "{app}\game_2048.exe"; Description: "Запустить 2048"; Flags: nowait postinstall skipifsilent

[Registry]
; Автозапуск Windows (если нужен)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
ValueType: string; ValueName: "2048 game"; ValueData: """{app}\game_2048.exe"""; Flags: uninsdeletevalue
[Setup]
