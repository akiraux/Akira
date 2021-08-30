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
 * Drawable for paths.
 */
public class Akira.Drawables.DrawablePath : Drawable {
    // In the future we will probably want control points with more data.
    public Geometry.Point[]? points = null;

    public DrawablePath (Geometry.Point[]? points = null) {
       if (points != null) {
           this.points = points;
       }
    }

    public override void simple_create_path (Cairo.Context cr) {
        if (points == null || points.length < 2) {
            return;
        }

        cr.save ();
        cr.translate (center_x, center_y);
        cr.new_path ();
        var ct = 0;

        foreach (var p in points) {
            if (ct == 0) {
                cr.move_to (p.x, p.y);
            } else {
                cr.line_to (p.x, p.y);
            }
            ++ct;
        }
        cr.restore ();
    }
}
