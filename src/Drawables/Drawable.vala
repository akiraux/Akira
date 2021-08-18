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
 * Overrides methods in Goo.CanvasItemSimple to handle a few things differently:
 * 1. Have uniform strokes in transfomed objects.
 * 2. Add a clipping quad to make clipping more efficient.
 */
public class Akira.Drawables.Drawable {
    public enum BorderType {
        CENTER,
        INSIDE,
        OUTSIDE
    }

    // Style
    public double line_width { get; set; default = 0; }
    public Gdk.RGBA fill_rgba { get; set; default = Gdk.RGBA (); }
    public Gdk.RGBA stroke_rgba { get; set; default = Gdk.RGBA (); }

    public int parent_id { get; set; default = -1; }
    public double center_x { get; set; default = 0; }
    public double center_y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }
    public BorderType border_type { get; set; default = BorderType.CENTER; }

    public Cairo.Matrix transform { get; set; default = Cairo.Matrix.identity (); }
    public Geometry.Rectangle bounds { get; set; default = Geometry.Rectangle (); }

    // Clipping path in global reference frame
    public Geometry.Quad? clipping_path = null;

    public bool new_hit_test (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_visible
    ) {
        double user_x = x, user_y = y;
        bool add_item = false;

        // Ignore if out of bounds
        if (bounds.left > x || bounds.right < x || bounds.top > y || bounds.bottom < y) {
          return false;
        }

        Cairo.Matrix global_transform = cr.get_matrix ();
        cr.save ();

        Cairo.Matrix tr = transform;
        cr.transform (tr);

        // Account for clipping path first, since they should be in the global reference
        if (clipping_path != null) {
            cr.move_to (clipping_path.tl_x, clipping_path.tl_y);
            cr.line_to (clipping_path.tr_x, clipping_path.tr_y);
            cr.line_to (clipping_path.br_x, clipping_path.br_y);
            cr.line_to (clipping_path.bl_x, clipping_path.bl_y);
            cr.close_path ();

            cr.set_fill_rule (Cairo.FillRule.WINDING);
            if (!cr.in_fill (user_x, user_y)) {
                cr.restore ();
                cr.new_path ();
                return false;
            }
        }

        cr.device_to_user (ref user_x, ref user_y);

        /* Remove any current translation, to avoid the 16-bit cairo limit. */
        var tmp = cr.get_matrix ();
        tmp.x0 = 0.0;
        tmp.y0 = 0.0;
        cr.set_matrix (tmp);

        simple_create_path (cr);

        /* Check the filled path, if required. */
        if (set_fill_options (cr)) {
            if (cr.in_fill (user_x, user_y)) {
                add_item = true;
            }
        }

        /* Check the stroke, if required. */
        if (set_stroke_options (cr)) {
            cr.set_matrix (global_transform);
            user_x = x - tr.x0;
            user_y = y - tr.y0;

            if (cr.in_stroke (user_x, user_y)) {
                add_item = true;
            }
        }

        cr.restore ();
        cr.new_path ();

        return add_item;
    }


    public unowned GLib.List<Drawable> get_items_at (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_visible,
        GLib.List<Drawable> found_items
    ) {
        if (new_hit_test (x, y, cr, is_pointer_event, parent_visible)) {
            found_items.prepend (this);
        }

        return found_items;
    }

    public bool set_fill_options (Cairo.Context context) {
        context.set_source_rgba (fill_rgba.red, fill_rgba.green, fill_rgba.blue, fill_rgba.alpha);
        context.set_antialias (Cairo.Antialias.GRAY);
        return true;
    }

    public bool set_stroke_options (Cairo.Context context) {
        context.set_source_rgba (stroke_rgba.red, stroke_rgba.green, stroke_rgba.blue, stroke_rgba.alpha);
        context.set_line_width (line_width);
        context.set_antialias (Cairo.Antialias.GRAY);
        return line_width > 0;
    }

    public virtual void simple_create_path (Cairo.Context context) {}

    public void paint (Cairo.Context cr, Geometry.Rectangle target_bounds, double scale) {
        // Simple bounds check
        if (bounds.left > target_bounds.right || bounds.right < target_bounds.left
            || bounds.top > target_bounds.bottom || bounds.bottom < target_bounds.top) {
          return;
        }

        cr.save ();
        Cairo.Matrix global_transform = cr.get_matrix ();

        // The clipping path is in global coordinates, so we can ignore the transformation.
        if (clipping_path != null) {
            cr.move_to (clipping_path.tl_x, clipping_path.tl_y);
            cr.line_to (clipping_path.tr_x, clipping_path.tr_y);
            cr.line_to (clipping_path.br_x, clipping_path.br_y);
            cr.line_to (clipping_path.bl_x, clipping_path.bl_y);
            cr.close_path ();
            cr.set_fill_rule (Cairo.FillRule.WINDING);
            cr.clip ();
        }

        // We apply the item transform before creating the path
        Cairo.Matrix tr = transform;
        cr.transform (tr);

        simple_create_path (cr);

        if (set_fill_options (cr)) {
            cr.fill_preserve ();
        }

        // We restore the global transformation to draw strokes with uniform width. Changing
        // the matrix does not affect the path already generated.
        cr.set_matrix (global_transform);

        if (set_stroke_options (cr)) {
            cr.stroke ();
        }

        cr.restore ();

        // Very important to initialize new path
        cr.new_path ();
    }

    public void paint_hover (Cairo.Context cr, Gdk.RGBA color, double line_width, Geometry.Rectangle target_bounds, double scale) {
        cr.save ();
        Cairo.Matrix global_transform = cr.get_matrix ();

        // We apply the item transform before creating the path
        Cairo.Matrix tr = transform;
        cr.transform (tr);

        simple_create_path (cr);

        cr.set_line_width (line_width / scale);
        cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        cr.stroke ();

        cr.restore ();

        // Very important to initialize new path
        cr.new_path ();
    }

    public Geometry.Rectangle generate_bounding_box () {
        double x1 = 0;
        double x2 = 0;
        double y1 = 0;
        double y2 = 0;

        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        Cairo.Context context = new Cairo.Context (surface);

        context.set_antialias (Cairo.Antialias.GRAY);

        Cairo.Matrix tr = transform;
        context.transform (tr);

        double translate_x = tr.x0;
        double translate_y = tr.y0;

        var fill_bounds = Geometry.Rectangle ();
        var stroke_bounds = Geometry.Rectangle ();

        set_fill_options (context);

        simple_create_path (context);

        context.set_matrix (Cairo.Matrix (1.0, 0.0, 0.0, 1.0, translate_x, translate_y));

        context.fill_extents (
            out fill_bounds.left,
            out fill_bounds.top,
            out fill_bounds.right,
            out fill_bounds.bottom
        );

        set_stroke_options (context);

        context.stroke_extents (
            out stroke_bounds.left,
            out stroke_bounds.top,
            out stroke_bounds.right,
            out stroke_bounds.bottom
        );

        if (fill_bounds.left == 0.0 && fill_bounds.right == 0.0) {
          /* The fill bounds are empty so just use the stroke bounds.
         If the stroke bounds are also empty the bounds will be all 0.0. */
            x1 = stroke_bounds.left;
            x2 = stroke_bounds.right;
            y1 = stroke_bounds.top;
            y2 = stroke_bounds.bottom;
        } else if (stroke_bounds.left == 0.0 && stroke_bounds.right == 0.0) {
          /* The stroke bounds are empty so just use the fill bounds. */
            x1 = fill_bounds.left;
            x2 = fill_bounds.right;
            y1 = fill_bounds.top;
            y2 = fill_bounds.bottom;
        } else {
          /* Both fill & stoke bounds are non-empty so combine them. */
          Utils.GeometryMath.min_max_coords (
              fill_bounds.left,
              fill_bounds.right,
              stroke_bounds.left,
              stroke_bounds.right,
              ref x1,
              ref x2
          );

          Utils.GeometryMath.min_max_coords (
              fill_bounds.top,
              fill_bounds.bottom,
              stroke_bounds.top,
              stroke_bounds.bottom,
              ref y1,
              ref y2
          );
        }

        return Geometry.Rectangle.with_coordinates (
            x1 + translate_x,
            y1 + translate_y,
            x2 + translate_x,
            y2 + translate_y
        );
    }
}
