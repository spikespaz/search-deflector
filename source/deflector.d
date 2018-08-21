module deflector;

import std.string: replace, indexOf, toLower, startsWith;
import std.windows.registry: Registry, Key, REGSAM;
import std.process: browse, spawnProcess, Config;
import std.uri: decodeComponent, encodeComponent;
import core.sys.windows.wincon: SetConsoleTitle;
import std.stdio: writeln, readln;
import common: createErrorDialog;
import std.array: split;
import conv: to;

alias DeflectionError = Exception;

/// Entry to call the deflection, or error out.
int main(string[] args) {
    if (args.length > 1) {
        try {
            deflect[1];

            return 0;
        } catch (Exception error) {
            createErrorDialog(error);

            return 1;
        }
    }

    createErrorDialog(
        new Exception("Expected one URI argument, recieved: \n" ~ args.to!string())
    );

    return 1;
}

/// Function to run after setup, actually deflected.
void deflect(const string uri) {
    const string[string] registryInfo = getRegistryInfo();

    if (uri.toLower().startsWith("microsoft-edge:")) {
        const string url = getQueryParams(uri)["url"].decodeComponent();

        if (url.startsWith("https://www.bing.com")) {
            const string searchQuery = getQueryParams(url)["pq"];
            const string searchURL = "https://" ~ registryInfo["EngineURL"].replace("{{query}}", searchQuery);

            openUri(registryInfo["BrowserPath"], searchURL);
        } else if (checkHttpUri(url))
            openUri(registryInfo["BrowserPath"], url);
        else
            throw new DeflectionError("Error deflecting: " ~ uri);
    } else
        throw new DeflectionError("Error deflecting: " ~ uri);
}

/// Check if a URI is HTTP protocol.
bool checkHttpUri(const string uri) {
    return 0 < uri.toLower().startsWith("http://", "https://");
}

/// Get all of the configuration information from the registry.
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

/// Open a URL by spawning a shell process to the browser executable, or system default.
void openUri(const string browserPath, const string url) {
    if (browserPath == "system_default")
        browse(url); // Automatically calls the system default browser.
    else
        spawnProcess([browserPath, url], null, Config.newEnv); // Uses a specific executable.
}

/// Parse the query parameters from a URI and return as an associative array.
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
