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
    private const double LINE_WIDTH = 0.5;
    private const double DOT_RADIUS = 2.0;

    public unowned ViewCanvas view_canvas { get; construct; }

    // Decorator items to be drawn in the Canvas.
    private Goo.CanvasItem root;
    private Gee.ArrayList<Goo.CanvasItemSimple> v_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> h_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> decorator_dots;

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
        v_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        h_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        decorator_dots = new Gee.ArrayList<Goo.CanvasItemSimple> ();

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
        foreach (var decorator in v_decorator_lines) {
            decorator.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        foreach (var decorator in h_decorator_lines) {
            decorator.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        foreach (var decorator in decorator_dots) {
            decorator.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }

        any_decorators_visible = false;
    }

    /*
     * Populates decorators (if applicable) based on match data and the snap grid.
     * Reuses decorator Goo.CanvasItems if possible, otherwise constructs new ones.
     */
    public void populate_decorators_from_data (Utils.Snapping.SnapMatchData data, Utils.Snapping.SnapGrid grid) {
        if (root == null) {
            root = view_canvas.get_root_item ();
        }

        reset_decorators ();

        if (data.v_data.snap_found ()) {
            foreach (var snap_position in data.v_data.exact_matches) {
                any_decorators_visible = true;
                add_vertical_decorator_line (snap_position.key, snap_position.value, grid);
            }
        }

        if (data.h_data.snap_found ()) {
            foreach (var snap_position in data.h_data.exact_matches) {
                any_decorators_visible = true;
                add_horizontal_decorator_line (snap_position.key, snap_position.value, grid);
            }
        }
    }

    private void add_vertical_decorator_line (int pos, int polarity_offset, Utils.Snapping.SnapGrid grid) {
        double lw = LINE_WIDTH / view_canvas.current_scale;
        var snap_value = grid.v_snaps.get (pos);
        if (snap_value != null) {
            // To actually show decorators in their exact position, we offset by 0.5.
            double actual_pos = (double) (pos + polarity_offset);

            // Add dots.
            foreach (var normal in snap_value.normals) {
                add_decorator_dot (normal, actual_pos);
            }

            // Add lines (reuse if possible).
            foreach (var line in v_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set ("y", actual_pos);
                    line.set ("line-width", lw);
                    line.raise (null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line (
                null,
                view_canvas.x1, actual_pos,
                view_canvas.x2, actual_pos,
                "line-width", lw,
                "stroke-color", settings.snaps_color,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set ("parent", root);
            tmp.raise (null);
            v_decorator_lines.add (tmp);
        }
    }

    private void add_horizontal_decorator_line (int pos, int polarity_offset, Utils.Snapping.SnapGrid grid) {
        double lw = LINE_WIDTH / view_canvas.current_scale;
        var snap_value = grid.h_snaps.get (pos);
        if (snap_value != null) {
            double actual_pos = (double) (pos + polarity_offset);

            // Add dots.
            foreach (var normal in snap_value.normals) {
                add_decorator_dot (actual_pos, normal);
            }

            // Add lines (reuse if possible).
            foreach (var line in h_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set ("x", actual_pos);
                    line.set ("line-width", lw);
                    line.raise (null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line (
                null,
                actual_pos, view_canvas.y1,
                actual_pos, view_canvas.y2,
                "line-width", lw,
                "stroke-color", settings.snaps_color,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set ("parent", root);
            tmp.raise (null);
            h_decorator_lines.add (tmp);
        }
    }

    private void add_decorator_dot (double x, double y) {
        double dot_radius = DOT_RADIUS / view_canvas.current_scale;

        // Add dot.
        foreach (var line in decorator_dots) {
            if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                line.set ("center_x", x);
                line.set ("center_y", y);
                line.set ("radius_x", dot_radius);
                line.set ("radius_y", dot_radius);
                line.raise (null);
                return;
            }
        }

        var tmp = new Goo.CanvasEllipse (
            null,
            x, y,
            dot_radius, dot_radius,
            "line-width", 0.0,
            "fill-color", settings.snaps_color,
            null
        );

        tmp.can_focus = false;
        tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

        tmp.set ("parent", root);
        tmp.raise (null);
        decorator_dots.add (tmp);
    }

    /*
     * Loop through all the existing guides and update the color.
     */
    private void on_update_snaps_color () {
        // Points.
        foreach (var dot in decorator_dots) {
            dot.set ("fill-color", settings.snaps_color);
        }

        // Horizontal lines.
        foreach (var line in h_decorator_lines) {
            line.set ("stroke-color", settings.snaps_color);
        }

        // Vertical lines.
        foreach (var line in v_decorator_lines) {
            line.set ("stroke-color", settings.snaps_color);
        }
    }
}
