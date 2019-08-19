import arsd.minigui;
import common: getConsoleArgs, createErrorDialog;
import setup: getAvailableBrowsers;

void main(string[] args) {
    try {
        auto window = new MainWindow("Search Deflector", 500, 500);
        auto layout = new PaddedVerticalLayout(window);

        auto textLabel0 = new TextLabel("Preferred Browser", TextAlignment.Left, layout);
        auto browserSelect = new DropDownSelection(layout);
        auto vSpacer0 = new VerticalSpacer(layout);

        auto textLabel1 = new TextLabel("Browser Executable", TextAlignment.Left,  layout);
        auto browserPath = new LineEdit(layout);
        auto vSpacer1 = new VerticalSpacer(layout);

        auto textLabel2 = new TextLabel("Preferred Search Engine", TextAlignment.Left,  layout);
        auto engineSelect = new DropDownSelection(layout);
        auto vSpacer2 = new VerticalSpacer(layout);

        auto textLabel3 = new TextLabel("Custom Search Engine URL", TextAlignment.Left,  layout);
        auto engineUrl = new LineEdit(layout);
        auto vSpacer3 = new VerticalSpacer(layout);

        auto applyButton = new Button("Apply Settings", layout);

        window.loop();
    } catch (Exception error) {
        createErrorDialog(error);
    }
}

class PaddedVerticalLayout : VerticalLayout {
    this(Widget parent = null) {
        super(parent);
    }

    override int marginLeft() {
        return 10;
    }

    override int marginTop() {
        return 10;
    }

    override int marginRight() {
        return 10;
    }

    override int marginBottom() {
        return 10;
    }
}

extern (Windows) int WinMain(void*, void*, char*, int) {
    main(getConsoleArgs());

    return 0;
}
