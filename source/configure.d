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
        if (DeflectorSettings.interfaceLanguage.length == 0)
            Translator.loadDefault();
        else
            Translator.load(DeflectorSettings.interfaceLanguage);

        auto app = ConfigApp();

        version (free_version)
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

/// Main structure for user interface
struct ConfigApp {
    Window window; /// Main program window
    VerticalLayout mainLayout; /// Main window layout
    SettingsSyncApi syncApi; /// Settings synchronization API instance for registry and UI

    DropDownSelection browserSelect; /// Drop down selection for installed browsers
    DropDownSelection engineSelect; /// Drop down selection for engines from engines.txt
    DropDownSelection languageSelection; /// Drop down selection for language translation

    LineEdit browserPath; /// Browser Path Line Edit
    LineEdit engineUrl; /// Engine URL Line Edit

    Checkbox useProfile; /// Enable/Disable Browser Profile Checkbox
    LineEdit profileName; /// Profile Name Line Edit

    Button browserPathButton; /// Browser Path Selection Button
    Button applyButton; /// Apply Settings Button
    Button wikiButton; /// Open Website Button
    Button closeButton; /// Close Interface Button

    TabWidget tabs; /// Main Tabs Widget

    TabWidgetPage settingsPage; /// Page for main settings
    TabWidgetPage languagePage; /// Page for language options

    version (free_version) {
        TabWidgetPage updatePage; /// Page for update information

        /// Labels for update information
        TextLabel versionLabel, uploaderLabel, timestampLabel, binarySizeLabel, downloadCountLabel;

        Button updateButton; /// Button to download and apply update
        Button detailsButton; /// Button to open the latest release

        JSONValue releaseJson; /// Release JSON data from GitHub
        JSONValue releaseAsset; /// Latest release JSOn asset data from GitHub
    }

    bool browserPathButtonHidden = true; /// Flag whether or not the path selection button should be shown

    /// Window construction main function
    void createWindow() {
        debug writeln("ConfigApp.createWindow()");

        this.window = new Window(400, 340, Translator.text("title.window"));
        this.window.win.setMinSize(300, 340);

        this.createWidgets();
        this.loadDefaults();
        this.bindCommonButtonListeners();
        this.showConfigPageDefaults();
        this.bindLanguagePageListeners();
        this.bindConfigPageListeners();

        version (free_version)
            this.bindUpdatePageListeners();

        // Little hack to mitigate issue #51
        this.tabs.setCurrentTab(1);
        this.tabs.setCurrentTab(0);

        // And this for good measure
        this.browserPathButton.hide();
        this.browserPathButtonHidden = true;
    }

    /// Checks whether or not the version online is newer by SemVer
    version (free_version) bool shouldUpdate() {
        debug writeln("ConfigApp.shouldUpdate()");

        return compareVersions(this.releaseJson["tag_name"].str, PROJECT_VERSION);
    }

    /// Returns the path to the downloaded installer in TEMP
    string getInstallerPath() {
        debug writeln("ConfigApp.getInstallerPath()");

        return buildNormalizedPath(tempDir(), SETUP_FILENAME);
    }

    /// Begin main window loop
    void loopWindow() {
        debug writeln("ConfigApp.loopWindow()");

        this.window.loop();
    }

    /// Construct all of widgets in the interface
    void createWidgets() {
        debug writeln("ConfigApp.createWidgets()");

        this.mainLayout = new VerticalLayout(this.window);

        this.tabs = new TabWidget(this.mainLayout);
        this.tabs.setMargins(0, 0, 0, 0);

        auto vSpacer = new VerticalSpacer(this.mainLayout);
        vSpacer.setMaxHeight(4);

        this.createCommonButtons();

        this.settingsPage = this.tabs.addPage(Translator.text("title.settings_page"));
        this.settingsPage.setPadding(4, 4, 4, 4);
        this.languagePage = this.tabs.addPage(Translator.text("title.language_page"));
        this.languagePage.setPadding(4, 4, 4, 4);

        version (free_version) {
            this.updatePage = this.tabs.addPage(Translator.text("title.update_page"));
            this.updatePage.setPadding(4, 4, 4, 4);

            this.createUpdatePageWidgets();
        }

        this.createConfigPageWidgets();
        this.createLanguagePageWidgets();

        TextLabel label = new TextLabel("%s: %s, %s: %s".format(
                Translator.text("fragment.version"), PROJECT_VERSION,
                Translator.text("fragment.author"), PROJECT_AUTHOR
            ), this.mainLayout);

        label.setMargins(6, 8, 4, 8);
    }

