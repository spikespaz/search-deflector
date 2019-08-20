import arsd.minigui;
import std.windows.registry: RegistryException;
import std.string: strip;
import std.stdio: writeln;
import std.algorithm: countUntil, canFind;
import common: mergeAAs, openUri, parseConfig, createErrorDialog,
    createWarningDialog, readSettings, writeSettings,
    DeflectorSettings, PROJECT_VERSION, PROJECT_AUTHOR, ENGINE_TEMPLATES, WIKI_URL;
import setup: getAvailableBrowsers, validateEngineUrl, validateExecutablePath;

void main(string[] args) {
    try {
        auto settings = readSettings();
        string[string] browsers = getAvailableBrowsers(false);
        const string[string] engines = parseConfig(ENGINE_TEMPLATES);

        try
            browsers = mergeAAs(browsers, getAvailableBrowsers(true));
        catch (RegistryException) {
        }

        auto window = new Window(400, 290, "Search Deflector");
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

        auto wikiButton = new Button("Open Website", layout);
        auto vSpacer5 = new VerticalSpacer(layout);

        auto infoText = new TextLabel(
                "Version: " ~ PROJECT_VERSION ~ ", Author: " ~ PROJECT_AUTHOR, layout);

        window.setPadding(4, 8, 4, 8);
        window.win.setMinSize(300, 290);

        vSpacer0.setMaxHeight(8);
        vSpacer1.setMaxHeight(8);
        vSpacer2.setMaxHeight(8);

        vSpacer4.setMaxHeight(2);
        vSpacer5.setMaxHeight(8);

        browserPath.setEnabled(false);
        engineUrl.setEnabled(false);
        browserPathButton.hide();

        browserSelect.addOption("Custom");
        browserSelect.addOption("System Default");
        engineSelect.addOption("Custom");

        applyButton.setEnabled(false);

        int browserIndex = ["system_default", ""].canFind(settings.browserPath) ? 1 : -1;
        int engineIndex = !browsers.values.canFind(settings.engineURL) ? 0 : -1;

        foreach (uint index, string browser; browsers.keys) {
            browserSelect.addOption(browser);

            if (browsers[browser] == settings.browserPath)
                browserIndex = index + 2;
        }

        foreach (uint index, string engine; engines.keys) {
            engineSelect.addOption(engine);

            if (engines[engine] == settings.engineURL)
                engineIndex = index + 1;
        }

        browserSelect.setSelection(browserIndex);
        engineSelect.setSelection(engineIndex);

        if (browserSelect.currentText == "Custom")
            engineUrl.setEnabled(true);

        browserPath.content = browsers.get(browserSelect.currentText, "");
        engineUrl.content = engines.get(engineSelect.currentText, settings.engineURL);

        browserPathButton.setMaxWidth(30);
        browserPathButton.addEventListener(EventType.triggered, {
            getOpenFileName(&browserPath.content, browserPath.content, null);

            settings.browserPath = browserPath.content.strip();
            applyButton.setEnabled(true);
        });

        browserSelect.addEventListener(EventType.change, {
            debug writeln(browserSelect.currentText);
            debug writeln(browserPath.content);

            if (browserSelect.currentText == "Custom") {
                browserPath.setEnabled(true);
                browserPathButton.show();

                browserPath.content = "";
            } else {
                browserPath.setEnabled(false);
                browserPathButton.hide();

                browserPath.content = browsers.get(browserSelect.currentText, "");
            }

            settings.browserPath = browserPath.content;
            applyButton.setEnabled(true);
        });

        browserPath.addEventListener(EventType.keyup, {
            settings.engineURL = engineUrl.content.strip();
            applyButton.setEnabled(true);
        });

        engineSelect.addEventListener(EventType.change, {
            debug writeln(engineSelect.currentText);
            debug writeln(engineUrl.content);

            if (engineSelect.currentText == "Custom") {
                engineUrl.setEnabled(true);

                engineUrl.content = "";
            } else {
                engineUrl.setEnabled(false);

                engineUrl.content = engines[engineSelect.currentText];
            }

            settings.engineURL = engineUrl.content;
            applyButton.setEnabled(true);

            debug writeln(engineUrl.content);
        });

        engineUrl.addEventListener(EventType.keyup, {
            settings.engineURL = engineUrl.content.strip();
            applyButton.setEnabled(true);
        });

        applyButton.addEventListener(EventType.triggered, {
            debug writeln("Valid Browser: ", validateExecutablePath(settings.browserPath));

            if (browserSelect.currentText != "System Default" &&
                !validateExecutablePath(settings.browserPath)) {
                debug writeln(settings.browserPath);

                createWarningDialog(
                    "Custom browser path is invalid.\nCheck the wiki for more information.",
                    window.hwnd);

                return;
            }

            if (!validateEngineUrl(settings.engineURL)) {
                debug writeln(settings.engineURL);

                createWarningDialog(
                    "Custom search engine URL is invalid.\nCheck the wiki for more information.",
                    window.hwnd);

                return;
            }

            writeSettings(settings);

            applyButton.setEnabled(false);

            debug writeln(settings);
        });

        wikiButton.addEventListener(EventType.triggered, {
            openUri(settings.browserPath, WIKI_URL);
        });

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);

        debug writeln(error);
    }
}
