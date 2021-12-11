use std::collections::HashMap;
use eframe::{egui, epi};
use search_deflector::registry;

fn main() {
    let app = SettingsApp::default();

    let mut native_options = eframe::NativeOptions::default();
    native_options.initial_window_size = Option::Some(egui::Vec2::new(500.0, 300.0));
    native_options.resizable = false;

    eframe::run_native(Box::new(app), native_options);
}

/// We derive Deserialize/Serialize so we can persist app state on shutdown.
#[cfg_attr(feature = "persistence", derive(serde::Deserialize, serde::Serialize))]
#[cfg_attr(feature = "persistence", serde(default))] // if we add new fields, give them default values when deserializing old state
pub struct SettingsApp {
    available_browsers: HashMap<String, String>,
    preferred_browser: String,
}

impl Default for SettingsApp {
    fn default() -> Self {
        let mut browsers = registry::get_installed_browsers(None).unwrap();
        browsers.insert("System Default".to_owned(), "".to_owned());

        SettingsApp {
            available_browsers: browsers,
            preferred_browser: String::default(),
        }
    }
}

impl epi::App for SettingsApp {
    fn name(&self) -> &str {
        "Configure Search Deflector"
    }

    /// Called once before the first frame.
    fn setup(
        &mut self,
        _ctx: &egui::CtxRef,
        _frame: &mut epi::Frame<'_>,
        _storage: Option<&dyn epi::Storage>,
    ) {
        // Load previous app state (if any).
        // Note that you must enable the `persistence` feature for this to work.
        #[cfg(feature = "persistence")]
        if let Some(storage) = _storage {
            *self = epi::get_value(storage, epi::APP_KEY).unwrap_or_default()
        }

        let mut fonts = egui::FontDefinitions::default();

        // Install my own font (maybe supporting non-latin characters):
        fonts.font_data.insert(
            "noto_sans".to_owned(),
            std::borrow::Cow::Borrowed(include_bytes!("../../fonts/Noto_Sans/NotoSans-Regular.ttf"))
        );

        // Put my font first (highest priority):
        fonts.fonts_for_family.get_mut(&egui::FontFamily::Proportional).unwrap().insert(0, "noto_sans".to_owned());

        // Put my font as last fallback for monospace:
        // fonts.fonts_for_family.get_mut(&egui::FontFamily::Monospace).unwrap().push("noto_sans".to_owned());

        // Make the font sizes for everything slightly larger than default
        fonts.family_and_size.insert(egui::TextStyle::Small, (egui::FontFamily::Proportional, 18.0));
        fonts.family_and_size.insert(egui::TextStyle::Body, (egui::FontFamily::Proportional, 20.0));
        fonts.family_and_size.insert(egui::TextStyle::Button, (egui::FontFamily::Proportional, 19.0));
        fonts.family_and_size.insert(egui::TextStyle::Heading, (egui::FontFamily::Proportional, 22.0));
        fonts.family_and_size.insert(egui::TextStyle::Monospace, (egui::FontFamily::Proportional, 18.0));

        _ctx.set_fonts(fonts);

        // _ctx.set_debug_on_hover(true);
    }

    /// Called by the frame work to save state before shutdown.
    /// Note that you must enable the `persistence` feature for this to work.
    #[cfg(feature = "persistence")]
    fn save(&mut self, storage: &mut dyn epi::Storage) {
        epi::set_value(storage, epi::APP_KEY, self);
    }

    /// Called each time the UI needs repainting, which may be many times per second.
    /// Put your widgets into a `SidePanel`, `TopPanel`, `CentralPanel`, `Window` or `Area`.
    fn update(&mut self, ctx: &egui::CtxRef, frame: &mut epi::Frame<'_>) {
        const AUTHOR_NAME: &str = "Jacob Birkett";
        const AUTHOR_URL: &str = "https://bitkett.dev";
        const DOCS_URL: &str = "https://github.com/spikespaz/search-deflector/wiki";
        const REPO_URL: &str = "https://github.com/spikespaz/search-deflector";
        const VERSION_BASE_URL: &str = "https://github.com/spikespaz/search-deflector/releases/tag";
        const VERSION_STR: &str = "2.0.0";

        egui::TopBottomPanel::bottom("bottom_panel").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.horizontal(|ui| {
                    ui.spacing_mut().item_spacing.x = 0.0;
                    ui.label("Version: ");
                    ui.hyperlink_to(VERSION_STR, format!("{}/{}", VERSION_BASE_URL, VERSION_STR));
                    ui.add_space(6.0);
                    ui.separator();
                    ui.add_space(6.0);
                    ui.label("Author: ");
                    ui.hyperlink_to(AUTHOR_NAME, AUTHOR_URL);
                    ui.add_space(6.0);
                    ui.separator();
                });

                ui.with_layout(egui::Layout::right_to_left(), |ui| {
                    if ui.button("Documentation").on_hover_text(DOCS_URL).clicked() {
                        let modifiers = ui.ctx().input().modifiers;
                        ui.ctx().output().open_url = Some(egui::output::OpenUrl {
                            url: DOCS_URL.to_owned(),
                            new_tab: modifiers.any(),
                        });
                    }

                    if ui.button("Repository").on_hover_text(REPO_URL).clicked() {
                        let modifiers = ui.ctx().input().modifiers;
                        ui.ctx().output().open_url = Some(egui::output::OpenUrl {
                            url: REPO_URL.to_owned(),
                            new_tab: modifiers.any(),
                        });
                    }
                });
            });
        });

        egui::CentralPanel::default().show(ctx, |ui| {
            // The central panel the region left after adding TopPanel's and SidePanel's

            ui.heading("eframe template");
            ui.hyperlink("https://github.com/emilk/eframe_template");
            ui.add(egui::github_link_file!(
                "https://github.com/emilk/eframe_template/blob/master/",
                "Source code."
            ));
            egui::warn_if_debug_build(ui);
        });
    }
}
