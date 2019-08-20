module updater;

import common: createErrorDialog, SETUP_FILENAME, PROJECT_AUTHOR, PROJECT_NAME, PROJECT_VERSION;
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

import arsd.minigui;

void main(string[] args) {
    try {
        const JSONValue releaseJson = getLatestRelease(PROJECT_AUTHOR, PROJECT_NAME);
        const JSONValue releaseAsset = getReleaseAsset(releaseJson, SETUP_FILENAME);
        const string installerFile = buildNormalizedPath(tempDir(), SETUP_FILENAME);

        auto window = new Window(300, 160, "Search Deflector Updater");
        auto layout = new VerticalLayout(window);

        window.setPadding(4, 8, 4, 8);
        window.win.setMinSize(300, 160);

        TextLabel label;

        label = new TextLabel("Version: " ~ releaseJson["tag_name"].str, layout);
        // label = new TextLabel("URL: " ~ releaseJson["html_url"].str, layout);
        label = new TextLabel("Uploader: " ~ releaseAsset["uploader"]["login"].str, layout);
        label = new TextLabel("Timestamp: " ~ releaseAsset["updated_at"].str, layout);
        label = new TextLabel("Binary Size: " ~ releaseAsset["size"].integer.to!string(), layout);
        label = new TextLabel("Download Count: " ~ releaseAsset["download_count"].integer.to!string(), layout);
        
        VerticalSpacer spacer;

        if (!compareVersions(releaseJson["tag_name"].str, PROJECT_VERSION.split('-')[0])) {
            spacer = new VerticalSpacer(layout);

            spacer.setMaxHeight(Window.lineHeight);

            label = new TextLabel("No update available.");
        }

        spacer = new VerticalSpacer(layout);

        auto updateButton = new Button("Install Update", layout);

        updateButton.addEventListener(EventType.triggered, {
            // Download the installer to the temporary path created above.
            download(releaseAsset["browser_download_url"].str, installerFile);

            // This executable should already be running as admin so no verb should be necessary.
            spawnShell(
                `"{{installerFile}}" /VERYSILENT /COMPONENTS="main, updater" /DIR="{{installPath}}"`
                .formatString([
                    "installerFile": installerFile,
                    "installPath": thisExePath().dirName()
                ]), null, Config.detached);
        });

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);

        debug writeln(error);
    }
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
    const string apiReleases = "https://api.github.com/repos/" ~ author ~ "/" ~
        repository ~ "/releases";

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
