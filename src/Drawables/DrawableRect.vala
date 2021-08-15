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
    public double radius_tr { get; set; default = 0; }
    public double radius_tl { get; set; default = 0; }
    public double radius_br { get; set; default = 0; }
    public double radius_bl { get; set; default = 0; }

    public bool has_radius { get { return (radius_tr + radius_tl + radius_br + radius_bl) > 0; } }

    public DrawableRect (Goo.CanvasItem parent, double tl_x, double tl_y, double width, double height) {
       this.parent = parent;
       this.center_x = tl_x + width / 2.0;
       this.center_y = tl_y + height / 2.0;
       this.width = width;
       this.height = height;

       // Add the newly created item to the Canvas or Artboard.
       parent.add_child (this, -1);
    }

    public override void simple_create_path (Cairo.Context cr) {
        if (has_radius) {
            //path_impl1 (cr);
            path_impl2 (cr);
            return;
        }

        var x = center_x - width / 2.0;
        var y = center_y - height / 2.0;
        cr.rectangle (x, y, width, height);
    }

    public void path_impl1 (Cairo.Context cr) {
        var x = center_x - width / 2.0;
        var y = center_y - height / 2.0;
        /* The radii can't be more than half the size of the rect. */
        double rx = double.min (radius_tr, width / 2);
        double ry = double.min (radius_bl, height / 2);

        /* Draw the top-right arc. */
        cr.save ();
        cr.translate (x + width - rx, y + ry);
        cr.scale (rx, ry);
        cr.arc (0.0, 0.0, 1.0, 1.5 * GLib.Math.PI, 2.0 * GLib.Math.PI);
        cr.restore ();

        /* Draw the line down the right side. */
        cr.line_to (x + width, y + height - ry);

        /* Draw the bottom-right arc. */
        cr.save ();
        cr.translate (x + width - rx, y + height - ry);
        cr.scale (rx, ry);
        cr.arc (0.0, 0.0, 1.0, 0.0, 0.5 * GLib.Math.PI);
        cr.restore ();

        /* Draw the line left across the bottom. */
        cr.line_to (x + rx, y + height);

        /* Draw the bottom-left arc. */
        cr.save ();
        cr.translate (x + rx, y + height - y);
        cr.scale (rx, ry);
        cr.arc (0.0, 0.0, 1.0, 0.5 * GLib.Math.PI, GLib.Math.PI);
        cr.restore ();

        /* Draw the line up the left side. */
        cr.line_to (x, y + ry);

        /* Draw the top-left arc. */
        cr.save ();
        cr.translate (x + rx, y + ry);
        cr.scale (rx, ry);
        cr.arc (0.0, 0.0, 1.0, GLib.Math.PI, 1.5 * GLib.Math.PI);
        cr.restore ();

        /* Close the path across the top. */
        cr.close_path ();
    }

    public void path_impl2 (Cairo.Context cr) {
        var w = width;
        var h = height;

        // aspect_ratio yet unused
        var aspect_ratio = 1.0;
        double rtl = radius_tl / aspect_ratio;
        double rtr = radius_tr / aspect_ratio;
        double rbl = radius_bl / aspect_ratio;
        double rbr = radius_br / aspect_ratio;

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


        var x = center_x - w / 2.0;
        var y = center_y - h / 2.0;
        var degrees = GLib.Math.PI / 180.0;

        // Add top-right
        if (rtr > 0) {
            cr.arc (x + w - rtr, y + rtr, rtr, -90 * degrees, 0);
        } else {
            cr.move_to (x + w, y);
        }

        if (rbr > 0) {
            // Add bottom-right
            cr.arc (x + w - rbr, y + h - rbr, rbr, 0, 90 * degrees);
        } else {
            cr.line_to (x + w, y + h);
        }

        if (rbl > 0) {
            // Add bottom-left
            cr.arc (x + rbl, y + h - rbl, rbl, 90 * degrees, 180 * degrees);
        } else {
            cr.line_to (x, y + h);
        }

        if (rtl > 0) {
            // Add top-left
            cr.arc (x + rtl, y + rtl, rtl, 180 * degrees, 270 * degrees);
        } else {
            cr.line_to (x, y);
        }
        cr.close_path ();
    }

    public override void simple_update (Cairo.Context cr) {
        /* We can quickly compute the bounds as being just the rectangle's size
           plus half the line width around each edge.
           For now we keep it as the full width to avoid weird clipping issues*/
        var half_line_width = get_line_width (); // / 2;

        var x = center_x - width / 2.0;
        var y = center_y - height / 2.0;

        bounds.x1 = x - half_line_width;
        bounds.y1 = y - half_line_width;
        bounds.x2 = x + width + half_line_width;
        bounds.y2 = y + height + half_line_width;
    }
}
