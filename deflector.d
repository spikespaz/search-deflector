import std.stdio : writeln;
import std.windows.registry;

void main(string[] args) {
    writeln(getAvailableBrowsers());
}

string[string] getAvailableBrowsers() {
    string[string] availableBrowsers;
    auto startMenuInternetKey = Registry.localMachine.getKey("SOFTWARE\\CLIENTS\\StartMenuInternet");

    foreach (key; startMenuInternetKey.keys()) {
        string browserName = key.getValue("").value_SZ();
        string browserPath = key.getKey("shell\\open\\command").getValue("").value_SZ();

        if (browserPath[0] == '"' && browserPath[$ - 1] == '"')
            browserPath = browserPath[1 .. $ - 1];

        availableBrowsers[browserName] = browserPath;
    }

    return availableBrowsers;
}
