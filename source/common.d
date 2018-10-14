module common;

import core.sys.windows.windows: CommandLineToArgvW, MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import std.windows.registry: Registry, RegistryException, Key, REGSAM;
import std.datetime: SysTime, DateTime;
import std.json: JSONValue, parseJSON;
import std.string: split, toStringz;
import std.uri: encodeComponent;
import std.range: zip, popFront;
import std.algorithm: sort;
import std.process: browse;
import std.format: format;
import std.net.curl: get;
import std.utf: toUTF16z;
import std.conv: to;

/// File name of the executable to download and run to install an update.
enum string SETUP_FILENAME = "SearchDeflector-Installer.exe";
/// Repository path information for Search Deflector, https://github.com/spikespaz/search-deflector.
enum string PROJECT_AUTHOR = "spikespaz";
enum string PROJECT_NAME = "search-deflector"; /// ditto
/// Current version of the Search Deflector binaries.
enum string PROJECT_VERSION = import("version.txt");

/// String of search engine templates.
enum string ENGINE_TEMPLATES = import("engines.txt");

// Old constants. Will be removed when other executables are updated.
/// Public version strings determined at compile time.
enum string VERSION = import("version.txt");
enum string UPDATE_FILE = "SearchDeflector-Installer.exe"; /// ditto
enum string RELEASES_URL = "https://api.github.com/repos/%s/%s/releases"; /// ditto

/// Creates a messabe box telling the user there was an error, and redirect to issues page.
public void createErrorDialog(const Exception error) {
    const uint messageId = MessageBox(null,
            "Search Deflector launch failed. Would you like to open the issues page to submit a bug report?" ~
            "\nThe important information will be filled out for you." ~
            "\n\nIf you do not wish to create a bug report, click 'No' to exit.",
            "Search Deflector", MB_ICONERROR | MB_YESNO);

    // dfmt off
    if (messageId == IDYES)
        browse("https://github.com/spikespaz/search-deflector/issues/new?body=" ~
            createIssueMessage(error).encodeComponent());
    // dfmt on
}

/// Creates a GitHub issue body with the data from an Exception.
public string createIssueMessage(const Exception error) {
    return "I have encountered an error launching Search Deflector.
The error information follows below.

**File:** `%s`

**Line:** %s

**Message:**
```
%s
```

**Stack Trace:**
```
%s
```
".format(error.file, error.line, error.msg, error.info);
}

/// Get all current releases as JSON from the GitHub API.
public JSONValue getReleases(const string author, const string repository) {
    return get(RELEASES_URL.format(author, repository)).parseJSON();
}

/// Return a JSONValue array sorted by the `tag_name` as semantic versions.
public JSONValue[] getSortedReleases(const string author, const string repository) {
    JSONValue[] releasesArray = getReleases(author, repository).array;

    // dfmt off
    releasesArray.sort!(
        (firstVer, secondVer) => compareVersions(firstVer["tag_name"].str, secondVer["tag_name"].str)
    );
    // dfmt on

    return releasesArray;
}

/// Return the latest release according to semantic versioning.
public JSONValue getLatestRelease(const string author, const string repository) {
    return getSortedReleases(author, repository)[0];
}

/// Compare two semantic versions, returning true if the first version is newer, false otherwise.
public bool compareVersions(const string firstVer, const string secondVer) {
    ushort[] firstVerParts = firstVer.split('.').to!(ushort[]);
    ushort[] secondVerParts = secondVer.split('.').to!(ushort[]);

    while (firstVerParts.length > secondVerParts.length) {
        if (firstVerParts[0] != 0)
            return true;
        firstVerParts.popFront();
    }

    while (secondVerParts.length > firstVerParts.length) {
        if (secondVerParts[0] != 0)
            return false;
        secondVerParts.popFront();
    }

    foreach (verParts; zip(firstVerParts, secondVerParts)) {
        if (verParts[0] > verParts[1])
            return true;
        else if (verParts[1] > verParts[0])
            return false;
    }

    return false;
}

/// Get the last recorded update check time.
public SysTime lastUpdateCheck() {
    Key deflectorKey;

    try {
        deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

        return SysTime.fromISOString(deflectorKey.getValue("LastUpdateCheck").value_SZ);
    } catch (RegistryException)
        return SysTime(DateTime(0, 1, 1));
}

/// Set the new last update check time.
public void lastUpdateCheck(SysTime checkTime) {
    Key deflectorKey;

    try
        deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);
    catch (RegistryException)
        deflectorKey = Registry.currentUser.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

    deflectorKey.setValue("LastUpdateCheck", checkTime.toISOString());

    deflectorKey.flush();
}

/// Return a string array of arguments that are parsed in ArgV style from a string.
string[] getConsoleArgs(const wchar* commandLine) {
    int argCount;
    wchar** argList = CommandLineToArgvW(commandLine, &argCount);
    string[] args;

    for (int index; index < argCount; index++)
        args ~= argList[index].to!string();

    return args;
}

/// Struct representing the settings to use for deflection.
struct DeflectorSettings {
    string engineURL; /// ditto
    string browserPath; /// ditto
}

/// Read the settings from the registry.
DeflectorSettings readSettings() {
    Key deflectorKey = registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

    return DeflectorSettings(deflectorKey.getValue("EngineURL").value_SZ, deflectorKey.getValue("BrowserPath").value_SZ);
}

/// Write settings to registry.
void writeSettings(const DeflectorSettings settings) {
    Key deflectorKey = Registry.currentUser.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

    // Write necessary changes.
    deflectorKey.setValue("EngineURL", settings.engineURL);
    deflectorKey.setValue("BrowserPath", settings.browserPath);

    deflectorKey.flush();
}
