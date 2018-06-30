module updater;

import std.json;
import std.net.curl;
import std.stdio: writeln;

const string releases = "https://api.github.com/repos/spikespaz/search-deflector/releases";

void main() {
    writeln(getLatestRelease());
}

string[string] getLatestRelease() {
    const JSONValue response = parseJSON(get(releases));

    return ["tag" : response["tag_name"].str, // "name": response["name"].toString(),
        // "url": response["url"].toString(),
        // "file": response["assets"][0]["url"].toString()
        ];
}
