module main;

import std.stdio : writeln;

void main(string[] args) {
    if (args.length > 1) {
        import deflect : deflect;

        deflect(args[1]);
    }
    else {
        try {
            import setup : setup;

            setup(args[0]);
        }
        catch (Exception error) {
            writeln("\nThe SearchDeflector setup has crashed. Try running the executable as administrator.\n",
                    "If the problem persists, please copy the error below and submit an issue on GitHub.\n",
                    "https://github.com/spikespaz/search-deflector/issues\n\n",
                    "=== BEGIN CRASH EXCEPTION ===\n\n", error, "\n\n=== END CRASH EXCEPTION ===");
        }
        finally {
            writeln("\nSearch Deflector setup completed. You may now close this terminal.");
            while (true) { }
        }
    }
}
