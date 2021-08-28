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
public class Akira.Drawables.DrawablePath : Drawable {
    // In the future we will probably want control points with more data.
    public Gee.ArrayList<Geometry.Point?>? points = null;

    public DrawablePath (Gee.ArrayList<Geometry.Point?>? points = null) {
       if (points != null) {
           this.points = points;
       }
    }

    public override void simple_create_path (Cairo.Context cr) {
        if (points == null || points.size < 2) {
            return;
        }

        Gee.ArrayList <Geometry.Point?> translated_points = recalculate_points ();

        cr.save ();
        cr.translate (center_x, center_y);
        cr.new_path ();
        var ct = 0;

        foreach (var p in translated_points) {
            if (ct == 0) {
                cr.move_to (p.x, p.y);
            } else {
                cr.line_to (p.x, p.y);
            }
            ++ct;
        }
        cr.restore ();
    }

    /*
     * This function shifts all points so that none of them are in negative space.
     */
    private Gee.ArrayList <Geometry.Point?> recalculate_points () {
        double min_x = 0, min_y = 0;

        foreach (var pt in points) {
            if (pt.x < min_x) {
                min_x = pt.x;
            }
            if (pt.y < min_y) {
                min_y = pt.y;
            }
        }

        Gee.ArrayList <Geometry.Point?> translated_points = new Gee.ArrayList<Geometry.Point?> ();
        foreach (var pt in points) {
            translated_points.add (Geometry.Point (pt.x - min_x, pt.y - min_y));
        }

        return translated_points;
    }
}
