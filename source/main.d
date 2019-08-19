import arsd.minigui;
import common: getConsoleArgs, createErrorDialog;
import setup: getAvailableBrowsers;

void main(string[] args) {
    try {
        auto window = new MainWindow("Search Deflector", 500, 500);
        // auto vLayout = new VerticalLayout(window);

        auto layout = window;

        auto textLabel0 = new TextLabel("Preferred Browser", TextAlignment.Left, layout);

        auto browserSelect = new DropDownSelection(layout);
        auto browserPath = new LineEdit(layout);

        auto textLabel1 = new TextLabel("Preferred Search Engine", TextAlignment.Left,  layout);

        auto engineSelect = new DropDownSelection(layout);
        auto engineUrl = new LineEdit(layout);

        auto spacer = new VerticalSpacer(layout);
        auto applyButton = new Button("Apply Settings", layout);

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);
    }
}

extern (Windows) int WinMain(void*, void*, char*, int) {
    main(getConsoleArgs());

    return 0;
}
