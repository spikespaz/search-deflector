[Setup]

AllowNetworkDrive=no
AllowUNCPath=no
AppContact=support@spikespaz.com
AppCopyright=Copyright (C) 2019 Jacob Birkett
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
InfoBeforeFile=pack\message.txt
LicenseFile=build\vars\license.txt
MinVersion=10.0
OutputBaseFilename=SearchDeflector-Installer
SetupIconFile=assets\logo.ico
Uninstallable=yes
UninstallDisplayName=Search Deflector
UninstallDisplayIcon={app}\setup.exe
VersionInfoVersion={#AppVersion}
VersionInfoDescription=Search Deflector {#AppVersion} Installer
WizardSmallImageFile=assets\logo.bmp
WizardImageFile=assets\wizard.bmp
OutputDir=build\dist
SourceDir=..

[Types]

Name: "full"; \
    Description: "Recommended Installation"
Name: "custom"; \
    Description: "Custom Installation"; \
    Flags: iscustom

[Components]

Name: "main"; \
    Description: "Application Files"; \
    Types: full custom; \
    Flags: Fixed
Name: "updater"; \
    Description: "Automatic Updater"; \
    Types: full custom

[Tasks]

Name: "localmachine"; \
    Description: "Register for all users"; \
    Flags: unchecked

[Files]

Source: "build\bin\setup.exe"; \
    DestDir: "{app}"; \
    Components: main
Source: "build\bin\deflector.exe"; \
    DestDir: "{app}"; \
    Components: main
Source: "build\vars\license.txt"; \
    DestDir: "{app}"; \
    Components: main


Source: "build\bin\libcurl.dll"; \
    DestDir: "{app}"; \
    Components: updater
Source: "build\bin\updater.exe"; \
    DestDir: "{app}"; \
    Components: updater
Source: "pack\updatetask.xml"; \
    DestDir: "{tmp}"; \
    Components: updater

[Icons]

Name: "{group}\Configure"; \
    Filename: "{app}\setup.exe"; \
    Flags: excludefromshowinnewinstall preventpinning; \
    Components: main
Name: "{group}\Visit Website"; \
    Filename: "https://spikespaz.com/search-deflector"; \
    Components: main


Name: "{group}\Force Update"; \
    Filename: "{app}\updater.exe"; \
    Flags: excludefromshowinnewinstall preventpinning; \
    Components: updater

[Run]

Filename: "{app}\setup.exe"; \
    Flags: hidewizard skipifsilent; \
    Components: main

Filename: "schtasks"; \
    Parameters: "/CREATE /F /TN ""Search Deflector Updater"" /XML ""{tmp}\updatetask.xml"""; \
    Flags: runhidden; \
    Components: updater
Filename: "schtasks"; \
    Parameters: "/CHANGE /TN ""Search Deflector Updater"" /TR ""{app}\updater.exe"""; \
    Flags: runhidden; \
    Components: updater

[UninstallRun]

Filename: "schtasks"; \
    Parameters: "/DELETE /F /TN ""Search Deflector Updater"""; \
    Flags: runhidden; \
    Components: updater

[Registry]

Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    Flags: uninsdeletekey; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "FriendlyTypeName"; \
    ValueData: "Search Deflector"; \
    ValueType: string; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "URL Protocol"; \
    ValueType: string; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector\shell\open\command"; \
    ValueData: """{app}\deflector.exe"" ""%1"""; \
    ValueType: string; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\Classes\SearchDeflector\DefaultIcon"; \
    ValueData: """{app}\deflector.exe,0"""; \
    ValueType: string; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\SearchDeflector"; \
    Flags: uninsdeletekey; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\SearchDeflector\Capabilities\URLAssociations"; \
    ValueName: "microsoft-edge"; \
    ValueData: "SearchDeflector"; \
    ValueType: string; \
    Components: main; \
    Tasks: localmachine
Root: HKLM; \
    Subkey: "Software\RegisteredApplications"; \
    ValueName: "SearchDeflector"; \
    ValueData: "Software\SearchDeflector\Capabilities"; \
    ValueType: string; \
    Flags: uninsdeletevalue; \
    Components: main; \
    Tasks: localmachine


Root: HKCU; \
    Subkey: "Software\Classes\SearchDeflector"; \
    Flags: uninsdeletekey; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "FriendlyTypeName"; \
    ValueData: "Search Deflector"; \
    ValueType: string; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\Classes\SearchDeflector"; \
    ValueName: "URL Protocol"; \
    ValueType: string; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\Classes\SearchDeflector\shell\open\command"; \
    ValueData: """{app}\deflector.exe"" ""%1"""; \
    ValueType: string; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\Classes\SearchDeflector\DefaultIcon"; \
    ValueData: """{app}\deflector.exe,0"""; \
    ValueType: string; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\SearchDeflector"; \
    Flags: uninsdeletekey; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\SearchDeflector\Capabilities\URLAssociations"; \
    ValueName: "microsoft-edge"; \
    ValueData: "SearchDeflector"; \
    ValueType: string; \
    Components: main; \
    Tasks: not localmachine
Root: HKCU; \
    Subkey: "Software\RegisteredApplications"; \
    ValueName: "SearchDeflector"; \
    ValueData: "Software\SearchDeflector\Capabilities"; \
    ValueType: string; \
    Flags: uninsdeletevalue; \
    Components: main; \
    Tasks: not localmachine


Root: HKCU; \
    Subkey: "Software\Clients\SearchDeflector"; \
    Flags: uninsdeletekey; \
    Components: main
Root: HKCU; \
    Subkey: "Software\Clients\SearchDeflector"; \
    ValueName: "EngineURL"; \
    ValueData: "google.com/search?q={{{{query}}"; \
    ValueType: string;
Root: HKCU; \
    Subkey: "Software\Clients\SearchDeflector"; \
    ValueName: "BrowserPath"; \
    ValueData: "system_default"; \
    ValueType: string;

[Code]

{
    The below code is from Martin Prikryl on Stack Overflow.
    https://stackoverflow.com/a/40949812/2512078
}

var InfoBeforeCheck: TNewCheckBox;

procedure CheckInfoBeforeRead;
begin
    WizardForm.NextButton.Enabled := InfoBeforeCheck.Checked;
end;

procedure InfoBeforeCheckClick(Sender: TObject);
begin
    CheckInfoBeforeRead;
end;

procedure InitializeWizard();
begin
    InfoBeforeCheck := TNewCheckBox.Create(WizardForm);
    InfoBeforeCheck.Parent := WizardForm.InfoBeforePage;
    InfoBeforeCheck.Top := WizardForm.LicenseNotAcceptedRadio.Top;
    InfoBeforeCheck.Left := WizardForm.LicenseNotAcceptedRadio.Left;
    InfoBeforeCheck.Width := WizardForm.LicenseNotAcceptedRadio.Width;
    InfoBeforeCheck.Height := WizardForm.LicenseNotAcceptedRadio.Height;
    InfoBeforeCheck.Caption := 'I promise that I have read the above information';
    InfoBeforeCheck.OnClick := @InfoBeforeCheckClick;

    WizardForm.InfoBeforeMemo.Height :=
        ((WizardForm.LicenseMemo.Top + WizardForm.LicenseMemo.Height) -
            WizardForm.InfoBeforeMemo.Top) +
        (InfoBeforeCheck.Top - WizardForm.LicenseAcceptedRadio.Top);
end;

procedure CurPageChanged(CurPageID: Integer);
begin
    if CurPageID = wpInfoBefore then
    begin
        CheckInfoBeforeRead;
    end;
end;
