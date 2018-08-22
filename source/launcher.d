module launcher;

import common: VERSION, UPDATE_FILE, getLastUpdateCheck, getLatestRelease, compareVersions, createErrorDialog;
import core.sys.windows.windows: CommandLineToArgvW, GetCommandLine;
import std.process: spawnProcess, Config;
import std.datetime: Clock, SysTime, days;
import std.path: dirName, buildPath;
import core.runtime: Runtime;
import std.file: thisExePath;
import std.json: JSONValue;
import std.format: format;
import std.string: split;
import std.conv: to;


/// Windows entry point.
extern (Windows) int WinMain() {
    int result;

    try {
        Runtime.initialize();

        const string[] args = getConsoleArgs();
        const string launchPath = buildPath(thisExePath().dirName(), VERSION, "%s");

        // dfmt off
        if (args.length > 1)
            spawnProcess(launchPath.format("deflector.exe") ~ args[1 .. $],
                null, Config.suppressConsole | Config.detached);
        // dfmt on

        const SysTime currentTime = Clock.currTime();

        if (getLastUpdateCheck() + days(1) < currentTime) {
            JSONValue releaseData = getLatestRelease("spikespaz", "search-deflector");

            if (compareVersions(releaseData["tag_name"].str, VERSION.split("-")[0])) {
                string downloadUrl;

                foreach (assetData; releaseData["assets"].array)
                    if (assetData["name"].str == UPDATE_FILE)
                        downloadUrl = assetData["browser_download_url"].str;

                // dfmt off
                spawnProcess([
                        launchPath.format("updater.exe"), releaseData["tag_name"].str,
                        releaseData["target_commitish"].str, downloadUrl
                    ],
                    null, Config.suppressConsole | Config.detached);
                // dfmt on
            }

        }

        Runtime.terminate();
    } catch (Exception error) {
        createErrorDialog(error);

        result = 1;
    }

    return result;
}

/// Return a string array of arguments as if it were in the main function.
string[] getConsoleArgs() {
    int argCount;
    wchar** argList = CommandLineToArgvW(GetCommandLine(), &argCount);
    string[] args;

    for (int index; index < argCount; index++)
        args ~= argList[index].to!string();

    return args;
}
