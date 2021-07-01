module deflector;

import common;
import std.uri: decodeComponent;
import std.conv: to;

version (free_version) {
    import core.thread: Thread;
    import core.time: seconds;
}

debug {
    import core.stdc.stdio: getchar;
    import std.stdio: writeln;
}

void main(string[] args) {
    if (args.length <= 1) {
        createErrorDialog(new Exception("Expected one URI argument, recieved: \n" ~ args.to!string()));
        return;
    }

    const auto searchInfo = getSearchInfo(args[1]);
    
    debug {
        writeln("\nInitial launch URI:\n\t" ~ args[1] ~ "\n");

        debug writeln("Decoded search information:");
        debug writeln("Search Term: " ~ searchInfo.searchTerm);
        debug writeln("Entered URL: " ~ searchInfo.enteredUrl);
        debug writeln("Selected URL: " ~ searchInfo.selectedUrl);
    }

    try {
        const string browserArgs = getBrowserArgs(
            DeflectorSettings.browserPath,
            DeflectorSettings.useProfile,
            DeflectorSettings.profileName
        );
        string launchUrl;

        if (searchInfo.enteredUrl !is null)
            launchUrl = searchInfo.enteredUrl;
        else if (searchInfo.selectedUrl !is null)
            launchUrl = searchInfo.selectedUrl;
        else if (searchInfo.searchTerm)
            if (searchInfo.searchTerm.decodeComponent() == "!DisableDonationRequest") {
                DeflectorSettings.disableNag = true;
                DeflectorSettings.dump();
            } else
                launchUrl = DeflectorSettings.engineURL.formatString(["query": searchInfo.searchTerm]);
        else
            throw new Exception("There was an error deflecting your search. Passed URI is:\t" ~ args[1]);

        openUri(DeflectorSettings.browserPath, browserArgs, launchUrl);

        version (free_version) // Makes the donation prompt open on the 10th search and every 20 afterward
        if ((!DeflectorSettings.disableNag && (DeflectorSettings.searchCount - 10) % 20 == 0)
                || DeflectorSettings.searchCount == 10) {
            Thread.sleep(seconds(5));
            openUri(DeflectorSettings.browserPath, browserArgs, WIKI_THANKS_URL);
        }
    } catch (Exception error) {
        createErrorDialog(error);
        debug writeln(error);
    }

    debug getchar();
}
