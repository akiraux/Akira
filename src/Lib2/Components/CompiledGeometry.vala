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
        public Coordinates? source_center;
        public Size? source_size;
        public Transform? source_transform;
        public Cairo.Matrix _transformation_matrix;
        // These rectangles are in global coordinates
        public Geometry.Quad area;

        // Cahced bounding box that contains the rotated area
        public Geometry.Rectangle area_bb;

        public CompiledGeometryData () {
            source_center = null;
            source_size = null;
            source_transform = null;
        }
    }

    public CompiledGeometryData _data;

    public Geometry.Quad area { get { return _data.area; }}
    public Geometry.Rectangle area_bb { get { return _data.area_bb; }}

    public double source_width {
        get {
            return _data.source_size == null ? area_bb.width : _data.source_size.width;
        }
    }

    public double source_height {
        get {
            return _data.source_size == null ? area_bb.height : _data.source_size.height;
        }
    }

    public double tl_x { get { return _data.area.tl_x; }}
    public double tl_y { get { return _data.area.tl_y; }}
    public double tr_x { get { return _data.area.tr_x; }}
    public double tr_y { get { return _data.area.tr_y; }}
    public double bl_x { get { return _data.area.bl_x; }}
    public double bl_y { get { return _data.area.bl_y; }}
    public double br_x { get { return _data.area.br_x; }}
    public double br_y { get { return _data.area.br_y; }}

    public double bb_top { get { return _data.area_bb.top; }}
    public double bb_left { get { return _data.area_bb.left; }}
    public double bb_bottom { get { return _data.area_bb.bottom; }}
    public double bb_right { get { return _data.area_bb.right; }}

    public Cairo.Matrix transformation_matrix { get { return _data._transformation_matrix; }}

    public CompiledGeometry (CompiledGeometryData data) {
        _data = data;
    }

    public CompiledGeometry.as_empty () {
        _data = CompiledGeometryData ();
        _data.area = Geometry.Quad ();
        _data.area_bb = Geometry.Rectangle ();
        _data._transformation_matrix = Cairo.Matrix.identity ();
    }

    public CompiledGeometry copy () {
        return new CompiledGeometry (_data);
    }

    public CompiledGeometry.dummy () {
        _data = CompiledGeometryData ();
    }

    public CompiledGeometry.from_components (Components? components, Lib2.Items.ModelNode? node, bool size_from_path = false) {
        _data = CompiledGeometryData ();

        if (components == null) {
            return;
        }

        _data.source_center = components.center;
        _data.source_transform = components.transform;

        assert (_data.source_center != null);

        if (_data.source_transform == null) {
            _data._transformation_matrix = Cairo.Matrix.identity ();
        } else {
            _data._transformation_matrix = _data.source_transform.transformation_matrix;
        }

        _data.area.transformation = _data._transformation_matrix;

        double half_width = 0;
        double half_height = 0;

        if (size_from_path) {
            if (components.path == null) {
                _data.area = Geometry.Quad ();
                _data.area_bb = Geometry.Rectangle ();
                return;
            }

            var ext = components.path.calculate_extents ();
            half_width = ext.width / 2.0;
            half_height = ext.height / 2.0;
            _data.source_size = new Lib2.Components.Size (ext.width, ext.height, false);
        } else {
            if (components.size == null) {
                _data.area = Geometry.Quad ();
                _data.area_bb = Geometry.Rectangle ();
                return;
            }

            _data.source_size = components.size;
            half_height = _data.source_size.height / 2.0;
            half_width = _data.source_size.width / 2.0;
        }

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

        _data._transformation_matrix.transform_point (ref x0, ref y0);
        _data._transformation_matrix.transform_point (ref x1, ref y1);
        _data._transformation_matrix.transform_point (ref x2, ref y2);
        _data._transformation_matrix.transform_point (ref x3, ref y3);

        var center_x = _data.source_center.x;
        var center_y = _data.source_center.y;
        _data._transformation_matrix.x0 = center_x;
        _data._transformation_matrix.y0 = center_y;

        y0 += center_y;
        x0 += center_x;

        y1 += center_y;
        x1 += center_x;

        y2 += center_y;
        x2 += center_x;

        y3 += center_y;
        x3 += center_x;

        _data.area.tl_x = x0;
        _data.area.tl_y = y0;
        _data.area.tr_x = x1;
        _data.area.tr_y = y1;
        _data.area.bl_x = x2;
        _data.area.bl_y = y2;
        _data.area.br_x = x3;
        _data.area.br_y = y3;

        _data.area_bb = _data.area.bounding_box;
    }

    public static CompiledGeometry.from_descendants (Components? components, Lib2.Items.ModelNode? node) {
        _data = CompiledGeometryData ();
        if (node == null || node.children == null) {
            return;
        }

        _data._transformation_matrix = Cairo.Matrix.identity ();
        _data.area.transformation = _data._transformation_matrix;

        double top = int.MAX;
        double bottom = int.MIN;
        double left = int.MAX;
        double right = int.MIN;

        foreach (var child in node.children.data) {
            unowned var cg = child.instance.compiled_geometry;
            if (cg == null) {
                continue;
            }

            top = double.min (top, cg.bb_top);
            bottom = double.max (bottom, cg.bb_bottom);
            left = double.min (left, cg.bb_left);
            right = double.max (right, cg.bb_right);
        }

        _data.area.tl_x = left;
        _data.area.tl_y = top;
        _data.area.tr_x = right;
        _data.area.tr_y = top;
        _data.area.bl_x = left;
        _data.area.bl_y = bottom;
        _data.area.br_x = right;
        _data.area.br_y = bottom;

        _data.area_bb = _data.area.bounding_box;
        _data._transformation_matrix.x0 = _data.area_bb.center_x;
        _data._transformation_matrix.y0 = _data.area_bb.center_y;
    }
}