    void createCommonButtons() {
        HorizontalSpacer hSpacer;
        HorizontalLayout hLayout;

        // Group for Apply, Website and Close buttons
        hLayout = new HorizontalLayout(this.mainLayout);

        hSpacer = new HorizontalSpacer(hLayout);
        hSpacer.setMaxWidth(8);
        hSpacer.setMaxHeight(1);

        this.applyButton = new Button(Translator.text("button.apply"), hLayout);
        this.applyButton.setEnabled(false);

        hSpacer = new HorizontalSpacer(hLayout);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.wikiButton = new Button(Translator.text("button.website"), hLayout);

        hSpacer = new HorizontalSpacer(hLayout);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.closeButton = new Button(Translator.text("button.close"), hLayout);

        hSpacer = new HorizontalSpacer(hLayout);
        hSpacer.setMaxWidth(8);
        hSpacer.setMaxHeight(1);
    }

    /// Main interface (first page) widget construction
    void createConfigPageWidgets() {
        debug writeln("ConfigApp.createConfigPageWidgets()");

        auto layout = new VerticalLayout(this.settingsPage);

        TextLabel label;
        VerticalSpacer vSpacer;
        HorizontalSpacer hSpacer;
        HorizontalLayout hLayout;

        // Group for selecting from a list of installed browsers
        label = new TextLabel(Translator.text("label.browser_name"), layout);
        this.browserSelect = new DropDownSelection(layout);
        this.browserSelect.addOption(Translator.text("option.custom_browser"));
        this.browserSelect.addOption(Translator.text("option.default_browser"));

        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        // Group for the browser path display/edit and a button to browse files
        label = new TextLabel(Translator.text("label.browser_path"), layout);
        hLayout = new HorizontalLayout(layout);
        this.browserPath = new LineEdit(hLayout);
        this.browserPath.setEnabled(false);
        this.browserPathButton = new Button("...", hLayout);
        this.browserPathButton.setMaxWidth(30);
        this.browserPathButton.hide();
        this.browserPathButtonHidden = true;

        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        // Group for selecting from a list of search engines
        label = new TextLabel(Translator.text("label.engine_name"), layout);
        this.engineSelect = new DropDownSelection(layout);
        this.engineSelect.addOption("Custom");

        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        // Group for editing the engine URL
        label = new TextLabel(Translator.text("label.engine_url"), layout);
        this.engineUrl = new LineEdit(layout);
        this.engineUrl.setEnabled(false);

        vSpacer = new VerticalSpacer(layout);
        vSpacer.setMaxHeight(8);

        // Group for enabling/disabling and naming the browser profile
        label = new TextLabel(Translator.text("label.profile_dir"), layout);
        hLayout = new HorizontalLayout(layout);
        this.profileName = new LineEdit(hLayout);
        this.profileName.setEnabled(false);
        hSpacer = new HorizontalSpacer(hLayout);
        hSpacer.setMaxWidth(2);
        hSpacer.setMaxHeight(1);
        this.useProfile = new Checkbox(Translator.text("label.enable_profile"), hLayout);
        this.useProfile.isChecked = false;
        this.useProfile.setMargins(4, 4, 0, 0);
        this.useProfile.setStretchiness(2, 4);

        // vSpacer = new VerticalSpacer(layout);
    }

    /// Language page widget construction
    void createLanguagePageWidgets() {
        debug writeln("ConfigApp.createLanguagePageWidgets()");

        auto layout = new VerticalLayout(this.languagePage);

        TextLabel label;

        label = new TextLabel(Translator.text("label.language_select"), layout);

        this.languageSelection = new DropDownSelection(layout);
        this.languageSelection.addOption(Translator.text("option.default_language"));

        foreach (string langKey; Translator.getLangKeys()) {
            debug writeln(Translator.getNameFromLangKey(langKey));
            this.languageSelection.addOption(Translator.getNameFromLangKey(langKey));
        }
    }

