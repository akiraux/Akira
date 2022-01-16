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
public class Akira.Lib.Managers.NobManager : Object {
    private const string STROKE_COLOR = "#666";
    private const double LINE_WIDTH = 1.0;

    public weak Lib.ViewCanvas view_canvas { get; construct; }

    private Utils.Nobs.NobSet nobs;
    private ViewLayers.ViewLayerNobs nob_layer = null;
    public int? anchor_point_node_id;

    // Tracks if an artboard is part of the current selection.
    private int last_id = -1;

    public NobManager (Lib.ViewCanvas canvas) {
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
        unowned var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            remove_select_effect ();
            remove_anchor_point_effect ();
            anchor_point_node_id = null;
            return;
        }

        int new_id = sm.selection.first_node ().id;
        last_id = new_id;
        update_nob_positions (sm.selection);
        update_nob_layer ();

        // Set the nob layer visible after is has been set non-visible by remove_select_effect
        nob_layer.set_visible (true);
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
    private void update_nob_positions (Lib.Items.NodeSelection selection) {
        var nob_size = Utils.Nobs.NobData.NOB_SIZE / view_canvas.current_scale;

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

    public void toggle_anchor_point (int id) {
        remove_anchor_point_effect ();

        if (anchor_point_node_id == id) {
            anchor_point_node_id = null;
            return;
        }

        anchor_point_node_id = id;

        maybe_create_anchor_point_effect ();
    }

    private void remove_anchor_point_effect () {
        nob_layer.add_anchor_point (null);
    }

    private void maybe_create_anchor_point_effect () {
        var node = view_canvas.items_manager.node_from_id (anchor_point_node_id);
        if (node == null) {
            assert (node != null);
            return;
        }

        nob_layer.add_anchor_point (node.instance.drawable);
    }

}
