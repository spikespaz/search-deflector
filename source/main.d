module main;

import updater: compareVersions, getLastUpdateCheck, setLastUpdateCheck, getLatestRelease, update;
import core.sys.windows.winuser: ShowWindow, SW_HIDE, SW_SHOWDEFAULT;
import core.sys.windows.wincon: SetConsoleTitle, GetConsoleWindow;
import std.datetime: Clock, SysTime, dur;
import std.stdio: writeln, readln;
import std.json: JSONValue;
import deflect: deflect;
import setup: setup;

private enum string VERSION = "0.0.4";

private
version (Win64)
    enum string DL_FILENAME = "SearchDeflector-x64.zip";
else
    enum string DL_FILENAME = "SearchDeflector-x32.zip";

void main(string[] args) {
    if (args.length > 1) { // A URL has been passed, deflect it.
        ShowWindow(GetConsoleWindow(), SW_HIDE);
        deflect(args[1]);

        SysTime currentTime = Clock.currTime();

        // if ((getLastUpdateCheck() + dur!"minutes"(1)) < currentTime) {
        if (true) {
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

                // SetConsoleTitle("Search Deflector - Version " ~ VERSION);
                ShowWindow(GetConsoleWindow(), SW_SHOWDEFAULT);
            } finally {
                writeln("\nSearch Deflector setup completed. You may now close this terminal.\nPress Enter to exit.");
                readln();
            }
        }
    } else { // There has been no arguments. The user is probably wanting to set up.
        try {
            writeln("Search Deflector Version: " ~ VERSION,
                    "\nUpdate File Name: " ~ DL_FILENAME);
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
