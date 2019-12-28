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

    /*
        Grabber Pos:   8
                     0 1 2
                     7   3
                     6 5 4

        // -1 if no nub is grabbed
    */
    enum Nob {
        NONE=-1,
        TOP_LEFT,
        TOP_CENTER,
        TOP_RIGHT,
        RIGHT_CENTER,
        BOTTOM_RIGHT,
        BOTTOM_CENTER,
        BOTTOM_LEFT,
        LEFT_CENTER,
        ROTATE
    }

    public enum EditMode {
        MODE_SELECTION,
        MODE_INSERT
    }

    public enum InsertType {
        RECT,
        ELLIPSE,
        TEXT
    }

    private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];

    private Goo.CanvasRect? hover_effect;

    private bool holding;
    private bool temp_event_converted;
    private double temp_event_x;
    private double temp_event_y;
    private double delta_x;
    private double delta_y;
    private double hover_x;
    private double hover_y;
    private double nob_size;
    private double current_scale;
    private int holding_id = Nob.NONE;
    private double bounds_x;
    private double bounds_y;
    private double bounds_w;
    private double bounds_h;

    private double border_size;
    private string border_color;
    private string fill_color;

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
        get_bounds (out bounds_x, out bounds_y, out bounds_w, out bounds_h);
    }

    public void set_cursor_by_edit_mode () {
        if (_edit_mode == EditMode.MODE_SELECTION) {
            set_cursor (Gdk.CursorType.ARROW);
        } else {
            set_cursor (Gdk.CursorType.CROSSHAIR);
        }
    }

    public override bool button_press_event (Gdk.EventButton event) {
        remove_hover_effect ();

        current_scale = get_scale ();
        temp_event_x = event.x / current_scale;
        temp_event_y = event.y / current_scale;
        temp_event_converted = false;

        //  debug ("canvas temp event x: %f", temp_event_x);
        //  debug ("canvas temp event y: %f", temp_event_y);

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
                update_decorations (selected_item);
            }
        }
    }

    public Goo.CanvasItem? insert_object (Gdk.EventButton event) {
        udpate_default_values ();

        if (insert_type == InsertType.RECT) {
          return add_rect (event);
        } else if (insert_type == InsertType.ELLIPSE) {
          return add_ellipse (event);
        } else if (insert_type == InsertType.TEXT) {
          return add_text (event);
        }
        return null;
    }

    private void update_effects (Object object, ParamSpec spec) {
        //  debug ("update effects, param: %s", spec.name);
        update_decorations ((Goo.CanvasItem) object);
    }

    public void update_decorations (Goo.CanvasItem item) {
        update_nob_position (item);
        update_select_effect (item);
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) {
            return false;
        }

        holding = false;

        if (delta_x == 0 && delta_y == 0) {
            return false;
        }

        item_moved (selected_item);
        add_hover_effect (selected_item);

        delta_x = 0;
        delta_y = 0;

        edit_mode = EditMode.MODE_SELECTION;
        set_cursor_by_edit_mode ();

        return false;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_to_upper (event.keyval)) {
            case Gdk.Key.E:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
                insert_type = Akira.Lib.Canvas.InsertType.ELLIPSE;
                return true;
            case Gdk.Key.R:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
                insert_type = Akira.Lib.Canvas.InsertType.RECT;
                return true;
            case Gdk.Key.T:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_INSERT;
                insert_type = Akira.Lib.Canvas.InsertType.TEXT;
                return true;
            case Gdk.Key.Escape:
                edit_mode = Akira.Lib.Canvas.EditMode.MODE_SELECTION;
                insert_type = null;
                return true;
            case Gdk.Key.Delete:
                delete_selected ();
                return true;
        }

        return false;
    }

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
            case Nob.TOP_LEFT:
                update_x = event_x < x + width;
                update_y = event_y < y + height;
                if (MIN_SIZE > height - new_delta_y) {
                   new_delta_y = 0;
                }
                if (MIN_SIZE > width - new_delta_x) {
                   new_delta_x = 0;
                }
                selected_item.translate (new_delta_x, new_delta_y);
                event_x -= new_delta_x;
                event_y -= new_delta_y;
                new_width = fix_size (width - new_delta_x);
                new_height = fix_size (height - new_delta_y);
                break;
            case Nob.TOP_CENTER:
                update_y = event_y < y + height;
                if (MIN_SIZE > height - new_delta_y) {
                   new_delta_y = 0;
                }
                new_height = fix_size (height - new_delta_y);
                selected_item.translate (0, new_delta_y);
                event_y -= new_delta_y;
                break;
            case Nob.TOP_RIGHT:
                update_x = event_x > x;
                if (!update_x) {
                    new_delta_x = 0;
                }
                update_y = event_y < y + height;
                new_width = fix_size (width + new_delta_x);
                if (!update_y) {
                    new_delta_y = 0;
                }
                if (new_delta_y < height) {
                    selected_item.translate (0, new_delta_y);
                    //  debug ("translate: %f,%f", 0, new_delta_y);
                    event_y -= new_delta_y;
                    new_height = fix_size (height - new_delta_y);
                }
                break;
            case Nob.RIGHT_CENTER:
                update_x = event_x > x;
                if (!update_x) {
                    new_delta_x = 0;
                }
                new_width = fix_size (width + new_delta_x);
                break;
            case Nob.BOTTOM_RIGHT:
                update_x = event_x > x;
                update_y = event_y > y;
                new_width = fix_size (width + new_delta_x);
                new_height = fix_size (height + new_delta_y);
                break;
            case Nob.BOTTOM_CENTER:
                update_y = event_y > y;
                if (!update_y) {
                    new_delta_y = 0;
                }
                new_height = fix_size (height + new_delta_y);
                break;
            case Nob.BOTTOM_LEFT:
                if (new_delta_x > width) {
                   new_delta_x = 0;
                }
                update_y = event_y > y;
                update_x = event_x < x + width;
                if (!update_x) {
                    new_delta_x = 0;
                }
                if (new_delta_y == 0) {
                    if (delta_y > 0 && update_y) {
                        new_delta_y = delta_y;
                    } else {
                        break;
                    }
                }
                //  debug ("translate: %f,%f", new_delta_x, 0);
                selected_item.translate (new_delta_x, 0);
                event_x -= new_delta_x;
                new_width = fix_size (width - new_delta_x);
                new_height = fix_size (height + new_delta_y);
                break;
            case Nob.LEFT_CENTER:
                update_x = event_x < x + width;
                if (new_delta_x < width) {
                    selected_item.translate (new_delta_x, 0);
                    event_x -= new_delta_x;
                    new_width = fix_size (width - new_delta_x);
                }
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

    private void add_select_effect (Goo.CanvasItem? target) {
        if (target == null || target == select_effect || target == hover_effect) {
            return;
        }

        double x, y;
        target.get ("x", out x, "y", out y);

        var item = (target as Goo.CanvasItemSimple);

        var fills_list_model = window.main_window.left_sidebar.fill_box_panel.fills_list_model;
        if (fills_list_model != null) {
            fills_list_model.add.begin (item);
        }

        var line_width = 1.0 / current_scale;
        var stroke = item.line_width / 2;
        var real_x = x - stroke;
        var real_y = y - stroke;

        select_effect = new Goo.CanvasRect (null, real_x, real_y, 0, 0,
                                            "line-width", line_width,
                                            "stroke-color", "#666", null);

        update_select_effect (target);

        select_effect.set ("parent", get_root_item ());

        nob_size = 10 / current_scale;

        for (int i = 0; i < 9; i++) {
            nobs[i] = new Selection.Nob (get_root_item (), current_scale, i);
            //  nobs[i].update_position (target, select_effect);
        }

        update_nob_position (target);
        select_effect.can_focus = false;

        item.notify.connect (update_effects);
    }

    private void update_select_effect (Goo.CanvasItem? target) {
        if (select_effect == null || target == null || target == select_effect) {
            return;
        }

        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);

        var item = (target as Goo.CanvasItemSimple);
        var stroke = item.line_width / 2;
        var real_width = width + stroke * 2;
        var real_height = height + stroke * 2;

        select_effect.set ("x", x , "y", y, "width", real_width, "height", real_height);
        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);
        select_effect.set_transform (transform);
    }

    private void remove_select_effect (bool keep_selection = false) {
        if (select_effect == null || selected_item == null) {
            return;
        }

        var fills_list_model = window.main_window.left_sidebar.fill_box_panel.fills_list_model;
        if (fills_list_model != null) {
            fills_list_model.clear.begin ();
        }

        select_effect.remove ();
        select_effect = null;

        if (selected_item != null && !keep_selection) {
            selected_item.notify.disconnect (update_effects);
            selected_item = null;
        }

        for (int i = 0; i < 9; i++) {
            nobs[i].remove ();
        }
    }

    public void reset_select () {
        remove_select_effect (true);
        current_scale = get_scale ();
        add_select_effect (selected_item);
    }

    private void add_hover_effect (Goo.CanvasItem? target) {
        if (target == null || hover_effect != null || target == selected_item || target == select_effect
            || edit_mode == EditMode.MODE_INSERT) {
            return;
        }

        if ((target as Goo.CanvasItemSimple) in nobs) {
            set_cursor_for_nob (get_grabbed_id (target));
            return;
        }

        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);

        var item = (target as Goo.CanvasItemSimple);

        var line_width = 2.0 / get_scale ();
        var stroke = item.line_width;
        var real_x = x - stroke;
        var real_y = y - stroke;
        var real_width = width + stroke * 2;
        var real_height = height + stroke * 2;

        hover_effect = new Goo.CanvasRect (null, real_x, real_y, real_width, real_height,
                                           "line-width", line_width, "stroke-color", "#41c9fd", null);
        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);
        hover_effect.set_transform (transform);

        hover_effect.set ("parent", get_root_item ());
        hover_effect.can_focus = false;
    }

    private void remove_hover_effect () {
        set_cursor_by_edit_mode ();

        if (hover_effect == null) {
            return;
        }

        hover_effect.remove ();
        hover_effect = null;
    }

    private int get_grabbed_id (Goo.CanvasItem? target) {
        for (int i = 0; i < 9; i++) {
            if (target == nobs[i]) return i;
        }

        return Nob.NONE;
    }

    private void set_cursor_for_nob (int grabbed_id) {
        switch (grabbed_id) {
            case Nob.NONE:
                set_cursor_by_edit_mode ();
                break;
            case Nob.TOP_LEFT:
                set_cursor (Gdk.CursorType.TOP_LEFT_CORNER);
                break;
            case Nob.TOP_CENTER:
                set_cursor (Gdk.CursorType.TOP_SIDE);
                break;
            case Nob.TOP_RIGHT:
                set_cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
                break;
            case Nob.RIGHT_CENTER:
                set_cursor (Gdk.CursorType.RIGHT_SIDE);
                break;
            case Nob.BOTTOM_RIGHT:
                set_cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
                break;
            case Nob.BOTTOM_CENTER:
                set_cursor (Gdk.CursorType.BOTTOM_SIDE);
                break;
            case Nob.BOTTOM_LEFT:
                set_cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);
                break;
            case Nob.LEFT_CENTER:
                set_cursor (Gdk.CursorType.LEFT_SIDE);
                break;
            case Nob.ROTATE:
                set_cursor (Gdk.CursorType.ICON);
                break;
        }
    }

    // Updates all the nub's position arround the selected item, except for the grabbed nub
    private void update_nob_position (Goo.CanvasItem target) {
        if (select_effect == null) {
            return;
        }

        var item = (target as Goo.CanvasItemSimple);

        var stroke = (item.line_width / 2);
        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);

        bool print_middle_width_nobs = width > nob_size * 3;
        bool print_middle_height_nobs = height > nob_size * 3;

        var nob_offset = (nob_size / 2);

        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);

        // TOP LEFT nob
        nobs[Nob.TOP_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.TOP_LEFT].translate (x - (nob_offset + stroke), y - (nob_offset + stroke));
        } else {
          nobs[Nob.TOP_LEFT].translate (x - nob_size - stroke, y - nob_size - stroke);
        }
        nobs[Nob.TOP_LEFT].raise (item);

        if (print_middle_width_nobs) {
          // TOP CENTER nob
          nobs[Nob.TOP_CENTER].set_transform (transform);
          if (print_middle_height_nobs) {
            nobs[Nob.TOP_CENTER].translate (x + (width / 2) - nob_offset, y - (nob_offset + stroke));
          } else {
            nobs[Nob.TOP_CENTER].translate (x + (width / 2) - nob_offset, y - (nob_size + stroke));
          }
          nobs[Nob.TOP_CENTER].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        } else {
          nobs[Nob.TOP_CENTER].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        nobs[Nob.TOP_CENTER].raise (item);

        // TOP RIGHT nob
        nobs[Nob.TOP_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.TOP_RIGHT].translate (x + width - (nob_offset - stroke), y - (nob_offset + stroke));
        } else {
          nobs[Nob.TOP_RIGHT].translate (x + width + stroke, y - (nob_size + stroke));
        }
        nobs[Nob.TOP_RIGHT].raise (item);

        if (print_middle_height_nobs) {
          // RIGHT CENTER nob
          nobs[Nob.RIGHT_CENTER].set_transform (transform);
          if (print_middle_width_nobs) {
            nobs[Nob.RIGHT_CENTER].translate (x + width - (nob_offset - stroke), y + (height / 2) - nob_offset);
          } else {
            nobs[Nob.RIGHT_CENTER].translate (x + width + stroke, y + (height / 2) - nob_offset);
          }
          nobs[Nob.RIGHT_CENTER].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        } else {
          nobs[Nob.RIGHT_CENTER].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        nobs[Nob.RIGHT_CENTER].raise (item);

        // BOTTOM RIGHT nob
        nobs[Nob.BOTTOM_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.BOTTOM_RIGHT].translate (x + width - (nob_offset - stroke), y + height - (nob_offset - stroke));
        } else {
          nobs[Nob.BOTTOM_RIGHT].translate (x + width + stroke, y + height + stroke);
        }
        nobs[Nob.BOTTOM_RIGHT].raise (item);

        if (print_middle_width_nobs) {
          // BOTTOM CENTER nob
          nobs[Nob.BOTTOM_CENTER].set_transform (transform);
          if (print_middle_height_nobs) {
            nobs[Nob.BOTTOM_CENTER].translate (x + (width / 2) - nob_offset, y + height - (nob_offset - stroke));
          } else {
            nobs[Nob.BOTTOM_CENTER].translate (x + (width / 2) - nob_offset, y + height + stroke);
          }
          nobs[Nob.BOTTOM_CENTER].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        } else {
          nobs[Nob.BOTTOM_CENTER].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        nobs[Nob.BOTTOM_CENTER].raise (item);

        // BOTTOM LEFT nob
        nobs[Nob.BOTTOM_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.BOTTOM_LEFT].translate (x - (nob_offset + stroke), y + height - (nob_offset - stroke));
        } else {
          nobs[Nob.BOTTOM_LEFT].translate (x - (nob_size + stroke), y + height + stroke);
        }
        nobs[Nob.BOTTOM_LEFT].raise (item);

        if (print_middle_height_nobs) {
          // LEFT CENTER nob
          nobs[Nob.LEFT_CENTER].set_transform (transform);
          if (print_middle_width_nobs) {
            nobs[Nob.LEFT_CENTER].translate (x - (nob_offset + stroke), y + (height / 2) - nob_offset);
          } else {
            nobs[Nob.LEFT_CENTER].translate (x - (nob_size + stroke), y + (height / 2) - nob_offset);
          }
          nobs[Nob.LEFT_CENTER].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        } else {
          nobs[Nob.LEFT_CENTER].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        nobs[Nob.LEFT_CENTER].raise (item);

        // ROTATE nob
        double distance = 40;
        if (current_scale < 1) {
            distance = 40 * (2 * current_scale - 1);
        }

        nobs[Nob.ROTATE].set_transform (transform);
        nobs[Nob.ROTATE].translate (x + (width / 2) - nob_offset, y - nob_offset - distance);
        nobs[Nob.ROTATE].raise (item);
    }

    private void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    private double fix_y_position (double y, double height, double delta_y) {
        var min_delta = Math.round ((MIN_POS - height) * current_scale);
        //  debug ("min delta y %f", min_delta);
        var max_delta = Math.round ((bounds_h - MIN_POS) * current_scale);
        //  debug ("max delta y %f", max_delta);
        var new_y = Math.round (y + delta_y);
        if (new_y < min_delta) {
            return 0;
        } else if (new_y > max_delta) {
            return 0;
        } else {
            return delta_y;
        }
    }

    private double fix_x_position (double x, double width, double delta_x) {
        var min_delta = Math.round ((MIN_POS - width) * current_scale);
        //  debug ("min delta x %f", min_delta);
        var max_delta = Math.round ((bounds_h - MIN_POS) * current_scale);
        //  debug ("max delta x %f", max_delta);
        var new_x = Math.round (x + delta_x);
        if (new_x < min_delta) {
            return 0;
        } else if (new_x > max_delta) {
            return 0;
        } else {
            return delta_x;
        }
    }

    private double fix_size (double size) {
        var new_size = Math.round (size);
        return new_size > MIN_SIZE ? new_size : MIN_SIZE;
    }

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

    public Goo.CanvasRect add_rect (Gdk.EventButton event) {
        var root = get_root_item ();
        //  debug ("fill color %s", fill_color);
        var rect = new Goo.CanvasRect (null, event.x, event.y, 1, 1,
                                       "line-width", border_size,
                                       "radius-x", 0.0,
                                       "radius-y", 0.0,
                                       "stroke-color", border_color,
                                       "fill-color", fill_color, null);

        rect.set ("parent", root);
        rect.set_transform (Cairo.Matrix.identity ());
        rect.set_data<double?> ("rotation", 0);
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, rect,
            "Rectangle", "shape-rectangle-symbolic", false);
        rect.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        init_item (rect);
        artboard.container.add (layer);
        artboard.show_all ();
        return rect;
    }

    public Goo.CanvasEllipse add_ellipse (Gdk.EventButton event) {
        var root = get_root_item ();
        var ellipse = new Goo.CanvasEllipse (null, event.x, event.y, 1, 1,
                                             "line-width", border_size,
                                             "stroke-color", border_color,
                                             "fill-color", fill_color);

        ellipse.set ("parent", root);
        ellipse.set_transform (Cairo.Matrix.identity ());
        ellipse.set_data<double?> ("rotation", 0);
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, ellipse,
            "Circle", "shape-circle-symbolic", false);
        ellipse.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        init_item (ellipse);
        artboard.container.add (layer);
        artboard.show_all ();
        return ellipse;
    }

    public Goo.CanvasText add_text (Gdk.EventButton event) {
        var root = get_root_item ();
        var text = new Goo.CanvasText (null, "Add text here", event.x, event.y, 200,
                                       Goo.CanvasAnchorType.NW, "font", "Open Sans 18");
        text.set ("parent", root);
        text.set ("height", 25f);
        text.set_transform (Cairo.Matrix.identity ());
        text.set_data<double?> ("rotation", 0);
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, text, "Text", "shape-text-symbolic", false);
        text.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        init_item (text);
        artboard.container.add (layer);
        artboard.show_all ();
        return text;
    }

    private void init_item (Object object) {
        object.set_data<int?> ("fill-alpha", 255);
        object.set_data<int?> ("stroke-alpha", 255);
        object.set_data<double?> ("opacity", 100);
    }

    public void udpate_default_values () {
        border_size = settings.set_border ? settings.border_size : 0.0;
        border_color = settings.set_border ? settings.border_color: "";
        fill_color = settings.fill_color;
    }
}
