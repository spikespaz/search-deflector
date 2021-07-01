# ![Search Deflector](assets/title.svg)

[![Latest Version](https://img.shields.io/github/release/spikespaz/search-deflector/all.svg?style=for-the-badge)](https://github.com/spikespaz/search-deflector/releases/latest)
[![Project License](https://img.shields.io/github/license/spikespaz/search-deflector.svg?style=for-the-badge)](https://github.com/spikespaz/search-deflector/blob/master/LICENSE)
[![Latest Release Downloads](https://img.shields.io/github/downloads/spikespaz/search-deflector/latest/total?label=RELEASE%20DOWNLOADS&style=for-the-badge)](http://tiny.cc/get-search-deflector)
[![Project Stars](https://img.shields.io/github/stars/spikespaz/search-deflector.svg?style=for-the-badge)](https://github.com/spikespaz/search-deflector/stargazers)

### **Search Deflector** is a small system utility that redirects searches made from the start menu or Cortana to whatever browser and search engine you prefer, removing ties with Microsoft Edge and Bing.

This software allows you to perform faster web searches by just tapping the Windows key, and typing your search. Hit enter, or click one of the results in the right panel. This is faster than opening your browser (if it isn't already), opening a new tab, and clicking the search bar.

After a simple setup, you can use *any* browser (provided it is registered as a protocol handler) and *any* search engine. If you are having trouble getting either of these to work, send me an email at support@birkett.dev or create an [issue](https://github.com/spikespaz/search-deflector/issues), and I will see what I can do to get your custom settings working.

[**Don't forget to check the wiki if you have any questions!**](https://github.com/spikespaz/search-deflector/wiki)

**Also, please star this repository if you like what I've made!**

---

**Note:** There is a free version and a paid version. Both are exactly the same. The free version is unsigned and may register a false-positive with your antivirus software. The version on the Microsoft Store costs $1.99, and is digitally signed and distributed by Microsoft. The free (classic) version uses custom code for automatic updates (source is [here](https://github.com/spikespaz/search-deflector/blob/master/source/updater.d)). I would greatly appreciate if you tried the free version from GitHub and later paid for the Store version, as even the few dollars goes a long way to help me out.

<h1>
  <a href="https://www.microsoft.com/store/productId/9P8ZJJ80RZ2K">
    <img src="assets/store.png" alt="Get it from Microsoft!" width="200"\>
  </a>
</h1>

**If you find this software useful and would like to show your appreciation, please consider making a small donation!**

<h1>
  <a href="https://birkett.dev/donate">
    <img src="https://birkett.dev/images/donate/donate.svg" alt="Donate!" width="200"\>
  </a>
</h1>

# Doesn't this already exist?

Yes, there are two other similar projects. [EdgeDeflector](https://github.com/da2x/EdgeDeflector) and [SearchWithMyBrowser](https://github.com/sylveon/SearchWithMyBrowser).

After using EdgeDeflector for quite some time, I noticed several issues with it. Sometimes it didn't work properly, it wasn't very configurable, and it relied on a browser extension (Chrometana) to change the search engine from Bing. I also tried SearchWithMyBrowser, however it had the same problems. I did not like the reliance on other software, so I set out to create a complete solution.

# How do I set it up?

Get it at the Microsoft Store [here](https://www.microsoft.com/store/productId/9P8ZJJ80RZ2K) to support development or download the latest installer executable by clicking [here](https://birkett.dev/tools/repo-dl/?user=spikespaz&repo=search-deflector&file=SearchDeflector-Installer.exe). Just follow the prompts.

**Take a look at the [Wiki page](https://github.com/spikespaz/search-deflector/wiki/Setup-&-Installing) if you're having trouble or need more information.**

# I found a bug / it doesn't work!

**First, look at the [Wiki](https://github.com/spikespaz/search-deflector/wiki/Troubleshooting) for help.** If that still doesn't fix your problem, submit a new [issue](https://github.com/spikespaz/search-deflector/issues) describing the problem with as much detail as possible.

# Links

| Name | Link |
| ---- | ---- |
| Homepage | https://birkett.dev/search-deflector                                      |
| Download | http://tiny.cc/get-search-deflector                                       |
| Store    | https://www.microsoft.com/store/productId/9P8ZJJ80RZ2K                    |
| Wiki     | https://github.com/spikespaz/search-deflector/wiki                        |
| Issues   | https://github.com/spikespaz/search-deflector/issues                      |
| License  | https://github.com/spikespaz/search-deflector/blob/master/LICENSE         |
| Email    | support@birkett.dev                                                       |

# Special thanks

Thank you to [@da2x](https://github.com/da2x) and [@sylveon](https://github.com/sylveon) for the inspiration, their source code helped greatly as a reference during development of Search Deflector, and [@adamdruppe](https://github.com/adamdruppe) for one-on-one help over IRC and his library, `minigui`, which makes this program's GUI possible.

Additionally, thanks to all of following early-adopters who reported the first issues and helped in the early days:

[@elliottedward327](https://github.com/elliottedward327),
[@maxloh](https://github.com/maxloh),
[@Thomas-QM](https://github.com/Thomas-QM),
[@loganran](https://github.com/loganran),
[@loginnotsecure](https://github.com/loginnotsecure),
[@shalvah](https://github.com/shalvah),
[@TruckMangione](https://github.com/TruckMangione),
[@lordvlad](https://github.com/lordvlad),
[@tango409](https://github.com/tango409),
[@Freyam](https://github.com/Freyam),
[@MulverineX](https://github.com/MulverineX),
[@fernandex00](https://github.com/fernandex00),
and others.

### Translations

A huge thanks is owed to all of the translators for this project. All of the translation files can be found in the [`lang`](https://github.com/spikespaz/search-deflector/tree/release/lang) directory of the project.
If you would like to contribute localization or improve upon existing ones, please submit a pull request with your adaptation of [`en-US.txt`](https://github.com/spikespaz/search-deflector/lang/en-US.txt) or send an email and tell me what GitHub handle or name to give credit to. If you send a name I will link to your blog or website if provided. Thank you!

| Language | Codes | Contributors |
| -------- | ----- | ------------ |
| Chinese  | `zh-CN`, `zn-HK`, `zn-TW` | [@linjiayinchn](https://github.com/linjiayinchn), [@maxloh](https://github.com/maxloh) |
| Croatian | `hr-HR`                   | [@anotherus3r](https://github.com/anotherus3r) |
| Spanish  | `es-ES`                   | [@caralu74](https://github.com/caralu74) |
| German   | `de-DE`                   | [@randomC0der](https://github.com/randomC0der) |
| Italian  | `it-IT`                   | [@eagleman](https://github.com/eagleman) |
