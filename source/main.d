module main;

import std.stdio: writeln, readln;
import setup: setup;
import deflect: deflect;
import updater: getLastUpdateCheck, setLastUpdateCheck, checkAndUpdate;
import core.sys.windows.winuser: ShowWindow, SW_HIDE;
import core.sys.windows.wincon: GetConsoleWindow;
import std.datetime: Clock, SysTime, dur;

private enum string VERSION = "0.0.5";

private
version (Win64)
    enum bool COMPILED_64 = true;
else
    enum bool COMPILED_64;

void main(string[] args) {
    if (args.length > 1) { // A URL has been passed, deflect it.
        ShowWindow(GetConsoleWindow(), SW_HIDE);
        deflect(args[1]);

        SysTime currentTime = Clock.currTime();

        if ((getLastUpdateCheck() + dur!"minutes"(1)) < currentTime) {
            setLastUpdateCheck(currentTime);
            try {
                checkAndUpdate(COMPILED_64, VERSION);
            } catch (Exception error) {
                writeln(
                    "\nSearch Deflector update failed.",
                    "\nPlease go to the repository and manually download the latest update.",
                    "\nhttps://github.com/spikespaz/search-deflector/releases"
                );
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
                    "\n\n=== BEGIN CRASH EXCEPTION ===\n\n", error, "\n\n=== END CRASH EXCEPTION ===");
        } finally {
            writeln("\nSearch Deflector setup completed. You may now close this terminal.\nPress Enter to exit.");
            readln();
        }
    }
}
