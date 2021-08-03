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

/*
 * A drawable for handling snapping lines and dots.
 */
public class Akira.Drawables.DrawableSnapData : Goo.CanvasItemSimple, Goo.CanvasItem {
    private const double LINE_WIDTH = 0.5;
    private const double DOT_RADIUS = 2;
    public double x { get; set; default = 0; }
    public double y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }

    private double[] line_pos;
    private double[] dot_x;
    private double[] dot_y;
    private bool vertical_lines = false;

    private Gdk.RGBA color;

    public DrawableSnapData (
        Goo.CanvasItem parent,
        double x,
        double y,
        double width,
        double height,
        bool vertical_lines
    ) {
       this.parent = parent;
       this.x = x;
       this.y = y;
       this.width = width;
       this.height = height;
       this.vertical_lines = vertical_lines;

       // Add the newly created item to the Canvas or Artboard.
       parent.add_child (this, -1);
    }

    /*
     * Updates drawable data.
     * It shouldn't be hard to optimize this code.
     */
    public void update_data (
        Utils.Snapping2.SnapMatch2 match_data,
        Gee.TreeMap<int, Utils.Snapping2.SnapMeta2> grid_points
    ) {
        line_pos = new double[0];
        dot_x = new double[0];
        dot_y = new double[0];

        if (match_data.snap_found ()) {
            foreach (var match in match_data.exact_matches) {
                var snap_value = grid_points.get (match);
                if (snap_value == null) {
                    return;
                }
                add_decorator_line (match, snap_value);
            }
        }
    }

    /*
     * Public method to update the color of decorators.
     */
    public void update_color (Gdk.RGBA new_color) {
        if (color == new_color) {
            return;
        }

        color = new_color;
        changed (false);
    }

    /*
     * Adds decorator lines and corresponding dots for given matches.
     */
    private void add_decorator_line (
        int pos,
        Utils.Snapping2.SnapMeta2 grid_snap_value
    ) {
        double actual_pos = (double) pos;

        add_to_darray (ref line_pos, actual_pos);

        foreach (var normal in grid_snap_value.normals) {
            add_dot (actual_pos, normal);
        }
    }

    /*
     * Adds dots to the array depending on whether or not the drawable is vertical.
     * This can probably be improved by having a better data structure.
     */
    private void add_dot (double pos, double normal) {
        if (vertical_lines) {
            add_to_darray (ref dot_x, pos);
            add_to_darray (ref dot_y, normal);
        } else {
            add_to_darray (ref dot_y, pos);
            add_to_darray (ref dot_x, normal);
        }
    }

    private void add_to_darray (ref double[] a, double value) {
        a.resize (a.length + 1);
        a[a.length - 1] = value;
    }

    // CanvasItemSimple methods

    /*
     * No hit testing on this.
     */
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

    /*
     * No path necessary, so override this method and ignore it.
     */
    public override void simple_create_path (Cairo.Context cr) {}

    /*
     * For now updates the entire screen. In the future this could be made smarter.
     * Note that this gets called on changed(true), so simply figuring out the area needed for
     * the extents of the lines is NOT enough.
     */
    public override void simple_update (Cairo.Context cr) {
            bounds.x1 = x;
            bounds.y1 = y;

            bounds.x2 = x + width;
            bounds.y2 = y + height;
    }


    /*
     * Overrides paint method and draws decorator lines and dots.
     */
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

        draw_lines (cr, target_bounds, scale);
        draw_dots (cr, target_bounds, scale);
    }

    /*
     * Draw lines. This could be improved to better render lines (more crisp).
     */
    private void draw_lines (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        if (line_pos.length == 0) {
            return;
        }

        cr.save ();
        cr.new_path ();

        cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        cr.set_line_width (1 / scale);

        foreach (var pos in line_pos) {
            if (vertical_lines) {
                cr.move_to (pos, y);
                cr.line_to (pos, height);
            } else {
                cr.move_to (x, pos);
                cr.line_to (width, pos);
            }
            cr.stroke ();
        }

        cr.restore ();
    }

    /*
     * Draw dots.
     */
    private void draw_dots (Cairo.Context cr, Goo.CanvasBounds target_bounds, double scale) {
        if (dot_x.length == 0 || dot_x.length != dot_y.length) {
            return;
        }

        cr.save ();
        cr.new_path ();

        cr.set_line_width (LINE_WIDTH / scale);

        cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        for (var i = 0; i < dot_x.length; ++i) {
            cr.arc (dot_x[i], dot_y[i], DOT_RADIUS / scale, 0, 2.0 * GLib.Math.PI);
            cr.fill ();
        }

        cr.restore ();
    }
}
