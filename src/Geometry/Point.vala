/*
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
  * Simple 2d point.
  */
public struct Akira.Geometry.Point {
    public double x;
    public double y;

    public Point (double x = 0, double y = 0) {
        this.x = x;
        this.y = y;
    }

    public Point add (Point pt) {
        return Geometry.Point (x + pt.x, y + pt.y);
    }

    public Point sub (Point pt) {
        return Geometry.Point (x - pt.x, y - pt.y);
    }
    
    public double dot (Point pt) {
        return x * pt.x + y * pt.y;
    }
    
    public Point scale (double val) {
        return Geometry.Point (x * val, y * val);
    }

    public double distance (Point pt) {
        return Utils.GeometryMath.distance (x, y, pt.x, pt.y);
    }

    public Point.deserialized (Json.Object obj) {
        x = obj.get_double_member ("x");
        y = obj.get_double_member ("y");
    }

    public Json.Node serialize () {
        var obj = new Json.Object ();
        obj.set_double_member ("x", x);
        obj.set_double_member ("y", y);
        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (obj);
        return node;
    }
}
