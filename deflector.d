import std.stdio : writeln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.array : split;
import helpers : getChoice;

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
    writeln(getEngineChoice(engines));
    writeln(getBrowserChoice(getAvailableBrowsers()));
}

string getBrowserChoice(const string[string] browsers) {
    string[] choices = browsers.keys.sort().array;

    foreach (index, choice; choices.enumerate())
        choices[index] = choice ~ " ~ " ~ browsers[choice];

    choices ~= ["Microsoft Edge", "System Default"];

    writeln("Please make a selection of one of the browsers below.\n");

    string choice = getChoice(choices).split(" ~ ")[0];
    return choice;
}

string getEngineChoice(const string[string] engines) {
    string[] choices = engines.keys.sort().array;
    choices ~= "Custom URL";

    writeln("Please make a selection of one of the search engines below.\n");

    string choice = getChoice(choices);
    return choice;
}

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
