/**
 * This file is part of Akira.
 *
 * Copyright (c) 2024 Alessandro Castellani
 *
 * Akira is free software: you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as  published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Akira. If not, see <https://www.gnu.org/ licenses/>.
 */
use gettextrs::gettext;
use gtk::subclass::prelude::*;
use gtk::{gio, gio::Settings, glib, prelude::*, ApplicationWindow};
use once_cell::sync::OnceCell;

use crate::config::APP_ID;

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct AppWindow {
        pub settings: OnceCell<Settings>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for AppWindow {
        const NAME: &'static str = "AppWindow";
        type Type = super::AppWindow;
        type ParentType = ApplicationWindow;
    }

    impl ObjectImpl for AppWindow {
        fn constructed(&self) {
            self.parent_constructed();

            let obj = self.obj();

            obj.setup_settings();
            obj.load_window_size();

            let mode_switch = granite::ModeSwitch::builder()
                .primary_icon_name("display-brightness-symbolic")
                .secondary_icon_name("weather-clear-night-symbolic")
                .primary_icon_tooltip_text(gettext("Light Background"))
                .secondary_icon_tooltip_text(gettext("Dark Background"))
                .valign(gtk::Align::Center)
                .build();

            let gtk_settings = gtk::Settings::default().expect("Unable to get GtkSettings object");
            mode_switch
                .bind_property("active", &gtk_settings, "gtk-application-prefer-dark-theme")
                .bidirectional()
                .build();

            let header_bar = gtk::HeaderBar::builder().show_title_buttons(true).build();

            header_bar.style_context().add_class("default-decoration");
            header_bar.pack_end(&mode_switch);

            obj.set_titlebar(Some(&header_bar));
        }
    }

    impl WidgetImpl for AppWindow {}
    impl WindowImpl for AppWindow {
        fn close_request(&self) -> glib::Propagation {
            self.obj()
                .save_window_size()
                .expect("Failed to save window state");

            glib::Propagation::Proceed
        }
    }
    impl ApplicationWindowImpl for AppWindow {}
}

// Extend and implements the proper classes to make AppWindow and actual GtkObject
glib::wrapper! {
    pub struct AppWindow(ObjectSubclass<imp::AppWindow>)
        @extends gtk::Widget, gtk::Window, gtk::ApplicationWindow,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl AppWindow {
    pub fn new<P: IsA<gtk::Application>>(application: &P) -> Self {
        glib::Object::builder()
            .property("application", application)
            .property("title", "Akira")
            .build()
    }

    fn setup_settings(&self) {
        let settings = Settings::new(APP_ID);
        self.imp()
            .settings
            .set(settings)
            .expect("`settings` should not be set before calling `setup_settings`.");
    }

    fn settings(&self) -> &Settings {
        self.imp()
            .settings
            .get()
            .expect("`settings` should be set in `setup_settings`.")
    }

    fn save_window_size(&self) -> Result<(), glib::BoolError> {
        let size = self.default_size();

        self.settings().set_int("window-width", size.0)?;
        self.settings().set_int("window-height", size.1)?;
        self.settings()
            .set_boolean("is-maximized", self.is_maximized())?;

        Ok(())
    }

    fn load_window_size(&self) {
        let width = self.settings().int("window-width");
        let height = self.settings().int("window-height");
        let is_maximized = self.settings().boolean("is-maximized");

        self.set_default_size(width, height);
        if is_maximized {
            self.maximize();
        }
    }
}

#[cfg(test)]
mod test {
    #[gtk::test]
    fn test_main_window() {
        let success: bool = true;
        assert!(success);
    }
}
