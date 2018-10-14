module updater;

import common: SETUP_FILENAME, PROJECT_AUTHOR, PROJECT_NAME, PROJECT_VERSION;
import std.json: JSONValue, JSONType, parseJSON;
import std.path: buildNormalizedPath, dirName;
import std.process: Config, spawnShell;
import std.file: tempDir, thisExePath;
import std.net.curl: get, download;
import std.string: split, replace;
import std.range: zip, popFront;
import std.algorithm: sort;
import std.stdio: writeln;
import std.conv: to;

/* NOTE:
    I was going to use the Windows API to hide and show the console window
    based on a "-silent" flag, but that quickly got too complicated and the
    implimentation was fragile. This comment is here as a reminder to myself
    to either finish that in the most correct way, or (since this will be run
    by the Task Scheduler) set the user running the process to "SYSTEM".
    I found this on Stack Overflow, and it seems to be the best option.
    https://stackoverflow.com/a/6568823/2512078
    It also needs to be run with highest privileges, not sure if the user
    being set to "SYSTEM" will take care of that for me.
*/

void main() {
    writeln("Search Deflector " ~ PROJECT_VERSION);

    const JSONValue releaseJson = getLatestRelease(PROJECT_AUTHOR, PROJECT_NAME);
    const JSONValue releaseAsset = getReleaseAsset(releaseJson, SETUP_FILENAME);

    if (!compareVersions(releaseJson["tag_name"].str, PROJECT_VERSION.split('-')[0]))
        return;

    // dfmt off
    writeln(
        "\nNew update information:",
        "\n=======================",
        "\nName: " ~ releaseJson["name"].str,
        "\nTag name: " ~ releaseJson["tag_name"].str,
        "\nAuthor: " ~ releaseJson["author"]["login"].str,
        "\nPrerelease: " ~ (releaseJson["prerelease"].type == JSONType.TRUE ? "Yes" : "No"),
        "\nPublish date: " ~ releaseJson["published_at"].str,
        "\nPatch notes: " ~ releaseJson["html_url"].str,
        "\nInstaller URL: " ~ releaseAsset["browser_download_url"].str
    );
    // dfmt on

    const string installerFile = buildNormalizedPath(tempDir(), SETUP_FILENAME);

    // Download the installer to the temporary path created above.
    download(releaseAsset["browser_download_url"].str, installerFile);

    // This executable should already be running as admin so no verb should be necessary.
    // dfmt off
    spawnShell(`"{{installerFile}}" /VERYSILENT /DIR="{{installPath}}"`.formatString([
        "installerFile": installerFile,
        "installPath": thisExePath().dirName()
    ]), null, Config.detached);
    // dfmt on
}

/// Iterate through a release's assets and return the one that matches the filename given.
JSONValue getReleaseAsset(const JSONValue release, const string filename) {
    foreach (asset; release["assets"].array)
        if (asset["name"].str == filename)
            return asset;

    assert(false);
}

/// Return the latest release according to semantic versioning.
JSONValue getLatestRelease(const string author, const string repository) {
    const string apiReleases = "https://api.github.com/repos/" ~ author ~ "/" ~ repository ~ "/releases";

    JSONValue releasesJson = get(apiReleases).parseJSON();

    releasesJson.array.sort!((a, b) => compareVersions(a["tag_name"].str, b["tag_name"].str))();

    return releasesJson.array[0];
}

/// Format a string by replacing each key with a value in replacements.
string formatString(const string input, const string[string] replacements) {
    string output = input;

    foreach (variable; replacements.byKeyValue())
        output = output.replace("{{" ~ variable.key ~ "}}", variable.value);

    return output;
}

/// Compare two semantic versions, returning true if the first version is newer, false otherwise.
public bool compareVersions(const string firstVer, const string secondVer) {
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
