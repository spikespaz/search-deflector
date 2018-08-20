module main;

import updater: compareVersions, getLastUpdateCheck, setLastUpdateCheck, getLatestRelease, update;
import core.sys.windows.winuser: ShowWindow, SW_HIDE, SW_SHOW;
import core.sys.windows.wincon: SetConsoleTitle, GetConsoleWindow;
import std.datetime: Clock, SysTime, dur;
import std.stdio: writeln, readln;
import std.json: JSONValue;
import deflect: deflect, DeflectionError;
import setup: setup;

private enum string VERSION = "0.0.4";

private
version (Win64)
    enum string DL_FILENAME = "SearchDeflector-x64.zip";
else
    enum string DL_FILENAME = "SearchDeflector-x86.zip";

void main(string[] args) {
    writeln("Search Deflector Version: " ~ VERSION,
            "\nUpdate File Name: " ~ DL_FILENAME);

    if (args.length > 1) { // A URL has been passed, deflect it.
        // ShowWindow(GetConsoleWindow(), SW_HIDE);

        try {
            deflect(args[1]);
        } catch (DeflectionError error) {
            writeln("Search Deflector doesn't know what to do with the URI it recieved.\n",
                    "Please submit a GitHub issue at https://github.com/spikespaz/search-deflector/issues.\n",
                    "Be sure to include the text below.\n\n", args[1], "\n\nPress Enter to exit.");
            readln();

            SetConsoleTitle("Search Deflector - Version " ~ VERSION);
            ShowWindow(GetConsoleWindow(), SW_SHOW);
        }

        SysTime currentTime = Clock.currTime();

        if (false) {
        // if ((getLastUpdateCheck() + dur!"minutes"(1)) < currentTime) {
            setLastUpdateCheck(currentTime);
            try {
                JSONValue latestRelease = getLatestRelease("spikespaz", "search-deflector");
                if (compareVersions(latestRelease["tag_name"].str, VERSION))
                    update(latestRelease, DL_FILENAME);

            } catch (Exception error) {
                writeln(
                    "\nSearch Deflector update failed.",
                    "\nPlease go to the repository and manually download the latest update.",
                    "\nhttps://github.com/spikespaz/search-deflector/releases",
                    "\n\n=== BEGIN CRASH EXCEPTION ===\n\n", error, "\n\n=== END CRASH EXCEPTION ==="
                );

                SetConsoleTitle("Search Deflector - Version " ~ VERSION);
                ShowWindow(GetConsoleWindow(), SW_SHOW);
            } finally {
                writeln("\nSearch Deflector setup completed. You may now close this terminal.\nPress Enter to exit.");
                readln();
            }
        }
    } else { // There has been no arguments. The user is probably wanting to set up.
        try {
            setup(args[0]);
        } catch (Exception error) {
            writeln(
                "\nThe Search Deflector setup has crashed. Try running the executable as administrator.",
                "\nIf the problem persists, please copy the error below and submit an issue on GitHub.",
                "\nhttps://github.com/spikespaz/search-deflector/issues",
                "\n\n=== BEGIN CRASH EXCEPTION ===\n\n", error, "\n\n=== END CRASH EXCEPTION ==="
            );
        } finally {
            writeln("\nSearch Deflector setup completed. You may now close this terminal.\nPress Enter to exit.");
            readln();
        }
    }
}
