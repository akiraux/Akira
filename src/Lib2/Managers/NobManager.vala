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
public class Akira.Lib2.Managers.NobManager : Object {
    private const string STROKE_COLOR = "#666";
    private const double LINE_WIDTH = 1.0;

    public weak Lib2.ViewCanvas view_canvas { get; construct; }

    private Utils.Nobs.NobSet nobs;
    private ViewLayers.ViewLayerNobs nob_layer = null;

    // Tracks if an artboard is part of the current selection.
    private int last_id = -1;

    public NobManager (Lib2.ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    construct {
        nobs = new Utils.Nobs.NobSet ();

        view_canvas.window.event_bus.selection_modified.connect (on_update_select_effect);
        view_canvas.mode_manager.mode_changed.connect (on_update_select_effect);
        nob_layer = new ViewLayers.ViewLayerNobs ();
        nob_layer.add_to_canvas (ViewLayers.ViewLayer.NOBS_LAYER_ID, view_canvas);
    }

    public Utils.Nobs.Nob hit_test (double x, double y) {
        double scale = view_canvas.current_scale;
        return nobs.hit_test (x, y, scale);
    }

    private void on_update_select_effect () {
        var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            remove_select_effect ();
            return;
        }

        int new_id = sm.selection.first_node ().id;
        last_id = new_id;
        update_nob_positions (sm.selection);
        update_nob_layer ();
    }

    /*
     * Resets all selection and nob items.
     */
    private void remove_select_effect () {
        nobs.set_active (false);
        update_nob_layer ();
        nob_layer.set_visible (false);
        last_id = -1;
    }

    /**
     * Update the position of all nobs of selected items. It will show or hide
     * them based on the properties of the selection.
     */
    private void update_nob_positions (Lib2.Items.NodeSelection selection) {
        var nob_size = Lib.Selection.Nob.NOB_SIZE / view_canvas.current_scale;

        var rect = selection.coordinates ();

        var width = rect.width;
        var height = rect.height;

        bool show_h_centers = height > nob_size * 3;
        bool show_v_centers = width > nob_size * 3;

        var active_nob_id = view_canvas.mode_manager.active_mode_nob;

        foreach (var nob in nobs.data) {
            bool set_visible = true;

            if (!show_h_centers && Utils.Nobs.is_horizontal_center (nob.handle_id)) {
                set_visible = false;
            } else if (!show_v_centers && Utils.Nobs.is_vertical_center (nob.handle_id)) {
                set_visible = false;
            }

            update_nob (ref nob, rect, set_visible && !nob_masked (nob, active_nob_id));
        }
    }

    private bool nob_masked (Utils.Nobs.NobData nob, Utils.Nobs.Nob nob_id) {
        if (nob_id == Utils.Nobs.Nob.NONE) {
            return true;
        } else if (nob_id == Utils.Nobs.Nob.ALL) {
            return false;
        }

        return nob.handle_id != nob_id;
    }

    private void update_nob (
        ref Utils.Nobs.NobData nob,
        Geometry.Quad rect,
        bool show
    ) {
        double sc = view_canvas.current_scale;
        var n0 = nob.handle_id;
        double cx = 0;
        double cy = 0;
        Utils.Nobs.nob_xy_from_coordinates (n0, rect, sc, ref cx, ref cy);

        nob.center_x = cx;
        nob.center_y = cy;
        nob.active = show;
    }

    private void update_nob_layer () {
        nob_layer.update_nob_data (nobs);
    }

}
