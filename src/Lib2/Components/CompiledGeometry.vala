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

public class Akira.Lib2.Components.CompiledGeometry {
    public Cairo.Matrix _transform;

    /* Coordinates
     * x0, y0 are top left
     * x1, y1 are top right
     * x2, y2 are bottom left
     * x3, y3 are bottom right
     * However, they are the rotated coordinates, so there is no guarantee that
     * they will maintain that order after rotation.
     */

    public double _x0;
    public double _y0;
    public double _x1;
    public double _y1;
    public double _x2;
    public double _y2;
    public double _x3;
    public double _y3;

    public double _bb_top;
    public double _bb_left;
    public double _bb_bottom;
    public double _bb_right;

    public CompiledGeometry () {}

    public Cairo.Matrix transform () { return _transform; }

    public double bb_top () { return _bb_top; }
    public double bb_right () { return _bb_right; }
    public double bb_bottom () { return _bb_bottom; }
    public double bb_left () { return _bb_left; }

    public double x0 () { return _x0; }
    public double y0 () { return _y0; }
    public double x1 () { return _x1; }
    public double y1 () { return _y1; }
    public double x2 () { return _x2; }
    public double y2 () { return _y2; }
    public double x3 () { return _x3; }
    public double y3 () { return _y3; }

    public bool contains (double x, double y) {
        return x >= _bb_left && x <= _bb_right && y >= _bb_top && x <= _bb_bottom;

    }

    public static CompiledGeometry compile (
        Coordinates center,
        Size size,
        Rotation rotation,
        Borders? borders,
        Flipped? flipped
    ) {
        var mat = Cairo.Matrix.identity();
        mat.rotate (rotation.in_radians ());
        var half_height = size.height / 2.0;
        var half_width = size.width / 2.0;
        var top = -half_height;
        var bottom = half_height;
        var left = -half_width;
        var right = half_width;

        var y0 = top;
        var x0 = left;

        var y1 = top;
        var x1 = right;

        var y2 = bottom;
        var x2 = left;

        var y3 = bottom;
        var x3 = right;

        mat.transform_point(ref x0, ref y0);
        mat.transform_point(ref x1, ref y1);
        mat.transform_point(ref x2, ref y2);
        mat.transform_point(ref x3, ref y3);

        mat.x0 = center.x;
        mat.y0 = center.y;

        y0 += center.y;
        x0 += center.x;

        y1 += center.y;
        x1 += center.x;

        y2 += center.y;
        x2 += center.x;

        y3 += center.y;
        x3 += center.x;

        var new_geom = new CompiledGeometry ();
        new_geom._transform = mat;
        new_geom._x0 = x0;
        new_geom._y0 = y0;
        new_geom._x1 = x1;
        new_geom._y1 = y1;
        new_geom._x2 = x2;
        new_geom._y2 = y2;
        new_geom._x3 = x3;
        new_geom._y3 = y3;

        Utils.GeometryMath.min_max_coords (x0, x1, x2, x3, ref new_geom._bb_left, ref new_geom._bb_right);
        Utils.GeometryMath.min_max_coords (y0, y1, y2, y3, ref new_geom._bb_top, ref new_geom._bb_bottom);

        return new_geom;
    }
}
