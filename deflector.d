import std.stdio : write, writeln, readln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.conv : to, parse, ConvException;
import std.string : toLower, strip;

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

void main() {
    writeln(getEngineChoice(engines));
    // writeln(getBrowserChoice(getAvailableBrowsers()));
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

string getBrowserChoice(const string[string] browsers) {
    string[] choices = sort(browsers.keys).array;

    writeln("Please make a selection of one of the browsers below.\n");

    foreach (index, choice; choices.enumerate(1))
        writeln('[' ~ index.to!string() ~ "]: " ~ choice ~ " - (" ~ browsers[choice] ~ ')');

    writeln('[' ~ (choices.length + 1).to!string() ~ "]: Microsoft Edge");
    writeln('[' ~ (choices.length + 2).to!string() ~ "]: System Default");

    write("\nSelection: ");
    int selection = getValidatedInput(readln(), choices.length + 2);

    while (selection == -1) {
        write("Please make a valid selection: ");
        selection = getValidatedInput(readln(), choices.length + 2);
    }

    string choice;

    if (selection == choices.length + 1)
        choice = "Microsoft Edge";
    else if (selection == choices.length + 2)
        choice = "System Default";
    else
        choice = choices[selection - 1];

    write("\nYou chose '" ~ choice ~ "', is this correct? (Y/n): ");

    if (readln().strip().toLower() == "n") {
        writeln();
        return getBrowserChoice(browsers);
    }
    else
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