    /// Updater page's widget construction
    version (free_version) void createUpdatePageWidgets() {
        debug writeln("ConfigApp.createUpdatePageWidgets()");

        auto layout = new VerticalLayout(this.updatePage);
        auto hLayout = new HorizontalLayout(layout);
        auto vLayout0 = new VerticalLayout(hLayout);
        auto vLayout1 = new VerticalLayout(hLayout);

        TextLabel label;
        VerticalSpacer spacer;

        label = new TextLabel(Translator.text("fragment.current_version") ~ ':', vLayout0);
        label = new TextLabel(Translator.text("fragment.build_date") ~ ':', vLayout0);

        label = new TextLabel(PROJECT_VERSION, vLayout1);
        label = new TextLabel(thisExePath.timeLastModified.toLocalTime.toReadableTimestamp(), vLayout1);

        spacer = new VerticalSpacer(vLayout0);
        spacer.setMaxHeight(Window.lineHeight);
        spacer = new VerticalSpacer(vLayout1);
        spacer.setMaxHeight(Window.lineHeight);

        label = new TextLabel(Translator.text("fragment.latest_version") ~ ':', vLayout0);
        label = new TextLabel(Translator.text("fragment.uploader") ~ ':', vLayout0);
        label = new TextLabel(Translator.text("fragment.timestamp") ~ ':', vLayout0);
        label = new TextLabel(Translator.text("fragment.binary_size") ~ ':', vLayout0);
        label = new TextLabel(Translator.text("fragment.download_count") ~ ':', vLayout0);

        this.versionLabel = new TextLabel("", vLayout1);
        this.uploaderLabel = new TextLabel("", vLayout1);
        this.timestampLabel = new TextLabel("", vLayout1);
        this.binarySizeLabel = new TextLabel("", vLayout1);
        this.downloadCountLabel = new TextLabel("", vLayout1);

        auto hLayout0 = new HorizontalLayout(layout);
        HorizontalSpacer hSpacer;

        this.updateButton = new Button(Translator.text("button.update"), hLayout0);
        this.updateButton.setEnabled(false);

        hSpacer = new HorizontalSpacer(hLayout0);
        hSpacer.setMaxWidth(4);
        hSpacer.setMaxHeight(1);

        this.detailsButton = new Button(Translator.text("button.details"), hLayout0);
    }

    /// Load defaults from registry into UI
    void loadDefaults() {
        debug writeln("ConfigApp.loadDefaults()");

        this.syncApi = SettingsSyncApi();
        this.syncApi.parent = &this;
        this.syncApi.browsers = getAllAvailableBrowsers();
        this.syncApi.engines = getEnginePresets();

        foreach (browser; this.syncApi.browsers.byKey)
            this.browserSelect.addOption(browser);

        foreach (engine; this.syncApi.engines.byKey)
            this.engineSelect.addOption(engine);

        this.languageSelection.setSelection(
            Translator.getLangKeys().countUntil(DeflectorSettings.interfaceLanguage) + 1
        );

        this.useProfile.isChecked = DeflectorSettings.useProfile;
        this.profileName.content = DeflectorSettings.profileName;
        this.profileName.setEnabled(DeflectorSettings.useProfile);
    }

    /// Set UI browser and engine names from the registry's values
    void showConfigPageDefaults() {
        debug writeln("ConfigApp.showConfigPageDefaults()");

        this.syncApi.browserName = this.syncApi.browsers.nameFromPath(DeflectorSettings.browserPath);
        this.syncApi.engineName = this.syncApi.engines.nameFromUrl(DeflectorSettings.engineURL);
    }

    /// Set the updater page's information from latest GitHub release
    version (free_version) void showUpdatePageDefaults() {
        debug writeln("ConfigApp.showUpdatePageDefaults()");

        if (this.shouldUpdate)
            this.updateButton.setEnabled(true);

        this.versionLabel.label = releaseJson["tag_name"].str;
        this.uploaderLabel.label = releaseAsset["uploader"]["login"].str;
        this.timestampLabel.label = SysTime.fromISOExtString(releaseAsset["updated_at"].str).toReadableTimestamp();
        this.binarySizeLabel.label = format("%.2f MB", releaseAsset["size"].integer / 1_048_576f);
        this.downloadCountLabel.label = releaseAsset["download_count"].integer.to!string();
    }

