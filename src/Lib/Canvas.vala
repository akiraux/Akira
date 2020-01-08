/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
* Authored by: Alberto Fanjul <albertofanjul@gmail.com>
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
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
        MODE_INSERT,
        MODE_PAN,
    }

    public Managers.SelectedBoundManager selected_bound_manager;
    private Managers.ItemsManager items_manager;
    private Managers.NobManager nob_manager;
    private Managers.HoverManager hover_manager;

    private bool holding;
    private double current_scale = 1.0;
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
        window.event_bus.set_focus_on_canvas.connect (on_set_focus_on_canvas);
    }

    public void update_bounds () {
        get_bounds (out bounds_x, out bounds_y, out bounds_w, out bounds_h);
    }

    public void set_cursor_by_edit_mode () {
        Gdk.CursorType? new_cursor;

        switch (_edit_mode) {
            case EditMode.MODE_SELECTION:
                new_cursor = Gdk.CursorType.ARROW;
                break;

            case EditMode.MODE_INSERT:
                new_cursor = Gdk.CursorType.CROSSHAIR;
                break;

            case EditMode.MODE_PAN:
                new_cursor = holding ? Gdk.CursorType.HAND2 : Gdk.CursorType.HAND1;
                break;

            default:
                new_cursor = Gdk.CursorType.ARROW;
                break;
        }

        if (current_cursor != new_cursor) {
            set_cursor (new_cursor);
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Escape:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_SELECTION;
                return true;

            case Gdk.Key.Delete:
                selected_bound_manager.delete_selection ();
                // delete_selected ();
                return true;

            case Gdk.Key.space:
                edit_mode = EditMode.MODE_PAN;
                return true;

            default:
                // Send to ItemsManager to deal with custom user shape
                // hotkey preferences from settings
                if (items_manager.set_insert_type_from_key (uppercase_keyval)) {
                    edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
                    return true;
                }

                return false;
        }
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.space:
                edit_mode = EditMode.MODE_SELECTION;
                return true;

            default:
                return false;
        }
    }

    public override bool button_press_event (Gdk.EventButton event) {
        focus_canvas ();

        holding = true;

        var temp_event_x = event.x / current_scale;
        var temp_event_y = event.y / current_scale;

        hover_manager.remove_hover_effect ();

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
                selected_bound_manager.reset_selection ();

                var new_item = items_manager.insert_item (event);
                selected_bound_manager.add_item_to_selection (new_item);

                selected_bound_manager.set_initial_coordinates (temp_event_x, temp_event_y);

                nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;
                break;

            case EditMode.MODE_SELECTION:
                var clicked_item = get_item_at (temp_event_x, temp_event_y, true);

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
                    // Item has been selected
                    selected_bound_manager.add_item_to_selection (clicked_item as Models.CanvasItem);
                }

                selected_bound_manager.set_initial_coordinates (temp_event_x, temp_event_y);
                break;

            case EditMode.MODE_PAN:
                set_cursor_by_edit_mode ();

                canvas_scroll_set_origin (temp_event_x, temp_event_y);
                break;
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) {
            return false;
        }

        holding = false;

        //item_moved (selected_item);
        //add_hover_effect (selected_item);

        switch (edit_mode) {
            case EditMode.MODE_PAN:
                set_cursor_by_edit_mode ();
                break;

            default:
                edit_mode = EditMode.MODE_SELECTION;
                break;
        }

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        var event_x = event.x / current_scale;
        var event_y = event.y / current_scale;

        window.event_bus.coordinate_change (event_x, event_y);

        if (!holding) {
            // Only motion_hover_effect
            hover_manager.add_hover_effect (event_x, event_y);
            return false;
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
            case EditMode.MODE_SELECTION:
                var selected_nob = nob_manager.selected_nob;
                selected_bound_manager.transform_bound (event_x, event_y, selected_nob);
                break;

            case EditMode.MODE_PAN:
                canvas_moved (event_x, event_y);
                break;
        }

        return true;
    }

    public void on_set_focus_on_canvas () {
        edit_mode = EditMode.MODE_SELECTION;
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
                current_scale -= 0.1;
                break;
            case "reset":
                current_scale = 1.0;
                break;
        }

        set_scale (current_scale);

        window.event_bus.zoom (current_scale);
    }

    private void on_request_change_cursor (Gdk.CursorType? cursor_type) {
        if (cursor_type == null) {
            set_cursor_by_edit_mode ();
            return;
        }

        set_cursor (cursor_type);
    }

    private void set_cursor (Gdk.CursorType? cursor_type) {
        // debug (@"Setting cursor: $cursor_type");
        current_cursor = cursor_type;

        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    /*
    public void change_z_selected (bool raise, bool total) {
        if (selected_item == null) {
            return;
        }

        var root_item = get_root_item ();
        var pos_selected = root_item.find_child (selected_item);
        if (pos_selected != -1) {
            int target_item_pos;
            if (total) {
                target_item_pos = raise ? (root_item.get_n_children () - 1): 0;
            } else {
                target_item_pos = pos_selected + (raise ? 1 : -1);
            }
            var target_item = root_item.get_child (target_item_pos);
            if (target_item != null) {
                if (raise) {
                    selected_item.raise (target_item);
                } else {
                    selected_item.lower (target_item);
                }
                //update_decorations (selected_item);
            }
        }
    }
    */
}
