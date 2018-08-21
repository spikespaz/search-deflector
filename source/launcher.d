module launcher;

import core.sys.windows.windows: GetCommandLine, CommandLineToArgvW;
import std.process: browse, spawnProcess, Config;
import common: createErrorDialog, VERSION;
import std.path: buildPath, dirName;
import std.uri: encodeComponent;
import core.runtime: Runtime;
import std.file: thisExePath;
import std.format: format;
import std.conv: to;

/// Main launch function to check for updates and redirect the URI.
int launch(const string[] arguments) {
    const string launchPath = buildPath(thisExePath().dirName(), VERSION, "deflector.exe");

    spawnProcess(launchPath ~ arguments, null, Config.suppressConsole | Config.detached);

    return 0;
}

/// Windows entry point.
extern (Windows) int WinMain() {
    int result;

    try {
        Runtime.initialize();

        launch(getConsoleArgs()[1 .. $]);

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
