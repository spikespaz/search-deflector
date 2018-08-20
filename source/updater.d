module updater;

import std.file: thisExePath, read, write, mkdir, exists, rmdirRecurse;
import std.windows.registry: Key, Registry, REGSAM;
import std.json: parseJSON, JSONValue;
import std.path: buildPath, dirName;
import std.net.curl: get, download;
import std.range: zip, popFront;
import std.datetime: SysTime;
import std.path: buildPath;
import std.algorithm: sort;
import std.zip: ZipArchive;
import std.format: format;
import std.stdio: writeln;
import std.string: split;
import std.conv: to;

private enum string RELEASES_URL = "https://api.github.com/repos/%s/%s/releases";

/// Update based on GitHub release data.
public void update(JSONValue releaseData, const string fileName) {
    string downloadUrl;

    foreach (assetData; releaseData["assets"].array)
        if (assetData["name"].str == fileName)
            downloadUrl = assetData["browser_download_url"].str;

    // dfmt off
    const string installPath = buildPath(thisExePath().dirName(),
        releaseData["tag_name"].str ~ '-' ~ releaseData["target_commitish"].str);
    const string archivePath = buildPath(installPath, fileName);
    // dfmt on

    // Already exists for some reason, get rid of it.
    if (exists(installPath))
        rmdirRecurse(installPath);

    mkdir(installPath);
    download(downloadUrl, archivePath);

    ZipArchive archiveFile = new ZipArchive(read(archivePath));

    foreach (member; archiveFile.directory)
        write(buildPath(installPath, member.name), member.expandedData());

    // Hardcoded to SearchDeflector.exe for now, want to find a way to make it fix itself.
    setShellCommand(buildPath(installPath, "SearchDeflector.exe"));
}

/// Get all current releases as JSON from the GitHub API.
public JSONValue getReleases(const string author, const string repository) {
    return get(RELEASES_URL.format(author, repository)).parseJSON();
}

/// Return a JSONValue array sorted by the `tag_name` as semantic versions.
public JSONValue[] getSortedReleases(const string author, const string repository) {
    JSONValue jsonData = getReleases(author, repository);
    JSONValue[] releasesArray = jsonData.array;

    // dfmt off
    releasesArray.sort!(
        (firstVer, secondVer) => compareVersions(firstVer["tag_name"].str, secondVer["tag_name"].str)
    );
    // dfmt on

    return releasesArray;
}

/// Return the latest release according to semantic versioning.
public JSONValue getLatestRelease(const string author, const string repository) {
    return getSortedReleases(author, repository)[0];
}

/// Get the last recorded update check time.
public SysTime getLastUpdateCheck() {
    Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

    return SysTime.fromISOString(deflectorKey.getValue("LastUpdateCheck").value_SZ);
}

/// Set the new last update check time.
public void setLastUpdateCheck(SysTime checkTime) {
    Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

    deflectorKey.setValue("LastUpdateCheck", checkTime.toISOString());

    deflectorKey.flush();
}

/// Set the new file association.
public void setShellCommand(const string filePath) {
    Key shellCommandKey = Registry.classesRoot.getKey("SearchDeflector\\shell\\open\\command", REGSAM.KEY_WRITE);

    shellCommandKey.setValue("", '"' ~ filePath ~ "\" \"%1\"");

    shellCommandKey.flush();
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
