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
        let mut fonts = egui::FontDefinitions::default();

        // Install my own font (maybe supporting non-latin characters):
        fonts.font_data.insert(
            "noto_sans".to_owned(),
            std::borrow::Cow::Borrowed(include_bytes!("../../fonts/Noto_Sans/NotoSans-Regular.ttf"))
        );

        // Put my font first (highest priority):
        fonts.fonts_for_family.get_mut(&egui::FontFamily::Proportional).unwrap().insert(0, "noto_sans".to_owned());

        // Make the font sizes for everything slightly larger than default
        fonts.family_and_size.insert(egui::TextStyle::Small, (egui::FontFamily::Proportional, 18.0));
        fonts.family_and_size.insert(egui::TextStyle::Body, (egui::FontFamily::Proportional, 20.0));
        fonts.family_and_size.insert(egui::TextStyle::Button, (egui::FontFamily::Proportional, 19.0));
        fonts.family_and_size.insert(egui::TextStyle::Heading, (egui::FontFamily::Proportional, 22.0));
        fonts.family_and_size.insert(egui::TextStyle::Monospace, (egui::FontFamily::Proportional, 18.0));

        _ctx.set_fonts(fonts);

        // _ctx.set_debug_on_hover(true);
    }

    fn update(&mut self, ctx: &egui::CtxRef, _frame: &mut epi::Frame<'_>) {
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
            ui.group(|ui| {
                ui.label("Preferred Browser");

                egui::ComboBox::from_id_source("browser_setting").selected_text(&self.preferred_browser).show_ui(ui, |ui| {
                    for browser in self.available_browsers.keys() {
                        ui.selectable_value(&mut self.preferred_browser, browser.clone(),browser);
                    }
                });
            });

            egui::warn_if_debug_build(ui);
        });
    }
}
