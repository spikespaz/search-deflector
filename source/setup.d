module setup;

import std.windows.registry: Key, Registry, REGSAM, RegistryException;
import std.string: toLower, strip, splitLines, indexOf, stripLeft;
import common: createErrorDialog, getConsoleArgs, VERSION;
import std.file: thisExePath, readText, isFile, exists;
import std.path: buildPath, dirName, isValidFilename;
import std.socket: getAddress, SocketOSException;
import std.regex: Regex, regex, matchFirst;
import std.stdio: write, writeln, readln;
import std.net.curl: get, CurlException;
import std.conv: parse, ConvException;
import std.datetime: Clock, SysTime;
import std.range: array, enumerate;
import std.algorithm: sort;
import std.utf: toUTF16z;
import std.array: split;

/// Online resource to the repository of the project containing a list of search engine choices.
enum string enginesURL = "https://raw.githubusercontent.com/spikespaz/search-deflector/master/engines.txt";

void main() {
    writeln("Version: " ~ VERSION);

    try
        setup(buildPath(thisExePath().dirName(), "launcher.exe"));
    catch (Exception error)
        createErrorDialog(error);

    writeln("\nPress Enter to close the setup.");
    readln();
}

/// Function to run when setting up the deflector.
void setup(const string filePath) {
    // dfmt off
    writeln("Welcome to Search Deflector setup.\n",
            "Just answer the prompts in this terminal to set your preferences, and you should be good to go.\n",
            "If you have any questions, please email me at 'support@spikespaz.com',\n",
            "or create an Issue on the GitHub repository (https://github.com/spikespaz/search-deflector/issues).\n\n",
            "Don't forget to star the repository on GitHub so people see it!\n");
    // dfmt on

    const string[string] browsers = getAvailableBrowsers();
    const string[string] engines = getEnginePresets();

    const string browserName = getBrowserChoice(browsers);
    string browserPath;

    switch (browserName) {
    case "System Default":
        browserPath = "system_default";
        break;
    case "Custom Path":
        browserPath = getCustomBrowser();
        break;
    default:
        browserPath = browsers[browserName];
    }

    const string engineName = getEngineChoice(engines);
    string engineURL;

    switch (engineName) {
    case "Custom URL":
        engineURL = getCustomEngine;
        break;
    default:
        engineURL = engines[engineName];
    }

    // dfmt off
    writeln("Search Deflector will be set up using the following variables.\n",
            "If these are incorrect, run this executable again without any arguments passed to restart the setup.\n",
            "\nSearch Engine: ", engineURL,
            "\nBrowser: ", browserPath);
    // dfmt on

    registerHandler(filePath, engineName, engineURL, browserName, browserPath);
}

/// Make necessary registry modifications to register the application as a handler for the Edge protocol.
void registerHandler(const string filePath, const string engineName, const string engineURL,
        const string browserName, const string browserPath) {
    // Try to open each one, if it doesn't exist, make it.
    Key deflectorKey = Registry.currentUser.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);
    Key uriClassKey = Registry.classesRoot.createKey("SearchDeflector", REGSAM.KEY_WRITE);
    Key iconKey = uriClassKey.createKey("DefaultIcon", REGSAM.KEY_WRITE);
    Key shellCommandKey = uriClassKey.createKey("shell\\open\\command", REGSAM.KEY_WRITE);
    Key softwareKey = Registry.localMachine.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);
    Key capabilityKey = softwareKey.createKey("Capabilities", REGSAM.KEY_WRITE);
    Key urlAssociationsKey = capabilityKey.createKey("UrlAssociations", REGSAM.KEY_WRITE);
    Key registeredAppsKey = Registry.localMachine.createKey("SOFTWARE\\RegisteredApplications", REGSAM.KEY_WRITE);

    // Write necessary changes.
    deflectorKey.setValue("EngineURL", engineURL);
    deflectorKey.setValue("BrowserPath", browserPath);
    deflectorKey.setValue("LastUpdateCheck", Clock.currTime.toISOString());

    uriClassKey.setValue("", "Search Deflector");
    uriClassKey.setValue("URL Protocol", "");

    iconKey.setValue("", filePath ~ ",0");

    shellCommandKey.setValue("", '"' ~ filePath ~ "\" \"%1\"");

    capabilityKey.setValue("ApplicationName", "Search Deflector");
    // dfmt off
    capabilityKey.setValue("ApplicationDescription",
        "Force web links for MS Edge to be opened with your preferred browser and search engine.");
    // dfmt on

    urlAssociationsKey.setValue("microsoft-edge", "SearchDeflector");
    registeredAppsKey.setValue("SearchDeflector", "SOFTWARE\\Clients\\SearchDeflector\\Capabilities");

    // Flush all of the keys and write changes.
    deflectorKey.flush();
    uriClassKey.flush();
    iconKey.flush();
    shellCommandKey.flush();
    softwareKey.flush();
    capabilityKey.flush();
    urlAssociationsKey.flush();
    registeredAppsKey.flush();
}

