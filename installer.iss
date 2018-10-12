#define AppVersion "0.2.3"
#define AppBranch "master"

[Setup]
AllowNetworkDrive=no
AllowUNCPath=no
AppContact=support@spikespaz.com
AppCopyright=Copyright (c) 2018 Jacob Birkett
AppId=spikespaz-search-deflector
AppName=Search Deflector
AppPublisher=spikespaz
AppPublisherURL=https://spikespaz.com
AppReadmeFile=https://github.com/spikespaz/search-deflector/blob/master/README.md
AppSupportURL=https://github.com/spikespaz/search-deflector/issues
AppUpdatesURL=https://github.com/spikespaz/search-deflector/releases
AppVerName=Search Deflector {#AppVersion}
AppVersion={#AppVersion}
AppModifyPath={app}\setup.exe
ChangesAssociations=yes
Compression=lzma
DefaultDirName={pf32}\Search Deflector
DefaultGroupName=Search Deflector
DisableWelcomePage=no
InfoBeforeFile=installer.txt
LicenseFile=build\LICENSE
MinVersion=10.0
OutputBaseFilename=SearchDeflector-Installer
SetupIconFile=icons\icon.ico
Uninstallable=yes
UninstallDisplayName=Search Deflector
UninstallDisplayIcon={app}\setup.exe
VersionInfoVersion={#AppVersion}
VersionInfoDescription=Search Deflector {#AppVersion} Installer
WizardSmallImageFile=icons\icon.bmp
OutputDir=build

[Files]
Source: "build\{#AppVersion}-master\*"; \
    Excludes: "LICENSE"; \
    DestDir: "{app}"; \
    Flags: recursesubdirs
Source: "build\LICENSE"; \
    DestDir: "{app}"
Source: "updatetask.xml"; \
    DestDir: "{tmp}"

[Icons]
Name: "{group}\Configure"; \
    Filename: "{app}\setup.exe"; \
    Flags: excludefromshowinnewinstall preventpinning
Name: "{group}\Force Update"; \
    Filename: "{app}\updater.exe"; \
    Flags: excludefromshowinnewinstall preventpinning
Name: "{group}\Visit Website"; \
    Filename: "https://github.com/spikespaz/search-deflector"

[Run]
Filename: "{app}\setup.exe"; \
    Flags: hidewizard
Filename: "schtasks"; \
    Parameters: "/CREATE /F /TN ""Search Deflector Updater"" /XML ""{tmp}\updatetask.xml"""; \
    Flags: runhidden
Filename: "schtasks"; \
    Parameters: "/CHANGE /TN ""Search Deflector Updater"" /TR ""{app}\updater.exe"""; \
    Flags: runhidden

[UninstallRun]
Filename: "schtasks"; \
    Parameters: "/DELETE /F /TN ""Search Deflector Updater"""; \
    Flags: runhidden

[Registry]
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    Flags: uninsdeletekey
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "FriendlyTypeName"; \
    ValueData: "Search Deflector"; \
    ValueType: string
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "URL Protocol"; \
    ValueType: string
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector\shell\open\command"; \
    ValueData: """{app}\deflector.exe"" ""%1"""; \
    ValueType: string
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector\DefaultIcon"; \
    ValueData: """{app}\deflector.exe,0"""; \
    ValueType: string
Root: HKLM; \
    Subkey: "Software\SearchDeflector"; \
    Flags: uninsdeletekey
Root: HKLM; \
    Subkey: "Software\SearchDeflector\Capabilities\URLAssociations"; \
    ValueName: "microsoft-edge"; \
    ValueData: "SearchDeflector"; \
    ValueType: string
Root: HKLM; \
    Subkey: "Software\RegisteredApplications"; \
    ValueName: "SearchDeflector"; \
    ValueData: "Software\SearchDeflector\Capabilities"; \
    ValueType: string; \
    Flags: uninsdeletevalue

