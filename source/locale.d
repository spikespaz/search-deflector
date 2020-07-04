module locale;

import core.sys.windows.winnt: LCID, LANGID, LPWSTR, LPCWSTR, DWORD, MAKELCID, SORT_DEFAULT;
import core.sys.windows.winnls: GetLocaleInfoW;
import std.file: thisExePath, readText, dirEntries, SpanMode;
import std.path: buildPath, dirName, baseName;
import std.string: fromStringz, toLower;
import std.utf: toUTF16z;
import std.conv: to;
import common: parseConfig;
debug import std.stdio: writeln;
debug import std.string: format;


extern (Windows) {
    /// https://docs.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-lcidtolocalename
    int LCIDToLocaleName(LCID, LPWSTR, int, DWORD);
    /// https://docs.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-localenametolcid
    LCID LocaleNameToLCID(LPCWSTR lpName, DWORD dwFlags);
    /// https://docs.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getuserdefaultuilanguage
    LANGID GetUserDefaultUILanguage();

    /// https://docs.microsoft.com/en-us/windows/win32/intl/locale-names
    /// https://www.magnumdb.com/search?q=LOCALE_NAME_MAX_LENGTH
    enum uint LOCALE_NAME_MAX_LENGTH = 0x55;
    /// https://docs.microsoft.com/en-us/windows/win32/intl/locale-allow-neutral-names
    /// https://www.magnumdb.com/search?q=LOCALE_ALLOW_NEUTRAL_NAMES
    enum uint LOCALE_ALLOW_NEUTRAL_NAMES = 0x08000000;
    /// https://docs.microsoft.com/en-us/windows/win32/intl/locale-slocalized-constants
    /// https://www.magnumdb.com/search?q=LOCALE_SLOCALIZEDDISPLAYNAME
    enum uint LOCALE_SLOCALIZEDDISPLAYNAME = 0x00000002;
}

/// Static object for translation file loading
static struct Translator {
    private static string[string] translationMap;
    private static string[string] langFileMap;
    private static string langKey;

    static this() {
        foreach (string fileName; dirEntries(buildPath(thisExePath().dirName(), "lang"), SpanMode.shallow)) {
            debug writeln("Found locale file: " ~ fileName);
            langFileMap[fileName.baseName().toLower()[0 .. $ - 4]] = fileName;
        }
    }

    static string getUserDefaultLangKey() {
        wchar[LOCALE_NAME_MAX_LENGTH] localeName;
        LCIDToLocaleName(getDefaultLCID(), localeName.ptr, LOCALE_NAME_MAX_LENGTH, LOCALE_ALLOW_NEUTRAL_NAMES);
        return localeName.ptr.fromStringz().to!string();
    }

    static uint getDefaultLCID() {
        return MAKELCID(GetUserDefaultUILanguage(), SORT_DEFAULT);
    }

    static string getNameFromLangKey(const string langKey) {
        const uint maxNameLen = 255;
        wchar[maxNameLen] langName;

        GetLocaleInfoW(
            LocaleNameToLCID(langKey.toUTF16z(), LOCALE_ALLOW_NEUTRAL_NAMES),
            LOCALE_SLOCALIZEDDISPLAYNAME,
            langName.ptr,
            maxNameLen
        );

        string langName0 = langName.ptr.fromStringz().to!string();
        debug writeln("langName: " ~ langName0);
        return langName0;
    }

    static string[] getLangKeys() {
        return langFileMap.keys;
    }

    /// Load translations from file by specified langKey
    static bool load(const string langKey) {
        Translator.langKey = langKey;
        return load();
    }

    /// Load the file corresponding to the current langKey
    static bool load() {
        bool success = true;
        string filePath = langFileMap.get(langKey, null);

        if (filePath is null) {
            debug writeln("Requested user default locale not found!");
            filePath = langFileMap["en-us"];
            success = false;
        }

        translationMap = parseConfig(readText(filePath));
        return success;
    }

    /// Load the user's default language, returns success
    static bool loadDefault() {
        return load(getUserDefaultLangKey());
    }

    /// Return the translation by key
    static string text(const string key) {
        debug writeln("Getting translation for key: " ~ key);

        if (key !in translationMap)
            debug writeln("Key not in translations: " ~ key);

        return translationMap.get(key, "UNKNOWN STRING");
    }
}
