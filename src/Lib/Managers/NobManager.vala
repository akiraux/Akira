/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Managers.NobManager : Object {
    private const string STROKE_COLOR = "#666";
    private const double LINE_WIDTH = 1.0;

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

    public weak Akira.Lib.Canvas canvas { get; construct; }

    public Nob selected_nob;

    private Goo.CanvasItem root;
    private Goo.CanvasItem select_effect;
    private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];
    private Goo.CanvasBounds select_bb;
    private double top;
    private double left;
    private double width;
    private double height;
    private double nob_size;

    // If the effect needs to be created or it's only a value update.
    private bool create { get; set; default = true; }

    public NobManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();

        canvas.window.event_bus.selected_items_changed.connect (on_add_select_effect);
        canvas.window.event_bus.zoom.connect (on_canvas_zoom);
        canvas.window.event_bus.hide_select_effect.connect (on_hide_select_effect);
        canvas.window.event_bus.show_select_effect.connect (on_show_select_effect);
    }

    private void on_canvas_zoom () {
        on_add_select_effect (canvas.selected_bound_manager.selected_items);
    }

    public void set_selected_by_name (Nob selected_nob) {
        this.selected_nob = selected_nob;
    }

    public Nob get_grabbed_id (Goo.CanvasItem? target) {
        int grabbed_id = -1;

        for (int i = 0; i < 9; i++) {
            if (target == nobs[i]) grabbed_id = i;
        }

        return (Nob) grabbed_id;
    }

    private void update_select_bb_coords (List<Models.CanvasItem> selected_items) {
        // Bounding box edges
        double bb_left = 1e6, bb_top = 1e6, bb_right = 0, bb_bottom = 0;

        foreach (var item in selected_items) {
            Goo.CanvasBounds item_bounds;
            item.get_bounds (out item_bounds);

            bb_left = double.min (bb_left, item_bounds.x1);
            bb_top = double.min (bb_top, item_bounds.y1);
            bb_right = double.max (bb_right, item_bounds.x2);
            bb_bottom = double.max (bb_bottom, item_bounds.y2);
        }

        select_bb = Goo.CanvasBounds () {
            x1 = bb_left,
            y1 = bb_top,
            x2 = bb_right,
            y2 = bb_bottom
        };

        top = select_bb.y1;
        left = select_bb.x1;
        width = select_bb.x2 - select_bb.x1;
        height = select_bb.y2 - select_bb.y1;
    }

    private void on_add_select_effect (List<Models.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            remove_select_effect ();
            return;
        }

        if (selected_items.length () > 1) {
            update_select_bb_coords (selected_items);
        }

        update_select_effect (selected_items);
        update_nob_position (selected_items);
        // We don't need to recreate those objects after this.
        create = false;
    }

    private void remove_select_effect (bool keep_selection = false) {
        if (select_effect == null) {
            return;
        }

        select_effect.remove ();
        select_effect = null;

        for (int i = 0; i < 9; i++) {
            nobs[i].remove ();
        }
        // Those objects were removed, new objects should be created.
        create = true;
        //  debug ("removed");
    }

    private void update_select_effect (List<Models.CanvasItem> selected_items) {
        double x = 0.0;
        double y = 0.0;
        double line_width = 0.0;
        double width = 0.0;
        double height = 0.0;

        var transform = Cairo.Matrix.identity ();

        set_bound_coordinates (
            selected_items,
            ref x, ref y,
            ref transform,
            ref line_width,
            ref width, ref height
        );

        // Account for line_width
        x -= line_width / 2;
        y -= line_width / 2;
        width += line_width;
        height += line_width;

        if (create) {
            //  debug ("create effect");
            select_effect = new Goo.CanvasRect (
                null,
                x, y,
                width,
                height,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );
            select_effect.set ("parent", root);
        }

        select_effect.set_transform (transform);
        select_effect.set ("width", width);
        select_effect.set ("height", height);
        select_effect.set ("line-width", LINE_WIDTH / canvas.current_scale);
    }

    private void update_nob_position (List<Models.CanvasItem> selected_items) {
        var transform = Cairo.Matrix.identity ();

        double line_width = 0.0;
        double x = 0.0;
        double y = 0.0;
        double width = 0.0;
        double height = 0.0;

        set_bound_coordinates (
            selected_items,
            ref x, ref y,
            ref transform,
            ref line_width,
            ref width, ref height
        );

        if (create) {
            //  debug ("create nobs");
            for (int i = 0; i < 9; i++) {
                nobs[i] = new Selection.Nob (root, (Managers.NobManager.Nob) i);
            }
        }

        canvas.window.event_bus.update_nob_size ();
        nob_size = Selection.Nob.NOB_SIZE / canvas.current_scale;

        bool print_middle_width_nobs = width > nob_size * 3;
        bool print_middle_height_nobs = height > nob_size * 3;

        var nob_offset = nob_size / 2;

        // TOP LEFT nob
        nobs[Nob.TOP_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
            nobs[Nob.TOP_LEFT].translate (x - (nob_offset + (line_width / 2)), y - (nob_offset + (line_width / 2)));
        } else {
            nobs[Nob.TOP_LEFT].translate (x - nob_size - (line_width / 2), y - nob_size - (line_width / 2));
        }
        nobs[Nob.TOP_LEFT].raise (select_effect);

        if (print_middle_width_nobs) {
            // TOP CENTER nob
            nobs[Nob.TOP_CENTER].set_transform (transform);
            if (print_middle_height_nobs) {
                nobs[Nob.TOP_CENTER].translate (x + (width / 2) - nob_offset, y - (nob_offset + (line_width / 2)));
            } else {
                nobs[Nob.TOP_CENTER].translate (x + (width / 2) - nob_offset, y - (nob_size + (line_width / 2)));
            }
            set_nob_visibility (Nob.TOP_CENTER, true);
        } else {
            set_nob_visibility (Nob.TOP_CENTER, false);
        }

        nobs[Nob.TOP_CENTER].raise (select_effect);

        // TOP RIGHT nob
        nobs[Nob.TOP_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
            nobs[Nob.TOP_RIGHT].translate (x + width - (nob_offset - (line_width / 2)), y - (nob_offset + (line_width / 2)));
        } else {
            nobs[Nob.TOP_RIGHT].translate (x + width + (line_width / 2), y - (nob_size + (line_width / 2)));
        }
        nobs[Nob.TOP_RIGHT].raise (select_effect);

        if (print_middle_height_nobs) {
            // RIGHT CENTER nob
            nobs[Nob.RIGHT_CENTER].set_transform (transform);
            if (print_middle_width_nobs) {
                nobs[Nob.RIGHT_CENTER].translate (x + width - (nob_offset - (line_width / 2)), y + (height / 2) - nob_offset);
            } else {
                nobs[Nob.RIGHT_CENTER].translate (x + width + (line_width / 2), y + (height / 2) - nob_offset);
            }
            set_nob_visibility (Nob.RIGHT_CENTER, true);
        } else {
            set_nob_visibility (Nob.RIGHT_CENTER, false);
        }

        nobs[Nob.RIGHT_CENTER].raise (select_effect);

        // BOTTOM RIGHT nob
        nobs[Nob.BOTTOM_RIGHT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
            nobs[Nob.BOTTOM_RIGHT].translate (
                x + width - (nob_offset - (line_width / 2)), y + height - (nob_offset - (line_width / 2))
            );
        } else {
            nobs[Nob.BOTTOM_RIGHT].translate (x + width + (line_width / 2), y + height + (line_width / 2));
        }
        nobs[Nob.BOTTOM_RIGHT].raise (select_effect);

        if (print_middle_width_nobs) {
            // BOTTOM CENTER nob
            nobs[Nob.BOTTOM_CENTER].set_transform (transform);
            if (print_middle_height_nobs) {
                nobs[Nob.BOTTOM_CENTER].translate (
                    x + (width / 2) - nob_offset, y + height - (nob_offset - (line_width / 2))
                );
            } else {
                nobs[Nob.BOTTOM_CENTER].translate (x + (width / 2) - nob_offset, y + height + (line_width / 2));
            }
            set_nob_visibility (Nob.BOTTOM_CENTER, true);
        } else {
            set_nob_visibility (Nob.BOTTOM_CENTER, false);
        }
        nobs[Nob.BOTTOM_CENTER].raise (select_effect);

        // BOTTOM LEFT nob
        nobs[Nob.BOTTOM_LEFT].set_transform (transform);
        if (print_middle_width_nobs && print_middle_height_nobs) {
            nobs[Nob.BOTTOM_LEFT].translate (x - (nob_offset + (line_width / 2)), y + height - (nob_offset - (line_width / 2)));
        } else {
            nobs[Nob.BOTTOM_LEFT].translate (x - (nob_size + (line_width / 2)), y + height + (line_width / 2));
        }
        nobs[Nob.BOTTOM_LEFT].raise (select_effect);

        if (print_middle_height_nobs) {
            // LEFT CENTER nob
            nobs[Nob.LEFT_CENTER].set_transform (transform);
            if (print_middle_width_nobs) {
                nobs[Nob.LEFT_CENTER].translate (x - (nob_offset + (line_width / 2)), y + (height / 2) - nob_offset);
            } else {
                nobs[Nob.LEFT_CENTER].translate (x - (nob_size + (line_width / 2)), y + (height / 2) - nob_offset);
            }
            set_nob_visibility (Nob.LEFT_CENTER, true);
        } else {
            set_nob_visibility (Nob.LEFT_CENTER, false);
        }

        nobs[Nob.LEFT_CENTER].raise (select_effect);

        // ROTATE nob
        double distance = 40;
        if (canvas.current_scale > 1) {
            distance -= (distance * canvas.current_scale) * 0.05;
        } else if (canvas.current_scale < 1) {
            distance += (distance / canvas.current_scale) / 4;
        }

        nobs[Nob.ROTATE].set_transform (transform);
        nobs[Nob.ROTATE].translate (x + (width / 2) - nob_offset, y - nob_offset - distance);
        nobs[Nob.ROTATE].raise (select_effect);
    }

    private void set_nob_visibility (Nob nob_handle, bool visible) {
        if (visible) {
            nobs[nob_handle].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
            return;
        }
        nobs[nob_handle].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
    }

    private void set_bound_coordinates (
        List<Models.CanvasItem> selected_items,
        ref double x,
        ref double y,
        ref Cairo.Matrix transform,
        ref double line_width,
        ref double _width,
        ref double _height
    ) {
        if (selected_items.length () == 1) {
            var item = selected_items.nth_data (0);

            item.get_transform (out transform);
            item.get ("line_width", out line_width);
            item.get ("width", out _width);
            item.get ("height", out _height);
            item.get ("x", out x);
            item.get ("y", out y);

            return;
        }

        line_width = 0.0;
        _width = width;
        _height = height;
        x = left;
        y = top;
    }

    private async void on_hide_select_effect () {
        for (int i = 0; i < 9; i++) {
            nobs[i].set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        select_effect.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
    }

    private async void on_show_select_effect () {
        for (int i = 0; i < 9; i++) {
            nobs[i].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        }
        select_effect.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
    }
}
