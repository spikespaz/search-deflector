module deflector;

import core.sys.windows.windows: MessageBox, MB_ICONWARNING, MB_YESNO, IDYES;
import std.process: browse, spawnProcess, Config, ProcessException;
import std.string: replace, indexOf, toLower, startsWith;
import std.windows.registry: Registry, Key, REGSAM;
import std.uri: decodeComponent, encodeComponent;
import common: createErrorDialog;
import std.regex: matchFirst;
import std.array: split;
import std.conv: to;

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

        if (queryParams !is null && "url" in queryParams) {
            const string url = queryParams["url"].decodeComponent();

            if (url.matchFirst(`^https:\/\/.+\.bing.com`))
                return "https://" ~ engineUrl.replace("{{query}}", getQueryParams(url)["q"]);
            else
                return url;
        } else // Didn't know what to do with the protocol URI, so just search the text same as Edge.
            return engineUrl.replace("{{query}}", uri[15 .. $].encodeComponent());
    } else
        throw new Exception("Not a 'microsoft-edge' URI: " ~ uri);
}

/// Get all of the configuration information from the registry.
string[string] getRegistryInfo() {
    Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

    // dfmt off
    return [
        "BrowserPath": deflectorKey.getValue("BrowserPath").value_SZ,
        "EngineURL": deflectorKey.getValue("EngineURL").value_SZ
    ];
    // dfmt on
}

/// Open a URL by spawning a shell process to the browser executable, or system default.
void openUri(const string browserPath, const string url) {
    if (browserPath == "system_default")
        browse(url); // Automatically calls the system default browser.
    else
        try
            spawnProcess([browserPath, url], null, Config.detached); // Uses a specific executable.
        catch (ProcessException error) {
            const uint messageId = MessageBox(null, "Search Deflector could not deflect the URI to your browser." ~
                    "\nMake sure that the browser is still installed and that the executable still exists." ~
                    "\n\nWould you like to see the full error message online?", "Search Deflector",
                    MB_ICONWARNING | MB_YESNO);

            if (messageId == IDYES)
                createErrorDialog(error);
        }
}

/// Parse the query parameters from a URI and return as an associative array.
string[string] getQueryParams(const string uri) {
    string[string] queryParams;

    const size_t queryStart = uri.indexOf('?');

    if (queryStart == -1)
        return null;

    const string[] paramStrings = uri[queryStart + 1 .. $].split('&');

    foreach (param; paramStrings) {
        const size_t equalsIndex = param.indexOf('=');
        const string key = param[0 .. equalsIndex];
        const string value = param[equalsIndex + 1 .. $];

        queryParams[key] = value;
    }

    return queryParams;
}
