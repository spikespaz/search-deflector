module configure;

import std.file: exists, isFile, tempDir, thisExePath, timeLastModified;
import std.algorithm: endsWith, canFind, countUntil;
import std.socket: SocketException, getAddress;
import std.windows.registry: RegistryException;
import std.path: buildNormalizedPath;
import std.string: indexOf, strip;
import std.traits: isPointer;
import std.datetime: SysTime;
import std.json: JSONValue;
import std.format: format;
import std.utf: toUTF16z;
import std.conv: to;

import core.stdc.stdlib: exit;

import arsd.minigui;

import common;
import updater;

debug import std.stdio: writeln;

void main(string[] args) {
    const bool forceUpdate = args.canFind("--update") || args.canFind("-u");

    try {
        auto app = ConfigApp();

        version(update_module)
        if (forceUpdate) {
            app.fetchReleaseInfo();

            if (app.shouldUpdate())
                app.installUpdate(true);

            return;
        }

        app.createWindow();
        app.loopWindow();
    } catch (Exception error) {
        createErrorDialog(error);
        debug writeln(error);
    }
}

struct ConfigApp {
    Window window;
    SettingsSyncApi syncApi;

    DropDownSelection browserSelect;
    DropDownSelection engineSelect;

    LineEdit browserPath;
    LineEdit engineUrl;

    Button browserPathButton;
    Button applyButton;
    Button wikiButton;
    Button closeButton;

    version(update_module) {
        TabWidget tabs;

        // All widgets for Settings tab
        TabWidgetPage page0;

        // All widgets for Update tab
        TabWidgetPage page1;

        TextLabel versionLabel, uploaderLabel, timestampLabel, binarySizeLabel, downloadCountLabel;

        Button updateButton;
        Button detailsButton;

        JSONValue releaseJson;
        JSONValue releaseAsset;
    } else {
        VerticalLayout tabs;
        VerticalLayout page0;
    }

    bool browserPathButtonHidden = true;

    void createWindow() {
        debug writeln("ConfigApp.createWindow()");

        this.window = new Window(400, 290, "Configure Search Deflector");
        this.window.win.setMinSize(300, 290);

        this.createWidgets();
        this.createConfigPageWidgets();
        version(update_module)
        this.createUpdatePageWidgets();
        this.loadDefaults();
        this.showConfigPageDefaults();
        this.bindConfigPageListeners();

        version(update_module) {
            this.bindUpdatePageListeners();

            // And a fix for the "..." button mysteriously appearing after switching tabs
            this.tabs.addDirectEventListener(EventType.click, (Event event) {
                auto t = (event.clientX / 80); // 80 = tab width
                if (!(event.clientY < Window.lineHeight && t >= 0 && t < this.tabs.children.length))
                    return;
                
                debug writeln("Tabs changed");

                if (this.browserPathButtonHidden)
                    this.browserPathButton.hide();
                else
                    this.browserPathButton.show();

                if (releaseJson.isNull) {
                    this.fetchReleaseInfo();
                    this.showUpdatePageDefaults();
                }
            });

            // Little hack to mitigate issue #51
            this.tabs.setCurrentTab(1);
            this.tabs.setCurrentTab(0);
        }

        // And this for good measure
        this.browserPathButton.hide();
        this.browserPathButtonHidden = true;
    }

    version(update_module)
    bool shouldUpdate() {
        debug writeln("ConfigApp.shouldUpdate()");

        return compareVersions(this.releaseJson["tag_name"].str, PROJECT_VERSION);
    }

    string getInstallerPath() {
        debug writeln("ConfigApp.getInstallerPath()");

        return buildNormalizedPath(tempDir(), SETUP_FILENAME);
    }

    void loopWindow() {
        debug writeln("ConfigApp.loopWindow()");

        this.window.loop();
    }

