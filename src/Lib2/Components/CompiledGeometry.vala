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

public class Akira.Lib2.Components.CompiledGeometry : Copyable<CompiledGeometry> {
    public struct CompiledGeometryData {
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

        // This is the bounding box that contains the rotated area
        public double _bb_top;
        public double _bb_left;
        public double _bb_bottom;
        public double _bb_right;

        // This is cached data used for hit-testing
        public Cairo.Matrix _ht_transform;
        public double _ht_half_width;
        public double _ht_half_height;
    }

    private CompiledGeometryData _data;

    public CompiledGeometry (CompiledGeometryData data) {
        _data = data;
    }

    public override CompiledGeometry copy () {
        return new CompiledGeometry (_data);
    }

    public Cairo.Matrix transform () { return _data._transform; }

    public double bb_top () { return _data._bb_top; }
    public double bb_right () { return _data._bb_right; }
    public double bb_bottom () { return _data._bb_bottom; }
    public double bb_left () { return _data._bb_left; }

    public double bb_center_x () { return (_data._bb_right + _data._bb_left) / 2.0; }
    public double bb_center_y () { return (_data._bb_bottom + _data._bb_top) / 2.0; }

    public double x0 () { return _data._x0; }
    public double y0 () { return _data._y0; }
    public double x1 () { return _data._x1; }
    public double y1 () { return _data._y1; }
    public double x2 () { return _data._x2; }
    public double y2 () { return _data._y2; }
    public double x3 () { return _data._x3; }
    public double y3 () { return _data._y3; }

    public bool contains (double x, double y) {
        x = _data._ht_transform.x0 - x;
        y = _data._ht_transform.y0 - y;
        _data._ht_transform.transform_distance (ref x, ref y);
        return (x >= -_data._ht_half_width && x <= _data._ht_half_width) &&
               (y >= -_data._ht_half_height && y <= _data._ht_half_height);
    }

    public void bounding_box (
        out double top,
        out double left,
        out double bottom,
        out double right,
        out double center_x,
        out double center_y
    ) {
        top = _data._bb_top;
        left = _data._bb_left;
        bottom = _data._bb_bottom;
        right = _data._bb_right;
        center_x = (left + right) / 2.0;
        center_y = (top + bottom) / 2.0;
    }

    public static CompiledGeometry compile (
        Coordinates center,
        Size size,
        Rotation rotation,
        Borders? borders,
        Flipped? flipped
    ) {
        var data = CompiledGeometryData ();
        data._transform = Cairo.Matrix.identity ();
        data._transform.rotate (rotation.in_radians ());

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

        data._transform.transform_point (ref x0, ref y0);
        data._transform.transform_point (ref x1, ref y1);
        data._transform.transform_point (ref x2, ref y2);
        data._transform.transform_point (ref x3, ref y3);

        data._transform.x0 = center.x;
        data._transform.y0 = center.y;

        y0 += center.y;
        x0 += center.x;

        y1 += center.y;
        x1 += center.x;

        y2 += center.y;
        x2 += center.x;

        y3 += center.y;
        x3 += center.x;

        data._x0 = x0;
        data._y0 = y0;
        data._x1 = x1;
        data._y1 = y1;
        data._x2 = x2;
        data._y2 = y2;
        data._x3 = x3;
        data._y3 = y3;

        data._ht_transform = Cairo.Matrix.identity ();
        data._ht_transform.rotate (-rotation.in_radians ());
        data._ht_transform.x0 = center.x;
        data._ht_transform.y0 = center.y;

        data._ht_half_width = half_width;
        data._ht_half_height = half_height;

        Utils.GeometryMath.min_max_coords (x0, x1, x2, x3, ref data._bb_left, ref data._bb_right);
        Utils.GeometryMath.min_max_coords (y0, y1, y2, y3, ref data._bb_top, ref data._bb_bottom);

        return new CompiledGeometry (data);
    }
}
