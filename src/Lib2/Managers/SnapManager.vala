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

public class Akira.Lib2.Managers.SnapManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    // Decorator items to be drawn in the Canvas.
    private ViewLayers.ViewLayerSnaps v_decorators;
    private ViewLayers.ViewLayerSnaps h_decorators;

    /*
     * Type of snap guides to show (could be a selection or just a point).
     */
    public enum SnapGuideType {
        NONE,
        SELECTION,
        POINT
    }

    /*
     * Data that can be used to tell the SnapManager details on how to show snap guides.
     */
    public class SnapGuideData {
        public SnapGuideType type = SnapGuideType.NONE;
        public double x = 0.0;
        public double y = 0.0;
    }

    private bool any_decorators_visible = false;

    public SnapManager (ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    construct {
        view_canvas.window.event_bus.update_snaps_color.connect (on_update_snaps_color);
    }

    /*
     * Generate guides as indicated by the data.
     */
    public void generate_decorators (SnapGuideData new_data) {
        switch (new_data.type) {
            case SnapGuideType.NONE:
                reset_decorators ();
                break;
            case SnapGuideType.SELECTION:
                unowned var selection = view_canvas.selection_manager.selection;
                var sensitivity = Utils.Snapping2.adjusted_sensitivity (view_canvas.current_scale);
                var selection_area = selection.bounding_box ();

                var snap_grid = Utils.Snapping2.generate_best_snap_grid (
                    view_canvas,
                    selection,
                    selection_area,
                    sensitivity
                );

                var matches = Utils.Snapping2.generate_snap_matches (
                    snap_grid,
                    selection,
                    selection_area,
                    sensitivity
                );

                populate_decorators_from_data (matches, snap_grid);
                break;
            case SnapGuideType.POINT:
                // TODO
                break;
        }
    }

    /*
     * Returns true if the manager has active decorators
     */
    public bool is_active () {
        return any_decorators_visible;
    }

    /*
     * Makes all decorators invisible, and ready to be reused
     */
    public void reset_decorators () {
        if (any_decorators_visible) {
            if (v_decorators != null) {
                v_decorators.hide_drawable ();
            }

            if (h_decorators != null) {
                h_decorators.hide_drawable ();
            }
        }

        any_decorators_visible = false;
    }

    /*
     * Populates decorators (if applicable) based on match data and the snap grid.
     * Reuses decorator Goo.CanvasItems if possible, otherwise constructs new ones.
     */
    public void populate_decorators_from_data (Utils.Snapping2.SnapMatchData2 data, Utils.Snapping2.SnapGrid2 grid) {
        reset_decorators ();

        if (data.v_data.snap_found () || data.h_data.snap_found ()) {
            if (v_decorators == null) {
                v_decorators = new ViewLayers.ViewLayerSnaps (
                    0,
                    0,
                    Layouts.MainCanvas.CANVAS_SIZE,
                    Layouts.MainCanvas.CANVAS_SIZE,
                    false
                );

                v_decorators.add_to_canvas (ViewLayers.ViewLayer.VSNAPS_LAYER_ID, view_canvas);
                on_update_snaps_color ();
            }

            if (h_decorators == null) {
                h_decorators = new ViewLayers.ViewLayerSnaps (
                    0,
                    0,
                    Layouts.MainCanvas.CANVAS_SIZE,
                    Layouts.MainCanvas.CANVAS_SIZE,
                    true
                );

                h_decorators.add_to_canvas (ViewLayers.ViewLayer.HSNAPS_LAYER_ID, view_canvas);
                on_update_snaps_color ();
            }


            v_decorators.update_data (data.v_data, grid.v_snaps);
            h_decorators.update_data (data.h_data, grid.h_snaps);

            if (!any_decorators_visible) {
                v_decorators.set_visible (true);
                h_decorators.set_visible (true);
            }

            any_decorators_visible = true;
        }
    }

    /*
     * Update decorator colors
     */
    private void on_update_snaps_color () {
        var color = Gdk.RGBA ();
        if (!color.parse (settings.snaps_color)) {
            return;
        }

        if (v_decorators != null) {
            v_decorators.update_color (color);
        }

        if (h_decorators != null) {
            h_decorators.update_color (color);
        }
    }
}
