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
*/

public class Akira.Lib.Canvas : Goo.Canvas {
    public weak Akira.Window window { get; construct; }

    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;

    /**
     * Signal triggered when item was clicked by the user
     */
    public signal void item_clicked (Goo.CanvasItem? item);

    /**
     * Signal triggered when item has finished moving by the user,
     * and a change of it's coordenates was made
     */
    public signal void item_moved (Goo.CanvasItem? item);

    public Goo.CanvasItem? _selected_item;
    public Goo.CanvasItem? selected_item {
        get {
            return _selected_item;
        }
        set {
            _selected_item = value;
            window.main_window.left_sidebar.transform_panel.item = _selected_item;
            event_bus.emit ("change-sensitivity", "single");
        }
    }
    public Goo.CanvasRect select_effect;
    private EditMode _edit_mode;
    public EditMode edit_mode {
        get {
            return _edit_mode;
        }
        set {
            _edit_mode = value;
            set_cursor_by_edit_mode ();
        }
    }
    public InsertType? insert_type { get; set; }


    public enum EditMode {
        MODE_SELECTION,
        MODE_INSERT
    }

    private Managers.SelectedBoundManager selected_bound_manager;
    private Managers.ItemsManager items_manager;
    private Managers.NobManager nob_manager;
    private Managers.HoverManager hover_manager;

    private Goo.CanvasRect? hover_effect;

    private bool holding;
    private bool temp_event_converted;
    private double temp_event_x;
    private double temp_event_y;
    private double delta_x;
    private double delta_y;
    private double hover_x;
    private double hover_y;
    private double current_scale = 1.0;
    private double bounds_x;
    private double bounds_y;
    private double bounds_w;
    private double bounds_h;

    public Canvas (Akira.Window window) {
        Object (window: window);
    }

    construct {
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.TOUCHPAD_GESTURE_MASK;
        events |= Gdk.EventMask.TOUCH_MASK;

        selected_bound_manager = new Managers.SelectedBoundManager (this);
        items_manager = new Managers.ItemsManager (this);
        nob_manager = new Managers.NobManager (this);
        hover_manager = new Managers.HoverManager (this);

        event_bus.request_zoom.connect (on_request_zoom);

        get_bounds (out bounds_x, out bounds_y, out bounds_w, out bounds_h);
    }

    public void set_cursor_by_edit_mode () {
        if (_edit_mode == EditMode.MODE_SELECTION) {
            set_cursor (Gdk.CursorType.ARROW);
        } else {
            set_cursor (Gdk.CursorType.CROSSHAIR);
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

            default:
                if (uppercase_keyval <= Gdk.Key.Z && uppercase_keyval >= Gdk.Key.A) {
                    // Send to ItemsManager to deal with custom user shape
                    // hotkey preferences from settings
                    edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
                    items_manager.set_insert_type_from_key (uppercase_keyval);

                    return true;
                }

                return false;
        }
    }

    public override bool button_press_event (Gdk.EventButton event) {
        holding = true;

        temp_event_x = event.x / current_scale;
        temp_event_y = event.y / current_scale;

        temp_event_converted = false;

        hover_manager.remove_hover_effect ();

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
                selected_bound_manager.reset_selection ();

                var new_item = items_manager.insert_item (event);
                selected_bound_manager.add_item_to_selection (new_item);

                selected_bound_manager.set_initial_coordinates (temp_event_x, temp_event_y);

                nob_manager.set_selected_by_name (Managers.NobManager.Nob.BOTTOM_RIGHT);
                break;

            case EditMode.MODE_SELECTION:
                Models.CanvasItem clicked_item = (Models.CanvasItem) get_item_at (temp_event_x, temp_event_y, true);

                if (clicked_item == null) {
                    selected_bound_manager.reset_selection ();

                    // Workaround: when no item is clicked, there's no point in keeping holding active
                    holding = false;
                    return true;
                }

                var clicked_nob_name = nob_manager.get_grabbed_id (clicked_item);
                nob_manager.set_selected_by_name (clicked_nob_name);

                selected_bound_manager.set_initial_coordinates (temp_event_x, temp_event_y);

                if (clicked_nob_name == Managers.NobManager.Nob.NONE) {
                    selected_bound_manager.reset_selection ();

                    // Item has been selected
                    selected_bound_manager.add_item_to_selection (clicked_item);
                }

                break;
        }

