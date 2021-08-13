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

public class Akira.Lib2.Components.Path : Copyable<Path> {
    // Control points relative to a top-left of 0,0.
    // In the future we will probably want control points with more data.
    public Geometry.Point[] data;
    public bool close = false;

    public Path (bool close = false) {
        data = new Geometry.Point[0];
        this.close = close;
    }

    public Path.from_single_point (Geometry.Point pt, bool close = false) {
        data = new Geometry.Point[1];
        data[0] = pt;
        this.close = close;
    }

    public Path.from_points (Geometry.Point[] data, bool close = false) {
        this.data = data;
        this.close = close;
    }


    public Path copy () {
        var cln = new Path ();
        cln.data = data;
        return cln;
    }

    public Geometry.Rectangle calculate_extents () {
        double min_x = 0;
        double max_x = 0;
        double min_y = 0;
        double max_y = 0;

        foreach (var pos in data) {
            if (pos.x < min_x) {
                min_x = pos.x;
            }
            if (pos.x > max_x) {
                max_x = pos.x;
            }

            if (pos.y < min_y) {
                min_y = pos.y;
            }
            if (pos.y > max_y) {
                max_y = pos.y;
            }
        }

        return Geometry.Rectangle.with_coordinates (min_x, min_y, max_x, max_y);
    }
}