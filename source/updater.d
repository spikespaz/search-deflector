module updater;

import std.json;
import std.net.curl;
import std.string: split;
import std.format: format;
import std.range: zip, popFront;
import std.algorithm: sort;
import std.conv: to;

version (Win64)
    private enum bool COMPILED_64 = true;
else
    private enum bool COMPILED_64;

private enum string RELEASES_URL = "https://api.github.com/repos/%s/%s/releases";

/// Get all current releases as JSON from the GitHub API.
public JSONValue getReleases(const string author, const string repository) {
    return get(RELEASES_URL.format(author, repository)).parseJSON();
}

/// Return a JSONValue array sorted by the `tag_name` as semantic versions.
public JSONValue[] getSortedReleases(const string author, const string repository) {
    JSONValue jsonData = getReleases(author, repository);
    JSONValue[] releasesArray = jsonData.array;

    releasesArray.sort!((firstVer, secondVer) => compareVersions(firstVer["tag_name"].str, secondVer["tag_name"].str));

    return releasesArray;
}

/// Return the latest release according to semantic versioning.
public JSONValue getLatestRelease(const string author, const string repository) {
    return getSortedReleases(author, repository)[0];
}

/// Compare two semantic versions, returning true if the first version is newer, false otherwise.
public bool compareVersions(const string firstVer, const string secondVer) {
    ushort[] firstVerParts = firstVer.split('.').to!(ushort[]);
    ushort[] secondVerParts = secondVer.split('.').to!(ushort[]);

    while (firstVerParts.length > secondVerParts.length) {
        if (firstVerParts[0] != 0) return true;
        firstVerParts.popFront();
    }

    while (secondVerParts.length > firstVerParts.length) {
        if (secondVerParts[0] != 0) return false;
        secondVerParts.popFront();
    }

    foreach (verParts; zip(firstVerParts, secondVerParts)) {
        if (verParts[0] > verParts[1]) return true;
        else if (verParts[1] > verParts[0]) return false;
    }

    return false;
}

void main() {
    import std.stdio;

    foreach (release; getSortedReleases("spikespaz", "example-releases"))
        writeln(release["tag_name"].str);
}
