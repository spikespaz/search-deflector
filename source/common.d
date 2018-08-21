module common;

import core.sys.windows.winuser: MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import std.uri: encodeComponent;
import std.process: browse;
import std.format: format;

/// Public version strings determined at compile time.
enum string VERSION = "0.0.5-master";
enum string UPDATE_FILE = "SearchDeflector-x86.zip";

/// Creates a messabe box telling the user there was an error, and redirect to issues page.
void createErrorDialog(const Exception error) {
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

