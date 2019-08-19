import arsd.minigui;
import std.windows.registry: RegistryException;
import std.stdio: writeln;
import common: mergeAAs, getConsoleArgs, parseConfig, createErrorDialog, PROJECT_VERSION, ENGINE_TEMPLATES;
import setup: getAvailableBrowsers;


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
        string[string] browsers = getAvailableBrowsers(false);
        const string[string] engines = parseConfig(ENGINE_TEMPLATES);

        try
            browsers = mergeAAs(browsers, getAvailableBrowsers(true));
        catch (RegistryException) {}

        auto window = new Window(400, 260, "Search Deflector");
        auto layout = new VerticalLayout(window);

        auto textLabel0 = new TextLabel("Preferred Browser", layout);
        auto browserSelect = new DropDownSelection(layout);
        auto vSpacer0 = new VerticalSpacer(layout);

        auto textLabel1 = new TextLabel("Browser Executable", layout);
        auto hLayout0 = new HorizontalLayout(layout);
        auto browserPath = new LineEdit(hLayout0);
        auto browserPathButton = new Button("...", hLayout0);
        auto vSpacer1 = new VerticalSpacer(layout);

        auto textLabel2 = new TextLabel("Preferred Search Engine", layout);
        auto engineSelect = new DropDownSelection(layout);
        auto vSpacer2 = new VerticalSpacer(layout);

        auto textLabel3 = new TextLabel("Custom Search Engine URL", layout);
        auto engineUrl = new LineEdit(layout);
        auto vSpacer3 = new VerticalSpacer(layout);

        auto applyButton = new Button("Apply Settings", layout);
        auto vSpacer4 = new VerticalSpacer(layout);
        
        auto infoText = new TextLabel("Version: " ~ PROJECT_VERSION, layout);

        window.setPadding(4, 8, 4, 8);
        window.win.setMinSize(300, 260);

        vSpacer0.setMaxHeight(8);
        vSpacer1.setMaxHeight(8);
        vSpacer2.setMaxHeight(8);

        vSpacer4.setMaxHeight(8);

        browserPath.setEnabled(false);
        engineUrl.setEnabled(false);
        browserPathButton.hide();

        browserSelect.addOption("Custom");
        engineSelect.addOption("Custom");

        foreach (string browser; browsers.keys)
            browserSelect.addOption(browser);

        foreach (string engine; engines.keys)
            engineSelect.addOption(engine);

        browserPathButton.setMaxWidth(30);
        browserPathButton.addEventListener(EventType.triggered, {
            getOpenFileName(&browserPath.content, browserPath.content, null);
        });

        browserSelect.addEventListener(EventType.change, {
            if (browserSelect.currentText == "Custom") {
                browserPath.setEnabled(true);
                browserPathButton.show();

                browserPath.content = "";
            } else {
                browserPath.setEnabled(false);
                browserPathButton.hide();

                browserPath.content = browsers[browserSelect.currentText];
            }
        });

        engineSelect.addEventListener(EventType.change, {
            if (engineSelect.currentText == "Custom") {
                engineUrl.setEnabled(true);

                engineUrl.content = "";
            } else {
                engineUrl.setEnabled(false);

                engineUrl.content = engines[engineSelect.currentText];
            }
        });

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);

        debug writeln(error);
    }
}