    void bindCommonButtonListeners() {
        this.applyButton.addEventListener(EventType.triggered, {
            this.syncApi.dump();
            this.applyButton.setEnabled(false);
        });

        this.wikiButton.addEventListener(EventType.triggered, {
            openUri(this.syncApi.browserPath, getBrowserArgs(DeflectorSettings.browserPath, DeflectorSettings.useProfile, DeflectorSettings.profileName), WIKI_URL);
        });

        this.closeButton.addEventListener(EventType.triggered, { exit(0); });
    }

    void bindLanguagePageListeners() {
        this.languageSelection.addEventListener(EventType.change, {
            debug writeln(this.languageSelection.currentText);

            if (this.languageSelection.getSelection() == 0)
                DeflectorSettings.interfaceLanguage = "";
            else
                DeflectorSettings.interfaceLanguage = Translator.getLangKeys()[this.languageSelection.getSelection() - 1];
            
            this.applyButton.setEnabled(true);
        });
    }

    /// Bind listeners for every widget on the config page that needs actions handled
    void bindConfigPageListeners() {
        debug writeln("ConfigApp.bindConfigPageListeners()");

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

            version (free_version) {
                if (releaseJson.isNull) {
                    this.fetchReleaseInfo();
                    this.showUpdatePageDefaults();
                }
            }
        });

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
            DeflectorSettings.browserPath = value;
            this.applyButton.setEnabled(true);
        });

        this.engineSelect.addEventListener(EventType.change, {
            debug writeln(this.engineSelect.currentText);
            this.syncApi.engineName = this.engineSelect.currentText;
            this.applyButton.setEnabled(true);
        });

        this.useProfile.addEventListener(EventType.change, {
            debug writeln("Profile name enabled: ", this.useProfile.isChecked);
            DeflectorSettings.useProfile = this.useProfile.isChecked;
            this.syncApi.dump();
            this.profileName.setEnabled(this.useProfile.isChecked);
        });

        this.profileName.addEventListener(EventType.keyup, {
            string value = this.profileName.content.strip(); // Sanitize
            debug writeln("Profile name changed: ", value);
            this.syncApi.profileName = value;
            this.syncApi.dump();
            this.applyButton.setEnabled(true);
        });

        this.engineUrl.addEventListener(EventType.keyup, {
            string value = this.engineUrl.content.strip(); // Sanitize
            debug writeln("Engine URL changed: ", value);
            DeflectorSettings.engineURL = value;
            this.applyButton.setEnabled(true);
        });
    }

    /// Bind listeners for widgets on the update page
    version (free_version) void bindUpdatePageListeners() {
        debug writeln("ConfigApp.bindUpdatePageListeners()");

        this.updateButton.addEventListener(EventType.triggered, {
            this.updateButton.setEnabled(false);

            this.installUpdate(false);
        });

        this.detailsButton.addEventListener(EventType.triggered, {
            openUri(this.syncApi.browserPath, getBrowserArgs(DeflectorSettings.browserPath, DeflectorSettings.useProfile, DeflectorSettings.profileName), this.releaseJson["html_url"].str);
        });
    }

    /// Fetch the latest release informatiion from GutHub
    version (free_version) void fetchReleaseInfo() {
        debug writeln("ConfigApp.fetchReleaseInfo()");

        this.releaseJson = getLatestRelease(PROJECT_AUTHOR, PROJECT_NAME);
        this.releaseAsset = getReleaseAsset(releaseJson, SETUP_FILENAME);
    }

    /// Begin installing the latest version of the program.
    version (free_version) void installUpdate(const bool silent) {
        debug writeln("ConfigApp.installUpdate()");

        startInstallUpdate(this.releaseAsset["browser_download_url"].str, this.getInstallerPath(), silent);
    }
}

/// Object to help keep both registry and interface up-to-date with eachother
struct SettingsSyncApi {
    private ConfigApp* parent;
    private string[string] engines;
    private string[string] browsers;

