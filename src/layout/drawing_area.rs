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
extern crate skia_safe;

use crate::canvas::Canvas;

use gtk::glib;
use gtk::prelude::DrawingAreaExtManual;
use gtk::{cairo, prelude::*, subclass::prelude::*};

mod imp {
    use super::*;
    use gtk::glib::clone;

    #[derive(Debug, Default)]
    pub struct DrawingArea {}

    #[glib::object_subclass]
    impl ObjectSubclass for DrawingArea {
        const NAME: &'static str = "DrawingArea";
        type ParentType = gtk::DrawingArea;
        type Type = super::DrawingArea;
    }

    impl ObjectImpl for DrawingArea {
        fn constructed(&self) {
            self.parent_constructed();

            let obj = self.obj();
            obj.build_canvas();
        }
    }
    impl WidgetImpl for DrawingArea {
        fn realize(&self) {
            self.parent_realize();

            let obj = self.obj();
            obj.set_draw_func(clone!(
                #[weak]
                obj,
                move |_, context, _, _| obj.draw(context)
            ));
        }
    }
    impl DrawingAreaImpl for DrawingArea {}
}

glib::wrapper! {
    pub struct DrawingArea(ObjectSubclass<imp::DrawingArea>)
    @extends gtk::DrawingArea, gtk::Widget, gtk::Buildable;
}

impl DrawingArea {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    fn draw(&self, context: &cairo::Context) {}

    fn build_canvas(&self) {
        let mut canvas = Canvas::new(2560, 1280);
        canvas.scale(1.2, 1.2);
        canvas.move_to(36.0, 48.0);
        canvas.quad_to(660.0, 880.0, 1200.0, 360.0);
        canvas.translate(10.0, 10.0);
        canvas.set_line_width(20.0);
        canvas.stroke();
        canvas.save();
        canvas.move_to(30.0, 90.0);
        canvas.line_to(110.0, 20.0);
        canvas.line_to(240.0, 130.0);
        canvas.line_to(60.0, 130.0);
        canvas.line_to(190.0, 20.0);
        canvas.line_to(270.0, 90.0);
        canvas.fill();

        let gl_area = gtk::GLArea::new();

        // let surface = canvas.surface;
        // How do we plug skia canvas into the gtk drawing area?
        // Do we need to pass through cairo context? (yuck)
        // self.attach(&canvas, 1, 1, 1, 1);
    }
}

impl Default for DrawingArea {
    fn default() -> Self {
        DrawingArea::new()
    }
}
