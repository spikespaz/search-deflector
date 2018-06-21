import std.stdio : write, writeln, readln;
import std.windows.registry;
import std.algorithm.sorting : sort;
import std.range : array, enumerate;
import std.conv : to, parse, ConvException;
import std.string : toLower, strip;

void main() {
    writeln(getBrowserChoice(getAvailableBrowsers()));
}

int getValidatedInput(string input, int maxValue) {
    try {
        const int result = parse!(int)(input);
        if (result > maxValue || result < 1)
            return -1;
        else
            return result;
    }
    catch (ConvException)
        return -1;
}

string getBrowserChoice(string[string] browsers) {
    string[] choices = sort(browsers.keys).array;

    writeln("Please make a selection of one of the browsers below.\n");

    foreach (index, choice; choices.enumerate(1))
        writeln('[' ~ to!(string)(index) ~ "]: " ~ choice ~ " - (" ~ browsers[choice] ~ ')');

    writeln('[' ~ to!(string)(choices.length + 1) ~ "]: Microsoft Edge");
    writeln('[' ~ to!(string)(choices.length + 2) ~ "]: System Default");

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
