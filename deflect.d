module deflect;

import std.stdio : writeln;

// Function to run after setup, actually deflected.
void deflect(const string url) {
    writeln(url); // Debug for now, just print the URL argument.
}
