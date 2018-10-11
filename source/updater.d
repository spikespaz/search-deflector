module updater;

import std.process: spawnProcess, escapeShellFileName;
import std.json: JSONValue, JSONType, parseJSON;
import std.path: buildPath, absolutePath;
import std.file: tempDir, thisExePath;
import std.net.curl: get, download;
import std.stdio: writeln;

/* TODO:
    These variables should be somewhat dynamic, and used as compile-time
    constants in variables.d somewhat like common.d currently is.
*/

/// File name of the executable to download and run to install an update.
enum string SETUP_FILENAME = "SearchDeflector-Installer.exe";
/// Repository path information for Search Deflector, https://github.com/spikespaz/search-deflector.
enum string PROJECT_AUTHOR = "spikespaz";
enum string PROJECT_NAME = "search-deflector"; /// Ditto.
/// Current version of the Search Deflector binaries.
enum string PROJECT_VERSION = "0.0.0";

void main(const string[] args) {
    writeln("Search Deflector " ~ PROJECT_VERSION);

    const JSONValue releaseJson = getLatestRelease(PROJECT_AUTHOR, PROJECT_NAME);
    const JSONValue releaseAsset = getReleaseAsset(releaseJson, SETUP_FILENAME);

    if (!compareVersions(releaseJson["tag_name"].str, PROJECT_VERSION))
        return;

    // dfmt off
    writeln(
        "\nNew update information:\n=======================",
        "\nName: " ~ releaseJson["name"].str,
        "\nTag name: " ~ releaseJson["tag_name"].str,
        "\nAuthor: " ~ releaseJson["author"]["login"].str,
        "\nPrerelease: " ~ (releaseJson["prerelease"].type is JSONType.TRUE ? "Yes" : "No"),
        "\nPublish date: " ~ releaseJson["published_at"].str,
        "\nPatch notes: " ~ releaseJson["html_url"].str,
        "\nInstaller URL: " ~ releaseAsset["browser_download_url"].str
    );
    // dfmt on

    const string installerFile = buildPath(tempDir(), SETUP_FILENAME);

    // Download the installer to the temporary path created above.
    download(releaseAsset["browser_download_url"].str, installerFile);
    // This executable should already be running as admin so no verb should be necessary.
    spawnProcess([installerFile, "/VERYSILENT", "/DIR=" ~ buildPath(thisExePath, "..", "..")
            .absolutePath().escapeShellFileName()]);
}

/// Iterate through a release's assets and return the one that matches the filename given.
JSONValue getReleaseAsset(const JSONValue release, const string filename) {
    import std.json: JSONValue;

    foreach (asset; release["assets"].array)
        if (asset["name"].str == filename)
            return asset;

    assert(false);
}

/// Return the latest release according to semantic versioning.
JSONValue getLatestRelease(const string author, const string repository) {
    import std.json: JSONValue, parseJSON;
    import std.algorithm: sort;
    import std.net.curl: get;

    const string apiReleases = "https://api.github.com/repos/" ~ author ~ "/" ~ repository ~ "/releases";

    JSONValue releasesJson = get(apiReleases).parseJSON();

    releasesJson.array.sort!((a, b) => compareVersions(a["tag_name"].str, b["tag_name"].str))();

    return releasesJson.array[0];
}

/// Compare two semantic versions, returning true if the first version is newer, false otherwise.
public bool compareVersions(const string firstVer, const string secondVer) {
    import std.range: zip, popFront;
    import std.string: split;
    import std.conv: to;

    ushort[] firstVerParts = firstVer.split('.').to!(ushort[]);
    ushort[] secondVerParts = secondVer.split('.').to!(ushort[]);

    while (firstVerParts.length > secondVerParts.length) {
        if (firstVerParts[0] != 0)
            return true;
        firstVerParts.popFront();
    }

    while (secondVerParts.length > firstVerParts.length) {
        if (secondVerParts[0] != 0)
            return false;
        secondVerParts.popFront();
    }

    foreach (verParts; zip(firstVerParts, secondVerParts)) {
        if (verParts[0] > verParts[1])
            return true;
        else if (verParts[1] > verParts[0])
            return false;
    }

    return false;
}

/* TODO:
    Abstract the shell command replacement into the setup executable,
    since this file changed to only execute the installer.

    That post-install functionality needs to be moved into the setup
    so that when the installer calls it, it can fix the registry settings
    to point to the new location or version folder autonomously.

    This should work by checking if the config key in the registry exists.
    If it does, make sure the "shell open" command points to the latest deflector.

    Also, once the setup is rewritten to use the Task Scheduler to run the updater,
    update that task to point to the new updater.

    Should be ported from the old code. For reference, I'll link it.
    https://github.com/spikespaz/search-deflector/blob/0.2.3/source/updater.d
*/
