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
public class Akira.Drawables.Drawable : Goo.CanvasItemSimple, Goo.CanvasItem {
    public int parent_id { get; set; default = -1; }
    public double center_x { get; set; default = 0; }
    public double center_y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }

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

        if (need_update > 0) {
            ensure_updated ();
        }

        /* Skip the item if the bounds don't intersect the expose rectangle. */
        if (bounds.x1 > x || bounds.x2 < x || bounds.y1 > y || bounds.y2 < y) {
          return false;
        }

        /* Check if the item should receive events. */
        if (is_pointer_event) {
            if (pointer_events == Goo.CanvasPointerEvents.NONE) {
                return false;
            }

            if (Goo.CanvasPointerEvents.VISIBLE_MASK in pointer_events
                && (!parent_visible || visibility <= Goo.CanvasItemVisibility.INVISIBLE ||
                    (visibility == Goo.CanvasItemVisibility.VISIBLE_ABOVE_THRESHOLD
                        && canvas.scale < visibility_threshold))) {
                    return false;
            }
        }

        Cairo.Matrix old = cr.get_matrix ();
        cr.save ();

        Cairo.Matrix tr;
        if (get_transform (out tr)) {
            cr.transform (tr);
        }

        cr.device_to_user (ref user_x, ref user_y);

        /* Remove any current translation, to avoid the 16-bit cairo limit. */
        var tmp = cr.get_matrix ();
        tmp.x0 = 0.0;
        tmp.y0 = 0.0;
        cr.set_matrix (tmp);

        /* If the item has a clip path, check if the point is inside it. */
        if (clipping_path != null) {
            cr.move_to (clipping_path.tl_x, clipping_path.tl_y);
            cr.line_to (clipping_path.tr_x, clipping_path.tr_y);
            cr.line_to (clipping_path.br_x, clipping_path.br_y);
            cr.line_to (clipping_path.bl_x, clipping_path.bl_y);
            cr.close_path ();

            cr.set_fill_rule (Cairo.FillRule.WINDING);
            if (!cr.in_fill (user_x, user_y)) {
                cr.restore ();
                return false;
            }
        }

        simple_create_path (cr);

        bool do_fill = false;
        bool do_stroke = false;
        unowned var style = get_style ();

        var pe = pointer_events;

        /* Check the filled path, if required. */
        if (Goo.CanvasPointerEvents.FILL_MASK in pe) {
            do_fill = style.set_fill_options (cr);
            if (!(Goo.CanvasPointerEvents.PAINTED_MASK in pe) || do_fill) {
                if (cr.in_fill (user_x, user_y)) {
                    add_item = true;
                }
            }
        }

        /* Check the stroke, if required. */
        if (!add_item && Goo.CanvasPointerEvents.STROKE_MASK in pe) {
            do_stroke = style.set_stroke_options (cr);
            if (!(Goo.CanvasPointerEvents.PAINTED_MASK in pe) || do_stroke) {
                cr.set_matrix (old);
                user_x = x - tr.x0;
                user_y = y - tr.y0;

                if (cr.in_stroke (user_x, user_y)) {
                    add_item = true;
                }
            }
        }

        cr.restore ();

        return add_item;
    }


    public unowned GLib.List<Goo.CanvasItem> get_items_at (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_visible,
        GLib.List<Goo.CanvasItem> found_items
    ) {
        if (new_hit_test (x, y, cr, is_pointer_event, parent_visible)) {
            found_items.prepend (this);
        }

        return found_items;
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

        cr.save ();

        Cairo.Matrix old = cr.get_matrix ();

        Cairo.Matrix tr;
        if (get_transform (out tr)) {
          cr.transform (tr);
        }

        ///* Clip with the item's clip path, if it is set. */
        if (clipping_path != null) {
            cr.move_to (clipping_path.tl_x, clipping_path.tl_y);
            cr.line_to (clipping_path.tr_x, clipping_path.tr_y);
            cr.line_to (clipping_path.br_x, clipping_path.br_y);
            cr.line_to (clipping_path.bl_x, clipping_path.bl_y);
            cr.close_path ();
            cr.set_fill_rule (Cairo.FillRule.WINDING);
            cr.clip ();
        }

        unowned var style = get_style ();
        simple_create_path (cr);

        if (style.set_fill_options (cr)) {
            cr.fill_preserve ();
        }

        cr.set_matrix (old);

        if (style.set_stroke_options (cr)) {
            cr.stroke ();
        }
        cr.restore ();

        cr.new_path ();
    }

    public Geometry.Rectangle bounding_box () {
        double x1 = 0;
        double x2 = 0;
        double y1 = 0;
        double y2 = 0;

        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        Cairo.Context context = new Cairo.Context (surface);

        context.set_antialias (Cairo.Antialias.GRAY);

        Cairo.Matrix tr;
        if (get_transform (out tr)) {
          context.transform (tr);
        }
        double translate_x = tr.x0;
        double translate_y = tr.y0;

        var fill_bounds = Geometry.Rectangle ();
        var stroke_bounds = Geometry.Rectangle ();
        unowned var style = get_style ();
        style.set_fill_options (context);

        simple_create_path (context);

        context.fill_extents (
            out fill_bounds.left,
            out fill_bounds.top,
            out fill_bounds.right,
            out fill_bounds.bottom
        );

        context.set_matrix (Cairo.Matrix (1.0, 0.0, 0.0, 1.0, translate_x, translate_y));

        style.set_stroke_options (context);
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

        return Geometry.Rectangle.with_coordinates (x1 + translate_x, y1 + translate_y, x2 + translate_x, y2 + translate_y);
    }
}
