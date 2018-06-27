module deflect;

import std.windows.registry;
import std.process : spawnShell;
import std.string : replace;
import std.stdio : writeln;

// Function to run after setup, actually deflected.
void deflect(const string url) {
    const string[string] registryInfo = getRegistryInfo();

    openURL(registryInfo["BrowserPath"], registryInfo["EngineURL"].replace("{{query}}", "Test+Search"));
}

string[string] getRegistryInfo() {
    Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

    return [
        "BrowserName": deflectorKey.getValue("BrowserName").value_SZ,
        "BrowserPath": deflectorKey.getValue("BrowserPath").value_SZ,
        "EngineName": deflectorKey.getValue("EngineName").value_SZ,
        "EngineURL": deflectorKey.getValue("EngineURL").value_SZ
    ];
}

void openURL(const string browserPath, const string url) {
    spawnShell('"' ~ browserPath ~ "\" \"" ~ url ~ '"');
}
