module deflector;

import std.string: replace, indexOf, toLower, startsWith;
import std.windows.registry: Registry, Key, REGSAM;
import std.process: browse, spawnProcess, Config;
import std.uri: decodeComponent, encodeComponent;
import common: createErrorDialog;
import std.array: split;
import std.conv: to;

alias DeflectionError = Exception;

/// Entry to call the deflection, or error out.
void main(string[] args) {
    if (args.length > 1) {
        try {
            const string[string] registryInfo = getRegistryInfo();
            openUri(registryInfo["BrowserPath"], rewriteUri(args[1], registryInfo["EngineURL"]));
        } catch (Exception error)
            createErrorDialog(error);
    } else
        createErrorDialog(new Exception("Expected one URI argument, recieved: \n" ~ args.to!string()));
}

/// Reqrites a "microsoft-edge" URI to something browsers can use.
string rewriteUri(const string uri, const string engineUrl) {
    if (uri.toLower().startsWith("microsoft-edge:")) {
        const string[string] queryParams = getQueryParams(uri);

        if ("url" in queryParams) {
            const string url = queryParams["url"].decodeComponent();

            if (url.startsWith("https://www.bing.com"))
                return "https://" ~ engineUrl.replace("{{query}}", getQueryParams(url)["pq"]); // "pq" maintains casing.
            else
                return url;
        } else // Didn't know what to do with the protocol URI, so just search the text same as Edge.
            return engineUrl.replace("{{query}}", uri[15 .. $].encodeComponent());

    } else
        throw new DeflectionError("Not a 'microsoft-edge' URI: " ~ uri);
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
