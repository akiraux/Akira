/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.MainViewCanvas : Gtk.Grid {
    public const int CANVAS_SIZE = 100000;
    public const double SCROLL_DISTANCE = 0;

    public Gtk.ScrolledWindow main_scroll;

    public Akira.Lib2.ViewCanvas canvas;

    public weak Akira.Window window { get; construct; }

    private Gtk.Overlay main_overlay;

    private double scroll_origin_x = 0;
    private double scroll_origin_y = 0;

    public MainViewCanvas (Akira.Window window) {
        Object (window: window, orientation: Gtk.Orientation.VERTICAL);
    }

    construct {
        get_style_context ().add_class ("main-canvas");

        main_overlay = new Gtk.Overlay ();

        main_scroll = new Gtk.ScrolledWindow (null, null);
        main_scroll.expand = true;

        // Overlay the scrollbars only if mouse pointer is inside canvas
        main_scroll.overlay_scrolling = false;

        // Change visibility of canvas scrollbars
        main_scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);

        canvas = new Akira.Lib2.ViewCanvas (window);
        canvas.set_bounds (0, 0, CANVAS_SIZE, CANVAS_SIZE);
        canvas.set_scale (1.0);

        canvas.canvas_moved.connect ((event_x, event_y) => {
            // Move scroll window according to normalized mouse delta
            // relative to the scroll window, so with Canvas' pixel
            // coordinates translated into ScrolledWindow's one.
            double event_x_pixel_space = event_x;
            double event_y_pixel_space = event_y;

            // Convert coordinates to pixel space, which does account for
            // canvas scale and canvas translation.
            // Otherwise, delta can start to "diverge" due to the
            // translation of starting point happening during canvas translation
            canvas.convert_to_pixels (ref event_x_pixel_space, ref event_y_pixel_space);

            var delta_x = event_x_pixel_space - scroll_origin_x;
            var delta_y = event_y_pixel_space - scroll_origin_y;

            main_scroll.hadjustment.value -= delta_x;
            main_scroll.vadjustment.value -= delta_y;
        });

        canvas.canvas_scroll_set_origin.connect ((origin_x, origin_y) => {
            // Update scroll origin on Canvas' button_press_event
            scroll_origin_x = origin_x;
            scroll_origin_y = origin_y;

            canvas.convert_to_pixels (ref scroll_origin_x, ref scroll_origin_y);
        });

        canvas.scroll_event.connect (on_scroll);

        main_scroll.add (canvas);

        main_overlay.add (main_scroll);

        add (main_overlay);
    }

    public bool on_scroll (Gdk.EventScroll event) {
        bool is_shift = (event.state & Gdk.ModifierType.SHIFT_MASK) > 0;
        bool is_ctrl = (event.state & Gdk.ModifierType.CONTROL_MASK) > 0;

        double delta_x, delta_y;
        event.get_scroll_deltas (out delta_x, out delta_y);

        if (delta_y < -SCROLL_DISTANCE) {
            // Scroll UP.
            if (is_ctrl) {
                // Divide the delta if it's too high. This fixes the zoom with
                // the mouse wheel.
                if (delta_y <= -1) {
                    delta_y /= 10;
                }
                // Get the current zoom before zooming.
                double old_zoom = canvas.get_scale ();
                // Zoom in.
                window.event_bus.update_scale (delta_y * -1);
                // Adjust zoom based on cursor position.
                zoom_on_cursor (event, old_zoom);
            } else if (is_shift) {
                main_scroll.hadjustment.value += delta_y * 10;
            } else {
                main_scroll.vadjustment.value += delta_y * 10;
            }
        } else if (delta_y > SCROLL_DISTANCE) {
            // Scroll DOWN.
            if (is_ctrl) {
                // Divide the delta if it's too high. This fixes the zoom with
                // the mouse wheel.
                if (delta_y >= 1) {
                    delta_y /= 10;
                }
                // Get the current zoom before zooming.
                double old_zoom = canvas.get_scale ();
                // Zoom out.
                window.event_bus.update_scale (-delta_y);
                // Adjust zoom based on cursor position.
                zoom_on_cursor (event, old_zoom);
            } else if (is_shift) {
                main_scroll.hadjustment.value += delta_y * 10;
            } else {
                main_scroll.vadjustment.value += delta_y * 10;
            }
        }

        if (delta_x < -SCROLL_DISTANCE) {
            main_scroll.hadjustment.value += delta_x * 10;
        } else if (delta_x > SCROLL_DISTANCE) {
            main_scroll.hadjustment.value += delta_x * 10;
        }

        return true;
    }

    private void zoom_on_cursor (Gdk.EventScroll event, double old_zoom) {
        // The regular zoom mode shifts the visible viewing area
        // to center itself (it already has one translation applied)
        // so you cannot just move the viewing area by the distance
        // of the current mouse location and the new mouse location.

        // If you want to zoom to your mouse you need to find the
        // difference between the distances of the current mouse location
        // in the current view scale to the left view border and the new
        // mouse location that has the new canvas scale applied to the
        // new left view border and shift the view by that difference.
        int width = main_scroll.get_allocated_width ();
        int height = main_scroll.get_allocated_height ();

        var center_x = main_scroll.hadjustment.value + (width / 2);
        var center_y = main_scroll.vadjustment.value + (height / 2);

        var old_center_x = (center_x / canvas.get_scale ()) * old_zoom;
        var old_center_y = (center_y / canvas.get_scale ()) * old_zoom;

        var new_event_x = (event.x / old_zoom) * canvas.get_scale ();
        var new_event_y = (event.y / old_zoom) * canvas.get_scale ();

        var old_hadjustment = old_center_x - (width / 2);
        var old_vadjustment = old_center_y - (height / 2);

        main_scroll.hadjustment.value +=
            (new_event_x - main_scroll.hadjustment.value) - (event.x - old_hadjustment);
        main_scroll.vadjustment.value +=
            (new_event_y - main_scroll.vadjustment.value) - (event.y - old_vadjustment);
    }
}
