module updater;

import std.json: JSONValue, parseJSON;
import std.net.curl: get, download;
import std.stdio: writeln;

void main(const string[] args) {
    const JSONValue releaseJson = getLatestRelease("spikespaz", "search-deflector");

    writeln(releaseJson);
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

// import std.windows.registry: Key, Registry, REGSAM, RegistryException;
// import core.sys.windows.windows: ShellExecuteA, SW_SHOWNORMAL;
// import std.path: buildPath, dirName;
// import common: createErrorDialog;
// import std.process: wait, spawnProcess;
// import std.net.curl: download;
// import std.string: toStringz;
// import std.file: thisExePath;
// import std.file: tempDir;

// void main(string[] args) {
//     try {
//         if (args.length == 1) {
//             if (checkConfigured())
//                 setShellCommand(buildPath(thisExePath().dirName(), "launcher.exe"));
//             else // Assumes already runnig as admin.
//                 spawnProcess(buildPath(thisExePath().dirName(), "setup.exe")).wait();
//         } else
//             update(args[1]);
//     } catch (Exception error)
//         createErrorDialog(error);
// }

// /// New update function to download and run the installer instead of unpacking the zip.
// void update(const string downloadUrl) {
//     const string downloadPath = buildPath(tempDir, "SearchDeflector-Installer.exe");

//     download(downloadUrl, downloadPath);

//     ShellExecuteA(null, "runas".toStringz(), downloadPath.toStringz(), null, null, SW_SHOWNORMAL);
// }

// /// Set the new file association.
// public void setShellCommand(const string filePath) {
//     Key shellCommandKey;

//     try
//         shellCommandKey = Registry.classesRoot.getKey("SearchDeflector\\shell\\open\\command", REGSAM.KEY_WRITE);
//     catch (RegistryException)
//         shellCommandKey = Registry.classesRoot.createKey("SearchDeflector\\shell\\open\\command", REGSAM.KEY_WRITE);

//     shellCommandKey.setValue("", '"' ~ filePath ~ "\" \"%1\"");

//     shellCommandKey.flush();
// }

// /// Checks if the required registry values already exist.
// bool checkConfigured() {
//     try {
//         Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector");

//         deflectorKey.getValue("BrowserPath");
//         deflectorKey.getValue("EngineURL");
//         deflectorKey.getValue("LastUpdateCheck");

//         return true;
//     } catch (RegistryException)
//         return false;
// }
