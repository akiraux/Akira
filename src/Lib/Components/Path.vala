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
 * Modified by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.Lib.Components.Path : Component, Copyable<Path> {
    // Control points relative to a top-left of 0,0.
    // In the future we will probably want control points with more data.
    public Geometry.PathSegment[] data;
    public bool close = false;

    public Path (bool close = false) {
        data = new Geometry.PathSegment[0];
        this.close = close;
    }

    public Path.from_single_point (Geometry.Point pt, bool close = false) {
        data = new Geometry.PathSegment[1];

        // Only a line can be created from a single point. No need to check command.
        data[0] = Geometry.PathSegment.line (pt);

        this.close = close;
    }

    public Path.from_points (Geometry.PathSegment[] data, bool close = false) {
        this.data = data;
        this.close = close;
    }

    public Path.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("path_data").get_elements ();
        data = new Geometry.PathSegment[0];
        var idx = 0;

        foreach (unowned var pt in arr) {
            data.resize (data.length + 1);
            data[idx] = Geometry.PathSegment.deserialized (pt.get_object ());
            ++idx;
        }
    }

    protected override void serialize_details (ref Json.Object obj) {
        var array = new Json.Array ();

        foreach (unowned var d in data) {
            array.add_element (d.serialize ());
        }

        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        obj.set_member ("path_data", node);
    }

    public Path copy () {
        var cln = new Path ();
        cln.data = data;
        cln.close = close;
        return cln;
    }

    public Geometry.Rectangle calculate_extents () {
        // The minimum values need to be large for finding minimum to work.
        Geometry.Rectangle extents = Geometry.Rectangle ();
        extents.top = extents.left = double.MAX;
        extents.bottom = extents.right = double.MIN;

        for (int i = 0; i < data.length; ++i) {
            var segment = data[i];

            if (segment.type == Lib.Modes.PathEditMode.Type.LINE) {
                var point = segment.line_end;
                extents.left = double.min (extents.left, point.x);
                extents.right = double.max (extents.right, point.x);
                extents.top = double.min (extents.top, point.y);
                extents.bottom = double.max (extents.bottom, point.y);
            } else {
                var seg_extents = Utils.GeometryMath.calculate_bounds_for_curve (segment, data[i - 1].last_point);

                extents.left = double.min (extents.left, seg_extents.left);
                extents.top = double.min (extents.top, seg_extents.top);
                extents.right = double.max (extents.right, seg_extents.right);
                extents.bottom = double.max (extents.bottom, seg_extents.bottom);
            }
        }

        return extents;
    }
}
