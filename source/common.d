module common;

import core.sys.windows.windows: CommandLineToArgvW, MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import std.windows.registry: Registry, RegistryException, Key, REGSAM;
import std.string: strip, splitLines, indexOf, stripLeft;
import std.uri: encodeComponent;
import std.process: browse;
import std.format: format;
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
/// String of the GitHub issue template.
enum string ISSUE_TEMPLATE = import("issue.txt");

/// Creates a message box telling the user there was an error, and redirect to issues page.
void createErrorDialog(const Exception error) {
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
string createIssueMessage(const Exception error) {
    return ISSUE_TEMPLATE.strip().format(error.file, error.line, error.msg, error.info);
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
    try {
        Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

        return DeflectorSettings(deflectorKey.getValue("EngineURL").value_SZ,
                deflectorKey.getValue("BrowserPath").value_SZ);
    } catch (RegistryException)
        return DeflectorSettings("google.com/search?q={{query}}", "system_default");
}

/// Write settings to registry.
void writeSettings(const DeflectorSettings settings) {
    Key deflectorKey = Registry.currentUser.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

    // Write necessary changes.
    deflectorKey.setValue("EngineURL", settings.engineURL);
    deflectorKey.setValue("BrowserPath", settings.browserPath);

    deflectorKey.flush();
}

/// Get a config in the pattern of "^(?<key>[^:]+)\s*:\s*(?<value>.+)$" from a string.
string[string] parseConfig(const string config) {
    string[string] data;

    foreach (line; config.splitLines()) {
        if (line.stripLeft()[0 .. 2] == "//") // Ignore comments.
            continue;

        const size_t sepIndex = line.indexOf(":");

        const string key = line[0 .. sepIndex].strip();
        const string value = line[sepIndex + 1 .. $].strip();

        data[key] = value;
    }

    return data;
}
