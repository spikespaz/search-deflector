module deflector;

import common: getConsoleArgs, openUri, createErrorDialog, DeflectorSettings, WIKI_THANKS_URL;
import std.string: replace, indexOf, toLower, startsWith;
import std.uri: decodeComponent, encodeComponent;
import std.regex: matchFirst;
import std.array: split;
import std.conv: to;

debug import std.stdio: writeln;

void main(string[] args) {
    if (args.length > 1) {
        try {
            auto settings = DeflectorSettings.get();

            openUri(settings.browserPath, rewriteUri(args[1], settings.engineURL));

            settings.searchCount++;

            version(free_version)
            if (settings.searchCount == 10)
                openUri(settings.browserPath, WIKI_THANKS_URL);

            settings.dump();
        } catch (Exception error) {
            createErrorDialog(error);

            debug writeln(error);
        }
    } else {
        createErrorDialog(new Exception(
                "Expected one URI argument, recieved: \n" ~ args.to!string()));
    }
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
