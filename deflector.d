module main;

import std.stdio : writeln;
import std.windows.registry;

void main(string[] args) {
    if (args.length > 1)
        deflect(args[1]);
    else {
        import setup : setup;

        setup(args[0]);
    }
}

// Function to run after setup, actually deflected.
void deflect(const string url) {
    writeln(url); // Debug for now, just print the URL argument.
}
