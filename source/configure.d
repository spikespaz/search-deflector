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

import common: mergeAAs, openUri, parseConfig, createErrorDialog, createWarningDialog, getConsoleArgs, getAvailableBrowsers,
    DeflectorSettings, PROJECT_NAME, PROJECT_VERSION, PROJECT_AUTHOR, SETUP_FILENAME, ENGINE_TEMPLATES, WIKI_URL;
import updater: compareVersions, startInstallUpdate, compareVersions, getReleaseAsset, getLatestRelease;

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

        this.syncApi = SettingsSyncApi(&this);
        this.syncApi.browsers = getAvailableBrowsers(false);
        this.syncApi.engines = parseConfig(ENGINE_TEMPLATES);

        try
            this.syncApi.browsers = mergeAAs(this.syncApi.browsers, getAvailableBrowsers(true));
        catch (RegistryException) {
        }
    }

    void showConfigPageDefaults() {
        debug writeln("ConfigApp.showConfigPageDefaults()");

        this.browserSelect.addOption("Custom");
        this.browserSelect.addOption("System Default");
        this.engineSelect.addOption("Custom");

        int browserIndex = ["system_default", ""].canFind(this.syncApi.browserPath) ? 1 : -1;
        int engineIndex = !this.syncApi.engines.values.canFind(this.syncApi.engineUrl) ? 0 : -1;

        foreach (uint index, string browser; this.syncApi.browsers.keys) {
            this.browserSelect.addOption(browser);

            if (this.syncApi.browsers[browser] == this.syncApi.browserPath)
                browserIndex = index + 2;
        }

        foreach (uint index, string engine; this.syncApi.engines.keys) {
            this.engineSelect.addOption(engine);

            if (this.syncApi.engines[engine] == this.syncApi.engineUrl)
                engineIndex = index + 1;
        }

        this.browserSelect.setSelection(browserIndex);
        this.engineSelect.setSelection(engineIndex);

        if (this.browserSelect.currentText == "Custom")
            this.engineUrl.setEnabled(true);

        this.browserPath.content = this.syncApi.browsers.get(this.browserSelect.currentText, "");
        this.engineUrl.content = this.syncApi.engines.get(this.engineSelect.currentText, this.syncApi.engineUrl);
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
            debug writeln(this.browserPath.content);

            if (this.browserSelect.currentText == "Custom") {
                this.browserPath.setEnabled(true);
                this.browserPathButton.show();
                this.browserPathButtonHidden = true;

                browserPath.content = "";
            } else {
                this.browserPath.setEnabled(false);
                this.browserPathButton.hide();
                this.browserPathButtonHidden = true;

                this.browserPath.content = this.syncApi.browsers.get(this.browserSelect.currentText, "");
            }

            this.syncApi.browserPath = this.browserPath.content;
            this.applyButton.setEnabled(true);
        });

        this.browserPath.addEventListener(EventType.keyup, {
            this.syncApi.engineUrl = this.engineUrl.content.strip();
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

                this.engineUrl.content = this.syncApi.engines[this.engineSelect.currentText];
            }

            this.syncApi.engineUrl = this.engineUrl.content;
            this.applyButton.setEnabled(true);

            debug writeln(this.engineUrl.content);
        });

        this.engineUrl.addEventListener(EventType.keyup, {
            this.syncApi.engineUrl = this.engineUrl.content.strip();
            this.applyButton.setEnabled(true);
        });

        this.applyButton.addEventListener(EventType.triggered, {
            debug writeln("Valid Browser: ", validateExecutablePath(this.syncApi.browserPath));

            if (this.browserSelect.currentText != "System Default" && !validateExecutablePath(this.syncApi.browserPath)) {
                debug writeln(this.syncApi.browserPath);

                createWarningDialog("Custom browser path is invalid.\nCheck the wiki for more information.", this.window
                    .hwnd);

                return;
            }

            if (!validateEngineUrl(this.syncApi.engineUrl)) {
                debug writeln(this.syncApi.engineURL);

                createWarningDialog("Custom search engine URL is invalid.\nCheck the wiki for more information.",
                    this.window.hwnd);

                return;
            }

            this.syncApi.dump();

            this.applyButton.setEnabled(false);

            debug writeln(this.syncApi);
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

    this(ConfigApp* parent) {
        this.parent = parent;
    }

    void dump() {
        this.settings.dump();
    }

    void browserPath(const string value) {
        if (value == "" || validateExecutablePath(value)) {
            this.settings.browserPath = value;
            this.parent.browserPath.content = value;
        }
    }

    void browserName(const string value) {
        assert((["Custom", "System Default", ""] ~ this.browsers.keys).canFind(value),
            "Browser name is an unexpected value: " ~ value);

        switch (value) {
            case "Custom":
                goto case "";
            case "System Default":
                goto case "";
            case "":
                this.browserPath = "";
                break;
            default:
                foreach(string name; this.browsers.keys)
                    if (value == name) {
                        this.browserPath = this.browsers[name];
                        break;
                    }
        }

        int browserIndex = ["system_default", ""].canFind(this.browserPath) ? 1 : -1;

        foreach (uint index, string browser; this.browsers.keys)
            if (this.browsers[browser] == this.browserPath)
                browserIndex = index + 2;

        this.parent.browserSelect.setSelection(browserIndex);
    }

    void engineUrl(const string value) {
        if (validateEngineUrl(value)) {
            this.settings.engineURL = value;
            this.parent.engineUrl.content = value;
        }
    }

    void engineName(const string value) {
        assert((["Custom", ""] ~ this.engines.keys).canFind(value),
            "Search engine name is an unexpected value: " ~ value);

        switch (value) {
            case "Custom":
                goto case "";
            case "":
                this.engineUrl = "";
                break;
            default:
                foreach(string name; this.engines.keys)
                    if (value == name) {
                        this.engineUrl = this.engines[name];
                        break;
                    }
        }

        int engineIndex = !this.engines.values.canFind(this.engineUrl) ? 0 : -1;

        foreach (uint index, string engine; this.engines.keys)
            if (this.engines[engine] == this.engineUrl)
                engineIndex = index + 1;

        this.parent.engineSelect.setSelection(engineIndex);
    }

    string browserPath() {
        return this.settings.browserPath;
    }

    string browserName() {
        if (this.browserPath == "")
            return "System Default";

        foreach (string item; this.browsers.keys)
            if (this.browsers[item] == this.browserPath)
                return item;
        
        return "Custom";
    }

    string engineUrl() {
        return this.settings.engineURL;
    }

    string engineName() {
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