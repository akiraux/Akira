/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

public class Akira.Lib2.ViewCanvas : Goo.Canvas {
    public weak Akira.Window window { get; construct; }

    public double current_scale = 1.0;

    private Gee.ArrayList<Lib2.Items.ModelItem> items;

    private double drag_x;
    private double drag_y;
    private Lib2.Items.ModelItem? drag_item = null;

    public ViewCanvas (Akira.Window window) {
        Object(window: window);
    }

    construct {
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        events |= Gdk.EventMask.TOUCHPAD_GESTURE_MASK;
        events |= Gdk.EventMask.TOUCH_MASK;

        items = new Gee.ArrayList<Lib2.Items.ModelItem> ();

        window.event_bus.update_scale.connect (on_update_scale);
        window.event_bus.set_scale.connect (on_set_scale);
        window.event_bus.set_focus_on_canvas.connect (on_set_focus_on_canvas);
    }

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    private void on_update_scale (double zoom) {
        // Force the zoom value to 8% if we're currently at a 2% scale in order
        // to go back to 10% and increase from there.
        if (current_scale == 0.02 && zoom == 0.1) {
            zoom = 0.08;
        }

        current_scale += zoom;
        // Prevent the canvas from shrinking below 2%;
        if (current_scale < 0.02) {
            current_scale = 0.02;
        }

        // Prevent the canvas from growing above 5000%;
        if (current_scale > 50) {
            current_scale = 50;
        }

        window.event_bus.set_scale (current_scale);
    }

    private void on_set_scale (double scale) {
        current_scale = scale;
        set_scale (scale);
        window.event_bus.zoom ();

        window.event_bus.update_snap_decorators ();
    }

    public void on_set_focus_on_canvas () {
        grab_focus (get_root_item ());
    }

    public override bool button_press_event (Gdk.EventButton event) {

        if (event.button == Gdk.BUTTON_PRIMARY) {
            drag_x = event.x * current_scale;
            drag_y = event.y * current_scale;
            drag_item = add_rect (drag_x, drag_y);
        }

        return false;
    }
    public override bool button_release_event (Gdk.EventButton event) {
        drag_item = null;
        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (drag_item != null) {
            move_item_to (drag_item, event.x * current_scale, event.y * current_scale);
        }

        return false;
    }

    private Lib2.Items.ModelItem add_rect (double x, double y) {
        var fill_color = Gdk.RGBA () { red = 1.0 , alpha = 1.0};
        var fills = new Gee.ArrayList<Lib2.Components.Fill> ();
        fills.add(new Lib2.Components.Fill (0, new Lib2.Components.Color (fill_color)));

        var new_rect = new Lib2.Items.ModelRect (
            new Lib2.Components.Coordinates (x, y),
            new Lib2.Components.Size (50.0, 50.0, false),
            null,
            new Lib2.Components.Fills (fills)
        );

        items.add(new_rect);

        compile_items ();
        add_item_to_canvas (new_rect);

        return new_rect;
    }

    private void compile_items() {
        foreach (var item in items) {
            item.compile_components (false);
        }
    }

    private void add_item_to_canvas (Lib2.Items.ModelItem item) {
        item.add_to_canvas (this);
        item.notify_view_of_changes ();
    }

    private void move_item_to (Lib2.Items.ModelItem item, double new_x, double new_y) {
        item.components.coordinates = new Lib2.Components.Coordinates (new_x, new_y);
        item.components.compiled_geometry = null;
        item.compile_components (true);
    }
}
