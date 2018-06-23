import std.stdio : writeln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.array : split;
import helpers : getChoice;

// The predefined search engines for the user to select. Custom URL is not here because it requires special input.
// The auto formatting is disabled because dfmt doesn't like associative array literals.
// dfmt off
immutable string[string] engines;
static this() {
    engines = [
        "Google": "google.com/search?q={{query}}",
        "DuckDuckGo": "duckduckgo.com/?q={{query}}",
        "Bing": "bing.com/search?q={{query}}",
        "Yahoo": "search.yahoo.com/search?p={{query}}",
        "Wikipedia": "wikipedia.org/wiki/Special:Search?search={{query}}",
        "GitHub": "github.com/search?q={{query}}",
        "Wolfram Alpha": "wolframalpha.com/input/?i={{query}}",
        "Ask": "ask.com/web?q={{query}}"
    ];
}
// dfmt on

void main() {
    writeln(getBrowserChoice(getAvailableBrowsers()));
    writeln(getEngineChoice(engines));
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
