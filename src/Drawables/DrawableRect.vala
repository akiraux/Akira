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
 *
 * Parts of this code are taken from GooCanvas
 */

/*
 * Drawable for rects.
 */
public class Akira.Drawables.DrawableRect : Drawable {
    public DrawableRect (double tl_x, double tl_y, double width, double height) {
       this.center_x = tl_x + width / 2.0;
       this.center_y = tl_y + height / 2.0;
       this.width = width;
       this.height = height;
    }

    public override void simple_create_path (Cairo.Context context) {
        rect_path (context, this);
    }

    public static void rect_path (Cairo.Context context, Drawable drawable) {
        if (drawable.has_radius) {
            //path_impl1 (cr);
            rounded_rect_path (context, drawable);
            return;
        }

        var w = drawable.width;
        var h = drawable.height;
        var x = drawable.center_x - w / 2.0;
        var y = drawable.center_y - h / 2.0;
        context.rectangle (x, y, w, h);
    }

    public static void rounded_rect_path (Cairo.Context context, Drawable drawable) {
        var w = drawable.width;
        var h = drawable.height;

        // aspect_ratio yet unused
        var aspect_ratio = 1.0;
        double rtl = drawable.radius_tl / aspect_ratio;
        double rtr = drawable.radius_tr / aspect_ratio;
        double rbl = drawable.radius_bl / aspect_ratio;
        double rbr = drawable.radius_br / aspect_ratio;

        double r_top = rtl + rtr;
        double r_bot = rbl + rbr;
        double r_right = rtr + rbr;
        double r_left = rtl + rbl;

        if (r_top > 0) {
            rtr = double.min (rtr, rtr / r_top * w);
            rtl = double.min (rtl, rtl / r_top * w);
        }

        if (r_bot > 0) {
            rbr = double.min (rbr, rbr / r_bot * w);
            rbl = double.min (rbl, rbl / r_bot * w);
        }

        if (r_left > 0) {
            rtl = double.min (rtl, rtl / r_left * h);
            rbl = double.min (rbl, rbl / r_left * h);
        }

        if (r_right > 0) {
            rtr = double.min (rtr, rtr / r_right * h);
            rbr = double.min (rbr, rbr / r_right * h);
        }


        var x = drawable.center_x - w / 2.0;
        var y = drawable.center_y - h / 2.0;
        var degrees = GLib.Math.PI / 180.0;

        // Add top-right
        if (rtr > 0) {
            context.arc (x + w - rtr, y + rtr, rtr, -90 * degrees, 0);
        } else {
            context.move_to (x + w, y);
        }

        if (rbr > 0) {
            // Add bottom-right
            context.arc (x + w - rbr, y + h - rbr, rbr, 0, 90 * degrees);
        } else {
            context.line_to (x + w, y + h);
        }

        if (rbl > 0) {
            // Add bottom-left
            context.arc (x + rbl, y + h - rbl, rbl, 90 * degrees, 180 * degrees);
        } else {
            context.line_to (x, y + h);
        }

        if (rtl > 0) {
            // Add top-left
            context.arc (x + rtl, y + rtl, rtl, 180 * degrees, 270 * degrees);
        } else {
            context.line_to (x, y);
        }

        context.close_path ();
    }

    //public override void simple_update (Cairo.Context cr) {
    //    /* We can quickly compute the bounds as being just the rectangle's size
    //       plus half the line width around each edge.
    //       For now we keep it as the full width to avoid weird clipping issues*/
    //    var half_line_width = get_line_width (); // / 2;

    //    var x = center_x - width / 2.0;
    //    var y = center_y - height / 2.0;

    //    bounds.left = x - half_line_width;
    //    bounds.top = y - half_line_width;
    //    bounds.right = x + width + half_line_width;
    //    bounds.bottom = y + height + half_line_width;
    //}
}