    void createWidgets() {
        debug writeln("ConfigApp.createWidgets()");

        auto layout = new VerticalLayout(this.window);

        version(update_module) {
            this.tabs = new TabWidget(layout);
            this.tabs.setMargins(0, 0, 0, 0);

            this.page0 = this.tabs.addPage("Settings");
            this.page0.setPadding(4, 4, 4, 4);

            this.page1 = this.tabs.addPage("Update");
            this.page1.setPadding(4, 4, 4, 4);
        } else {
            this.tabs = layout;
            this.page0 = layout;
            this.page0.setPadding(4, 8, 0, 8);
        }

        TextLabel label = new TextLabel("Version: " ~ PROJECT_VERSION ~ ", Author: " ~ PROJECT_AUTHOR, layout);
        label.setMargins(4, 8, 2, 8);
    }

    void createConfigPageWidgets() {
        debug writeln("ConfigApp.createConfigPageWidgets()");

        auto layout = new VerticalLayout(this.page0);

        TextLabel label;
        VerticalSpacer vSpacer;

        label = new TextLabel("Preferred Browser", layout);
        this.browserSelect = new DropDownSelection(layout);
        this.browserSelect.addOption("Custom");
        this.browserSelect.addOption("System Default");
        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        label = new TextLabel("Browser Executable", layout);
        auto hLayout0 = new HorizontalLayout(layout);
        this.browserPath = new LineEdit(hLayout0);
        this.browserPath.setEnabled(false);
        this.browserPathButton = new Button("...", hLayout0);
        this.browserPathButton.setMaxWidth(30);
        this.browserPathButton.hide();
        this.browserPathButtonHidden = true;

        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        label = new TextLabel("Preferred Search Engine", layout);
        this.engineSelect = new DropDownSelection(layout);
        this.engineSelect.addOption("Custom");
        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        label = new TextLabel("Custom Search Engine URL", layout);
        this.engineUrl = new LineEdit(layout);
        this.engineUrl.setEnabled(false);
        vSpacer = new VerticalSpacer(layout);

        auto hLayout1 = new HorizontalLayout(layout);

        HorizontalSpacer hSpacer;

        this.applyButton = new Button("Apply", hLayout1);
        this.applyButton.setEnabled(false);

        hSpacer = new HorizontalSpacer(hLayout1);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.wikiButton = new Button("Website", hLayout1);

        hSpacer = new HorizontalSpacer(hLayout1);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.closeButton = new Button("Close", hLayout1);
    }

    version(update_module)
    void createUpdatePageWidgets() {
        debug writeln("ConfigApp.createUpdatePageWidgets()");

        auto layout = new VerticalLayout(this.page1);
        auto hLayout = new HorizontalLayout(layout);
        auto vLayout0 = new VerticalLayout(hLayout);
        auto vLayout1 = new VerticalLayout(hLayout);

        TextLabel label;
        VerticalSpacer spacer;

        label = new TextLabel("Current Version:", vLayout0);
        label = new TextLabel("Build Date:", vLayout0);

        label = new TextLabel(PROJECT_VERSION, vLayout1);
        label = new TextLabel(thisExePath.timeLastModified.toLocalTime.toReadableTimestamp(), vLayout1);

        spacer = new VerticalSpacer(vLayout0);
        spacer.setMaxHeight(Window.lineHeight);
        spacer = new VerticalSpacer(vLayout1);
        spacer.setMaxHeight(Window.lineHeight);

        label = new TextLabel("Latest Version:", vLayout0);
        label = new TextLabel("Uploader:", vLayout0);
        label = new TextLabel("Timestamp:", vLayout0);
        label = new TextLabel("Binary Size:", vLayout0);
        label = new TextLabel("Download Count:", vLayout0);

        this.versionLabel = new TextLabel("", vLayout1);
        this.uploaderLabel = new TextLabel("", vLayout1);
        this.timestampLabel = new TextLabel("", vLayout1);
        this.binarySizeLabel = new TextLabel("", vLayout1);
        this.downloadCountLabel = new TextLabel("", vLayout1);

        auto hLayout0 = new HorizontalLayout(layout);
        HorizontalSpacer hSpacer;

        this.updateButton = new Button("Update", hLayout0);
        this.updateButton.setEnabled(false);

        hSpacer = new HorizontalSpacer(hLayout0);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.detailsButton = new Button("Details", hLayout0);
    }

