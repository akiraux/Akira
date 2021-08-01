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
 */

 // #TODO: ATTRIBUTE GOOCANVAS

/*
 * A drawable for handling snapping lines and dots.
 */
public class Akira.Drawables.DrawableSnapData : Goo.CanvasItemSimple, Goo.CanvasItem {
    public double x { get; set; default = 0; }
    public double y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }

    private Utils.Snapping2.SnapMatchData2 _data;
    private Utils.Snapping2.SnapGrid2 _grid;

    private double[] v_lines;
    private double[] h_lines;

    private double[] dot_x;
    private double[] dot_y;

    public DrawableSnapData (Goo.CanvasItem parent, double x, double y, double width, double height) {
       this.parent = parent;
       this.x = x;
       this.y = y;
       this.width = width;
       this.height = height;

       // Add the newly created item to the Canvas or Artboard.
       parent.add_child (this, -1);
    }

    public void update_data (Utils.Snapping2.SnapMatchData2 data, Utils.Snapping2.SnapGrid2 grid) {
        _data = data;
        _grid = grid;

        // #TODO Obvious optimizations possible
        v_lines = new double[0];
        h_lines = new double[0];
        dot_x = new double[0];
        dot_y = new double[0];

        if (data.v_data.snap_found ()) {
            foreach (var snap_position in data.v_data.exact_matches) {
                add_decorator_line (snap_position, grid.v_snaps, true);
            }
        }

        if (data.h_data.snap_found ()) {
            foreach (var snap_position in data.h_data.exact_matches) {
                add_decorator_line (snap_position, grid.h_snaps, false);
            }
        }

    }

    private void add_decorator_line (
        int pos,
        Gee.TreeMap<int, Utils.Snapping2.SnapMeta2> exact_matches,
        bool vertical
    ) {

        var snap_value = exact_matches.get (pos);
        if (snap_value == null) {
            return;
        }

        double actual_pos = (double) pos;

        if (vertical) {
            add_to_darray (ref h_lines, actual_pos);
        }
        else {
            add_to_darray (ref v_lines, actual_pos);
        }

        foreach (var normal in snap_value.normals) {
            add_dot (actual_pos, normal, vertical);
        }

    }

    private void add_dot (double pos, double normal, bool vertical) {
        if (vertical) {
            add_to_darray (ref dot_x, normal);
            add_to_darray (ref dot_y, pos);
        }
        else {
            add_to_darray (ref dot_x, pos);
            add_to_darray (ref dot_y, normal);
        }
    }

    private void add_to_darray (ref double[] a, double value) {
        a.resize (a.length + 1);
        a[a.length - 1] = value;
    }

    // CanvasItemSimple methods
    public unowned GLib.List<Goo.CanvasItem> get_items_at (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_visible,
        GLib.List<Goo.CanvasItem> found_items
    ) {
        return found_items;
    }

    public override void simple_create_path (Cairo.Context cr) {}

    public override void simple_update (Cairo.Context cr) {
        bounds.x1 = x;
        bounds.y1 = y;
        bounds.x2 = x + width;
        bounds.y2 = y + height;
    }


    public void paint (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        /* Skip the item if the bounds don't intersect the expose rectangle. */
        if (bounds.x1 > target_bounds.x2 || bounds.x2 < target_bounds.x1
            || bounds.y1 > target_bounds.y2 || bounds.y2 < target_bounds.y1) {
          return;
        }

        /* Check if the item should be visible. */
        if (visibility <= Goo.CanvasItemVisibility.INVISIBLE
            || (visibility == Goo.CanvasItemVisibility.VISIBLE_ABOVE_THRESHOLD
            && scale < visibility_threshold)) {
          return;
        }

        draw_vertical_lines (cr, target_bounds, scale);
        draw_horizontal_lines (cr, target_bounds, scale);
        draw_dots (cr, target_bounds, scale);
    }

    private void draw_vertical_lines (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        if (v_lines.length == 0) {
            return;
        }

        cr.save ();
        cr.new_path ();

        cr.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        cr.set_line_width (1 / scale);

        foreach (var v in v_lines) {
            cr.move_to (v, y);
            cr.line_to (v, height);
            cr.stroke ();
        }

        cr.restore ();
    }

    private void draw_horizontal_lines (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        if (h_lines.length == 0) {
            return;
        }

        cr.save ();
        cr.new_path ();

        cr.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        cr.set_line_width (1 / scale);

        foreach (var v in h_lines) {
            cr.move_to (x, v);
            cr.line_to (width, v);
            cr.stroke ();
        }

        cr.restore ();
    }

    private void draw_dots (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        if (dot_x.length == 0 || dot_x.length != dot_y.length) {
            return;
        }

        cr.save ();
        cr.new_path ();

        cr.set_line_width (1 / scale);

        cr.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        for (var i = 0; i < dot_x.length; ++i) {
            cr.arc (dot_x[i], dot_y[i], 2 / scale, 0, 2.0 * GLib.Math.PI);
            cr.fill ();
        }

        cr.restore ();
    }
}
