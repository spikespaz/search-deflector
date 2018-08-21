import core.sys.windows.winuser: MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import core.sys.windows.windows: GetCommandLine;
import std.uri: encodeComponent;
import core.runtime: Runtime;
import std.process: browse;
import std.format: format;
import std.string: split;
import std.uni: isWhite;
import std.conv: text;

/// Main launch function to check for updates and redirect the URI.
int launch(const string[] arguments) {
    return 0;
}

/// Windows entry point.
extern (Windows) int WinMain() {
    int result;

    try {
        Runtime.initialize();

        string[] arguments = GetCommandLine().text.split!isWhite[1 .. $];
        result = launch(arguments);

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

/// Creates a GitHub issue body with the data from an Exception.
string createIssueMessage(const Exception error) {
    return "I have encountered an error launching Search Deflector.
The error information follows below.

**File:** `%s`

**Line:** %s

**Message:**
```
%s
```

**Stack Trace:**
```
%s
```
".format(error.file, error.line, error.msg, error.info);
}