    void loadDefaults() {
        debug writeln("ConfigApp.loadDefaults()");

        this.syncApi = SettingsSyncApi();
        this.syncApi.parent = &this;
        this.syncApi.settings = DeflectorSettings();
        this.syncApi.browsers = getAllAvailableBrowsers();
        this.syncApi.engines = parseConfig(ENGINE_TEMPLATES);

        foreach (browser; this.syncApi.browsers.byKey)
            this.browserSelect.addOption(browser);

        foreach (engine; this.syncApi.engines.byKey)
            this.engineSelect.addOption(engine);    
    }

    void showConfigPageDefaults() {
        debug writeln("ConfigApp.showConfigPageDefaults()");

        this.syncApi.browserName = this.syncApi.browsers.nameFromPath(this.syncApi.settings.browserPath);
        this.syncApi.engineName = this.syncApi.engines.nameFromUrl(this.syncApi.settings.engineURL);
    }

    version(update_module)
    void showUpdatePageDefaults() {
        debug writeln("ConfigApp.showUpdatePageDefaults()");

        if (this.shouldUpdate)
            this.updateButton.setEnabled(true);

        this.versionLabel.label = releaseJson["tag_name"].str;
        this.uploaderLabel.label = releaseAsset["uploader"]["login"].str;
        this.timestampLabel.label = SysTime.fromISOExtString(releaseAsset["updated_at"].str).toReadableTimestamp();
        this.binarySizeLabel.label = format("%.2f MB", releaseAsset["size"].integer / 1_048_576f);
        this.downloadCountLabel.label = releaseAsset["download_count"].integer.to!string();
    }

    void bindConfigPageListeners() {
        debug writeln("ConfigApp.bindConfigPageListeners()");

        this.browserPathButton.addEventListener(EventType.triggered, {
            getOpenFileName(&this.browserPath.content, this.browserPath.content, null);

            this.syncApi.browserPath = this.browserPath.content.strip();
            this.applyButton.setEnabled(true);
        });

        this.browserSelect.addEventListener(EventType.change, {
            debug writeln(this.browserSelect.currentText);
            this.syncApi.browserName = this.browserSelect.currentText;
            this.applyButton.setEnabled(true);
        });

        this.browserPath.addEventListener(EventType.keyup, {
            string value = this.browserPath.content.strip(); // Santitize
            debug writeln("Browser path changed: ", value);
            this.syncApi.settings.browserPath = value;
            this.applyButton.setEnabled(true);
        });

        this.engineSelect.addEventListener(EventType.change, {
            debug writeln(this.engineSelect.currentText);
            this.syncApi.engineName = this.engineSelect.currentText;
            this.applyButton.setEnabled(true);
        });

        this.engineUrl.addEventListener(EventType.keyup, {
            string value = this.engineUrl.content.strip(); // Sanitize
            debug writeln("Engine URL changed: ", value);
            this.syncApi.settings.engineURL = value;
            this.applyButton.setEnabled(true);
        });

        this.applyButton.addEventListener(EventType.triggered, {
            debug writeln(this.syncApi.settings);
            this.syncApi.dump();
            this.applyButton.setEnabled(false);
        });

        this.wikiButton.addEventListener(EventType.triggered, { openUri(this.syncApi.browserPath, WIKI_URL); });

        this.closeButton.addEventListener(EventType.triggered, { exit(0); });
    }

    version(update_module)
    void bindUpdatePageListeners() {
        debug writeln("ConfigApp.bindUpdatePageListeners()");

        this.updateButton.addEventListener(EventType.triggered, {
            this.updateButton.setEnabled(false);

            this.installUpdate(false);
        });

        this.detailsButton.addEventListener(EventType.triggered, {
            openUri(this.syncApi.browserPath, this.releaseJson["html_url"].str);
        });
    }

    version(update_module)
    void fetchReleaseInfo() {
        debug writeln("ConfigApp.fetchReleaseInfo()");

        this.releaseJson = getLatestRelease(PROJECT_AUTHOR, PROJECT_NAME);
        this.releaseAsset = getReleaseAsset(releaseJson, SETUP_FILENAME);
    }

    version(update_module)
    void installUpdate(const bool silent) {
        debug writeln("ConfigApp.installUpdate()");

        startInstallUpdate(this.releaseAsset["browser_download_url"].str, this.getInstallerPath(), silent);
    }
}

