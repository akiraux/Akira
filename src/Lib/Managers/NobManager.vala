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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Managers.NobManager : Object {
    /*
        Grabber Pos:   8
                     0 1 2
                     7   3
                     6 5 4

        // -1 if no nub is grabbed
    */
    public enum Nob {
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

    public weak Goo.Canvas canvas { get; construct; }

    private Goo.CanvasItem root;
    private Goo.CanvasItem select_effect;
    private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];
    private Nob selected_nob;
    private double top;
    private double left;
    private double width;
    private double height;
    private double nob_size;
    private double current_scale;
    private int holding_id = Nob.NONE;

    public NobManager (Goo.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();

        on_zoom ();

        event_bus.selected_items_bb_changed.connect (on_add_select_effect);
        event_bus.zoom.connect (on_zoom);
    }

    public void set_selected_by_name (Nob selected_nob) {
        this.selected_nob = selected_nob;
    }

    public Nob get_selected_nob () {
        return selected_nob;
    }

    public Nob get_grabbed_id (Goo.CanvasItem? target) {
        int grabbed_id = -1;

        for (int i = 0; i < 9; i++) {
            if (target == nobs[i]) grabbed_id = i;
        }

        return (Nob) grabbed_id;
    }

    private void on_zoom () {
        current_scale = canvas.get_scale ();
    }

    private void update_select_bb_coords (Goo.CanvasBounds select_bb) {
        top = select_bb.y1;
        left = select_bb.x1;
        width = select_bb.x2 - select_bb.x1;
        height = select_bb.y2 - select_bb.y1;
    }

    private void on_add_select_effect (Goo.CanvasBounds? select_bb) {
        remove_select_effect ();

        if (select_bb == null) {
            return;
        }

        update_select_bb_coords (select_bb);

        /*
        var fills_list_model = window.main_window.left_sidebar.fill_box_panel.fills_list_model;
        if (fills_list_model != null) {
            fills_list_model.add.begin (item);
        }
        */

        var line_width = 1.0 / current_scale;

        if (select_effect == null) {
            select_effect = new Goo.CanvasRect (
                null,
                left, top,
                0, 0,
                "line-width", line_width,
                "stroke-color", "#666",
                null
            );
        }

        update_select_effect (select_bb);

        select_effect.set ("parent", root);

        nob_size = 10 / current_scale;

        for (int i = 0; i < 9; i++) {
            var radius = i == 8 ? nob_size : 0;
            nobs[i] = new Goo.CanvasRect (
                null,
                0, 0, nob_size, nob_size,
                "line-width", line_width,
                "radius-x", radius,
                "radius-y", radius,
                "stroke-color", "#41c9fd",
                "fill-color", "#fff",
                null
            );

            nobs[i].set ("parent", root);
        }

        update_nob_position (select_bb);

        //select_effect.can_focus = false;
    }

    private void remove_select_effect (bool keep_selection = false) {
        if (select_effect == null) {
            return;
        }

        /*
        var fills_list_model = window.main_window.left_sidebar.fill_box_panel.fills_list_model;
        if (fills_list_model != null) {
            fills_list_model.clear.begin ();
        }
        */

        select_effect.remove ();
        select_effect = null;

        for (int i = 0; i < 9; i++) {
            nobs[i].remove ();
        }
    }

    // Updates all the nub's position arround the selected item, except for the grabbed nub
    private void update_nob_position (Goo.CanvasBounds select_bb) {
        var stroke = 0;
        var x = left;
        var y = top;

        bool print_middle_width_nobs = width > nob_size * 3;
        bool print_middle_height_nobs = height > nob_size * 3;

        var nob_offset = (nob_size / 2);

        var transform = Cairo.Matrix.identity ();
        //item.get_transform (out transform);

        // TOP LEFT nob
        nobs[Nob.TOP_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.TOP_LEFT].translate (x - (nob_offset + stroke), y - (nob_offset + stroke));
        } else {
          nobs[Nob.TOP_LEFT].translate (x - nob_size - stroke, y - nob_size - stroke);
        }
        nobs[Nob.TOP_LEFT].raise (select_effect);

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
        nobs[Nob.TOP_CENTER].raise (select_effect);

        // TOP RIGHT nob
        nobs[Nob.TOP_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.TOP_RIGHT].translate (x + width - (nob_offset - stroke), y - (nob_offset + stroke));
        } else {
          nobs[Nob.TOP_RIGHT].translate (x + width + stroke, y - (nob_size + stroke));
        }
        nobs[Nob.TOP_RIGHT].raise (select_effect);

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
        nobs[Nob.RIGHT_CENTER].raise (select_effect);

        // BOTTOM RIGHT nob
        nobs[Nob.BOTTOM_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.BOTTOM_RIGHT].translate (x + width - (nob_offset - stroke), y + height - (nob_offset - stroke));
        } else {
          nobs[Nob.BOTTOM_RIGHT].translate (x + width + stroke, y + height + stroke);
        }
        nobs[Nob.BOTTOM_RIGHT].raise (select_effect);

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
        nobs[Nob.BOTTOM_CENTER].raise (select_effect);

        // BOTTOM LEFT nob
        nobs[Nob.BOTTOM_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
          nobs[Nob.BOTTOM_LEFT].translate (x - (nob_offset + stroke), y + height - (nob_offset - stroke));
        } else {
          nobs[Nob.BOTTOM_LEFT].translate (x - (nob_size + stroke), y + height + stroke);
        }
        nobs[Nob.BOTTOM_LEFT].raise (select_effect);

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
        nobs[Nob.LEFT_CENTER].raise (select_effect);

        // ROTATE nob
        double distance = 40;
        if (current_scale < 1) {
            distance = 40 * (2 * current_scale - 1);
        }

        nobs[Nob.ROTATE].set_transform (transform);
        nobs[Nob.ROTATE].translate (x + (width / 2) - nob_offset, y - nob_offset - distance);
        nobs[Nob.ROTATE].raise (select_effect);
    }

    private void update_select_effect (Goo.CanvasBounds select_bb) {
        select_effect.set (
            "x", left,
            "y", top,
            "width", width,
            "height", height
        );

        /*
        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);
        select_effect.set_transform (transform);
        */
    }

    /*
    public void update_decorations (Goo.CanvasItem item) {
        update_nob_position (item);
        update_select_effect (item);
    }

    private void update_effects (Object object, ParamSpec spec) {
        //  debug ("update effects, param: %s", spec.name);
        update_decorations ((Goo.CanvasItem) object);
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


    */
}
