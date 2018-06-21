import std.stdio : write, writeln, readln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.string : leftJustify;
import std.conv : to, parse;

void main(string[] args) {
    writeln(getBrowserChoice(getAvailableBrowsers()));
}

string getBrowserChoice(string[string] browsers) {
    string[] choices = sort(browsers.keys).array;

    writeln("Please make a selection of one of the browsers below.\n");

    foreach (index, choice; choices.enumerate(1))
        writeln('[' ~ to!(string)(index) ~ "]: " ~ choice ~ " - (" ~ browsers[choice] ~ ')');

    writeln('[' ~ to!(string)(choices.length + 1) ~ "]: Microsoft Edge");
    writeln('[' ~ to!(string)(choices.length + 2) ~ "]: System Default");


    write("\nSelection: ");
    string selection = readln();

    return choices[parse!(int)(selection) - 1];
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
