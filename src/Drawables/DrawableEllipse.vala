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
 * Drawable for ellipses.
 */
public class Akira.Drawables.DrawableEllipse : Drawable {
    public double center_x { get; set; default = 0; }
    public double center_y { get; set; default = 0; }
    public double width { get; set; default = 0; }
    public double height { get; set; default = 0; }
    public double radius_x { get; set; default = 0; }
    public double radius_y { get; set; default = 0; }

    public DrawableEllipse (
        Goo.CanvasItem parent,
        double center_x,
        double center_y,
        double radius_x,
        double radius_y
    ) {
       this.parent = parent;
       this.center_x = center_x;
       this.center_y = center_y;
       this.radius_x = radius_x;
       this.radius_y = radius_x;

       // Add the newly created item to the Canvas or Artboard.
       parent.add_child (this, -1);
    }

    public override void simple_create_path (Cairo.Context cr) {
        cr.save ();
        cr.new_path ();
        cr.translate (center_x, center_y);
        cr.scale (radius_x, radius_y);
        cr.arc (0.0, 0.0, 1.0, 0.0, 2.0 * GLib.Math.PI);
        cr.restore ();
    }
}
