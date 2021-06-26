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
    public unowned Akira.Window window { get; construct; }

    public Lib2.Managers.ItemsManager items_manager;
    public Lib2.Managers.SelectionManager selection_manager;
    public Lib2.Managers.ModeManager mode_manager;
    public Lib2.Managers.HoverManager hover_manager;
    public Lib2.Managers.NobManager nob_manager;
    public Lib2.Managers.SnapManager snap_manager;
    public Lib2.Managers.CopyManager copy_manager;

    public bool ctrl_is_pressed = false;
    public bool shift_is_pressed = false;
    public double current_scale = 1.0;

    private Utils.Nobs.Nob hovered_nob = Utils.Nobs.Nob.NONE;
    private Gdk.CursorType current_cursor = Gdk.CursorType.ARROW;

    public ViewCanvas (Akira.Window window) {
        Object (window: window);
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
        selection_manager = new Lib2.Managers.SelectionManager (this);
        mode_manager = new Lib2.Managers.ModeManager (this);
        hover_manager = new Lib2.Managers.HoverManager (this);
        nob_manager = new Lib2.Managers.NobManager (this);
        snap_manager = new Lib2.Managers.SnapManager (this);
        copy_manager = new Lib2.Managers.CopyManager (this);

        window.event_bus.update_scale.connect (on_update_scale);
        window.event_bus.set_scale.connect (on_set_scale);
        window.event_bus.set_focus_on_canvas.connect (focus_canvas);
        window.event_bus.insert_item.connect (start_insert_mode);
        window.event_bus.update_snap_decorators.connect (on_update_snap_decorators);
    }

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    public void visible_bounds (
        ref double top,
        ref double left,
        ref double bottom,
        ref double right
    ) {
        top = vadjustment.value / current_scale;
        left = hadjustment.value / current_scale;
        bottom = top + get_allocated_height () / current_scale;
        right = left + get_allocated_width () / current_scale;
    }

    public void start_insert_mode (string insert_item_type) {
        var new_mode = new Akira.Lib2.Modes.ItemInsertMode (this, insert_item_type);
        mode_manager.register_mode (new_mode);
    }

    public void interaction_mode_changed () {
        set_cursor_by_interaction_mode ();
    }

    public void set_cursor_by_interaction_mode () {
        hover_manager.remove_hover_effect ();
        Gdk.CursorType? new_cursor = mode_manager.active_cursor_type ();

        if (new_cursor == null) {
            var hover_cursor = Utils.Nobs.cursor_from_nob (hovered_nob);
            new_cursor = (hover_cursor == null) ? Gdk.CursorType.ARROW : hover_cursor;
        }

        if (current_cursor != new_cursor) {
            // debug (@"Changing cursor. $new_cursor");
            set_cursor (new_cursor);
        }
    }

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

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = true;
                //toggle_item_ghost (false);
                break;

            case Gdk.Key.Shift_L:
            case Gdk.Key.Shift_R:
                shift_is_pressed = true;
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                // Show the ghost item only if the CTRL button is not pressed.
                //toggle_item_ghost (!ctrl_is_pressed);
                break;

        }

        if (mode_manager.key_press_event (event)) {
            return true;
        }

        switch (uppercase_keyval) {
            case Gdk.Key.space:
                mode_manager.start_panning_mode ();
                if (mode_manager.key_press_event (event)) {
                    return true;
                }
                break;

            case Gdk.Key.Up:
            case Gdk.Key.Down:
            case Gdk.Key.Right:
            case Gdk.Key.Left:
                //window.event_bus.move_item_from_canvas (event);
                //window.event_bus.detect_artboard_change ();
                return true;
            default:
                break;
        }

        if (uppercase_keyval == Gdk.Key.J) {
            items_manager.debug_add_rectangles (10000, true);

            return true;
        }

        if (uppercase_keyval == Gdk.Key.G) {
            items_manager.add_debug_group (300, 300, true);
            return true;
        }

        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = false;
                break;

            case Gdk.Key.Shift_L:
            case Gdk.Key.Shift_R:
                shift_is_pressed = false;
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                //toggle_item_ghost (false);
                break;
        }

        if (mode_manager.key_release_event (event)) {
            return true;
        }

        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        hover_manager.remove_hover_effect ();

        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        if (mode_manager.button_press_event (event)) {
            return true;
        }

        if (event.button == Gdk.BUTTON_MIDDLE) {
            mode_manager.start_panning_mode ();
            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

        handle_selection_press_event (event);

        var target_nob = nob_manager.hit_test (event.x, event.y);

        if (target_nob != Utils.Nobs.Nob.NONE) {
            // TODO - hook up transform

            return true;
        }

        var target = items_manager.hit_test (event.x, event.y);
        if (target != null) {
            if (!selection_manager.item_selected (target.id)) {
                selection_manager.add_to_selection (target.id);
                return true;
            }
        }
        else {
            selection_manager.reset_selection ();
        }


        return false;
    }

    private bool handle_selection_press_event (Gdk.EventButton event) {
        var nob_clicked = nob_manager.hit_test (event.x, event.y);

        if (nob_clicked == Utils.Nobs.Nob.NONE) {
            var target = items_manager.hit_test (event.x, event.y, false);
            if (target != null) {
                if (!selection_manager.item_selected (target.id)) {
                    selection_manager.add_to_selection (target.id);
                }
            }
            else {
                selection_manager.reset_selection ();
            }
        }

        if (!selection_manager.is_empty ()) {
            var new_mode = new Lib2.Modes.TransformMode (this, nob_clicked);
            mode_manager.register_mode (new_mode);

            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

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

        if (mode_manager.motion_notify_event (event)) {
            return true;
        }

        var target_nob = nob_manager.hit_test (event.x, event.y);

        if (target_nob != Utils.Nobs.Nob.NONE) {
            hover_manager.remove_hover_effect ();
            if (hovered_nob != target_nob) {
                hovered_nob = target_nob;
                set_cursor_by_interaction_mode ();
            }
            return true;
        }
        else if (hovered_nob != Utils.Nobs.Nob.NONE) {
            hovered_nob = Utils.Nobs.Nob.NONE;
            set_cursor_by_interaction_mode ();
        }

        hover_manager.on_mouse_over (event.x, event.y);

        return false;
    }

    private void set_cursor (Gdk.CursorType? cursor_type) {
        current_cursor = (cursor_type == null ? Gdk.CursorType.ARROW : cursor_type);
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), current_cursor);
        get_window ().set_cursor (cursor);
    }



    // #TODO temporary
    /*
    public override bool draw (Cairo.Context ctx) {
        base.draw (ctx);

        foreach (var item in items_manager.items) {
            //draw_debug_info (ctx, item);
        }

        draw_debug_selection(ctx);

        return false;
    }
    */

    public void draw_debug_info (Cairo.Context ctx, Lib2.Items.ModelItem item) {
        /*
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        var cs = current_scale;

        ctx.save ();
        var cg = item.components.compiled_geometry;
        var top = cg.bb_top () * cs;
        var left = cg.bb_left () * cs;
        var bottom = cg.bb_bottom () * cs;
        var right = cg.bb_right () * cs;

        var width = right - left;
        var height = bottom - top;
        ctx.move_to (left - xadj, top - yadj);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.rel_line_to (width, 0);
        ctx.rel_line_to (0, height);
        ctx.rel_line_to (-width, 0);
        ctx.close_path ();
        ctx.stroke ();

        ctx.arc (cg.x0 () * cs - xadj, cg.y0 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x1 () * cs - xadj, cg.y1 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x2 () * cs - xadj, cg.y2 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x3 () * cs - xadj, cg.y3 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();

        ctx.restore ();
        */
    }

    public void draw_debug_selection (Cairo.Context ctx) {
        /*
        if (selection_manager.selection.is_empty ()) {
            return;
        }
        var cs = current_scale;

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
        double rotation = 0;

        selection_manager.selection.coordinates (
            out x0,
            out y0,
            out x1,
            out y1,
            out x2,
            out y2,
            out x3,
            out y3,
            out rotation
        );
        x0 = x0 * cs - xadj;
        y0 = y0 * cs - yadj;
        x1 = x1 * cs - xadj;
        y1 = y1 * cs - yadj;
        x2 = x2 * cs - xadj;
        y2 = y2 * cs - yadj;
        x3 = x3 * cs - xadj;
        y3 = y3 * cs - yadj;

        ctx.save ();
        ctx.move_to (x0, y0);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.line_to (x1, y1);
        ctx.line_to (x3, y3);
        ctx.line_to (x2, y2);
        ctx.close_path ();
        ctx.stroke ();
        ctx.restore ();
        */
    }

    /*
     * Will update snap decorators if necessary.
     */
    private void on_update_snap_decorators () {
        var extra_context = mode_manager.active_mode_extra_context ();
        if (extra_context is Akira.Lib2.Modes.TransformMode.TransformExtraContext) {
            snap_manager.generate_decorators (
                ((Lib2.Modes.TransformMode.TransformExtraContext) extra_context).snap_guide_data);
        } else if (snap_manager.is_active ()) {
            snap_manager.reset_decorators ();
        }
    }
}
