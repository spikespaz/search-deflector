module updater;

import std.file: thisExePath, tempDir, exists, mkdirRecurse, read, write;
import std.windows.registry: Key, Registry, REGSAM;
import std.path: dirName, buildPath;
import common: createErrorDialog;
import std.net.curl: download;
import std.zip: ZipArchive;
import std.conv: to;

void main(string[] args) {
    if (args.length < 2)
        createErrorDialog(new Exception("Incorrect number of arguments passed to updater.\nFound: " ~ args.to!string));

    try
        update(args[1], args[2]);
    catch (Exception error)
        createErrorDialog(error);
}

/// Main update function that downloads and extracts the update archive.
void update(const string downloadUrl, const string updateVer) {
    import std.stdio: writeln;

    const string installDir = buildPath(thisExePath().dirName(), "..", updateVer);
    const string archivePath = buildPath(tempDir, "update.zip");

    writeln(installDir);
    writeln(archivePath);

    if (!exists(installDir))
        mkdirRecurse(installDir);

    download(downloadUrl, archivePath);

    ZipArchive archiveFile = new ZipArchive(read(archivePath));

    foreach (member; archiveFile.directory)
        write(buildPath(installDir, member.name), member.expandedData());

    setShellCommand(buildPath(installDir, updateVer, "launcher.exe"));
}

/// Set the new file association.
public void setShellCommand(const string filePath) {
    Key shellCommandKey = Registry.classesRoot.getKey("SearchDeflector\\shell\\open\\command", REGSAM.KEY_WRITE);

    shellCommandKey.setValue("", '"' ~ filePath ~ "\" \"%1\"");

    shellCommandKey.flush();
}
