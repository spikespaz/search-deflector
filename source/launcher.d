module launcher;

import common: VERSION, UPDATE_FILE, getConsoleArgs, lastUpdateCheck, getLatestRelease, compareVersions, createErrorDialog;
import core.sys.windows.windows: GetCommandLineW, ShellExecuteA, SW_HIDE, SW_SHOWNORMAL;
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

        const string[] args = getConsoleArgs(GetCommandLineW());
        const string launchPath = buildPath(thisExePath().dirName(), "%s");

        if (args.length > 1 && args[1] != "--setup" && args[1] != "--update")
            spawnProcess(launchPath.format("deflector.exe") ~ args[1 .. $], null, Config.suppressConsole);

        if (args[1] == "--setup")
            ShellExecuteA(null, "runas".toStringz(), launchPath.format("setup.exe").toStringz(), null, null, SW_SHOWNORMAL);
        else if (args[1] == "--update" || shouldCheckUpdate(days(1))) {
            string[string] updateInfo = getUpdateInfo(VERSION.split('-')[0]);

            if (updateInfo)
                spawnProcess([launchPath.format("updater.exe"), escapeWindowsArgument(updateInfo["download"])]);
        }

        Runtime.terminate();
    } catch (Exception error) {
        createErrorDialog(error);
        throw error;

        result = 1;
    }

    return result;
}

/// Check if it's time for an update since last update check time.
bool shouldCheckUpdate(const Duration interval) {
    const SysTime currentTime = Clock.currTime();

    if (lastUpdateCheck() + interval < currentTime) {
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
