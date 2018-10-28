module setup;

import common: DeflectorSettings, parseConfig, writeSettings, createErrorDialog, getConsoleArgs,
    PROJECT_VERSION, ENGINE_TEMPLATES;
import std.windows.registry: Registry, Key;
import std.string: strip, split, indexOf, toLower;
import std.socket: SocketException, getAddress;
import std.regex: Regex, regex, matchFirst;
import std.stdio: write, writeln, readln;
import std.conv: ConvException, parse;
import std.path: isValidFilename;
import std.file: exists, isFile;
import std.range: enumerate;
import std.algorithm: sort;
import std.utf: toUTF16z;
import std.range: array;

void main() {
    writeln("Version: " ~ PROJECT_VERSION);

    try {
        const string[string] browsers = getAvailableBrowsers();
        const string[string] engines = parseConfig(ENGINE_TEMPLATES);

        DeflectorSettings settings = promptSettings(browsers, engines);

        writeSettings(settings);
    } catch (Exception error) {
        createErrorDialog(error);
    }

    writeln("\nPress Enter to close the setup.");
    readln();
}

/// Function to run when setting up the deflector.
DeflectorSettings promptSettings(const string[string] browsers, const string[string] engines) {
    // dfmt off
    writeln("Welcome to the Search Deflector setup.\n",
            "Just answer the prompts in this terminal to set your preferences, and you should be good to go.\n",
            "If you have any questions, please email me at 'support@spikespaz.com',\n",
            "or create an Issue on the GitHub repository (https://github.com/spikespaz/search-deflector/issues).\n\n",
            "Don't forget to star the repository on GitHub so people see it!\n");
    // dfmt on

    DeflectorSettings settings;

    const string browserName = promptBrowserChoice(browsers);

    switch (browserName) {
    case "System Default":
        settings.browserPath = "system_default";
        break;
    case "Custom Path":
        settings.browserPath = promptBrowserPath();
        break;
    default:
        settings.browserPath = browsers[browserName];
    }

    const string engineName = promptEngineChoice(engines);

    switch (engineName) {
    case "Custom URL":
        settings.engineURL = promptCustomEngine();
        break;
    default:
        settings.engineURL = engines[engineName];
    }

    // dfmt off
    writeln("Search Deflector will be set up using the following variables.\n",
            "If these are incorrect, run this executable again without any arguments passed to restart the setup.\n",
            "\nSearch Engine: \"", settings.engineURL, "\"",
            "\nBrowser: \"", settings.browserPath, "\"");
    // dfmt on

    return settings;
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

/// Helper function to ask the user to pick one of the strings passed in as choices.
string promptChoice(const string[] choices) {
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
        return promptChoice(choices);
    }
}

/// Ask the user which browser they want to use from the available options found in registry.
/// Optional extras for Edge and the system default browser, requires custom handling.
string promptBrowserChoice(const string[string] browsers) {
    string[] choices = browsers.keys.sort().array;

    foreach (index, choice; choices.enumerate())
        choices[index] = choice ~ " ~ " ~ browsers[choice];

    choices ~= ["System Default", "Custom Path"]; // Each of these strings, if returned, need special handling.

    writeln("Please make a selection of one of the browsers below.\n");

    string choice = promptChoice(choices).split(" ~ ")[0];
    return choice;
}

/// Similar to getBrowserChoice(), this function asks the user which search engine they prefer.
/// If the user chooses the "Custom URL" option, the return value must be handled specially,
/// asking for further input (their own search URL).
string promptEngineChoice(const string[string] engines) {
    string[] choices = engines.keys.sort().array;
    choices ~= "Custom URL"; // This string needs custom handling if returned.

    writeln("Please make a selection of one of the search engines below.\n");

    string choice = promptChoice(choices);
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
string promptCustomEngine() {
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
        return promptCustomEngine();
    }
}

/// Ask the user for a custom browser path and validate it.
string promptBrowserPath() {
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
        return promptBrowserPath();
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
    } catch (SocketException)
        return false;
}
