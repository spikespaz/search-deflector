module common;

import std.format: format;

enum string VERSION = "0.0.5-master";

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

