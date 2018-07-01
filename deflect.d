module deflect;

import std.windows.registry: Registry, Key, REGSAM;
import std.process: spawnShell;
import std.string: replace, indexOf, toLower, startsWith;
import std.array: split;
import std.stdio: writeln, readln;
import std.uri: decodeComponent, encodeComponent;

// Function to run after setup, actually deflected.
void deflect(const string uri) {
    const string[string] registryInfo = getRegistryInfo();

    if (uri.toLower().startsWith("microsoft-edge:")) {
        const string url = getQueryParams(uri)["url"].decodeComponent();

        if (url.startsWith("https://www.bing.com")) {
            const string searchQuery = getQueryParams(url)["pq"];
            const string searchURL = "https://" ~ registryInfo["EngineURL"].replace("{{query}}", searchQuery);

            openURI(registryInfo["BrowserPath"], searchURL);
        } else if (checkHTTPURI(url))
            openURI(registryInfo["BrowserPath"], url);
        else
            deflectionError(uri);
    } else
        deflectionError(uri);
}

void deflectionError(const string uri) {
    writeln("Search Deflector doesn't know what to do with the URI it recieved.\n",
            "Please submit a GitHub issue at https://github.com/spikespaz/search-deflector/issues.\n",
            "Be sure to include the text below.\n\n", uri, "\n\nPress Enter to exit.");
    readln();
}

// Check if a URI is HTTP protocol.
bool checkHTTPURI(const string uri) {
    return 0 < uri.toLower().startsWith("http://", "https://");
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
    if (browserPath == "system_default")
        spawnShell("start \"\" " ~ url ~ '"');
    else
        spawnShell("start \"\" \"" ~ browserPath ~ "\" \"" ~ url ~ '"');
}

// Parse the query parameters from a URI and return as an associative array.
string[string] getQueryParams(const string uri) {
    string[string] queryParams;

    const size_t queryStart = uri.indexOf('?');
    const string[] paramStrings = uri[queryStart + 1 .. $].split('&');

    foreach (param; paramStrings) {
        const size_t equalsIndex = param.indexOf('=');
        const string key = param[0 .. equalsIndex];
        const string value = param[equalsIndex + 1 .. $];

        queryParams[key] = value;
    }

    return queryParams;
}