/// Fetch a list of available browsers from the Windows registry along with their paths.
/// Use the names as the keys in an associative array containing the browser executable paths.
string[string] getAvailableBrowsers() {
    string[string] availableBrowsers;
    Key startMenuInternetKey = Registry.localMachine.getKey("SOFTWARE\\Clients\\StartMenuInternet");

    foreach (key; startMenuInternetKey.keys) {
        string browserName = key.getValue("").value_SZ;
        string browserPath = key.getKey("shell\\open\\command").getValue("").value_SZ;

        if (!isValidFilename(browserPath) && !exists(browserPath)) {
            browserPath = getConsoleArgs(browserPath.toUTF16z())[0];

            if (!isValidFilename(browserPath) && !exists(browserPath))
                continue;
        }

        availableBrowsers[browserName] = browserPath;
    }

    return availableBrowsers;
}

/// Try to fetch the engine presets from the repository, if it fails, read from local.
string[string] getEnginePresets() {
    string enginesText;

    try
        enginesText = get(enginesURL).idup; // Get the string of the resource content.
    catch (CurlException)
        enginesText = readText(buildPath(thisExePath().dirName(), "engines.txt"));

    return parseConfig(enginesText);
}

/// Helper function to ask the user to pick one of the strings passed in as choices.
string getChoice(const string[] choices) {
    foreach (index, choice; choices.enumerate(1))
        writeln("[", index, "]: ", choice);

    write("\nSelection: ");
    size_t selection = getValidatedInput(readln(), choices.length);

    while (selection == -1) {
        write("Please make a valid selection: ");
        selection = getValidatedInput(readln(), choices.length);
    }

    string choice = choices[selection - 1];

    write("\nYou chose '" ~ choice ~ "'.\nIs this correct? (Y/n): ");

    if (readln().strip().toLower() == "y") {
        writeln();
        return choice;
    } else {
        writeln();
        return getChoice(choices);
    }
}

/// Ask the user which browser they want to use from the available options found in registry.
/// Optional extras for Edge and the system default browser, requires custom handling.
string getBrowserChoice(const string[string] browsers) {
    string[] choices = browsers.keys.sort().array;

    foreach (index, choice; choices.enumerate())
        choices[index] = choice ~ " ~ " ~ browsers[choice];

    choices ~= ["System Default", "Custom Path"]; // Each of these strings, if returned, need special handling.

    writeln("Please make a selection of one of the browsers below.\n");

    string choice = getChoice(choices).split(" ~ ")[0];
    return choice;
}

/// Similar to getBrowserChoice(), this function asks the user which search engine they prefer.
/// If the user chooses the "Custom URL" option, the return value must be handled specially,
/// asking for further input (their own search URL).
string getEngineChoice(const string[string] engines) {
    string[] choices = engines.keys.sort().array;
    choices ~= "Custom URL"; // This string needs custom handling if returned.

    writeln("Please make a selection of one of the search engines below.\n");

    string choice = getChoice(choices);
    return choice;
}

/// Validate that a string is a proper numeral between 1 and maxValue inclusive for the getChoice function.
int getValidatedInput(const string input, const size_t maxValue) {
    string temp = input.strip();

    try {
        const int result = temp.parse!int();
        if (result > maxValue || result < 1)
            return -1;
        else
            return result;
    } catch (ConvException)
        return -1; // Since the minimum choice index is 1, just return -1 if the input is invalid.
}

/// Ask the user for a custom engine URL and validate the input.
string getCustomEngine() {
    // dfmt off
    writeln("Please enter a custom search engine URL.\n",
            "Include the string '{{query}}' which will be replaced with the search component.\n",
            "For example, Google would be 'google.com/search?q={{query}}'.");
    // dfmt on

    write("\nURL: ");
    string url = readln().strip();

    while (!validateEngineUrl(url)) {
        write("Please enter a valid URL: ");
        url = readln().strip();
    }

    write("\nYou entered '" ~ url ~ "'.\nIs this correct? (Y/n): ");

    if (readln().strip().toLower() == "y") {
        writeln();
        return url;
    } else {
        writeln();
        return getCustomEngine();
    }
}

/// Ask the user for a custom browser path and validate it.
string getCustomBrowser() {
    const Regex!char pathRegex = regex(`^\s*(["']|)\s*(.+?)\s*(\1)\s*$`);

    writeln("Please enter a custom browser path.");
    write("\nPath: ");

    string path = readln().matchFirst(pathRegex)[2];

    while (!path || !exists(path) || !isFile(path)) {
        write("Please enter a valid path: ");
        path = readln().matchFirst(pathRegex)[2];
    }

    write("\nYou entered '" ~ path ~ "'.\nIs this correct? (Y/n): ");

    if (readln().strip().toLower() == "y") {
        writeln();
        return path;
    } else {
        writeln();
        return getCustomBrowser();
    }
}

/// Validate that a user's custom search engine URL is a valid candidate.
bool validateEngineUrl(const string url) {
    if (url.indexOf("{{query}}") == -1)
        return false;

    try {
        const ptrdiff_t slashIndex = url.indexOf("/");

        if (slashIndex == -1)
            getAddress(url);
        else
            getAddress(url[0 .. slashIndex]);

        return true;
    } catch (SocketOSException)
        return false;
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
