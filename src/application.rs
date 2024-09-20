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
use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};

use crate::AppWindow;

mod imp {
    use granite::prelude::SettingsExt;
    use gtk::glib::clone;

    use crate::config::SLASHED_APP_ID;

    use super::*;

    #[derive(Debug, Default)]
    pub struct App {}

    #[glib::object_subclass]
    impl ObjectSubclass for App {
        const NAME: &'static str = "App";
        type Type = super::App;
        type ParentType = gtk::Application;
    }

    impl ObjectImpl for App {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            obj.setup_gactions();
            obj.set_accels_for_action("app.quit", &["<primary>q"]);
        }
    }

    impl ApplicationImpl for App {
        fn activate(&self) {
            let application = self.obj();
            // Get the current window or create one if necessary
            let window = if let Some(window) = application.active_window() {
                window
            } else {
                let window = AppWindow::new(&*application);
                window.upcast()
            };

            window.present();
        }

        fn startup(&self) {
            self.parent_startup();

            granite::init();

            let display = gtk::gdk::Display::default().expect("Couldn't get GDK display");
            gtk::IconTheme::for_display(&display).add_resource_path(SLASHED_APP_ID);

            let gtk_settings =
                gtk::Settings::default().expect("Unable to get the GtkSettings object");
            let granite_settings =
                granite::Settings::default().expect("Unable to get the Granite settings object");
            gtk_settings.set_gtk_application_prefer_dark_theme(
                granite_settings.prefers_color_scheme() == granite::SettingsColorScheme::Dark,
            );

            granite_settings.connect_prefers_color_scheme_notify(clone!(
                #[weak]
                gtk_settings,
                move |granite_settings| {
                    gtk_settings.set_gtk_application_prefer_dark_theme(
                        granite_settings.prefers_color_scheme()
                            == granite::SettingsColorScheme::Dark,
                    );
                }
            ));
        }
    }

    impl GtkApplicationImpl for App {}
}

glib::wrapper! {
    pub struct App(ObjectSubclass<imp::App>)
        @extends gio::Application, gtk::Application,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl App {
    pub fn new(application_id: &str, flags: &gio::ApplicationFlags) -> Self {
        glib::Object::builder()
            .property("application-id", application_id)
            .property("flags", flags)
            .build()
    }

    fn setup_gactions(&self) {
        let quit_action = gio::ActionEntry::builder("quit")
            .activate(move |app: &Self, _, _| app.quit())
            .build();
        self.add_action_entries([quit_action]);
    }
}
