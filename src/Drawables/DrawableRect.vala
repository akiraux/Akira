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
    public double x { get; set; default = 0; }
    public double y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }
    public double radius_x { get; set; default = 0; }
    public double radius_y { get; set; default = 0; }

    public DrawableRect (Goo.CanvasItem parent, double x, double y, double width, double height) {
       this.parent = parent;
       this.x = x;
       this.y = y;
       this.width = width;
       this.height = height;

       // Add the newly created item to the Canvas or Artboard.
       parent.add_child (this, -1);
    }

    public override void simple_create_path (Cairo.Context cr) {
       if (radius_x > 0 || radius_y > 0) {
           /* The radii can't be more than half the size of the rect. */
           double rx = double.min (radius_x, width / 2);
           double ry = double.min (radius_y, height / 2);

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
       else {
           cr.rectangle (x, y, width, height);
       }
    }

    public override void simple_update (Cairo.Context cr) {
        /* We can quickly compute the bounds as being just the rectangle's size
           plus half the line width around each edge.
           For now we keep it as the full width to avoid weird clipping issues*/
        var half_line_width = get_line_width (); // / 2;

        bounds.x1 = x - half_line_width;
        bounds.y1 = y - half_line_width;
        bounds.x2 = x + width + half_line_width;
        bounds.y2 = y + height + half_line_width;
    }
}
