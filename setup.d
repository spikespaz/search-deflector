module setup;

import std.stdio : write, writeln, readln;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.array : split;
import std.net.curl : get, CurlException;
import std.conv : parse, ConvException;
import std.string : toLower, strip, splitLines, indexOf, stripLeft;
import std.windows.registry;


// Online resource to the repository of the project containing a list of search engine choices.
immutable string enginesURL = "https://raw.githubusercontent.com/spikespaz/search-deflector/master/engines.txt";

// Function to run when setting up the deflector.
void setup(const string filePath) {
    // dfmt off
    writeln("Welcome to Search Deflector setup.\n",
            "Just answer the prompts in this terminal to set your preferences, and you should be good to go.\n",
            "If you have any questions, please email me at 'support@spikespaz.com',\n",
            "or create an Issue on the GitHub repository (https://github.com/spikespaz/search-deflector/issues).\n");
    // dfmt on

    const string enginesText = get(enginesURL).idup; // Get the string of the resource content.

    const string[string] browsers = getAvailableBrowsers();
    const string[string] engines = parseConfig(enginesText);

    const string browser = getBrowserChoice(browsers);
    const string engine = getEngineChoice(engines);
    const string engineURL = engine == "Custom URL" ? getCustomEngine() : engines[engine];

    // dfmt off
    writeln("Search Deflector will be set up using the following variables.\n",
            "If these are incorrect, run this executable again without any arguments passed to restart the setup.\n",
            "\nSearch Engine: ", engine,
            "\nSearch Engine URL: ", engineURL,
            "\nBrowser: ", browser);
    // dfmt on

    if (browser != "System Default" && browser != "Microsoft Edge")
        writeln("Browser Path: ", browsers[browser]);
}


// Fetch a list of available browsers from the Windows registry along with their paths.
// Use the names as the keys in an associative array containing the browser executable paths.
string[string] getAvailableBrowsers() {
    string[string] availableBrowsers;
    auto startMenuInternetKey = Registry.localMachine.getKey("SOFTWARE\\CLIENTS\\StartMenuInternet");

    foreach (key; startMenuInternetKey.keys) {
        string browserName = key.getValue("").value_SZ;
        string browserPath = key.getKey("shell\\open\\command").getValue("").value_SZ;

        if (browserPath[0] == '"' && browserPath[$ - 1] == '"')
            browserPath = browserPath[1 .. $ - 1];

        availableBrowsers[browserName] = browserPath;
    }

    return availableBrowsers;
}

// Helper function to ask the user to pick one of the strings passed in as choices.
string getChoice(const string[] choices) {
    foreach (index, choice; choices.enumerate(1))
        writeln("[", index, "]: ", choice);

    write("\nSelection: ");
    int selection = getValidatedInput(readln(), choices.length);

    while (selection == -1) {
        write("Please make a valid selection: ");
        selection = getValidatedInput(readln(), choices.length);
    }

    string choice = choices[selection - 1];

    write("\nYou chose '" ~ choice ~ "'.\nIs this correct? (Y/n): ");

    if (readln().strip().toLower() == "n") {
        writeln();
        return getChoice(choices);
    }
    else {
        writeln();
        return choice;
    }
}

// Ask the user which browser they want to use from the available options found in registry.
// Optional extras for Edge and the system default browser, requires custom handling.
string getBrowserChoice(const string[string] browsers) {
    string[] choices = browsers.keys.sort().array;

    foreach (index, choice; choices.enumerate())
        choices[index] = choice ~ " ~ " ~ browsers[choice];

    choices ~= ["Microsoft Edge", "System Default"]; // Each of these strings, if returned, need special handling.

    writeln("Please make a selection of one of the browsers below.\n");

    string choice = getChoice(choices).split(" ~ ")[0];
    return choice;
}

// Similar to getBrowserChoice(), this function asks the user which search engine they prefer.
// If the user chooses the "Custom URL" option, the return value must be handled specially,
// asking for further input (their own search URL).
string getEngineChoice(const string[string] engines) {
    string[] choices = engines.keys.sort().array;
    choices ~= "Custom URL"; // This string needs custom handling if returned.

    writeln("Please make a selection of one of the search engines below.\n");

    string choice = getChoice(choices);
    return choice;
}

// Validate that a string is a proper numeral between 1 and maxValue inclusive for the getChoice function.
int getValidatedInput(const string input, const int maxValue) {
    string temp = input.strip();

    try {
        const int result = temp.parse!int();
        if (result > maxValue || result < 1)
            return -1;
        else
            return result;
    }
    catch (ConvException)
        return -1; // Since the minimum choice index is 1, just return -1 if the input is invalid.
}

// Ask the user for a custom engine URL and validate the input.
string getCustomEngine() {
    // dfmt off
    writeln("Please enter a custom search engine URL.\n",
            "Include the string '{{query}}' which will be replaced with the search component.\n",
            "For example, Google would be 'google.com/search?q={{query}}'.");
    // dfmt on

    write("\nURL: ");
    string url = readln().strip();

    while (!validateEngineURL(url)) {
        write("Please enter a valid URL: ");
        url = readln().strip();
    }

    write("\nYou entered '" ~ url ~ "'.\nIs this correct? (Y/n): ");

    if (readln().strip().toLower() == "n") {
        writeln();
        return getCustomEngine();
    }
    else {
        writeln();
        return url;
    }
}

// Validate that a user's custom search engine URL is a valid candidate.
bool validateEngineURL(const string url) {
    if (url.indexOf("{{query}}") == -1)
        return false;

    try {
        if (get(url))
            return true;
        else
            return false;
    }
    catch (CurlException) {
        return false;
    }
}

// Get a config in the pattern of "^(?<key>[^:]+)\s*:\s*(?<value>.+)$" from a string.
string[string] parseConfig(const string config) {
    string[string] data;

    foreach (line; config.splitLines()) {
        if (line.stripLeft()[0 .. 2] == "//") // Ignore comments.
            continue;

        const int sepIndex = line.indexOf(":");

        const string key = line[0 .. sepIndex].strip();
        const string value = line[sepIndex + 1 .. $].strip();

        data[key] = value;
    }

    return data;
}
