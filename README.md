<h1 align="center">
  <img src="icons/banner.png" alt="Search Deflector"/>
</h1>

### **Search Deflector** is a small tool that redirects searches made from the Windows Start Menu or Cortana to whatever browser and search engine you prefer. No more Microsoft Edge and Bing!

Now you can search faster by just tapping the Windows key, and typing your search. Hit enter, or click one of the results in the right panel. This is faster than opening your browser (if it isn't already), opening a new tab, and clicking the search bar. I've found it to be a good quality-of-life trick.

**Please don't forget to star this repository** if you like what I've made!

After a simple setup, you can use *any* browser (provided it is registered as a protocol handler) and *any* search engine. If you are having trouble getting either of these to work, send me an email at support@spikespaz.com or create an [issue](https://github.com/spikespaz/search-deflector/issues), and I will see what I can do to get your custom settings working.

### Doesn't this already exist?

Yes, I know. [EdgeDeflector](https://github.com/da2x/EdgeDeflector) and [SearchWithMyBrowser](https://github.com/sylveon/SearchWithMyBrowser).

I had been using EdgeDeflector for quite some time, but it had some issues. It was buggy, sometimes it doesn't transform the URIs properly. It also doesn't allow you to change the search engine, and it only uses your system default browser.

SearchWithMyBrowser has the same problems as EdgeDeflector.

# I found a bug / it doesn't work!

Please submit a GitHub [issue](https://github.com/spikespaz/search-deflector/issues) with as many details as possible. If the program crashed, you should get a message box with a button that will redirect you to the issues page with most of the important information filled out. Just add a title, and maybe include the text that you searched for.

If you don't think a new issue would be very helpful, or if you need help setting it up, you can email me at support@spikespaz.com. I don't bite.

# Setup

### 0. Using the installer

* **Please remember to delete the old directory that contains files from previous versions if you are manually updating.**

1. Go to the [releases page](https://github.com/spikespaz/search-deflector/releases) and download the installer executable.

2. Run the installer executable.
   * I didn't sign the executable, so you will get a warning saying "Windows protected your PC".
   * Click the small text that says "More info", then the button "Run anyway".
   * If you are concerned about this warning, it is because I haven't verifiied the installer's "authenticity". IF you want to, you can see the source code yourself, it isn't malicious.

3. Follow the prompts that the installer gives you. Agree to the license, and read the information on the second page.

4. Once you get to the part where a command prompt window pops up, follow the detailed instructions below.

### 1. Choosing a browser

In the below screenshot, I have selected option 2 for Firefox. Search Deflector will scan your registry for programs that are capable of handling URL protocols, and list them for you to choose. Just enter the number in square brackets next to the browser you want. Press Enter, and then Y to confirm your choice or N to repeat the last question.

![Setup Screenshot 1](screenshots/setup-0.png)

### 2. Choosing a search engine

Same as the browser, select the search engine you would like to use. If the search engine you want is missing, please create a [new issue](https://github.com/spikespaz/search-deflector/issues/new) and request that it be added, or fork the repository and add it to [`engines.txt`](https://github.com/spikespaz/search-deflector/blob/master/engines.txt), then submit a pull request.

See [the next section](#3-using-a-custom-url) for details on the last option, "Custom URL".

![Setup Screenshot 2](screenshots/setup-1.png)

### 3. Using a custom URL

**If you chose the last option, "Custom URL", in the previous step, keep reading. Otherwise, skip to the next section.**

Here, you can enter a custom URL to use as a search engine. It must include the string `{{query}}`, which will be replaced with your search URI component. Please do not enter the `https?://` protocol part of the URL, it will be ignored. See [`engines.txt`](https://github.com/spikespaz/search-deflector/blob/master/engines.txt) for examples on the format.

The program will then check the validity of your input by sending a GET request to the URL. If it succeeds and returns 200, you can move forward.

If you use this option, please create a [new issue](https://github.com/spikespaz/search-deflector/issues/new) and request that it be added, or fork the repository and add your search engine to [`engines.txt`](https://github.com/spikespaz/search-deflector/blob/master/engines.txt), then submit a pull request.

![Setup Screenshot 3](screenshots/setup-2.png)

### 4. Finishing the setup

The setup is complete. Just press Enter to close the window. Make sure that the information listed is what you expected it to be. If it isn't, select all of the console output and paste it into a [new issue](https://github.com/spikespaz/search-deflector/issues/new) on GitHub. That is unintentional. If there was a crash before you get to this point, do the same.

**As of version [0.1.0](https://github.com/spikespaz/releases/tag/0.1.0), if an error occurs you will recieve a message box that has two buttons. If you click "Yes", it will redirect you to the GitHub issues page with all of the crash information filled out for you. You just need to set a title.**

When reporting errors, include as much detail as you can. Tell me what happened before the crash, if you have any idea why the crash might have happened.

# Building

You need a D compiler. I recommend [`LDC2`](https://github.com/ldc-developers/ldc/releases), if you have that you can just run `build.sh` with MinGW or Git Bash. Read the build script to figure out what needs to be done. You also need the [Microsoft Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#vs-2017).

The build script can also compile one module at a time, but only one.

*(If anyone is good at Bash scripting, please submit a PR with a revised build script so I can select multiple modules to compile!)*

- `./build.sh setup`
- `./build.sh launcher`
- `./build.sh updater`
- `./build.sh deflector`

You need `rcedit.exe` on your system `PATH` variable to add the icon to the executable. Get that from https://github.com/electron/rcedit.

# Donations

If you would like to show appreciation for my work, I would gladly accept a small donation!

I am the sole author of this project, and if you appreciate my work or any of my other projects, you can donate a small amount to help me out.

Even if you don't want to donate, I would hugely appreciate a star on the repository so the visibility goes up and I get that nice dopamine. Seeing people use the software I've worked hard on makes me happy.

I will accept donations through PayPal.Me, Buy Me a Coffee, or Patreon.

[![Buy Me a Coffee](https://i.imgur.com/fN422E7.png)](https://buymeacoffee.com/spikespaz)
[![PayPal.Me](https://i.imgur.com/JWkunGi.png)](https://paypal.me/spikespaz)
[![Patreon](https://i.imgur.com/K05b2RO.png)](https://patreon.com/spikespaz)

# Links

| Name | Link |
| ---- | ---- |
| Download | https://github.com/spikespaz/search-deflector/releases                    |
| Issues   | https://github.com/spikespaz/search-deflector/issues                      |
| License  | https://github.com/spikespaz/search-deflector/blob/master/LICENSE         |
| Readme   | https://github.com/spikespaz/search-deflector/blob/master/README.md       |
| DEV Post | https://dev.to/spikespaz/start-menu-search-on-windows-10-with-google-46ie |
| Email    | support@spikespaz.com                                                     |

# Special thanks

All of the very first users of this project deserve callouts for putting up with me and the bugs I've made.

Even though I've basically usurped their projects, @da2x and @sylveon for the inspiration.

 - @maxloh
 - @Thomas-QM
 - @loganran
 - @loginnotsecure
 - @shalvah
 - @TruckMangione
 - @lordvlad
 - @tango409
 - @Freyam
 - @MulverineX
 - @fernandex00

Sorry if I missed your name.

~~Extra special thanks to Microsoft for giving me a problem to solve.~~
