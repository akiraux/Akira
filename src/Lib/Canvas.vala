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

    public Goo.CanvasItem? selected_item;
    public Goo.CanvasRect select_effect;

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

    private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];

    private weak Goo.CanvasItem? hovered_item;
    private Goo.CanvasRect? hover_effect;

    private bool holding;
    private double event_x_root;
    private double event_y_root;
    private double start_x;
    private double start_y;
    private double start_w;
    private double start_h;
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

    construct {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
        get_bounds(out bounds_x, out bounds_y, out bounds_w, out bounds_h);
    }

    public override bool button_press_event (Gdk.EventButton event) {
        remove_hover_effect ();

        current_scale = get_scale ();
        event_x_root = event.x;
        event_y_root = event.y;

        var clicked_item = get_item_at (event.x / current_scale, event.y / current_scale, true);

        if (clicked_item != null) {
            var clicked_id = get_grabbed_id (clicked_item);
            holding = true;

            if (clicked_id == Nob.NONE) { // Non-nub was clicked
                remove_select_effect ();
                if (clicked_item is Goo.CanvasItemSimple) {
                    clicked_item.get ("x", out start_x, "y", out start_y, "width", out start_w, "height", out start_h);
                    print("start event: start_x %f, start_y %f, start_w %f, start_h %f\n", start_x, start_y, start_w, start_h);
                }

                add_select_effect (clicked_item);
                grab_focus (clicked_item);

                selected_item = clicked_item;
                holding_id = Nob.NONE;
            } else { // nub was clicked
                selected_item.get ("x", out start_x, "y", out start_y);
                holding_id = clicked_id;
            }
        } else {
            remove_select_effect ();
            grab_focus (get_root_item ());
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) return false;

        holding = false;

        if (delta_x == 0 && delta_y == 0) { // Hidden for now. Just change poss && (start_w == real_width) && (start_h == real_height)) {
            return false;
        }

        selected_item.get ("x", out start_x, "y", out start_y, "width", out start_w, "height", out start_h);
        print("release event: start_x %f, start_y %f, start_w %f, start_h %f\n", start_x, start_y, start_w, start_h);
        item_moved (selected_item);
        add_hover_effect (selected_item);

        delta_x = 0;
        delta_y = 0;


        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (!holding) {
            motion_hover_event (event);
            return false;
        }

        delta_x = (event.x - event_x_root) / current_scale;
        delta_y = (event.y - event_y_root) / current_scale;

        print("delta_x: %f\n", delta_x);
        print("delta_y: %f\n", delta_y);

        var new_x = start_x;
        var new_y = start_y;
        var new_width = start_w;
        var new_height = start_h;

        switch (holding_id) {
            case Nob.NONE: // Moving
                new_x = fix_x_position ((delta_x + start_x), start_w);
                new_y = fix_y_position ((delta_y + start_y), start_h);
                break;
            case Nob.TOP_LEFT:
                new_x = fix_size (delta_x + start_x);
                new_y = fix_size (delta_y + start_y);
                new_width = fix_size (start_w - delta_x);
                new_height = fix_size (start_h - delta_y);
                break;
            case Nob.TOP_CENTER:
                new_y = delta_y + start_y;
                new_height = start_h - delta_y;
                break;
            case Nob.TOP_RIGHT:
                new_x = start_x;
                new_y = fix_size (delta_y + start_y);
                new_width = fix_size (start_w + delta_x);
                new_height = fix_size (start_h - delta_y);
                break;
            case Nob.RIGHT_CENTER:
                new_width = start_w + delta_x;
                break;
            case Nob.BOTTOM_RIGHT:
                new_width = fix_size (start_w + delta_x);
                new_height = fix_size (start_h + delta_y);
                break;
            case Nob.BOTTOM_CENTER:
                new_height = fix_size (start_h + delta_y);
                break;
            case Nob.BOTTOM_LEFT:
                new_x = fix_size(delta_x + start_x);
                new_width = fix_size (start_w - delta_x);
                new_height = fix_size (start_h + delta_y);
                break;
            case Nob.LEFT_CENTER:
                new_x = delta_x + start_x;
                new_width = start_w - delta_x;
                break;
            case Nob.ROTATE:
                break;
            default:
                print("grab rotate");
                break;
        }
        selected_item.set ("x", new_x, "y", new_y, "width", new_width, "height", new_height);

        update_nob_position (selected_item);
        update_select_effect (selected_item);

        return false;
    }

    private void motion_hover_event (Gdk.EventMotion event) {
        hovered_item = get_item_at (event.x / get_scale (), event.y / get_scale (), true);

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
        if (target == null || target == select_effect) {
            return;
        }

        double x, y;
        target.get ("x", out x, "y", out y);

        var item = (target as Goo.CanvasItemSimple);

        var line_width = 1.0 / current_scale;
        var real_x = x - (line_width * 2);
        var real_y = y - (line_width * 2);
        var width = item.bounds.x2 - item.bounds.x1;
        var height = item.bounds.y2 - item.bounds.y1;

        select_effect = new Goo.CanvasRect (null, real_x, real_y, width, height,
                                   "line-width", line_width,
                                   "stroke-color", "#666", null
                                   );

        select_effect.set ("parent", get_root_item ());

        nob_size = 10 / current_scale;

        for (int i = 0; i < 9; i++) {
            var radius = i == 8 ? nob_size : 0;
            nobs[i] = new Goo.CanvasRect (null, 0, 0, nob_size, nob_size,
                "line-width", line_width,
                "radius-x", radius,
                "radius-y", radius,
                "stroke-color", "#41c9fd",
                "fill-color", "#fff", null
            );
            nobs[i].set ("parent", get_root_item ());
        }

        update_nob_position (target);
        select_effect.can_focus = false;
    }

    private void update_select_effect (Goo.CanvasItem? target) {
        if (target == null || target == select_effect) {
            return;
        }

        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);

        var item = (target as Goo.CanvasItemSimple);
        var stroke = (item.line_width / 2);
        var line_width = 1.0 / current_scale;
        var real_x = x - (line_width * 2);
        var real_y = y - (line_width * 2);

        select_effect.set ("x", real_x, "y", real_y, "width", width + (stroke * 2), "height", height + (stroke * 2));
    }

    private void remove_select_effect () {
        if (select_effect == null) {
            return;
        }

        select_effect.remove ();
        select_effect = null;
        selected_item = null;

        for (int i = 0; i < 9; i++) {
            nobs[i].remove ();
        }
    }

    public void reset_select () {
        if (selected_item == null && select_effect == null) {
            return;
        }

        select_effect.remove ();
        select_effect = null;

        for (int i = 0; i < 9; i++) {
            nobs[i].remove ();
        }

        current_scale = get_scale ();
        add_select_effect (selected_item);
    }

    private void add_hover_effect (Goo.CanvasItem? target) {
        if (target == null || hover_effect != null || target == selected_item || target == select_effect) {
            return;
        }

        if ((target as Goo.CanvasItemSimple) in nobs) {
            set_cursor_for_nob (get_grabbed_id (target));
            return;
        }

        double x, y;
        target.get ("x", out x, "y", out y);

        var item = (target as Goo.CanvasItemSimple);

        var line_width = 2.0 / get_scale ();
        var stroke = item.line_width;
        var real_x = x - (line_width * 2);
        var real_y = y - (line_width * 2);
        var width = item.bounds.x2 - item.bounds.x1 + stroke - line_width;
        var height = item.bounds.y2 - item.bounds.y1 + stroke - line_width;

        hover_effect = new Goo.CanvasRect (null, real_x, real_y, width, height,
                                   "line-width", line_width,
                                   "stroke-color", "#41c9fd", null
                                   );
        hover_effect.set ("parent", get_root_item ());

        hover_effect.can_focus = false;
    }

    private void remove_hover_effect () {
        set_cursor (Gdk.CursorType.ARROW);

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
                set_cursor (Gdk.CursorType.ARROW);
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
    // TODO: concider item rotation into account
    private void update_nob_position (Goo.CanvasItem target) {
        var item = (target as Goo.CanvasItemSimple);

        var stroke = (item.line_width / 2);
        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);
        var middle = (nob_size / 2) + stroke;
        var middle_stroke = (nob_size / 2) - stroke;

        // TOP LEFT nob
        nobs[Nob.TOP_LEFT].set ("x", x - middle, "y", y - middle);

        // TOP CENTER nob
        nobs[Nob.TOP_CENTER].set ("x", x + (width / 2) - middle, "y", y - middle);

        // TOP RIGHT nob
        nobs[Nob.TOP_RIGHT].set ("x", x + width - middle_stroke, "y", y - middle);

        // RIGHT CENTER nob
        nobs[Nob.RIGHT_CENTER].set ("x", x + width - middle_stroke,
                    "y", y + (height / 2) - middle);

        // BOTTOM RIGHT nob
        nobs[Nob.BOTTOM_RIGHT].set ("x", x + width - middle_stroke,
                    "y", y + height - middle_stroke);

        // BOTTOM CENTER nob
        nobs[Nob.BOTTOM_CENTER].set ("x", x + (width / 2) - middle,
                    "y", y + height - middle_stroke);

        // BOTTOM LEFT nob
        nobs[Nob.BOTTOM_LEFT].set ("x", x - middle,
                    "y", y + height - middle_stroke);

        // LEFT CENTER nob
        nobs[Nob.LEFT_CENTER].set ("x", x - middle,
                    "y", y + (height / 2) - middle);

        // ROTATE nob
        double distance = 40;
        if (current_scale < 1) {
            distance = 40 + ((40 - (40 * current_scale)) * 2);
        }

        nobs[Nob.ROTATE].set ("x", x + (width / 2) - middle,
                    "y", y - (nob_size / 2) - distance);
    }

    private void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    // To make it so items can't become imposible to grab. TODOs
    private double fix_y_position (double y, double height) {
        var min_delta = (MIN_POS - height) * current_scale;
        var max_delta = (bounds_h + height - MIN_POS) * current_scale;
        print("min_y_delta %f\n", min_delta);
        print("max_y_delta %f\n", max_delta);
        if (y < min_delta) {
            return Math.round (min_delta);
        } else if (y > max_delta) {
            return Math.round (max_delta);
        } else {
            return Math.round (y);
        }
    }

    // To make it so items can't become imposible to grab. TODOs
    private double fix_x_position (double x, double width) {
        var min_delta = (MIN_POS - width) * current_scale;
        var max_delta = (bounds_h + width - MIN_POS) * current_scale;
        print("min_x_delta %f\n", min_delta);
        print("max_x_delta %f\n", max_delta);
        if (x < min_delta) {
            return Math.round (min_delta);
        } else if (x > max_delta) {
            return Math.round (max_delta);
        } else {
            return Math.round (x);
        }
    }

    private double fix_size (double size) {
        return size > MIN_SIZE ? Math.round (size) : MIN_SIZE;
    }
}