struct SettingsSyncApi {
    private ConfigApp* parent;
    private DeflectorSettings settings;
    private string[string] engines;
    private string[string] browsers;

    void dump() {
        debug writeln("SettingsSyncApi.dump()");

        if (this.parent.browserSelect.currentText != "System Default" && !validateExecutablePath(this.browserPath)) {
            debug writeln("Bad browser path: ", this.browserPath);
            createWarningDialog("Custom browser path is invalid.\nCheck the wiki for more information.", this.parent.window.hwnd);
            return;
        }

        if (!validateEngineUrl(this.engineUrl)) {
            debug writeln("Bad engine URL: ", this.engineUrl);
            createWarningDialog("Custom search engine URL is invalid.\nCheck the wiki for more information.", this.parent.window.hwnd);
            return;
        }

        this.settings.dump();
    }

    void browserPath(const string value) {
        debug writeln("SettingsSyncApi.browserPath(value)");

        if (value == "" || validateExecutablePath(value)) {
            this.settings.browserPath = value;
            
            if (value != this.parent.browserPath.content)
                this.parent.browserPath.content = value;
        }
    }

    void browserName(const string value) {
        debug writeln("SettingsSyncApi.browserName(value)");

        assert((["Custom", "System Default", ""] ~ this.browsers.keys).canFind(value),
            "Browser name is an unexpected value: " ~ value);

        int browserIndex = -1;

        switch (value) {
            case "Custom":
                this.parent.browserPath.setEnabled(true);
                this.parent.browserPathButton.show();
                this.browserPath = "";
                break;
            case "":
            case "System Default":
                this.parent.browserPath.setEnabled(false);
                this.parent.browserPathButton.hide();
                this.browserPath = "";
                break;
            default:
                this.parent.browserPath.setEnabled(false);
                this.parent.browserPathButton.hide();

                foreach (browser; this.browsers.byKeyValue)
                    if (browser.key == value) {
                        this.browserPath = browser.value;
                        break;
                    }
        }

        if (this.parent.browserSelect.currentText != value)
            this.parent.browserSelect.currentText = value;
    }

    void engineUrl(const string value) {
        debug writeln("SettingsSyncApi.engineUrl(value)");
        
        if (validateEngineUrl(value)) {
            this.settings.engineURL = value;

            if (value != this.parent.engineUrl.content)
                this.parent.engineUrl.content = value;
        }
    }

    void engineName(const string value) {
        debug writeln("SettingsSyncApi.engineName(value)");

        assert((["Custom", ""] ~ this.engines.keys).canFind(value),
            "Search engine name is an unexpected value: " ~ value);

        switch (value) {
            case "":
            case "Custom":
                this.parent.engineUrl.setEnabled(true);
                this.engineUrl = "";
                break;
            default:
                this.parent.engineUrl.setEnabled(false);

                foreach (engine; this.engines.byKeyValue)
                    if (engine.key == value) {
                        this.engineUrl = engine.value;
                        break;
                    }
        }

        if (this.parent.engineSelect.currentText != value)
            this.parent.engineSelect.currentText = value;
    }

    string browserPath() {
        debug writeln("SettingsSyncApi.browserPath()");
        return this.settings.browserPath;
    }

    string browserName() {
        debug writeln("SettingsSyncApi.browserName()");

        if (["", "system_default"].canFind(this.browserPath))
            return "System Default";

        foreach (browser; this.browsers.byKeyValue)
            if (browser.value == this.browserPath)
                return browser.key;
        
        return "Custom";
    }

    string engineUrl() {
        debug writeln("SettingsSyncApi.engineUrl()");
        return this.settings.engineURL;
    }

    string engineName() {
        debug writeln("SettingsSyncApi.browserName()");

        foreach (string item; this.engines.keys)
            if (this.engines[item] == this.engineUrl)
                return item;

        return "Custom";
    }
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

string toReadableTimestamp(T)(T time) {
    return "%02d-%02d-%0004d  %02d:%02d %s".format(time.month, time.day, time.year, (time.hour > 12 ?
            time.hour - 12 : time.hour), time.minute, (time.hour > 12 ? "PM" : "AM"));
}

bool isNull(T)(T value) if (is(T == class) || isPointer!T) {
	return value is null;
}