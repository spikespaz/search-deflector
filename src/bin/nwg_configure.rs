#![windows_subsystem = "windows"]

use std::cell::RefCell;
use std::ops::Deref;
use std::rc::Rc;

use native_windows_gui as nwg;
use nwg::NativeUi;

#[derive(Default)]
pub struct SDConfigure {
    window: nwg::Window,
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

        nwg::Window::builder()
            .size((300, 400))
            .position((0, 0))
            .title("Configure Search Deflector")
            .build(&mut data.window)?;

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

        return Ok(ui);
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
    nwg::init().expect("Failed to init Native Windows GUI");
    nwg::Font::set_global_family("Segoe UI").expect("Failed to set default font");

    let _app = SDConfigure::build_ui(Default::default()).expect("Failed to build UI");
    nwg::dispatch_thread_events();
}
