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

    public Geometry.TransformedRectangle? clipping_path = null;

    public unowned GLib.List<Goo.CanvasItem> get_items_at (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_visible,
        GLib.List<Goo.CanvasItem> found_items
    ) {
        double user_x = x, user_y = y;
        bool add_item = false;

        if (need_update > 0) {
            ensure_updated ();
        }

        /* Skip the item if the bounds don't intersect the expose rectangle. */
        if (bounds.x1 > x || bounds.x2 < x || bounds.y1 > y || bounds.y2 < y) {
          return found_items;
        }

        /* Check if the item should receive events. */
        if (is_pointer_event) {
            if (pointer_events == Goo.CanvasPointerEvents.NONE) {
                return found_items;
            }

            if (Goo.CanvasPointerEvents.VISIBLE_MASK in pointer_events
                && (!parent_visible || visibility <= Goo.CanvasItemVisibility.INVISIBLE ||
                    (visibility == Goo.CanvasItemVisibility.VISIBLE_ABOVE_THRESHOLD
                        && canvas.scale < visibility_threshold))) {
                    return found_items;
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
                return found_items;
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

        if (add_item) {
          found_items.prepend (this);
        }
        cr.restore ();

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
}
