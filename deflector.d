import std.stdio : write, writeln, readln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.array : split;
import std.string : indexOf, strip, toLower;
import helpers : getChoice, parseConfig;
import std.net.curl : get, CurlException;

// Online resource to the repository of the project containing a list of search engine choices.
immutable string enginesURL = "https://raw.githubusercontent.com/spikespaz/search-deflector/master/engines.txt";

void main(string[] args) {
    if (args.length > 1)
        deflect(args[1]);
    else
        setup(args[0]);
}

// Function to run when setting up the deflector.
void setup(const string filePath) {
    // For some reason, the formatter puts this all on one line (even though it's only for this one).
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

    writeln("Search Deflector will be set up using the following variables.\n",
            "If these are incorrect, run this executable again without any arguments passed to restart the setup.\n",
            "\nSearch Engine: ", engine,
            "\nSearch Engine URL: ", engineURL,
            "\nBrowser: ", browser);

    if (browser != "System Default" && browser != "Microsoft Edge")
        writeln("Browser Path: ", browsers[browser]);
}

// Function to run after setup, actually deflected.
void deflect(const string url) {
    writeln(url); // Debug for now, just print the URL argument.
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

// Ask the user for a custom engine URL and validate the input.
string getCustomEngine() {
    writeln("Please enter a custom search engine URL.\n"
            ~ "Include the string '{{query}}' which will be replaced with the search component.\n"
            ~ "For example, Google would be 'google.com/search?q={{query}}'.");

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
