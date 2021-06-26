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
        // These rectangles are in global coordinates
        public Geometry.RotatedRectangle area;

        // This is the bounding box that contains the rotated area
        public Geometry.Rectangle area_bb;
    }

    private CompiledGeometryData _data;

    public Geometry.RotatedRectangle area { get { return _data.area; }}
    public Geometry.Rectangle area_bb { get { return _data.area_bb; }}

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

    public CompiledGeometry (CompiledGeometryData data) {
        _data = data;
    }

    public CompiledGeometry copy () {
        return new CompiledGeometry (_data);
    }

    public Cairo.Matrix transform () { return _data._transform; }

    public static CompiledGeometry compile (Components? components, Lib2.Items.ModelNode? node) {
        //print ("compile %d\n", (node == null) ? -2 : node.id);
        var data = CompiledGeometryData ();
        if (node == null || !node.instance.is_group ()) {
            if (components == null) {
                return new CompiledGeometry(data);
            }
            compile_item (components, ref data);
        }
        else {
            compile_group (components, node, ref data);
        }

        return new CompiledGeometry (data);
    }

    public static void compile_item (Components? components, ref CompiledGeometryData data) {
        unowned var rotation = components.rotation;
        unowned var size = components.size;
        unowned var center = components.center;

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

        data.area.tl_x = x0;
        data.area.tl_y = y0;
        data.area.tr_x = x1;
        data.area.tr_y = y1;
        data.area.bl_x = x2;
        data.area.bl_y = y2;
        data.area.br_x = x3;
        data.area.br_y = y3;
        data.area.rotation = components.rotation.in_radians ();

        Utils.GeometryMath.min_max_coords (x0, x1, x2, x3, ref data.area_bb.left, ref data.area_bb.right);
        Utils.GeometryMath.min_max_coords (y0, y1, y2, y3, ref data.area_bb.top, ref data.area_bb.bottom);
    }

    public static void compile_group (Components? components, Lib2.Items.ModelNode? node, ref CompiledGeometryData data) {
        if (node == null || node.children == null) {
            return;
        }

        data._transform = Cairo.Matrix.identity ();

        double top = int.MAX;
        double bottom = int.MIN;
        double left = int.MAX;
        double right = int.MIN;

        foreach (var child in node.children.data) {
            unowned var cg = child.instance.item.compiled_geometry;
            if (cg == null) {
                continue;
            }

            top = double.min (top, cg.bb_top);
            bottom = double.max (bottom, cg.bb_bottom);
            left = double.min (left, cg.bb_left);
            right = double.max (right, cg.bb_right);
        }

        data.area.tl_x = left;
        data.area.tl_y = top;
        data.area.tr_x = right;
        data.area.tr_y = top;
        data.area.bl_x = left;
        data.area.bl_y = bottom;
        data.area.br_x = right;
        data.area.br_y = bottom;
        data.area.rotation = 0;

        data.area_bb.top = top;
        data.area_bb.left = left;
        data.area_bb.bottom = bottom;
        data.area_bb.right = right;

        data._transform.x0 = data.area_bb.center_x;
        data._transform.y0 = data.area_bb.center_y;
    }
}
