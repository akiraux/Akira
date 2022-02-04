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

public class Akira.Lib.Components.Path : Component, Copyable<Path> {
    // Control points relative to a top-left of 0,0.
    // In the future we will probably want control points with more data.
    //  public Geometry.Point[] data;
    // Control the path edit mode between straight line and curves.
    // Line requires 1 points whereas, path requires 4 points.
    //  public Lib.Modes.PathEditMode.Type[] commands;
    public Utils.PathSegment[] data;
    public bool close = false;

    public Path (bool close = false) {
        //  data = new Geometry.Point[0];
        //  commands = new Lib.Modes.PathEditMode.Type[0];
        data = new Utils.PathSegment[0];
        this.close = close;
    }

    public Path.from_single_point (Geometry.Point pt, bool close = false) {
        //  data = new Geometry.Point[1];
        //  data[0] = pt;

        //  commands = new Lib.Modes.PathEditMode.Type[1];
        //  commands[0] = command;
        data = new Utils.PathSegment[1];

        // Only a line can be created from a single point. No need to check command.
        data[0] = Utils.PathSegment.line (pt);

        this.close = close;
    }

    public Path.from_points (Utils.PathSegment[] data, bool close = false) {
        //  this.data = data;
        //  this.commands = commands;
        this.data = data;
        this.close = close;
    }

    public Path.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("path_data").get_elements ();
        data = new Utils.PathSegment[0];
        var idx = 0;
        foreach (unowned var pt in arr) {
            data.resize (data.length + 1);
            //  data[idx] = Geometry.Point.deserialized (pt.get_object ());
            data[idx] = Utils.PathSegment.deserialized (pt.get_object ());
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
        // The minimum values need to be large so for finding minimum to work.
        double min_x = double.MAX;
        double max_x = double.MIN;
        double min_y = double.MAX;
        double max_y = double.MIN;

        int point_idx = 0;
        //  for (int cmd_idx = 0; cmd_idx < commands.length; ++cmd_idx) {
        for (int i = 0; i < data.length; ++i) {
            var segment = data[i];

            if (segment.type == Lib.Modes.PathEditMode.Type.LINE) {
                var point = segment.line_end;//data[point_idx];
                min_x = double.min (min_x, point.x);
                max_x = double.max (max_x, point.x);
                min_y = double.min (min_y, point.y);
                max_y = double.max (max_y, point.y);

                ++point_idx;
            } else if (segment.type == Lib.Modes.PathEditMode.Type.CUBIC) {
                var p0 = data[i - 1].last_point;//data[point_idx - 1];
                var p1 = segment.curve_begin;//data[point_idx];
                var p2 = segment.tangent_1;//data[point_idx + 1];
                var p3 = segment.tangent_2;//data[point_idx + 2];
                var p4 = segment.curve_end;//data[point_idx + 3];

                double[] b1_extremes = Utils.Bezier.get_extremes (p0, p2, p1);
                double[] b2_extremes = Utils.Bezier.get_extremes (p1, p3, p4);

                double temp = double.min (b1_extremes[0], b2_extremes[0]);
                min_x = double.min (min_x, temp);

                temp = double.min (b1_extremes[1], b2_extremes[1]);
                min_y = double.min (min_y, temp);

                temp = double.max (b1_extremes[2], b2_extremes[2]);
                max_x = double.max (max_x, temp);

                temp = double.max (b1_extremes[3], b2_extremes[3]);
                max_y = double.max (max_y, temp);

                point_idx += 4;
            }
        }

        return Geometry.Rectangle.with_coordinates (min_x, min_y, max_x, max_y);
    }
}