        return true;

        /*
        Goo.CanvasItem clicked_item;

        if (edit_mode == EditMode.MODE_INSERT) {
            remove_select_effect ();
            var item = insert_object (event);
            selected_item = item;
            add_hover_effect (item);
            add_select_effect (item);
            clicked_item = nobs[Nob.BOTTOM_RIGHT];
        } else {
            clicked_item = get_item_at (temp_event_x, temp_event_y, true);
        }

        if (clicked_item != null && clicked_item != selected_item && clicked_item != select_effect
            && clicked_item != hover_effect) {
            var clicked_id = get_grabbed_id (clicked_item);
            holding = true;

            if (clicked_id == Nob.NONE) {
                remove_select_effect ();
                add_select_effect (clicked_item);
                grab_focus (clicked_item);
                selected_item = clicked_item;
                holding_id = Nob.NONE;
            } else { // nob was clicked
                holding_id = clicked_id;
            }
        }

        if (clicked_item == selected_item && selected_item != null) {
            holding = true;
            holding_id = Nob.NONE;
        }

        if (clicked_item == null) {
            remove_select_effect ();
            focus_canvas ();
        }

        return true;
        */
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) {
            return false;
        }

        holding = false;

        //item_moved (selected_item);
        //add_hover_effect (selected_item);

        edit_mode = EditMode.MODE_SELECTION;

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        var event_x = event.x / current_scale;
        var event_y = event.y / current_scale;

        event_bus.coordinate_change (event_x, event_y);

        if (!holding) {
            // Only motion_hover_effect
            hover_manager.add_hover_effect (event_x, event_y);
            return false;
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
            case EditMode.MODE_SELECTION:
                var selected_nob = nob_manager.get_selected_nob ();
                selected_bound_manager.transform_bound (event_x, event_y, selected_nob);
                break;
        }

        return true;
    }

    public void focus_canvas () {
        edit_mode = EditMode.MODE_SELECTION;
        grab_focus (get_root_item ());
    }

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

    private void on_request_zoom (string direction) {
        event_bus.emit ("zoom");
    }

    /*
    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (!holding) {
            motion_hover_event (event);
            return false;
        }
        var event_x = event.x / current_scale;
        var event_y = event.y / current_scale;

        convert_to_item_space (selected_item, ref event_x, ref event_y);

        //  debug ("event x: %f", event_x);
        //  debug ("event y: %f", event_y);

        if (!temp_event_converted) {
            convert_to_item_space (selected_item, ref temp_event_x, ref temp_event_y);
            temp_event_converted = true;
        }

        //  debug ("temp event x: %f", temp_event_x);
        //  debug ("temp event y: %f", temp_event_y);

        delta_x = event_x - temp_event_x;
        delta_y = event_y - temp_event_y;

        //  debug ("delta x: %f", delta_x);
        //  debug ("delta y: %f", delta_y);

        double x, y, width, height;
        selected_item.get ("x", out x, "y", out y, "width", out width, "height", out height);

        //  debug ("x: %f", x);
        //  debug ("y: %f", y);

        var new_height = height;
        var new_width = width;

        var new_delta_x = delta_x;
        var new_delta_y = delta_y;

        var canvas_x = x;
        var canvas_y = y;
        convert_from_item_space (selected_item, ref canvas_x, ref canvas_y);

        //  debug ("new delta x: %f", new_delta_x);
        //  debug ("new delta y: %f", new_delta_y);

        //  debug ("height: %f", height);
        //  debug ("width: %f", width);

        bool update_x = new_delta_x != 0;
        bool update_y = new_delta_y != 0;

        //  debug ("update x: %s", update_x.to_string ());
        //  debug ("update y: %s", update_y.to_string ());

        switch (holding_id) {
            case Nob.NONE: // Moving
                double move_x = fix_x_position (canvas_x, width, delta_x);
                double move_y = fix_y_position (canvas_y, height, delta_y);
                //  debug ("move x %f", move_x);
                //  debug ("move y %f", move_y);
                selected_item.translate (move_x, move_y);
                event_x -= move_x;
                event_y -= move_y;
                break;
            case Nob.ROTATE:
                var center_x = x + width / 2;
                var center_y = y + height / 2;

                //  debug ("center x: %f", center_x);
                //  debug ("center y: %f", center_y);

                var start_radians = GLib.Math.atan2 (center_y - temp_event_y, temp_event_x - center_x);
                //  debug ("start_radians %f, atan2(%f - %f, %f - %f)", start_radians, center_y, temp_event_y, temp_event_x, center_x);
                var radians = GLib.Math.atan2 (center_y - event_y, event_x - center_x);
                //  debug ("radians %f, atan2(%f - %f, %f - %f)", radians, center_y, event_y, event_x, center_x);
                radians = start_radians - radians;
                double rotation = radians * (180 / Math.PI);
                //  debug ("rotation: %f", rotation);

                convert_from_item_space (selected_item, ref event_x, ref event_y);
                selected_item.rotate (rotation, center_x, center_y);
                rotation += selected_item.get_data<double?> ("rotation");
                selected_item.set_data<double?> ("rotation", rotation);
                convert_to_item_space (selected_item, ref event_x, ref event_y);
                break;
        }

        //  debug ("new width: %f", new_width);
        //  debug ("new height: %f", new_height);

        //  debug ("update x: %s", update_x.to_string ());
        //  debug ("update y: %s", update_y.to_string ());

        selected_item.set ("width", new_width, "height", new_height);

        update_nob_position (selected_item);
        update_select_effect (selected_item);

        if (update_x) {
            temp_event_x = event_x;
            //  debug ("temp event x: %f", temp_event_x);
        }
        if (update_y) {
            temp_event_y = event_y;
            //  debug ("temp event y: %f", temp_event_y);
        }

        return true;
    }
    */

    /*
    private void motion_hover_event (Gdk.EventMotion event) {
        var hovered_item = get_item_at (event.x / get_scale (), event.y / get_scale (), true);

        if (!(hovered_item is Goo.CanvasItemSimple)) {
            remove_hover_effect ();
            return;
        }

        add_hover_effect (hovered_item);

        double check_x;
        double check_y;
        hovered_item.get ("x", out check_x, "y", out check_y);

        if ((hover_x != check_x || hover_y != check_y) && hover_effect != hovered_item) {
            remove_hover_effect ();
        }

        hover_x = check_x;
        hover_y = check_y;
    }

    public void reset_select () {
        remove_select_effect (true);
        current_scale = get_scale ();
        add_select_effect (selected_item);
    }


    private void remove_hover_effect () {
        set_cursor_by_edit_mode ();

        if (hover_effect == null) {
            return;
        }

        hover_effect.remove ();
        hover_effect = null;
    }
    */

    private void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    /*
    public void delete_selected () {
        if (selected_item != null) {
            selected_item.remove ();

            var artboard = window.main_window.right_sidebar.layers_panel.artboard;
            Akira.Layouts.Partials.Layer layer = selected_item.get_data<Akira.Layouts.Partials.Layer?> ("layer");
            if (layer != null) {
                artboard.container.remove (layer);
            }
            remove_select_effect ();
            remove_hover_effect ();
        }
    }
    */
}
