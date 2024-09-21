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
    pub struct Layers {}

    #[glib::object_subclass]
    impl ObjectSubclass for Layers {
        const NAME: &'static str = "Layers";
        type Type = super::Layers;
        type ParentType = gtk::Grid;
    }

    impl ObjectImpl for Layers {}
    impl WidgetImpl for Layers {}
    impl GridImpl for Layers {}
}

glib::wrapper! {
    pub struct Layers(ObjectSubclass<imp::Layers>) @extends gtk::Widget, gtk::Grid;
}

impl Default for Layers {
    fn default() -> Self {
        glib::Object::builder()
            .property("width-request", 200)
            .build()
    }
}
