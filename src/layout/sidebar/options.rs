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
use gtk::glib;
use gtk::subclass::prelude::*;

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct Options {}

    #[glib::object_subclass]
    impl ObjectSubclass for Options {
        const NAME: &'static str = "Options";
        type Type = super::Options;
        type ParentType = gtk::Grid;
    }

    impl ObjectImpl for Options {}
    impl WidgetImpl for Options {}
    impl GridImpl for Options {}
}

glib::wrapper! {
    pub struct Options(ObjectSubclass<imp::Options>) @extends gtk::Widget, gtk::Grid;
}

impl Default for Options {
    fn default() -> Self {
        glib::Object::builder()
            .property("width-request", 200)
            .build()
    }
}
