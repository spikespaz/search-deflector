module main;

import std.stdio : writeln;
import std.windows.registry;

void main(string[] args) {
    if (args.length > 1) {
        import deflect : deflect;

        deflect(args[1]);
    }
    else {
        import setup : setup;

        setup(args[0]);
    }
}
