module launcher;

import common: VERSION, UPDATE_FILE, lastUpdateCheck, getLatestRelease, compareVersions, createErrorDialog;
import core.sys.windows.windows: CommandLineToArgvW, GetCommandLine, ShellExecuteA, SW_HIDE;
import std.process: spawnProcess, escapeWindowsArgument, Config;
import std.datetime: Clock, SysTime, Duration, days;
import std.path: dirName, buildPath;
import std.string: toStringz, split;
import core.runtime: Runtime;
import std.file: thisExePath;
import std.json: JSONValue;
import std.format: format;
import std.conv: to;

/// Windows entry point.
extern (Windows) int WinMain() {
    int result;

    try {
        Runtime.initialize();

        const string[] args = getConsoleArgs();
        const string launchPath = buildPath(thisExePath().dirName(), "%s");

        // dfmt off
        if (args.length > 1)
            spawnProcess(launchPath.format("deflector.exe") ~ args[1 .. $],
                null, Config.suppressConsole | Config.detached);
        // dfmt on

        if (shouldCheckUpdate(days(1))) {
            string[string] updateInfo = getUpdateInfo(VERSION.split('-')[0]);

            if (updateInfo)
                ShellExecuteA(null, "runas".toStringz(), launchPath.format("updater.exe").toStringz(),
                        (escapeWindowsArgument(updateInfo["download"]) ~ ' ' ~ escapeWindowsArgument(
                            updateInfo["version"] ~ '-' ~ updateInfo["branch"])).toStringz(), null, SW_HIDE);
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

/// Check if it's time for an update since last update check time.
bool shouldCheckUpdate(const Duration interval) {
    const SysTime currentTime = Clock.currTime();
    const SysTime lastCheck = lastUpdateCheck();

    if (lastCheck + interval < currentTime) {
        lastUpdateCheck(currentTime);
        return true;
    }

    return false;
}

string[string] getUpdateInfo(const string currentVer) {
    JSONValue releaseData = getLatestRelease("spikespaz", "search-deflector");

    if (!compareVersions(releaseData["tag_name"].str, currentVer))
        return null;

    // dfmt off
    string[string] updateData = [
        "version": releaseData["tag_name"].str,
        "branch": releaseData["target_commitish"].str,
        "url": releaseData["html_url"].str];
    // dfmt on

    foreach (assetData; releaseData["assets"].array)
        if (assetData["name"].str == UPDATE_FILE)
            updateData["download"] = assetData["browser_download_url"].str;

    return updateData;
}
