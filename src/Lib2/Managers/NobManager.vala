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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 *
 */
public class Akira.Lib2.Managers.NobManager : Object  {
    private const string STROKE_COLOR = "#666";
    private const double LINE_WIDTH = 1.0;

    public weak Lib2.ViewCanvas view_canvas { get; construct; }

    private Goo.CanvasRect? select_effect = null;
    private Akira.Lib.Selection.Nob[] nobs = null;
    private Goo.CanvasPolyline? rotation_line = null;

    // Tracks if an artboard is part of the current selection.
    private bool is_artboard = false;

    public NobManager (Lib2.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );
    }

    construct {
        view_canvas.window.event_bus.selection_modified.connect (on_update_select_effect);
        view_canvas.window.event_bus.zoom.connect (on_update_select_effect);
    }

    public Utils.Nobs.Nob hit_test (double x, double y) {
        double scale = view_canvas.current_scale;
        foreach (var ui_nob in nobs) {
            if (ui_nob != null && ui_nob.is_visible ()) {
                if (ui_nob.hit_test (x, y, scale)) {
                    return ui_nob.handle_id;
                }
            }
        }

        return Utils.Nobs.Nob.NONE;
    }

    private void on_update_select_effect () {
        var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            remove_select_effect ();
        }

        populate_nobs (sm.selection);
        update_select_effect (sm.selection);
        update_nob_positions (sm.selection);
    }

    /*
     * Resets all selection and nob items.
     */
    private void remove_select_effect () {
        if (select_effect != null) {
            select_effect.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }

        if (rotation_line != null) {
            rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }

        if (nobs != null) {
            foreach (var nob in nobs) {
                nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
            }
        }
    }

    /*
     * Constructs all nobs and the rotation line if they haven't been constructed already.
     * Nobs don't take mouse events, instead hit_test () is used to interact with nobs.
     */
    private void populate_nobs (Lib2.Items.ItemSelection selection) {
        if (nobs != null) {
            return;
        }

       nobs = new Lib.Selection.Nob[9];

        for (int i = 0; i < 9; i++) {
            var nob = new Lib.Selection.Nob (view_canvas.get_root_item (), (Utils.Nobs.Nob) i);
            nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
            nob.pointer_events = Goo.CanvasPointerEvents.NONE;
            nobs[i] = nob;
        }

        // Create the line to visually connect the rotation nob to the item.
        rotation_line = new Goo.CanvasPolyline.line (
            null, 0, 0, 0, Utils.Nobs.ROTATION_LINE_HEIGHT,
            "line-width", LINE_WIDTH / view_canvas.current_scale,
            "stroke-color", STROKE_COLOR,
            null);
        rotation_line.set ("parent", view_canvas.get_root_item ());
        rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        rotation_line.pointer_events = Goo.CanvasPointerEvents.NONE;
    }

    /**
     * Update the position of all nobs of selected items. It will show or hide them based on
     * the properties of the selection.
     */
    private void update_nob_positions (Lib2.Items.ItemSelection selection) {
        var nob_size = Lib.Selection.Nob.NOB_SIZE / view_canvas.current_scale;

        double tl_x;
        double tl_y;
        double tr_x;
        double tr_y;
        double bl_x;
        double bl_y;
        double br_x;
        double br_y;
        double rotation;

        selection.coordinates (
            out tl_x,
            out tl_y,
            out tr_x,
            out tr_y,
            out bl_x,
            out bl_y,
            out br_x,
            out br_y,
            out rotation
        );

        var width = Utils.GeometryMath.distance (tl_x, tl_y, tr_x, tr_y).abs ();
        var height = Utils.GeometryMath.distance (tl_x, tl_y, bl_x, bl_y).abs ();

        bool show_h_centers = height > nob_size * 3;
        bool show_v_centers = width > nob_size * 3;

        foreach (var nob in nobs) {
            bool set_visible = true;

            if (!show_h_centers && Utils.Nobs.is_horizontal_center (nob.handle_id)) {
                set_visible = false;
            }
            else if (!show_v_centers && Utils.Nobs.is_vertical_center (nob.handle_id)) {
                set_visible = false;
            }

            update_nob (nob, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y, rotation, set_visible);
        }
    }

    private void update_nob (
        Lib.Selection.Nob nob,
        double tl_x,
        double tl_y,
        double tr_x,
        double tr_y,
        double bl_x,
        double bl_y,
        double br_x,
        double br_y,
        double rotation,
        bool show
    ) {
        double sc = view_canvas.current_scale;
        var n0 = nob.handle_id;
        double cx = 0;
        double cy = 0;
        Utils.Nobs.nob_xy_from_coordinates (n0, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y, sc, ref cx, ref cy);

        if (nob.handle_id == Utils.Nobs.Nob.ROTATE) {
            if (show) {
                var n1 = Utils.Nobs.Nob.TOP_CENTER;
                double tx = 0;
                double ty = 0;
                Utils.Nobs.nob_xy_from_coordinates (n1, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y, sc, ref tx, ref ty);

                var new_pts = new Goo.CanvasPoints (2);
                new_pts.set_point (0, cx, cy);
                new_pts.set_point (1, tx, ty);
                rotation_line.points = new_pts;

                rotation_line.set ("line-width", LINE_WIDTH / view_canvas.current_scale);
                rotation_line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);

                double pp0 = 0.0;
                double pp1 = 0.0;
                double pp2 = 0.0;
                double pp3 = 0.0;
                rotation_line.points.get_point(0, out pp0, out pp1);
                rotation_line.points.get_point(1, out pp2, out pp3);
            }
            else {
                rotation_line.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
            }

        }

        nob.update_global_state (cx, cy, rotation, show);
        nob.raise (select_effect);
    }

    /**
     * Updates selection items, constructing them if necessary.
     */
    private void update_select_effect (Lib2.Items.ItemSelection selection) {
        double tl_x;
        double tl_y;
        double tr_x;
        double tr_y;
        double bl_x;
        double bl_y;
        double br_x;
        double br_y;
        double rotation;

        selection.coordinates (
            out tl_x,
            out tl_y,
            out tr_x,
            out tr_y,
            out bl_x,
            out bl_y,
            out br_x,
            out br_y,
            out rotation
        );

        var center_x = (tl_x + tr_x + bl_x + br_x) / 4.0;
        var center_y = (tl_y + tr_y + bl_y + br_y) / 4.0;

        var width = Utils.GeometryMath.distance (tl_x, tl_y, tr_x, tr_y).abs ();
        var height = Utils.GeometryMath.distance (tl_x, tl_y, bl_x, bl_y).abs ();

        if (select_effect == null) {
            select_effect = new Goo.CanvasRect (
                null,
                -width / 2.0, -height / 2.0,
                width, height,
                "line-width", LINE_WIDTH / view_canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            select_effect.set ("parent", view_canvas.get_root_item ());
            select_effect.pointer_events = Goo.CanvasPointerEvents.NONE;
        }

        select_effect.set ("x", -width / 2.0);
        select_effect.set ("y", -height / 2.0);
        select_effect.set ("width", width);
        select_effect.set ("height", height);
        select_effect.set ("line-width", LINE_WIDTH / view_canvas.current_scale);

        var tr = Cairo.Matrix.identity ();
        tr.x0 = center_x;
        tr.y0 = center_y;
        tr.rotate (rotation);

        select_effect.set_transform (tr);
        select_effect.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        select_effect.raise (null);
    }
}

