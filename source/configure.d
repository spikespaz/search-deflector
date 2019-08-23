module configure;

import std.windows.registry: Registry, Key, RegistryException;
import std.algorithm: endsWith, canFind, countUntil;
import std.socket: SocketException, getAddress;
import std.string: indexOf, strip;
import std.path: isValidFilename;
import std.file: exists, isFile;
import std.stdio: writeln;
import std.utf: toUTF16z;

import arsd.minigui;

import common: mergeAAs, openUri, parseConfig, createErrorDialog,
    createWarningDialog, readSettings, writeSettings,
    getConsoleArgs, DeflectorSettings, PROJECT_VERSION, PROJECT_AUTHOR,
    ENGINE_TEMPLATES, WIKI_URL;

void main(string[] args) {
    try {
        auto window = new Window(400, 290, "Configure Search Deflector");
        auto app = ConfigApp(window);

        app.loop();
    } catch (Exception error) {
        createErrorDialog(error);
        debug writeln(error);
    }
}

struct ConfigApp {
    string[string] browsers;
    string[string] engines;

    DeflectorSettings settings;
    Window window;

    DropDownSelection browserSelect;
    DropDownSelection engineSelect;

    LineEdit browserPath;
    LineEdit engineUrl;

    Button browserPathButton;
    Button applyButton;
    Button wikiButton;

    this(Window window) {
        this.window = window;
        this.window.setPadding(4, 8, 4, 8);
        this.window.win.setMinSize(300, 290);

        this.createWidgets();
        this.loadDefaults();
        this.showDefaults();
        this.bindListeners();
    }

    void loop() {
        this.window.loop();
    }

    void createWidgets() {
        auto layout = new VerticalLayout(window);

        TextLabel label;

        label = new TextLabel("Preferred Browser", layout);
        this.browserSelect = new DropDownSelection(layout);
        auto vSpacer0 = new VerticalSpacer(layout);
        vSpacer0.setMaxHeight(8);

        label = new TextLabel("Browser Executable", layout);
        auto hLayout0 = new HorizontalLayout(layout);
        this.browserPath = new LineEdit(hLayout0);
        this.browserPath.setEnabled(false);
        this.browserPathButton = new Button("...", hLayout0);
        this.browserPathButton.setMaxWidth(30);
        this.browserPathButton.hide();

        auto vSpacer1 = new VerticalSpacer(layout);
        vSpacer1.setMaxHeight(8);

        label = new TextLabel("Preferred Search Engine", layout);
        this.engineSelect = new DropDownSelection(layout);
        auto vSpacer2 = new VerticalSpacer(layout);
        vSpacer2.setMaxHeight(8);

        label = new TextLabel("Custom Search Engine URL", layout);
        this.engineUrl = new LineEdit(layout);
        this.engineUrl.setEnabled(false);
        auto vSpacer3 = new VerticalSpacer(layout);

        this.applyButton = new Button("Apply Settings", layout);
        this.applyButton.setEnabled(false);
        auto vSpacer4 = new VerticalSpacer(layout);
        vSpacer4.setMaxHeight(2);

        this.wikiButton = new Button("Open Website", layout);
        auto vSpacer5 = new VerticalSpacer(layout);
        vSpacer5.setMaxHeight(8);

        label = new TextLabel("Version: " ~ PROJECT_VERSION ~ ", Author: " ~ PROJECT_AUTHOR, layout);
    }

    void loadDefaults() {
        this.settings = readSettings();
        this.browsers = getAvailableBrowsers(false);
        this.engines = parseConfig(ENGINE_TEMPLATES);

        try
            this.browsers = mergeAAs(this.browsers, getAvailableBrowsers(true));
        catch (RegistryException) {
        }
    }

    void showDefaults() {
        this.browserSelect.addOption("Custom");
        this.browserSelect.addOption("System Default");
        this.engineSelect.addOption("Custom");

        int browserIndex = ["system_default", ""].canFind(settings.browserPath) ? 1 : -1;
        int engineIndex = !this.browsers.values.canFind(settings.engineURL) ? 0 : -1;

        foreach (uint index, string browser; this.browsers.keys) {
            this.browserSelect.addOption(browser);

            if (this.browsers[browser] == this.settings.browserPath)
                browserIndex = index + 2;
        }

        foreach (uint index, string engine; engines.keys) {
            this.engineSelect.addOption(engine);

            if (engines[engine] == this.settings.engineURL)
                engineIndex = index + 1;
        }

        this.browserSelect.setSelection(browserIndex);
        this.engineSelect.setSelection(engineIndex);

        if (this.browserSelect.currentText == "Custom")
            this.engineUrl.setEnabled(true);

        this.browserPath.content = this.browsers.get(this.browserSelect.currentText, "");
        this.engineUrl.content = engines.get(this.engineSelect.currentText, this.settings.engineURL);
    }

