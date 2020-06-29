module locale;

import core.sys.windows.winnt: LCID, LANGID, LPWSTR, DWORD, MAKELCID, SORT_DEFAULT;
import std.file: thisExePath, readText, dirEntries, SpanMode;
import std.path: buildPath, dirName, baseName;
import std.string: fromStringz, toLower;
import std.conv: to;
import common: parseConfig;
debug import std.stdio: writeln;


extern (Windows) {
    ///
    int LCIDToLocaleName(LCID, LPWSTR, int, DWORD);
    ///
    LANGID GetUserDefaultUILanguage();

    ///
    enum uint LOCALE_NAME_MAX_LENGTH = 0x55;
    ///
    enum uint LOCALE_ALLOW_NEUTRAL_NAMES = 0x08000000;
}

/// Static object for translation file loading
static struct Translator {
    private static string[string] map;
    private static int lcid;
    private static string lang_key;

    static string getUserDefaultLangKey() {
        wchar[LOCALE_NAME_MAX_LENGTH] localeName;

        LCIDToLocaleName(
            MAKELCID(GetUserDefaultUILanguage(), SORT_DEFAULT),
            localeName.ptr,
            LOCALE_NAME_MAX_LENGTH,
            LOCALE_ALLOW_NEUTRAL_NAMES
        );

        return localeName.ptr.fromStringz().to!string();
    }

    private static string getTranslationFilePath(const string lang) {
        foreach (string name; dirEntries(buildPath(thisExePath().dirName(), "lang"), SpanMode.shallow)) {
            debug writeln("Found locale: " ~ name);

            if (name.baseName().toLower() == lang.toLower() ~ ".txt")
                return name;
        }

        return null;
    }

    /// Finds the user's current preferred language and loads the corresponding file
    static void load() {
        lang_key = getUserDefaultLangKey();
        string file_path = getTranslationFilePath(lang_key);

        if (file_path is null) {
            debug writeln("Requested user default locale not found!");
            file_path = getTranslationFilePath("en-US");
        }

        map = parseConfig(readText(file_path));
    }

    /// Return the translation by key
    static string text(string key) {
        debug writeln("Getting translation for key: " ~ key);
        return map[key];
    }
}
