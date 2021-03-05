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
* Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
*/

// This manager handles snap generation. It uses a list of selected items, and a list of candidate items to determine
// whether snaps in the vertical and horizontal directions are suggested.
//
// Selected items may be a collection of items being dragged.
//
// Candidate items may be all items in the canvas, or items within an artboard.
//
// Matching is done in the vertical and horizontal directiosn independently


public class Akira.Lib.Managers.SnapManager : Object {
    private const string STROKE_COLOR = "#ff0000";
    private const double LINE_WIDTH = 0.5;
    private const double DOT_RADIUS = 2.0;
    private const double SENSITIVITY = 5.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }


    // Decorator items to be drawn in the Canvas
    private Goo.CanvasItem root;
    private Gee.ArrayList<Goo.CanvasItemSimple> v_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> h_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> decorator_dots;

    // Last generated match data
    public Utils.Snapping.SnapGrid snap_grid;
    public Utils.Snapping.SnapMatchData snap_match_data;

    public SnapManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        snap_grid.v_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();
        snap_grid.v_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();

        snap_match_data.h_data.exact_matches = new Gee.HashMap<int, int> ();
        snap_match_data.v_data.exact_matches = new Gee.HashMap<int, int> ();

        v_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        h_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        decorator_dots = new Gee.ArrayList<Goo.CanvasItemSimple> ();
    }

    public void reset () {
        snap_grid.v_snaps.clear ();
        snap_grid.h_snaps.clear ();
        reset_matches ();
        reset_decorators ();
    }

    public void reset_matches () {
        snap_match_data.h_data.type = Utils.Snapping.MatchType.NONE;
        snap_match_data.h_data.reference_position = 0;
        snap_match_data.h_data.snap_position = 0;
        snap_match_data.h_data.polarity_offset = 0;
        snap_match_data.h_data.exact_matches.clear ();

        snap_match_data.v_data.type = Utils.Snapping.MatchType.NONE;
        snap_match_data.v_data.reference_position = 0;
        snap_match_data.v_data.snap_position = 0;
        snap_match_data.v_data.polarity_offset = 0;
        snap_match_data.v_data.exact_matches.clear ();
    }

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
    }

    public void generate_snap_matches (List<Items.CanvasItem> selection) {
        snap_grid = Utils.Snapping.snap_grid_from_canvas(canvas, selection, (int)SENSITIVITY);

        snap_match_data = Utils.Snapping.generate_snap_matches(snap_grid, selection, (int)SENSITIVITY);
    }

    public void populate_decorators () {
        if (root == null) {
            root = canvas.get_root_item ();
        }

        reset_decorators ();

       if (snap_match_data.v_data.snap_found ()) {
            foreach (var snap_position in snap_match_data.v_data.exact_matches) {
                add_vertical_decorator_line (snap_position.key, snap_position.value);
            }
       }

       if (snap_match_data.h_data.snap_found ()) {
            foreach (var snap_position in snap_match_data.h_data.exact_matches) {
                add_horizontal_decorator_line (snap_position.key, snap_position.value);
            }
       }

    }

    private void add_vertical_decorator_line (int pos, int polarity_offset) {
        var snap_value = snap_grid.v_snaps.get (pos);
        if (snap_value != null) {

            // add dots
            foreach (var normal in snap_value.normals) {
                add_decorator_dot (normal, pos + polarity_offset);
            }

            // add lines (reuse if possible
            foreach (var line in v_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set ("y", (double)pos + polarity_offset);
                    line.set ("line-width", LINE_WIDTH / canvas.current_scale);
                    line.raise (null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line (
                null,
                canvas.x1, pos + polarity_offset,
                canvas.x2, pos + polarity_offset,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set ("parent", root);
            tmp.raise (null);
            v_decorator_lines.add (tmp);
        }
    }

    private void add_horizontal_decorator_line (int pos, int polarity_offset) {
        var snap_value = snap_grid.h_snaps.get (pos);
        if (snap_value != null) {

            // add dots
            foreach (var normal in snap_value.normals) {
                add_decorator_dot (pos + polarity_offset, normal);
            }

            // add lines (reuse if possible
            foreach (var line in h_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set ("x", (double)pos + polarity_offset);
                    line.set ("line-width", LINE_WIDTH / canvas.current_scale);
                    line.raise (null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line (
                null,
                pos + polarity_offset, canvas.y1,
                pos + polarity_offset, canvas.y2,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set ("parent", root);
            tmp.raise (null);
            h_decorator_lines.add (tmp);
        }
    }

    private void add_decorator_dot (int x, int y) {
        // add dot
        foreach (var line in decorator_dots) {
            if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                line.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
                line.set ("center_x", (double)x);
                line.set ("center_y", (double)y);
                line.set ("radius_x", DOT_RADIUS / canvas.current_scale);
                line.set ("radius_y", DOT_RADIUS / canvas.current_scale);
                line.raise (null);
                return;
            }
        }

        var tmp = new Goo.CanvasEllipse (
            null,
            x, y,
            DOT_RADIUS / canvas.current_scale, DOT_RADIUS / canvas.current_scale,
            "line-width", 0.0,
            "fill-color", STROKE_COLOR,
            null
        );

        tmp.can_focus = false;
        tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

        tmp.set ("parent", root);
        tmp.raise (null);
        decorator_dots.add (tmp);
    }

}
