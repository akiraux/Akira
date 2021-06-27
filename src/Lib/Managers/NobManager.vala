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

    /*
     * Nob data associated with an item selection.
     */
    public class ItemNobData : Object {
        construct {
            bb_matrix = Cairo.Matrix.identity ();
        }

        // Values in canvas coordinates.
        public double top_left_x = 0.0;
        public double top_left_y = 0.0;
        public double width_offset_x = 0.0;
        public double width_offset_y = 0.0;
        public double height_offset_x = 0.0;
        public double height_offset_y = 0.0;

        // bb_width and bb_height are also used by the SizeMiddleware to represent
        // the width and height of selected items in the Transform Panel.
        public double bb_width = 0.0;
        public double bb_height = 0.0;

        public Cairo.Matrix bb_matrix;

        // Values for the Transform Panel fields.
        public double selected_x = 0.0;
        public double selected_y = 0.0;
    }

    public weak Akira.Lib.Canvas canvas { get; construct; }

    public Nob selected_nob;
    public Nob hovered_nob;

    private Goo.CanvasItem root;
    private Goo.CanvasRect? select_effect;
    private Akira.Lib.Selection.Nob[] nobs = new Akira.Lib.Selection.Nob[9];
    private Goo.CanvasPolyline? rotation_line;

    // Active nob data associated with current selection.
    // private ItemNobData active_nob_data;

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

    public Nob hit_test (double x, double y) {
        double scale = canvas.current_scale;
        foreach (var ui_nob in nobs) {
            if (ui_nob != null && ui_nob.is_visible ()) {
                if (ui_nob.hit_test (x, y, scale)) {
                    return ui_nob.handle_id;
                }
            }
        }

        return Nob.NONE;
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

    public static bool is_corner_nob (Nob nob) {
        return nob == Nob.TOP_RIGHT || nob == Nob.TOP_LEFT || nob == Nob.BOTTOM_RIGHT || nob == Nob.BOTTOM_LEFT;
    }

    /*
     * Return a cursor type based of the type of nob.
     */
    public static Gdk.CursorType? cursor_from_nob (Nob nob_id) {
        Gdk.CursorType? result = null;
        switch (nob_id) {
            case Managers.NobManager.Nob.NONE:
                result = null;
                break;
            case Managers.NobManager.Nob.TOP_LEFT:
                result = Gdk.CursorType.TOP_LEFT_CORNER;
                break;
            case Managers.NobManager.Nob.TOP_CENTER:
                result = Gdk.CursorType.TOP_SIDE;
                break;
            case Managers.NobManager.Nob.TOP_RIGHT:
                result = Gdk.CursorType.TOP_RIGHT_CORNER;
                break;
            case Managers.NobManager.Nob.RIGHT_CENTER:
                result = Gdk.CursorType.RIGHT_SIDE;
                break;
            case Managers.NobManager.Nob.BOTTOM_RIGHT:
                result = Gdk.CursorType.BOTTOM_RIGHT_CORNER;
                break;
            case Managers.NobManager.Nob.BOTTOM_CENTER:
                result = Gdk.CursorType.BOTTOM_SIDE;
                break;
            case Managers.NobManager.Nob.BOTTOM_LEFT:
                result = Gdk.CursorType.BOTTOM_LEFT_CORNER;
                break;
            case Managers.NobManager.Nob.LEFT_CENTER:
                result = Gdk.CursorType.LEFT_SIDE;
                break;
            case Managers.NobManager.Nob.ROTATE:
                result = Gdk.CursorType.EXCHANGE;
                break;
        }

        return result;
    }


    /**
     * Takes a set of items and populates information needed to determine
     * the selection box and nob positions. If the number of items is one,
     * the selection box may be rotated, otherwise it is never rotated.
     */
    public static void populate_nob_bounds_from_items (List<Items.CanvasItem> items, ref ItemNobData nob_data) {
        nob_data.top_left_x = 0;
        nob_data.top_left_y = 0;

        // Check if we only have one item currently selected.
        if (items.length () == 1) {
            var item = items.first ().data;
            item.get_transform (out nob_data.bb_matrix);

            // Set the coordinates for the transform panel.
            // Use x and y coordinates to account for the item being inside artboard.
            nob_data.selected_x = item.coordinates.x;
            nob_data.selected_y = item.coordinates.y;

            Cairo.Matrix nob_matrix = nob_data.bb_matrix;
            if (item.artboard != null) {
                Cairo.Matrix artboard_matrix;
                item.artboard.get_transform (out artboard_matrix);
                nob_matrix.multiply (nob_data.bb_matrix, artboard_matrix);
            }

            nob_data.bb_width = item.size.width;
            nob_data.bb_height = item.size.height;

            double width_offset_x = nob_data.bb_width;
            double width_offset_y = 0;
            double height_offset_x = 0;
            double height_offset_y = nob_data.bb_height;
            nob_matrix.transform_distance (ref width_offset_x, ref width_offset_y);
            nob_matrix.transform_distance (ref height_offset_x, ref height_offset_y);
            nob_matrix.transform_point (ref nob_data.top_left_x, ref nob_data.top_left_y);
            nob_data.width_offset_x = width_offset_x;
            nob_data.width_offset_y = width_offset_y;
            nob_data.height_offset_x = height_offset_x;
            nob_data.height_offset_y = height_offset_y;
            return;
        }

        nob_data.bb_matrix = Cairo.Matrix.identity ();

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
        nob_data.selected_x = x;
        nob_data.selected_y = y;

        nob_data.bb_width = x2 - x1;
        nob_data.bb_height = y2 - y1;

        nob_data.top_left_x = x1;
        nob_data.top_left_y = y1;
        nob_data.width_offset_x = nob_data.bb_width;
        nob_data.width_offset_y = 0;
        nob_data.height_offset_x = 0;
        nob_data.height_offset_y = nob_data.bb_height;
    }

    /**
     * Calculates the position of a nob based on values
     * calculated using `populate_nob_bounds_from_items`.
     */
    private static void calculate_nob_position (
        Nob nob_name,
        ItemNobData nob_data,
        ref double pos_x,
        ref double pos_y
    ) {
        double top_left_x = nob_data.top_left_x;
        double top_left_y = nob_data.top_left_y;
        double width_offset_x = nob_data.width_offset_x;
        double width_offset_y = nob_data.width_offset_y;
        double height_offset_x = nob_data.height_offset_x;
        double height_offset_y = nob_data.height_offset_y;

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
        var nob_data = new ItemNobData ();
        populate_nob_bounds_from_items (items, ref nob_data);
        calculate_nob_position (nob_name, nob_data, ref pos_x, ref pos_y);
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

        var active_nob_data = new ItemNobData ();
        populate_nob_bounds_from_items (selected_items, ref active_nob_data);

        update_select_effect (selected_items, active_nob_data);
        update_nob_position (selected_items, active_nob_data);
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
    private void update_select_effect (List<Items.CanvasItem> selected_items, ItemNobData nob_data) {
        if (select_effect == null) {
            select_effect = new Goo.CanvasRect (
                null,
                0, 0,
                nob_data.bb_width, nob_data.bb_height,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            select_effect.set ("parent", root);
            select_effect.pointer_events = Goo.CanvasPointerEvents.NONE;
        }

        // If only one item is selected and it's inside an artboard,
        // we need to convert its coordinates from the artboard space.
        Cairo.Matrix tmp_matrix = nob_data.bb_matrix;
        var item = selected_items.first ().data;
        if (selected_items.length () == 1 && item.artboard != null) {
            item.canvas.convert_from_item_space (item.artboard, ref tmp_matrix.x0, ref tmp_matrix.y0);
        }

        select_effect.set_transform (tmp_matrix);
        select_effect.set ("width", nob_data.bb_width);
        select_effect.set ("height", nob_data.bb_height);
        select_effect.set ("line-width", LINE_WIDTH / canvas.current_scale);
    }

    /**
     * Update the position of all nobs of selected items. It will show or hide them based on
     * the properties of the selection.
     */
    private void update_nob_position (List<Items.CanvasItem> selected_items, ItemNobData nob_data) {
        is_artboard = false;
        foreach (var item in selected_items) {
            if (item is Items.CanvasArtboard) {
                is_artboard = true;
                break;
            }
        }

        var nob_size = Selection.Nob.NOB_SIZE / canvas.current_scale;
        bool print_middle_width_nobs = nob_data.bb_width > nob_size * 3;
        bool print_middle_height_nobs = nob_data.bb_height > nob_size * 3;

        foreach (var nob in nobs) {
            bool set_visible = true;
            double center_x = 0;
            double center_y = 0;

            var nob_name = nob.handle_id;

            calculate_nob_position (nob_name, nob_data, ref center_x, ref center_y);

            // Unique calculation for the rotation nob.
            if (nob.handle_id == Nob.ROTATE) {
                double line_offset_x = 0;
                double line_offset_y = - (LINE_HEIGHT / canvas.current_scale);
                nob_data.bb_matrix.transform_distance (ref line_offset_x, ref line_offset_y);

                // If only one item is selected and it's inside an artboard,
                // we need to convert its coordinates from the artboard space.
                Cairo.Matrix tmp_matrix = nob_data.bb_matrix;
                var item = selected_items.first ().data;
                if (selected_items.length () == 1 && item.artboard != null) {
                    item.canvas.convert_from_item_space (item.artboard, ref tmp_matrix.x0, ref tmp_matrix.y0);
                }

                center_x = nob_data.top_left_x + nob_data.width_offset_x / 2.0 + line_offset_x;
                center_y = nob_data.top_left_y + nob_data.width_offset_y / 2.0 + line_offset_y;

                set_visible = !is_artboard;

                if (set_visible) {
                    rotation_line.set_transform (tmp_matrix);
                    rotation_line.translate (nob_data.bb_width / 2.0, - LINE_HEIGHT / canvas.current_scale);
                    rotation_line.set ("line-width", LINE_WIDTH / canvas.current_scale);
                    rotation_line.set ("height", LINE_HEIGHT / canvas.current_scale);
                    rotation_line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    rotation_line.raise (select_effect);
                } else {
                    rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
                }

                // Raise to the rotation_line, so the line is under the rotation nob.
                nob.update_state (nob_data.bb_matrix, center_x, center_y, set_visible);
                nob.raise (rotation_line);
                continue;
            }

            // Check if we need to hide the vertically centered nobs.
            if (!print_middle_height_nobs && (nob_name == Nob.RIGHT_CENTER || nob_name == Nob.LEFT_CENTER)) {
                set_visible = false;
            }

            // Check if we need to hide the horizontally centere nobs.
            if (!print_middle_width_nobs && (nob_name == Nob.TOP_CENTER || nob_name == Nob.BOTTOM_CENTER)) {
                set_visible = false;
            }

            nob.update_state (nob_data.bb_matrix, center_x, center_y, set_visible);
            nob.raise (select_effect);

            // If we're hiding all centered nobs, we need to shift the position
            // of the corner nobs to improve the grabbing area.
            if (!print_middle_width_nobs && !print_middle_height_nobs) {
                var half = nob_size / 2;

                // Use Cairo.translate to automatically account for the item's rotation.
                if (nob_name == Nob.TOP_LEFT) {
                    nob.translate (-half, -half);
                } else if (nob_name == Nob.TOP_RIGHT) {
                    nob.translate (half, -half);
                } else if (nob_name == Nob.BOTTOM_RIGHT) {
                    nob.translate (half, half);
                } else if (nob_name == Nob.BOTTOM_LEFT) {
                    nob.translate (-half, half);
                }
            }
        }
    }

    /**
     * Constructs all nobs and the rotation line if they haven't been constructed already.
     * Nobs don't take mouse events, instead hit_test () is used to interact with nobs.
     */
    private void populate_nobs () {
        if (nobs_constructed) {
            return;
        }

        root = canvas.get_root_item ();

        for (int i = 0; i < 9; i++) {
            var nob = new Selection.Nob (root, (Managers.NobManager.Nob) i);
            nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
            nob.pointer_events = Goo.CanvasPointerEvents.NONE;
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
