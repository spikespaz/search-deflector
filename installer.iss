#define AppVersion "0.1.0"
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
AppVerName=Search Deflector v0.1.0
AppVersion={#AppVersion}-{#AppBranch}
ChangesEnvironment=yes
Compression=lzma
DefaultDirName={pf32}\Search Deflector
DefaultGroupName="Search Deflector"
InfoBeforeFile=README.rtf
LicenseFile=LICENSE
MinVersion=10.0.10240
OutputBaseFilename=SearchDeflector-Installer
SetupIconFile=icons\icon.ico
Uninstallable=yes
UninstallDisplayName=Search Deflector
VersionInfoVersion={#AppVersion}
WizardSmallImageFile=icons\icon.bmp
OutputDir=build

[Files]
Source: "build\{#AppVersion}-{#AppBranch}\*"; DestDir: "{app}\{#AppVersion}-{#AppBranch}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Configure Search Deflector"; Filename: "{app}\{#AppVersion}-{#AppBranch}\setup.exe"
Name: "{group}\Uninstall Search Deflector"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppVersion}-{#AppBranch}\setup.exe"; Description: "Configure Search Deflector"; Flags: hidewizard
