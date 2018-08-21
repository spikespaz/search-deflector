import core.sys.windows.winuser: MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import std.process: browse, spawnProcess, Config;
import core.sys.windows.windows: GetCommandLine, CommandLineToArgvW;
import common: createIssueMessage, VERSION;
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
        const uint messageId = MessageBox(null, "Search Deflector launch failed." ~
                "\nWould you like to open the issues page to submit a bug report?" ~
                "\nThe important information will be filled out for you." ~
                "\nIf you do not wish to create a bug report, click 'No' to exit.",
                "Search Deflector Launcher", MB_ICONERROR | MB_YESNO);

        // dfmt off
        if (messageId == IDYES)
            browse("https://github.com/spikespaz/search-deflector/issues/new?body=" ~
                createIssueMessage(error).encodeComponent());
        // dfmt on

        result = 1;
    }

    return result;
}

/// Return a string array of arguments as if it were in the main function.
string[] getConsoleArgs() {
    wchar** argList;
    int argCount;

    string[] args;

    argList = CommandLineToArgvW(GetCommandLine(), &argCount);

    for (int index; index < argCount; index++)
        args ~= argList[index].to!string();

    return args;
}
