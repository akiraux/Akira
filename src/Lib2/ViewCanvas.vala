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
    private const int SIZE = 30;
    public weak Akira.Window window { get; construct; }

    public Lib2.Managers.ItemsManager items_manager;
    public Lib2.Managers.SelectionManager selection_manager;
    public Lib2.Managers.ModeManager mode_manager;

    public double current_scale = 1.0;

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

        items_manager = new Lib2.Managers.ItemsManager (this);
        mode_manager = new Lib2.Managers.ModeManager (this);
        selection_manager = new Lib2.Managers.SelectionManager (this);

        window.event_bus.update_scale.connect (on_update_scale);
        window.event_bus.set_scale.connect (on_set_scale);
        window.event_bus.set_focus_on_canvas.connect (focus_canvas);
        window.event_bus.insert_item.connect (start_insert_mode);
    }

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    public void start_insert_mode (string insert_item_type) {
        var new_mode = new Akira.Lib2.Modes.ItemInsertMode (this, mode_manager, insert_item_type);
        mode_manager.register_mode (new_mode);
    }

    public void interaction_mode_changed () {}

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

    public void focus_canvas () {
        grab_focus (get_root_item ());
    }

    public override bool button_press_event (Gdk.EventButton event) {
        //hover_manager.remove_hover_effect ();

        if (mode_manager.button_press_event (event)) {
            return true;
        }

        if (event.button == Gdk.BUTTON_MIDDLE) {
            mode_manager.start_panning_mode ();
            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        //return press_event_on_selection (event)
        return false;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        if (mode_manager.button_release_event (event)) {
            return true;
        }
        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        //window.event_bus.coordinate_change (event.x, event.y);

        if (mode_manager.motion_notify_event (event)) {
            return true;
        }

        /*
        var nob_hovered = nob_manager.hit_test (event.x, event.y);
        if (nob_hovered != nob_manager.hovered_nob) {
            nob_manager.hovered_nob = nob_hovered;
            set_cursor_by_interaction_mode ();
        }

        hover_manager.on_mouse_over (event.x, event.y, nob_hovered);
        */

        return false;
    }

    public override bool draw (Cairo.Context ctx) {
        base.draw (ctx);

        /*
        foreach (var item in items_manager.items) {
            draw_debug_info (ctx, item);
        }
        */

        draw_debug_selection(ctx);

        return false;
    }

    public void draw_debug_info (Cairo.Context ctx, Lib2.Items.ModelItem item) {
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        ctx.save ();
        var cg = item.components.compiled_geometry;
        var top = cg.bb_top () * current_scale;
        var left = cg.bb_left () * current_scale;
        var bottom = cg.bb_bottom () * current_scale;
        var right = cg.bb_right () * current_scale;

        var width = right - left;
        var height = bottom - top;
        ctx.move_to (left - xadj, top - yadj);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.rel_line_to (width, 0);
        ctx.rel_line_to (0, height);
        ctx.rel_line_to (-width, 0);
        ctx.close_path ();
        ctx.stroke ();

        ctx.arc (cg.x0 () - xadj, cg.y0 () - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x1 () - xadj, cg.y1 () - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x2 () - xadj, cg.y2 () - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x3 () - xadj, cg.y3 () - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();

        ctx.restore ();
    }

    public void draw_debug_selection (Cairo.Context ctx) {
        if (selection_manager.selection.is_empty ()) {
            return;
        }

        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        double x0 = 0;
        double y0 = 0;
        double x1 = 0;
        double y1 = 0;
        double x2 = 0;
        double y2 = 0;
        double x3 = 0;
        double y3 = 0;

        selection_manager.selection.coordinates(
            ref x0,
            ref y0,
            ref x1,
            ref y1,
            ref x2,
            ref y2,
            ref x3,
            ref y3
        );
        x0 -= xadj;
        y0 -= yadj;
        x1 -= xadj;
        y1 -= yadj;
        x2 -= xadj;
        y2 -= yadj;
        x3 -= xadj;
        y3 -= yadj;

        ctx.save ();
        ctx.move_to (x0, y0);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.line_to (x1, y1);
        ctx.line_to (x3, y3);
        ctx.line_to (x2, y2);
        ctx.close_path ();
        ctx.stroke ();
        ctx.restore ();
    }
}
