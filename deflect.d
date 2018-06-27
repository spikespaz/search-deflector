module deflect;

import std.windows.registry;
import std.process : spawnShell;
import std.string : replace, indexOf;
import std.array : split;
import std.stdio : writeln, readln;
import std.uri : decodeComponent, encodeComponent;

// Function to run after setup, actually deflected.
void deflect(const string uri) {
    const string[string] registryInfo = getRegistryInfo();
    const string[string] uriQueryParams = getQueryParams(uri);
    const string[string] bingQueryParams = getQueryParams(uriQueryParams["url"].decodeComponent());
    const string searchComponent = bingQueryParams["q"];
    const string searchURL = registryInfo["EngineURL"].replace("{{query}}", searchComponent);

    openURI(registryInfo["BrowserPath"], searchURL);
}

// Get all of the configuration information from the registry.
string[string] getRegistryInfo() {
    Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

    // dfmt off
    return [
        "BrowserName": deflectorKey.getValue("BrowserName").value_SZ,
        "BrowserPath": deflectorKey.getValue("BrowserPath").value_SZ,
        "EngineName": deflectorKey.getValue("EngineName").value_SZ,
        "EngineURL": deflectorKey.getValue("EngineURL").value_SZ
    ];
    // dfmt on
}

// Open a URL by spawning a shell process to the browser executable, or system default.
void openURI(const string browserPath, const string url) {
    spawnShell('"' ~ browserPath ~ "\" \"" ~ url ~ '"');
}

// Parse the query parameters from a URI and return as an associative array.
string[string] getQueryParams(const string uri) {
    string[string] queryParams;

    const int queryStart = uri.indexOf('?');
    const string[] paramStrings = uri[queryStart + 1 .. $].split('&');

    foreach (param; paramStrings) {
        const int equalsIndex = param.indexOf('=');
        const string key = param[0 .. equalsIndex];
        const string value = param[equalsIndex + 1 .. $];

        queryParams[key] = value;
    }

    return queryParams;
}
