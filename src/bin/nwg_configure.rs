#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::cell::RefCell;
use std::ops::Deref;
use std::rc::Rc;

use native_windows_gui as nwg;
use nwg::NativeUi;
use nwg::stretch::{
    geometry::{Size, Rect},
    style::{Dimension as D, FlexDirection}
};

#[derive(Default)]
pub struct SDConfigure {
    window: nwg::Window,

    main_layout: nwg::FlexboxLayout,
    main_tabs: nwg::TabsContainer,

    general_tab: nwg::Tab,
    // general_tab_layout: nwg::FlexboxLayout,

    // browser_label: nwg::Label,
    // browser_dropdown: nwg::ComboBox<String>,
    // engine_label: nwg::Label,
    // engine_dropdown: nwg::ComboBox<String>,

    advanced_tab: nwg::Tab,
    // advanced_tab_layout: nwg::FlexboxLayout,

    language_tab: nwg::Tab,
    // language_tab_layout: nwg::FlexboxLayout,

    update_tab: nwg::Tab,
    // update_tab_layout: nwg::FlexboxLayout,

    // status_layout: nwg::FlexboxLayout,
    // version_label: nwg::Label,
    // website_button: nwg::Button,
}

impl SDConfigure {
    fn exit(&self) {
        nwg::stop_thread_dispatch();
    }
}

pub struct SDConfigureUi {
    inner: Rc<SDConfigure>,
    default_handler: RefCell<Vec<nwg::EventHandler>>,
}

impl NativeUi<SDConfigureUi> for SDConfigure {
    fn build_ui(mut data: SDConfigure) -> Result<SDConfigureUi, nwg::NwgError> {
        use nwg::Event as E;

        let window_size = (400, 400);
        let display_size = (nwg::Monitor::width(), nwg::Monitor::height());
        let display_center = (display_size.0 / 2, display_size.1 / 2);
        let window_top_left = (display_center.0 - (window_size.0 / 2), display_center.1 - (window_size.1 / 2));

        println!("Window size: {:?}\nDisplay size: {:?}\nDisplay center: {:?}\nWindow top-left: {:?}", window_size, display_size, display_center, window_top_left);

        nwg::Window::builder()
            .size(window_size)
            .position(window_top_left)
            .title("Configure Search Deflector")
            .build(&mut data.window)?;

        nwg::TabsContainer::builder()
            .parent(&data.window)
            .build(&mut data.main_tabs)?;

        nwg::Tab::builder()
            .parent(&data.main_tabs)
            .text("General")
            .build(&mut data.general_tab)?;

        nwg::Tab::builder()
            .parent(&data.main_tabs)
            .text("Advanced")
            .build(&mut data.advanced_tab)?;

        nwg::Tab::builder()
            .parent(&data.main_tabs)
            .text("Language")
            .build(&mut data.language_tab)?;

        nwg::Tab::builder()
            .parent(&data.main_tabs)
            .text("Update")
            .build(&mut data.update_tab)?;

        nwg::FlexboxLayout::builder()
            .parent(&data.window)
            .flex_direction(FlexDirection::Column)
            .child(&data.main_tabs)
            .build(&mut data.main_layout)?;

        let ui = SDConfigureUi {
            inner: Rc::new(data),
            default_handler: Default::default(),
        };

        let window_handles = [&ui.window.handle];
        for handle in window_handles.iter() {
            let evt_ui = Rc::downgrade(&ui.inner);
            let handle_events = move |evt, _evt_data, handle| {
                if let Some(evt_ui) = evt_ui.upgrade() {
                    match evt {
                        E::OnWindowClose => {
                            if &handle == &evt_ui.window {
                                SDConfigure::exit(&evt_ui);
                            }
                        },
                        _ => {}
                    }
                }
            };

            ui.default_handler.borrow_mut().push(nwg::full_bind_event_handler(handle, handle_events));
        }

        Ok(ui)
    }
}

impl Drop for SDConfigureUi {
    fn drop(&mut self) {
        let mut handlers = self.default_handler.borrow_mut();
        for handler in handlers.drain(..0) {
            nwg::unbind_event_handler(&handler);
        }
    }
}

impl Deref for SDConfigureUi {
    type Target = SDConfigure;

    fn deref(&self) -> &SDConfigure {
        &self.inner
    }
}

fn main() {
    // unsafe { nwg::win32::high_dpi::set_dpi_awareness(); } // This doesn't work even with the feature "high-dpi" enabled.
    nwg::init().expect("Failed to init Native Windows GUI");
    // nwg::enable_visual_styles(); // This should be in nwg/lib.rs, at the bottom, in init(), however sometimes styles aren't applied.
    nwg::Font::set_global_family("Segoe UI").expect("Failed to set default font");

    let _app = SDConfigure::build_ui(Default::default()).expect("Failed to build UI");
    nwg::dispatch_thread_events();
}
