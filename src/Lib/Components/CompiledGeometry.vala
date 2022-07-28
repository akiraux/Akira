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

public class Akira.Lib.Components.CompiledGeometry : Copyable<CompiledGeometry> {
    public struct CompiledGeometryData {
        public Coordinates? source_center;
        public Size? source_size;
        public Transform? source_transform;
        public Cairo.Matrix _transformation_matrix;
        // Bounding box in local coordinates.
        public Geometry.Rectangle local_bb;
        // These rectangles are in global coordinates.
        public Geometry.Quad area;
        public Geometry.Quad drawable_area;

        // Cached bounding box that contains the rotated area.
        public Geometry.Rectangle area_bb;

        public CompiledGeometryData () {
            source_center = null;
            source_size = null;
            source_transform = null;
        }
    }

    public CompiledGeometryData _data;

    public Geometry.Rectangle local_bb { get { return _data.local_bb; }}
    public Geometry.Quad area { get { return _data.area; }}
    public Geometry.Rectangle area_bb { get { return _data.area_bb; }}
    public Geometry.Rectangle drawable_bb { get { return _data.drawable_area.bounding_box; }}

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

    public CompiledGeometry.from_components (
        Components? components,
        Lib.Items.ModelNode? node,
        bool size_from_path = false
    ) {
        _data = CompiledGeometryData ();

        if (components == null) {
            return;
        }

        _data.source_center = components.center;
        _data.source_transform = components.transform;

        unowned var compiled_border = node.instance.compiled_border;
        var border_width = compiled_border == null ? 0 : compiled_border.size;

        assert (_data.source_center != null);

        if (_data.source_transform == null) {
            _data._transformation_matrix = Cairo.Matrix.identity ();
        } else {
            _data._transformation_matrix = _data.source_transform.transformation_matrix;
        }

        double width = 0;
        double height = 0;

        int border_overestimate = 1;

        if (size_from_path) {
            if (components.path == null) {
                _data.local_bb = Geometry.Rectangle ();
                _data.area = Geometry.Quad ();
                _data.area_bb = Geometry.Rectangle ();
                return;
            }

            var ext = components.path.calculate_extents ();
            width = ext.width;
            height = ext.height;
            _data.source_size = new Lib.Components.Size (ext.width, ext.height, false);
            border_overestimate = 4;
        } else {
            if (components.size == null) {
                _data.local_bb = Geometry.Rectangle ();
                _data.area = Geometry.Quad ();
                _data.area_bb = Geometry.Rectangle ();
                return;
            }

            _data.source_size = components.size;
            height = _data.source_size.height;
            width = _data.source_size.width;
        }

        var center_x = _data.source_center.x;
        var center_y = _data.source_center.y;

        var hw = width / 2.0;
        var hh = height / 2.0;
        _data.local_bb = Geometry.Rectangle.with_coordinates (-hw, -hh, hw, hh);

        _data.area = Geometry.Quad.from_components (center_x, center_y, width, height, _data._transformation_matrix);

        if (border_width > 0) {
            var bw = border_width * 2 * border_overestimate;
            _data.drawable_area = Geometry.Quad.from_components (center_x, center_y, width + bw, height + bw, _data._transformation_matrix);
        }
        else {
            _data.drawable_area = _data.area;
        }

        _data.area_bb = _data.area.bounding_box;

        _data._transformation_matrix.x0 = center_x;
        _data._transformation_matrix.y0 = center_y;
    }

    public static CompiledGeometry.from_descendants (Components? components, Lib.Items.ModelNode? node) {
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

        _data.drawable_area = _data.area;
        _data.local_bb = _data.area.bounding_box;
        _data.area_bb = _data.area.bounding_box;
    }
}
