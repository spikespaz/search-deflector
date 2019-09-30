module updater;

import std.process: Config, spawnShell;
import std.json: JSONValue, parseJSON;
import std.net.curl: get, download;
import std.range: zip, popFront;
import std.file: thisExePath;
import std.algorithm: sort;
import std.stdio: writeln;
import std.string: split;
import std.path: dirName;
import std.conv: to;

import core.stdc.stdlib: exit;

import common: formatString;

debug import std.stdio: writeln;

void startInstallUpdate(const string downloadUrl, const string installerFile, const bool silent = false) {
    // Download the installer to the temporary path created above.
    download(downloadUrl, installerFile);

    auto launchArgs = `"{{installerFile}}" {{otherArgs}} /components="main, updater" /dir="{{installPath}}"`
        .formatString(["installerFile"
                : installerFile, "installPath" : thisExePath().dirName(), "otherArgs" : silent ? "/verysilent" : ""]);

    debug writeln(launchArgs);

    // This executable should already be running as admin so no verb should be necessary.
    spawnShell(launchArgs, null, Config.detached | Config.suppressConsole);

    exit(0);
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
