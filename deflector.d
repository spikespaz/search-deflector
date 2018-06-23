import std.stdio : write, writeln, readln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.conv : to, parse, ConvException;
import std.string : toLower, strip;
import std.array : split;

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

int getValidatedInput(const string input, const int maxValue) {
    string temp = input;

    try {
        const int result = temp.parse!int();
        if (result > maxValue || result < 1)
            return -1;
        else
            return result;
    }
    catch (ConvException)
        return -1;
}

string getChoice(string[] choices) {
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
    else
        return choice;
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
