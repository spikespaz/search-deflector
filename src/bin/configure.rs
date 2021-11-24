extern crate native_windows_gui as nwg;
extern crate native_windows_derive as nwd;

use nwd::NwgUi;
use nwg::NativeUi;

use nwg::stretch::{
    geometry::{Size, Rect},
    style::{Dimension as D, FlexDirection, JustifyContent, AlignContent, Style},
};


// const PAD: Rect<D> = Rect {
//     start: D::Points(2.0),
//     end: D::Points(2.0), 
//     top: D::Points(2.0), 
//     bottom: D::Points(2.0)
// };

#[derive(Default, NwgUi)]
pub struct BasicApp {
    #[nwg_control(size: (300, 400), center: true, title: "Configure Search Deflector", flags: "WINDOW|VISIBLE|RESIZABLE")]
    #[nwg_events(OnWindowClose: [BasicApp::say_goodbye])]
    window: nwg::Window,

    #[nwg_layout(
        parent: window,
        flex_direction: FlexDirection::Column,
        align_content: AlignContent::SpaceBetween,
        // padding: Rect {
        //     start: D::Points(4.0),
        //     end: D::Points(2.0),
        //     top: D::Points(4.0),
        //     bottom: D::Points(4.0),
        // },
    )]
    main_layout: nwg::FlexboxLayout,

    #[nwg_control(parent: window)]
    #[nwg_layout_item(
        layout: main_layout,
        // size: Size {
        //     width: D::Auto,
        //     height: D::Percent(1.0),
        // }
    )]
    window_tabs: nwg::TabsContainer,

    #[nwg_control(text: "Settings", parent: window_tabs)]
    settings_tab: nwg::Tab,

    #[nwg_control(text: "Language", parent: window_tabs)]
    language_tab: nwg::Tab,

    #[nwg_control(text: "Update", parent: window_tabs)]
    update_tab: nwg::Tab,

    // ***Bottom flex layout with version, author tag and website button***

    #[nwg_layout(
        parent: window,
        flex_direction: FlexDirection::Row,
        // justify_content: JustifyContent::SpaceBetween,
        // padding: Rect {
        //     start: D::Points(4.0),
        //     end: D::Points(4.0),
        //     top: D::Auto,
        //     bottom: D::Points(4.0),
        // },
    )]
    #[nwg_layout_item(
        layout: main_layout,
        max_size: Size {
            width: D::Percent(1.0),
            height: D::Points(40.0),
        },
    )]
    bottom_layout: nwg::FlexboxLayout,

    // #[nwg_control(
    //     text: "Version: 2.0.0, Author: Jacob Birkett"
    // )]
    // #[nwg_layout_item(
    //     layout: bottom_layout,
    //     flex_grow: 1.0,
    //     size: Size {
    //         width: D::Auto,
    //         height: D::Auto,
    //     },
    // )]
    // version_label: nwg::Label,

    #[nwg_control(text: "Website", parent: window)]
    #[nwg_layout_item(
        // layout: main_layout,
        layout: bottom_layout,
        size: Size {
            width: D::Points(80.0),
            height: D::Auto,
        },
    )]
    website_button: nwg::Button,
}

impl BasicApp {

    // fn say_hello(&self) {
    //     nwg::simple_message("Hello", &format!("Hello {}", self.name_edit.text()));
    // }
    
    fn say_goodbye(&self) {
        // nwg::simple_message("Goodbye", "Goodbye!");
        nwg::stop_thread_dispatch();
    }

}

fn main() {
    nwg::init().expect("Failed to init Native Windows GUI");
    nwg::Font::set_global_family("Segoe UI").expect("Failed to set default font");

    let _app = BasicApp::build_ui(Default::default()).expect("Failed to build UI");

    nwg::dispatch_thread_events();
}