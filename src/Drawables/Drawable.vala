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
    public enum HitTestType {
        SELECT,
        GROUP_REGION
    }

    public enum BorderType {
        CENTER,
        INSIDE,
        OUTSIDE
    }

    // Constant styling.
    private const int TARGET_SCALE = 10;

    // Style
    public double line_width { get; set; default = 0; }
    public Gdk.RGBA fill_rgba { get; set; default = Gdk.RGBA (); }
    public Gdk.RGBA stroke_rgba { get; set; default = Gdk.RGBA (); }
    public BorderType border_type { get; set; default = BorderType.CENTER; }
    public double radius_tr { get; set; default = 0; }
    public double radius_tl { get; set; default = 0; }
    public double radius_br { get; set; default = 0; }
    public double radius_bl { get; set; default = 0; }

    public int parent_id { get; set; default = -1; }
    public string label { get; set; default = ""; }
    public double center_x { get; set; default = 0; }
    public double center_y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }
    public Cairo.Matrix transform { get; set; default = Cairo.Matrix.identity (); }

    public Geometry.Rectangle bounds { get; set; default = Geometry.Rectangle (); }

    // Clipping path in global reference frame
    public Geometry.Quad? clipping_path = null;

    // Convenience getters
    public bool has_radius { get { return (radius_tr + radius_tl + radius_br + radius_bl) > 0; } }

    public bool is_drawn = false;

    /*
     * Return true if the position x,y in local coordinates is inside of the selectable
     * area of a drawable.
     */
    public virtual bool hit_test (
        double x,
        double y,
        Cairo.Context context,
        double scale,
        HitTestType hit_test_type
    ) {
        if (hit_test_type == GROUP_REGION) {
            return false;
        }

        double user_x = x, user_y = y;
        bool add_item = false;

        // Ignore if out of bounds
        if (bounds.does_not_contain (x, y)) {
            return false;
        }

        Cairo.Matrix global_transform = context.get_matrix ();
        context.save ();

        Cairo.Matrix tr = transform;
        context.transform (tr);

        // Account for clipping path first, since they should be in the global reference
        if (clipping_path != null) {
            context.move_to (clipping_path.tl_x, clipping_path.tl_y);
            context.line_to (clipping_path.tr_x, clipping_path.tr_y);
            context.line_to (clipping_path.br_x, clipping_path.br_y);
            context.line_to (clipping_path.bl_x, clipping_path.bl_y);
            context.close_path ();

            context.set_fill_rule (Cairo.FillRule.WINDING);
            if (!context.in_fill (user_x, user_y)) {
                context.restore ();
                context.new_path ();
                return false;
            }
        }

        context.device_to_user (ref user_x, ref user_y);

        /* Remove any current translation, to avoid the 16-bit cairo limit. */
        var tmp = context.get_matrix ();
        tmp.x0 = 0.0;
        tmp.y0 = 0.0;
        context.set_matrix (tmp);

        simple_create_path (context);

        /* Check the filled path, if required. */
        if (set_fill_options (context)) {
            if (context.in_fill (user_x, user_y)) {
                add_item = true;
            }
        }

        /* Check the stroke, if required. */
        if (set_stroke_options (context)) {
            context.set_matrix (global_transform);
            user_x = x - tr.x0;
            user_y = y - tr.y0;

            if (context.in_stroke (user_x, user_y)) {
                add_item = true;
            }
        }

        context.restore ();
        context.new_path ();

        return add_item;
    }

    /*
     * Create the path for an drawable, used in other methods.
     */
    public virtual void simple_create_path (Cairo.Context context) {}

    /*
     * Main paint method.
     */
    public virtual void paint (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        // Simple bounds check
        if (bounds.left > target_bounds.right || bounds.right < target_bounds.left
            || bounds.top > target_bounds.bottom || bounds.bottom < target_bounds.top) {
          return;
        }

        context.save ();
        Cairo.Matrix global_transform = context.get_matrix ();

        // The clipping path is in global coordinates, so we can ignore the transformation.
        if (clipping_path != null) {
            context.move_to (clipping_path.tl_x, clipping_path.tl_y);
            context.line_to (clipping_path.tr_x, clipping_path.tr_y);
            context.line_to (clipping_path.br_x, clipping_path.br_y);
            context.line_to (clipping_path.bl_x, clipping_path.bl_y);
            context.close_path ();
            context.set_fill_rule (Cairo.FillRule.WINDING);
            context.clip ();
        }

        // We apply the item transform before creating the path
        Cairo.Matrix tr = transform;
        context.transform (tr);

        simple_create_path (context);

        if (set_fill_options (context)) {
            context.fill_preserve ();
        }

        // We restore the global transformation to draw strokes with uniform width. Changing
        // the matrix does not affect the path already generated.
        context.set_matrix (global_transform);

        if (set_stroke_options (context)) {
            context.stroke ();
        }

        context.restore ();

        // Very important to initialize new path
        context.new_path ();

        is_drawn = true;
    }

    /*
     * Hover paint method for the drawable.
     */
    public virtual void paint_hover (
        Cairo.Context context,
        Gdk.RGBA color,
        double line_width,
        Geometry.Rectangle target_bounds,
        double scale
    ) {
        context.save ();
        Cairo.Matrix global_transform = context.get_matrix ();

        // We apply the item transform before creating the path
        Cairo.Matrix tr = transform;
        context.transform (tr);

        simple_create_path (context);

        context.set_line_width (line_width / scale);
        context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        context.set_matrix (global_transform);
        context.stroke ();

        context.restore ();

        // Very important to initialize new path
        context.new_path ();
    }

    /*
     * Create a target like element on top of the drawable to represent the
     * current subselection anchor point that will be used as alignment pivot.
     */
    public virtual void paint_anchor (
        Cairo.Context context,
        Gdk.RGBA color,
        double line_width,
        double scale
    ) {
        context.save ();
        Cairo.Matrix global_transform = context.get_matrix ();

        // We apply the item transform before creating the path
        Cairo.Matrix tr = transform;
        context.transform (tr);

        var t_scale = TARGET_SCALE / scale;
        // context.save ();
        context.new_path ();
        context.scale (t_scale, t_scale);
        context.arc (0.0, 0.0, 1.0, 0.0, 2.0 * GLib.Math.PI);
        // context.restore ();

        context.set_line_width (line_width / scale);
        context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        context.set_matrix (global_transform);
        context.stroke ();

        context.restore ();

        // Very important to initialize new path
        context.new_path ();
    }

    /*
     * Generates the bounding box for the drawable.
    */
    public virtual Geometry.Rectangle generate_bounding_box () {
        double x1 = 0;
        double x2 = 0;
        double y1 = 0;
        double y2 = 0;

        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.A1, 1, 1);
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

    public virtual void request_redraw (ViewLayers.BaseCanvas canvas, bool recalculate_bounds) {
        if (recalculate_bounds) {
            bounds = generate_bounding_box ();
        }
        else if (!is_drawn) {
            // This request is to clear the old draw, but since it was never drawn, we can ignore.
            return;
        }

        canvas.request_redraw (bounds);
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

}