    void bindListeners() {
        this.browserPathButton.addEventListener(EventType.triggered, {
            getOpenFileName(&this.browserPath.content, this.browserPath.content, null);

            this.settings.browserPath = this.browserPath.content.strip();
            this.applyButton.setEnabled(true);
        });

        this.browserSelect.addEventListener(EventType.change, {
            debug writeln(this.browserSelect.currentText);
            debug writeln(this.browserPath.content);

            if (this.browserSelect.currentText == "Custom") {
                this.browserPath.setEnabled(true);
                this.browserPathButton.show();

                browserPath.content = "";
            } else {
                this.browserPath.setEnabled(false);
                this.browserPathButton.hide();

                this.browserPath.content = this.browsers.get(this.browserSelect.currentText, "");
            }

            this.settings.browserPath = this.browserPath.content;
            this.applyButton.setEnabled(true);
        });

        this.browserPath.addEventListener(EventType.keyup, {
            this.settings.engineURL = this.engineUrl.content.strip();
            this.applyButton.setEnabled(true);
        });

        this.engineSelect.addEventListener(EventType.change, {
            debug writeln(this.engineSelect.currentText);
            debug writeln(this.engineUrl.content);

            if (this.engineSelect.currentText == "Custom") {
                this.engineUrl.setEnabled(true);

                this.engineUrl.content = "";
            } else {
                this.engineUrl.setEnabled(false);

                this.engineUrl.content = engines[this.engineSelect.currentText];
            }

            this.settings.engineURL = this.engineUrl.content;
            this.applyButton.setEnabled(true);

            debug writeln(this.engineUrl.content);
        });

        this.engineUrl.addEventListener(EventType.keyup, {
            this.settings.engineURL = this.engineUrl.content.strip();
            this.applyButton.setEnabled(true);
        });

        this.applyButton.addEventListener(EventType.triggered, {
            debug writeln("Valid Browser: ", validateExecutablePath(this.settings.browserPath));

            if (this.browserSelect.currentText != "System Default" &&
                !validateExecutablePath(this.settings.browserPath)) {
                debug writeln(this.settings.browserPath);

                createWarningDialog(
                    "Custom browser path is invalid.\nCheck the wiki for more information.",
                    this.window.hwnd);

                return;
            }

            if (!validateEngineUrl(this.settings.engineURL)) {
                debug writeln(this.settings.engineURL);

                createWarningDialog(
                    "Custom search engine URL is invalid.\nCheck the wiki for more information.",
                    this.window.hwnd);

                return;
            }

            writeSettings(this.settings);

            this.applyButton.setEnabled(false);

            debug writeln(this.settings);
        });

        this.wikiButton.addEventListener(EventType.triggered, {
            openUri(this.settings.browserPath, WIKI_URL);
        });
    }
}

/// Fetch a list of available browsers from the Windows registry along with their paths.
/// Use the names as the keys in an associative array containing the browser executable paths.
string[string] getAvailableBrowsers(const bool currentUser = false) {
    string[string] availableBrowsers;
    Key startMenuInternetKey;

    if (currentUser)
        startMenuInternetKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\StartMenuInternet");
    else
        startMenuInternetKey = Registry.localMachine.getKey("SOFTWARE\\Clients\\StartMenuInternet");

    foreach (key; startMenuInternetKey.keys) {
        string browserName;

        try
            browserName = key.getValue("").value_SZ;
        catch (RegistryException)
            continue;

        string browserPath = key.getKey("shell\\open\\command").getValue("").value_SZ;

        if (!isValidFilename(browserPath) && !exists(browserPath)) {
            browserPath = getConsoleArgs(browserPath.toUTF16z())[0];

            if (!isValidFilename(browserPath) && !exists(browserPath))
                continue;
        }

        availableBrowsers[browserName] = browserPath;
    }

    return availableBrowsers;
}

bool validateExecutablePath(const string path) {
    return path && path.exists() && path.isFile() && path.endsWith(".exe");
}

/// Validate that a user's custom search engine URL is a valid candidate.
bool validateEngineUrl(const string url) {
    if (url.indexOf("{{query}}") == -1)
        return false;

    try {
        const ptrdiff_t slashIndex = url.indexOf("/");

        if (slashIndex == -1)
            getAddress(url);
        else
            getAddress(url[0 .. slashIndex]);

        return true;
    } catch (SocketException)
        return false;
}
