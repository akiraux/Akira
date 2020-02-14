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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alberto Fanjul <albertofanjul@gmail.com>
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Canvas : Goo.Canvas {
    public weak Akira.Window window { get; construct; }

    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    private EditMode _edit_mode;
    public EditMode edit_mode {
        get {
            return _edit_mode;
        }
        set {
            if (_edit_mode != value) {
                _edit_mode = value;
                set_cursor_by_edit_mode ();
            }
        }
    }

    public enum EditMode {
        MODE_SELECTION,
        MODE_EXPORT_AREA,
        MODE_INSERT,
        MODE_PAN,
        MODE_PANNING,
    }

    public Managers.SelectedBoundManager selected_bound_manager;
    private Managers.ItemsManager items_manager;
    private Managers.NobManager nob_manager;
    private Managers.HoverManager hover_manager;

    public bool ctrl_is_pressed = false;
    private bool holding;
    public double current_scale = 1.0;
    private double bounds_x;
    private double bounds_y;
    private double bounds_w;
    private double bounds_h;
    private Gdk.CursorType current_cursor = Gdk.CursorType.ARROW;

    public Canvas (Akira.Window window) {
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

        selected_bound_manager = new Managers.SelectedBoundManager (this);
        items_manager = new Managers.ItemsManager (this);
        nob_manager = new Managers.NobManager (this);
        hover_manager = new Managers.HoverManager (this);

        window.event_bus.request_zoom.connect (on_request_zoom);
        window.event_bus.request_change_cursor.connect (on_request_change_cursor);
        window.event_bus.request_change_mode.connect (on_request_change_mode);
        window.event_bus.set_focus_on_canvas.connect (on_set_focus_on_canvas);
        window.event_bus.request_escape.connect (on_set_focus_on_canvas);
    }

    public void insert_item_default (Akira.Lib.Models.CanvasItem item, bool select) {
        double start_x, start_y, scale, rotation;
        start_x = Akira.Layouts.MainCanvas.CANVAS_SIZE / 2;
        start_y = Akira.Layouts.MainCanvas.CANVAS_SIZE / 2;

        if (selected_bound_manager.selected_items.length () > 0) {
            selected_bound_manager.selected_items.nth_data (0).get_simple_transform (
                out start_x, out start_y, out scale, out rotation
            );
        }

        items_manager.add_item (item);
        Utils.AffineTransform.set_position (item, start_x, start_y);

        if (select) {
            selected_bound_manager.reset_selection ();
            selected_bound_manager.add_item_to_selection (item);
        }
    }

    public void update_bounds () {
        get_bounds (out bounds_x, out bounds_y, out bounds_w, out bounds_h);
    }

    public void set_cursor_by_edit_mode () {
        // debug ("Calling set_cursor_by_edit_mode");
        Gdk.CursorType? new_cursor;

        switch (_edit_mode) {
            case EditMode.MODE_SELECTION:
                new_cursor = Gdk.CursorType.ARROW;
                break;

            case EditMode.MODE_INSERT:
            case EditMode.MODE_EXPORT_AREA:
                new_cursor = Gdk.CursorType.CROSSHAIR;
                break;

            case EditMode.MODE_PAN:
                new_cursor = Gdk.CursorType.HAND2;
                break;

            case EditMode.MODE_PANNING:
                new_cursor = Gdk.CursorType.HAND1;
                break;

            default:
                new_cursor = Gdk.CursorType.ARROW;
                break;
        }

        if (current_cursor != new_cursor) {
            // debug (@"Changing cursor. $new_cursor");
            set_cursor (new_cursor);
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Escape:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_SELECTION;
                break;

            case Gdk.Key.Delete:
                selected_bound_manager.delete_selection ();
                break;

            case Gdk.Key.space:
                if (edit_mode != EditMode.MODE_PANNING) {
                    edit_mode = EditMode.MODE_PAN;
                }
                break;

            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = true;
                break;

            case Gdk.Key.Up:
            case Gdk.Key.Down:
            case Gdk.Key.Right:
            case Gdk.Key.Left:
                window.event_bus.move_item_from_canvas (event);
                break;
        }

        return true;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.space:
                edit_mode = EditMode.MODE_SELECTION;
                break;

            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = false;
                break;
        }

        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        focus_canvas ();

        holding = true;

        event.x /= current_scale;
        event.y /= current_scale;

        hover_manager.remove_hover_effect ();

        if (event.button == Gdk.BUTTON_MIDDLE) {
            edit_mode = EditMode.MODE_PANNING;
            canvas_scroll_set_origin (event.x, event.y);
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
                selected_bound_manager.reset_selection ();

                var new_item = items_manager.insert_item (event);
                selected_bound_manager.add_item_to_selection (new_item);

                selected_bound_manager.set_initial_coordinates (event.x, event.y);

                nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;
                break;

            case EditMode.MODE_SELECTION:
                var clicked_item = get_item_at (event.x, event.y, true);

                if (clicked_item == null) {
                    selected_bound_manager.reset_selection ();
                    // TODO: allow for multi select with click & drag on canvas
                    // Workaround: when no item is clicked, there's no point in keeping holding active
                    holding = false;
                    return true;
                }

                var clicked_nob_name = Managers.NobManager.Nob.NONE;

                if (clicked_item is Selection.Nob) {
                    var selected_nob = clicked_item as Selection.Nob;

                    clicked_nob_name = nob_manager.get_grabbed_id (selected_nob);
                }

                nob_manager.selected_nob = clicked_nob_name;

                if (clicked_item is Models.CanvasItem) {
                    if ((clicked_item as Models.CanvasItem).locked) {
                        return true;
                    }
                    // Item has been selected
                    selected_bound_manager.add_item_to_selection (clicked_item as Models.CanvasItem);
                }

                selected_bound_manager.set_initial_coordinates (event.x, event.y);
                break;

            case EditMode.MODE_PAN:
                //set_cursor_by_edit_mode ();
                edit_mode = EditMode.MODE_PANNING;
                canvas_scroll_set_origin (event.x, event.y);
                break;
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) {
            return true;
        }

        holding = false;

        if (event.button == Gdk.BUTTON_MIDDLE) {
            edit_mode = EditMode.MODE_SELECTION;
        }

        switch (edit_mode) {
            case EditMode.MODE_PANNING:
                edit_mode = EditMode.MODE_PAN;
                break;

            default:
                edit_mode = EditMode.MODE_SELECTION;
                break;
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        event.x /= current_scale;
        event.y /= current_scale;

        window.event_bus.coordinate_change (event.x, event.y);

        if (!holding) {
            // Only motion_hover_effect
            hover_manager.add_hover_effect (event.x, event.y);
            return false;
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
            case EditMode.MODE_SELECTION:
                var selected_nob = nob_manager.selected_nob;
                selected_bound_manager.transform_bound (event.x, event.y, selected_nob);
                break;

            case EditMode.MODE_PANNING:
                canvas_moved (event.x, event.y);
                break;
        }

        return true;
    }

    public void on_set_focus_on_canvas () {
        edit_mode = EditMode.MODE_SELECTION;
        ctrl_is_pressed = false;
        focus_canvas ();
    }

    public void focus_canvas () {
        grab_focus (get_root_item ());
    }

    private void on_request_zoom (string direction) {
        switch (direction) {
            case "in":
                current_scale += 0.1;
                break;
            case "out":
                if (current_scale == 0.1) {
                    break;
                }
                current_scale -= 0.1;
                break;
            case "reset":
                current_scale = 1.0;
                break;
        }

        set_scale (current_scale);
        window.event_bus.zoom ();
    }

    private void on_request_change_cursor (Gdk.CursorType? cursor_type) {
        // debug ("Setting cursor from on_request_change_cursor");
        if (cursor_type == null) {
            set_cursor_by_edit_mode ();
            return;
        }

        set_cursor (cursor_type);
    }

    private void on_request_change_mode (EditMode mode) {
        edit_mode = mode;
    }

    private void set_cursor (Gdk.CursorType? cursor_type) {
        // debug (@"Setting cursor: $cursor_type");
        current_cursor = cursor_type;

        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }
}