    /// Dump current settings to registry
    void dump() {
        debug writeln("SettingsSyncApi.dump()");

        if (this.parent.browserSelect.currentText != Translator.text("option.default_browser") && !validateExecutablePath(this.browserPath)) {
            debug writeln("Bad browser path: ", this.browserPath);
            createWarningDialog("Custom browser path is invalid.\nCheck the wiki for more information.", this.parent
                    .window.hwnd);
            return;
        }

        if (!validateEngineUrl(this.engineUrl)) {
            debug writeln("Bad engine URL: ", this.engineUrl);
            createWarningDialog("Custom search engine URL is invalid.\nCheck the wiki for more information.",
                    this.parent.window.hwnd);
            return;
        }

        DeflectorSettings.dump();
    }

    /// Set the browser path after validation
    void browserPath(const string value) {
        debug writeln("SettingsSyncApi.browserPath(value)");

        if (value == "" || validateExecutablePath(value)) {
            DeflectorSettings.browserPath = value;

            if (value != this.parent.browserPath.content)
                this.parent.browserPath.content = value;
        }
    }

    /// Set the browser name from the path provided
    void browserName(const string value) {
        debug writeln("SettingsSyncApi.browserName(value)");

        if (!([Translator.text("option.custom_browser"), Translator.text("option.default_browser"), ""] ~ this.browsers.keys).canFind(value))
            this.browserPath = "";

        if (value.length == 0 || value == Translator.text("option.default_browser")) {
            this.parent.browserPath.setEnabled(false);
            this.parent.browserPathButton.hide();
            this.browserPath = "";
        } else if (value == Translator.text("option.custom_browser")) {
            this.parent.browserPath.setEnabled(true);
            this.parent.browserPathButton.show();
            this.browserPath = "";
        } else {
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

    /// Set the engine URL after validation
    void engineUrl(const string value) {
        debug writeln("SettingsSyncApi.engineUrl(value)");

        if (validateEngineUrl(value)) {
            DeflectorSettings.engineURL = value;

            if (value != this.parent.engineUrl.content)
                this.parent.engineUrl.content = value;
        }
    }

    /// Set the engine name in accordance to the URL
    void engineName(const string value) {
        debug writeln("SettingsSyncApi.engineName(value)");

        assert(([Translator.text("option.custom_engine"), ""] ~ this.engines.keys).canFind(value), "Search engine name is an unexpected value: " ~ value);

        if (value.length == 0 || value == Translator.text("option.custom_engine")) {
            this.parent.engineUrl.setEnabled(true);
            this.engineUrl = "";
        } else {
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

    /// Set the profile name and disable if empty
    void profileName(const string value) {
        if (value.length == 0)
            DeflectorSettings.useProfile = false;

        DeflectorSettings.profileName = value;
    }

    /// Get the browser path
    string browserPath() {
        debug writeln("SettingsSyncApi.browserPath()");
        return DeflectorSettings.browserPath;
    }

    /// Get the browser name from the current path
    string browserName() {
        debug writeln("SettingsSyncApi.browserName()");

        if (["", "system_default"].canFind(this.browserPath))
            return Translator.text("option.default_browser");

        foreach (browser; this.browsers.byKeyValue)
            if (browser.value == this.browserPath)
                return browser.key;

        return Translator.text("option.custom_browser");
    }

    /// Get the current engine URL
    string engineUrl() {
        debug writeln("SettingsSyncApi.engineUrl()");
        return DeflectorSettings.engineURL;
    }

    /// Get the current engine name from path in settings
    string engineName() {
        debug writeln("SettingsSyncApi.browserName()");

        foreach (string item; this.engines.keys)
            if (this.engines[item] == this.engineUrl)
                return item;

        return Translator.text("option.custom_engine");
    }
}

/// Return true if the executable path is valid
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

/// Convert date from JSON API to human readable string
string toReadableTimestamp(T)(T time) {
    return "%02d-%02d-%0004d  %02d:%02d %s".format(time.month, time.day, time.year, (time.hour > 12 ?
            time.hour - 12 : time.hour), time.minute, (time.hour > 12 ? "PM" : "AM"));
}
