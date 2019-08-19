import arsd.minigui;
import std.windows.registry: RegistryException;
import std.stdio: writeln;
import common: getConsoleArgs, createErrorDialog;
import setup: getAvailableBrowsers, getAvailableBrowsers;


extern (Windows) int WinMain(void*, void*, char*, int) {    
    import core.runtime: Runtime;
    
    try {
        Runtime.initialize();

        debug writeln("Initialized D runtime.");

        main(getConsoleArgs());

        Runtime.terminate();

        debug writeln("Terminated D runtime.");
    } catch (Throwable error) { // @suppress(dscanner.suspicious.catch_em_all)
        createErrorDialog(error);

        debug writeln(error);
    }

    return 0;
}

void main(string[] args) {
    try {
        auto window = new MainWindow("Search Deflector", 400, 250);
        auto layout = new VerticalLayout(window);

        auto textLabel0 = new TextLabel("Preferred Browser", TextAlignment.Left, layout);
        auto browserSelect = new DropDownSelection(layout);
        auto vSpacer0 = new VerticalSpacer(layout);

        auto textLabel1 = new TextLabel("Browser Executable", TextAlignment.Left,  layout);
        auto browserPath = new LineEdit(layout);
        auto vSpacer1 = new VerticalSpacer(layout);

        auto textLabel2 = new TextLabel("Preferred Search Engine", TextAlignment.Left,  layout);
        auto engineSelect = new DropDownSelection(layout);
        auto vSpacer2 = new VerticalSpacer(layout);

        auto textLabel3 = new TextLabel("Custom Search Engine URL", TextAlignment.Left,  layout);
        auto engineUrl = new LineEdit(layout);
        auto vSpacer3 = new VerticalSpacer(layout);

        auto applyButton = new Button("Apply Settings", layout);

        window.setMargins(4, 8, 4, 8);

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);

        debug writeln(error);
    }
}
