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
  * Naive rotated rectangle meant for convenience. This struct does not guarantee
  * that the properties of a rectangle are kept. For all intents and purposes, this
  * is simply a collection of four points and a rotation.
  */
public struct Akira.Geometry.Quad {
    public Cairo.Matrix transformation;
    public double tl_x;
    public double tl_y;
    public double tr_x;
    public double tr_y;
    public double bl_x;
    public double bl_y;
    public double br_x;
    public double br_y;

    public double center_x { get { return (tl_x + tr_x + bl_x + br_x) / 4.0; } }
    public double center_y { get { return (tl_y + tr_y + bl_y + br_y) / 4.0; } }

    public double width { get { return Utils.GeometryMath.distance (tl_x, tl_y, tr_x, tr_y).abs (); } }
    public double height { get { return Utils.GeometryMath.distance (tl_x, tl_y, bl_x, bl_y).abs (); } }

    public void top_bottom (ref double top, ref double bottom) {
        Utils.GeometryMath.min_max_coords (tl_y, tr_y, bl_y, br_y, ref top, ref bottom);
    }

    public void left_right (ref double left, ref double right) {
        Utils.GeometryMath.min_max_coords (tl_x, tr_x, bl_x, br_x, ref left, ref right);
    }

    public Rectangle bounding_box {
        get {
            double min_x = 0;
            double max_x = 0;
            Utils.GeometryMath.min_max_coords (tl_x, tr_x, bl_x, br_x, ref min_x, ref max_x);

            double min_y = 0;
            double max_y = 0;
            Utils.GeometryMath.min_max_coords (tl_y, tr_y, bl_y, br_y, ref min_y, ref max_y);

            return Rectangle .with_coordinates (min_x, min_y, max_x, max_y);
        }
    }


    public Quad () {
        transformation = Cairo.Matrix.identity ();
        tl_x = 0;
        tl_y = 0;
        tr_x = 0;
        tr_y = 0;
        bl_x = 0;
        bl_y = 0;
        br_x = 0;
        br_y = 0;
    }

    public Quad.from_rectangle (Geometry.Rectangle rect) {
        transformation = Cairo.Matrix.identity ();
        tl_x = rect.left;
        tl_y = rect.top;
        tr_x = rect.right;
        tr_y = rect.top;
        bl_x = rect.left;
        bl_y = rect.bottom;
        br_x = rect.right;
        br_y = rect.bottom;
    }

    public Quad.from_components (
        double center_x,
        double center_y,
        double width,
        double height,
        Cairo.Matrix transform
    ) {
        transformation = transform;

        var hw = width / 2.0;
        var hh = height / 2.0;

        tl_x = - hw;
        tl_y = - hh;
        br_x = hw;
        br_y = hh;

        var woffx = width;
        var woffy = 0.0;
        transform.transform_distance (ref tl_x, ref tl_y);
        transform.transform_distance (ref br_x, ref br_y);
        transform.transform_distance (ref woffx, ref woffy);

        tl_x = center_x + tl_x;
        tl_y = center_y + tl_y;

        tr_x = tl_x + woffx;
        tr_y = tl_y + woffy;

        br_x = center_x + br_x;
        br_y = center_y + br_y;
        bl_x = br_x - woffx;
        bl_y = br_y - woffy;

        transform.x0 = center_x - hw; 
        transform.y0 = center_y - hh; 
    }

    public bool contains (double x, double y) {
        if (!bounding_box.contains (x, y)) {
            return false;
        }

        return Utils.GeometryMath.points_on_same_side_of_line (tl_x, tl_y, tr_x, tr_y, br_x, br_y, x, y)
            && Utils.GeometryMath.points_on_same_side_of_line (tr_x, tr_y, br_x, br_y, bl_x, bl_y, x, y)
            && Utils.GeometryMath.points_on_same_side_of_line (br_x, br_y, bl_x, bl_y, tl_x, tl_y, x, y)
            && Utils.GeometryMath.points_on_same_side_of_line (bl_x, bl_y, tl_x, tl_y, tr_x, tr_y, x, y);
    }

    public void translate (double dx, double dy) {
        tl_x += dx;
        tr_x += dx;
        bl_x += dx;
        br_x += dx;

        tl_y += dy;
        tr_y += dy;
        bl_y += dy;
        br_y += dy;
    }

    public string to_string () {
        return "tl: %f %f tr: %f %f br: %f %f bl: %f %f".printf (
        tl_x,
        tl_y,
        tr_x,
        tr_y,
        br_x,
        br_y,
        bl_x,
        bl_y
        );
    }
}
