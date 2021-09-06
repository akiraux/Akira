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
    public Utils.PathItem[] data;
    public bool close = false;

    public Path (bool close = false) {
        data = new Utils.PathItem[0];
        this.close = close;
    }

    public Path.from_single_point (Geometry.Point pt, bool close = false) {
        data = new Utils.PathItem[1];

        // When user creates a new path from a single point, the first point
        // is always PathMove.
        var item = new Utils.PathMove ();
        item.add_point(pt);
        data[0] = item;

        this.close = close;
    }

    public Path.from_points (Utils.PathItem[] data, bool close = false) {
        this.data = data;
        this.close = close;
    }

    public Path.deserialized (Json.Object obj) {
        // TODO:
        // var arr = obj.get_array_member ("path_data").get_elements ();
        // data = new Geometry.Point[0];
        // var idx = 0;
        // foreach (unowned var pt in arr) {
        //     data.resize (data.length + 1);
        //     data[idx] = Geometry.Point.deserialized (pt.get_object ());
        //     ++idx;
        // }
    }

    protected override void serialize_details (ref Json.Object obj) {
        // TODO:
        // var array = new Json.Array ();
        //
        // foreach (unowned var d in data) {
        //     array.add_element (d.serialize ());
        // }
        //
        // var node = new Json.Node (Json.NodeType.ARRAY);
        // node.set_array (array);
        // obj.set_member ("path_data", node);
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

        foreach (var item in data) {
            if (item.command != Utils.PathPointFactory.Command.LINE) {
                // TODO: Temporary until i handle Curves
                continue;
            }

            foreach (var point in item.points) {
                if (point.x < min_x) {
                    min_x = point.x;
                }
                if (point.x > max_x) {
                    max_x = point.x;
                }

                if (point.y < min_y) {
                    min_y = point.y;
                }
                if (point.y > max_y) {
                    max_y = point.y;
                }
            }
        }

        return Geometry.Rectangle.with_coordinates (min_x, min_y, max_x, max_y);
    }
}
