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
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.NobManager : Object {
    private const string STROKE_COLOR = "#666";
    private const double LINE_WIDTH = 1.0;
    private const double LINE_HEIGHT = 40.0;

    /*
    Grabber Pos:
      8
      |
    0 1 2
    7   3
    6 5 4

    // -1 if no nob is grabbed.
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
    private Goo.CanvasRect? select_effect;
    private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];
    private Goo.CanvasPolyline? rotation_line;

    // Values in canvas coordinates.
    private double top_left_x;
    private double top_left_y;
    private double width_offset_x;
    private double width_offset_y;
    private double height_offset_x;
    private double height_offset_y;
    // bb_width and bb_height are also used by the SizeManager to represent
    // the width and height of selected items in the Transform Panel.
    public double bb_width;
    public double bb_height;
    private Cairo.Matrix bb_matrix;

    // Values for the Transform Panel fields.
    private double selected_x;
    private double selected_y;

    // Tracks if an artboard is part of the current selection.
    private bool is_artboard;
    private bool nobs_constructed = false;

    // If the effect needs to be created or it's only a value update.
    private bool create { get; set; default = true; }

    public NobManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        canvas.window.event_bus.selected_items_list_changed.connect (on_add_select_effect);
        canvas.window.event_bus.selected_items_changed.connect (on_add_select_effect);

        canvas.window.event_bus.zoom.connect (on_canvas_zoom);
        canvas.window.event_bus.hide_select_effect.connect (on_hide_select_effect);
        canvas.window.event_bus.show_select_effect.connect (on_show_select_effect);
    }

    /**
     * Set which nob is selected by its Nob name.
     */
    public void set_selected_by_name (Nob selected_nob) {
        this.selected_nob = selected_nob;
    }

    /**
     * Compares a target item to the current nobs to see if there is a match.
     * Otherwise returns Nob.NONE.
     */
    public Nob get_grabbed_id (Goo.CanvasItem? target) {
        int grabbed_id = Nob.NONE;

        for (var i = 0; i < 9; ++i) {
            if (target == nobs[i]) {
                grabbed_id = i;
                break;
            }
        }

        return (Nob) grabbed_id;
    }

    public static bool is_top_nob (Nob nob) {
        return nob == Nob.TOP_LEFT || nob == Nob.TOP_CENTER || nob == Nob.TOP_RIGHT;
    }

    public static bool is_bot_nob (Nob nob) {
        return nob == Nob.BOTTOM_LEFT || nob == Nob.BOTTOM_CENTER || nob == Nob.BOTTOM_RIGHT;
    }

    public static bool is_left_nob (Nob nob) {
        return nob == Nob.TOP_LEFT || nob == Nob.LEFT_CENTER || nob == Nob.BOTTOM_LEFT;
    }

    public static bool is_right_nob (Nob nob) {
        return nob == Nob.TOP_RIGHT || nob == Nob.RIGHT_CENTER || nob == Nob.BOTTOM_RIGHT;
    }

    /**
     * Takes a set of items and populates information needed to determine
     * the selection box and nob positions. If the number of items is one,
     * the selection box may be rotated, otherwise it is never rotated.
     */
    public static void populate_nob_bounds_from_items (
        List<Items.CanvasItem> items,
        ref Cairo.Matrix matrix,
        ref double top_left_x,
        ref double top_left_y,
        ref double width_offset_x,
        ref double width_offset_y,
        ref double height_offset_x,
        ref double height_offset_y,
        ref double width,
        ref double height,
        ref double selected_x,
        ref double selected_y
    ) {
        top_left_x = 0;
        top_left_y = 0;

        // Check if we only have one item currently selected.
        if (items.length () == 1) {
            var item = items.first ().data;
            item.get_transform (out matrix);

            // Set the coordinates for the transform panel.
            // Use x and y coordinates to account for the item being inside artboard.
            selected_x = item.coordinates.x;
            selected_y = item.coordinates.y;

            Cairo.Matrix nob_matrix = matrix;
            if (item.artboard != null) {
                Cairo.Matrix artboard_matrix;
                item.artboard.get_transform (out artboard_matrix);
                nob_matrix.multiply (matrix, artboard_matrix);
            }

            width = item.size.width;
            height = item.size.height;

            width_offset_x = width;
            width_offset_y = 0;
            height_offset_x = 0;
            height_offset_y = height;
            nob_matrix.transform_distance (ref width_offset_x, ref width_offset_y);
            nob_matrix.transform_distance (ref height_offset_x, ref height_offset_y);
            nob_matrix.transform_point (ref top_left_x, ref top_left_y);
            return;
        }

        matrix = Cairo.Matrix.identity ();

        bool first = true;
        double x = 0;
        double y = 0;
        double x1 = 0;
        double y1 = 0;
        double x2 = 0;
        double y2 = 0;
        foreach (var item in items) {
            // Store the coordinates accounting for items inside artboards.
            x = first ? item.coordinates.x : double.min (x, item.coordinates.x);
            y = first ? item.coordinates.y : double.min (y, item.coordinates.y);

            x1 = first ? item.coordinates.x1 : double.min (x1, item.coordinates.x1);
            x2 = double.max (x2, item.coordinates.x2);
            y1 = first ? item.coordinates.y1 : double.min (y1, item.coordinates.y1);
            y2 = double.max (y2, item.coordinates.y2);
            first = false;
        }

        // Set the coordinates for the transform panel.
        selected_x = x;
        selected_y = y;

        width = x2 - x1;
        height = y2 - y1;

        top_left_x = x1;
        top_left_y = y1;
        width_offset_x = width;
        width_offset_y = 0;
        height_offset_x = 0;
        height_offset_y = height;
    }

    /**
     * Calculates the position of a nob based on values
     * calculated using `populate_nob_bounds_from_items`.
     */
    private static void calculate_nob_position (
        Nob nob_name,
        double top_left_x,
        double top_left_y,
        double width_offset_x,
        double width_offset_y,
        double height_offset_x,
        double height_offset_y,
        ref double pos_x,
        ref double pos_y
    ) {
        switch (nob_name) {
            case Nob.TOP_LEFT:
                pos_x = top_left_x;
                pos_y = top_left_y;
                break;
            case Nob.TOP_CENTER:
                pos_x = top_left_x + width_offset_x / 2.0;
                pos_y = top_left_y + width_offset_y / 2.0;
                break;
            case Nob.TOP_RIGHT:
                pos_x = top_left_x + width_offset_x;
                pos_y = top_left_y + width_offset_y;
                break;
            case Nob.RIGHT_CENTER:
                pos_x = top_left_x + width_offset_x + height_offset_x / 2.0;
                pos_y = top_left_y + width_offset_y + height_offset_y / 2.0;
                break;
            case Nob.BOTTOM_RIGHT:
                pos_x = top_left_x + width_offset_x + height_offset_x;
                pos_y = top_left_y + width_offset_y + height_offset_y;
                break;
            case Nob.BOTTOM_CENTER:
                pos_x = top_left_x + width_offset_x / 2.0 + height_offset_x;
                pos_y = top_left_y + width_offset_y / 2.0 + height_offset_y;
                break;
            case Nob.BOTTOM_LEFT:
                pos_x = top_left_x + height_offset_x;
                pos_y = top_left_y + height_offset_y;
                break;
            case Nob.LEFT_CENTER:
                pos_x = top_left_x + height_offset_x / 2.0;
                pos_y = top_left_y + height_offset_y / 2.0;
                break;
            case Nob.NONE:
            default:
                break;
        }
    }

    /**
     * Calculates the position of a nob based on a selection of items and the nob id.
     */
    public static void nob_position_from_items (
        List<Items.CanvasItem> items,
        Nob nob_name,
        ref double pos_x,
        ref double pos_y
    ) {
        Cairo.Matrix dummy_matrix = Cairo.Matrix.identity ();
        double dummy_top_left_x = 0;
        double dummy_top_left_y = 0;
        double dummy_width_offset_x = 0;
        double dummy_width_offset_y = 0;
        double dummy_height_offset_x = 0;
        double dummy_height_offset_y = 0;
        double dummy_width = 0;
        double dummy_height = 0;
        double dummy_selected_x = 0;
        double dummy_selected_y = 0;

        populate_nob_bounds_from_items (
            items,
            ref dummy_matrix,
            ref dummy_top_left_x,
            ref dummy_top_left_y,
            ref dummy_width_offset_x,
            ref dummy_width_offset_y,
            ref dummy_height_offset_x,
            ref dummy_height_offset_y,
            ref dummy_width,
            ref dummy_height,
            ref dummy_selected_x,
            ref dummy_selected_y
        );

        calculate_nob_position (
            nob_name,
            dummy_top_left_x,
            dummy_top_left_y,
            dummy_width_offset_x,
            dummy_width_offset_y,
            dummy_height_offset_x,
            dummy_height_offset_y,
            ref pos_x,
            ref pos_y
         );
    }

    /**
     * What happens when the canvas is zoomed in.
     */
    private void on_canvas_zoom () {
        on_add_select_effect (canvas.selected_bound_manager.selected_items);
    }

    /**
     * Adds selection effects if applicable to selected items,
     * and repositions the selection and nobs.
     */
    private void on_add_select_effect (List<Items.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            remove_select_effect ();
            return;
        }

        populate_nobs ();

        populate_nob_bounds_from_items (
            selected_items,
            ref bb_matrix,
            ref top_left_x,
            ref top_left_y,
            ref width_offset_x,
            ref width_offset_y,
            ref height_offset_x,
            ref height_offset_y,
            ref bb_width,
            ref bb_height,
            ref selected_x,
            ref selected_y
        );

        update_select_effect (selected_items);
        update_nob_position (selected_items);
    }

    /**
     * Resets all selection and nob items.
     */
    private void remove_select_effect (bool keep_selection = false) {
        if (select_effect == null) {
            return;
        }

        select_effect.remove ();
        select_effect = null;

        rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);

        foreach (var nob in nobs) {
            nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
    }

    /**
     * Updates selection items, constructing them if necessary.
     */
    private void update_select_effect (List<Items.CanvasItem> selected_items) {
        if (select_effect == null) {
            select_effect = new Goo.CanvasRect (
                null,
                0, 0,
                bb_width, bb_height,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            select_effect.set ("parent", root);
            select_effect.pointer_events = Goo.CanvasPointerEvents.NONE;
        }

        // If only one item is selected and it's inside an artboard,
        // we need to convert its coordinates from the artboard space.
        Cairo.Matrix tmp_matrix = bb_matrix;
        var item = selected_items.first ().data;
        if (selected_items.length () == 1 && item.artboard != null) {
            item.canvas.convert_from_item_space (item.artboard, ref tmp_matrix.x0, ref tmp_matrix.y0);
        }

        select_effect.set_transform (tmp_matrix);
        select_effect.set ("width", bb_width);
        select_effect.set ("height", bb_height);
        select_effect.set ("line-width", LINE_WIDTH / canvas.current_scale);
    }

    /**
     * Update the position of all nobs of selected items. It will show or hide them based on
     * the properties of the selection.
     */
    private void update_nob_position (List<Items.CanvasItem> selected_items) {
        is_artboard = false;
        foreach (var item in selected_items) {
            if (item is Items.CanvasArtboard) {
                is_artboard = true;
                break;
            }
        }

        var nob_size = Selection.Nob.NOB_SIZE / canvas.current_scale;
        bool print_middle_width_nobs = bb_width > nob_size * 3;
        bool print_middle_height_nobs = bb_height > nob_size * 3;

        foreach (var nob_simple in nobs) {
            var nob = nob_simple as Selection.Nob;
            bool set_visible = true;
            double center_x = 0;
            double center_y = 0;

            var nob_name = nob.handle_id;

            calculate_nob_position (
                nob_name,
                top_left_x,
                top_left_y,
                width_offset_x,
                width_offset_y,
                height_offset_x,
                height_offset_y,
                ref center_x,
                ref center_y
            );

            if (!print_middle_height_nobs && (nob_name == Nob.RIGHT_CENTER || nob_name == Nob.LEFT_CENTER)) {
                set_visible = false;
            } else if (!print_middle_width_nobs && (nob_name == Nob.TOP_CENTER || nob_name == Nob.BOTTOM_CENTER)) {
                set_visible = false;
            } else if (nob.handle_id == Nob.ROTATE) {
                double line_offset_x = 0;
                double line_offset_y = - (LINE_HEIGHT / canvas.current_scale);
                bb_matrix.transform_distance (ref line_offset_x, ref line_offset_y);

                // If only one item is selected and it's inside an artboard,
                // we need to convert its coordinates from the artboard space.
                Cairo.Matrix tmp_matrix = bb_matrix;
                var item = selected_items.first ().data;
                if (selected_items.length () == 1 && item.artboard != null) {
                    item.canvas.convert_from_item_space (item.artboard, ref tmp_matrix.x0, ref tmp_matrix.y0);
                }

                center_x = top_left_x + width_offset_x / 2.0 + line_offset_x;
                center_y = top_left_y + width_offset_y / 2.0 + line_offset_y;

                set_visible = !is_artboard;

                if (set_visible) {
                    rotation_line.set_transform (tmp_matrix);
                    rotation_line.translate (bb_width / 2.0, - LINE_HEIGHT / canvas.current_scale);
                    rotation_line.set ("line-width", LINE_WIDTH / canvas.current_scale);
                    rotation_line.set ("height", LINE_HEIGHT / canvas.current_scale);
                    rotation_line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    rotation_line.raise (select_effect);
                } else {
                    rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
                }

                // Raise to the rotation_line, so the line is under the rotation nob.
                nob.update_state (bb_matrix, center_x, center_y, set_visible);
                nob.raise (rotation_line);
                return;
            }

            nob.update_state (bb_matrix, center_x, center_y, set_visible);
            nob.raise (select_effect);
        }
    }

    /**
     * Constructs all nobs and the rotation line if they haven't been constructed already.
     */
    private void populate_nobs () {
        if (nobs_constructed) {
            return;
        }

        root = canvas.get_root_item ();

        for (int i = 0; i < 9; i++) {
            var nob = new Selection.Nob (root, (Managers.NobManager.Nob) i);
            nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
            nobs[i] = nob;
        }

        // Create the line to visually connect the rotation nob to the item.
        rotation_line = new Goo.CanvasPolyline.line (
            null, 0, 0, 0, LINE_HEIGHT,
            "line-width", LINE_WIDTH / canvas.current_scale,
            "stroke-color", STROKE_COLOR,
            null);
        rotation_line.set ("parent", root);
        rotation_line.pointer_events = Goo.CanvasPointerEvents.NONE;

        nobs_constructed = true;
    }


    /**
     * Asynchronous call to hide selection and nobs.
     */
    private async void on_hide_select_effect () {
        foreach (var nob in nobs) {
            nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }

        select_effect.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
    }

    /**
     * Asynchronous call to show selection and nobs.
     */
    private async void on_show_select_effect () {
        for (int i = 0; i < 9; i++) {
            // If an artboard is part of the current selection, don't show the rotation nob.
            if (is_artboard && i == 8) {
                continue;
            }
            nobs[i].set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        }
        select_effect.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);

        if (!is_artboard) {
            rotation_line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        }
    }
}
