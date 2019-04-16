module deflector;

import core.sys.windows.windows: GetCommandLineW, MessageBox, MB_ICONWARNING, MB_YESNO, IDYES;
import common: getConsoleArgs, createErrorDialog, readSettings, writeSettings, DeflectorSettings, WIKI_THANKS_URL;
import std.process: browse, spawnProcess, Config, ProcessException;
import std.string: replace, indexOf, toLower, startsWith;
import std.uri: decodeComponent, encodeComponent;
import core.runtime: Runtime;
import std.regex: matchFirst;
import std.array: split;
import std.conv: to;

/// Entry to call the deflection, or error out.
extern (Windows) int WinMain(void*, void*, void*, int) {
    Runtime.initialize();

    string[] args = getConsoleArgs(GetCommandLineW());

    if (args.length > 1) {
        try {
            DeflectorSettings settings = readSettings();

            openUri(settings.browserPath, rewriteUri(args[1], settings.engineURL));

            settings.searchCount++;

            if (settings.freeVersion && settings.searchCount == 10)
                openUri(settings.browserPath, WIKI_THANKS_URL);

            writeSettings(settings);
        } catch (Exception error)
            createErrorDialog(error);
    } else {
        createErrorDialog(new Exception("Expected one URI argument, recieved: \n" ~ args.to!string()));
        return 1;
    }

    Runtime.terminate();

    return 0;
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
