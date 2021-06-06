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
public struct Akira.Geometry.RotatedRectangle {
    public double rotation;
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

    public RotatedRectangle () {
        rotation = 0;
        tl_x = 0;
        tl_y = 0;
        tr_x = 0;
        tr_y = 0;
        bl_x = 0;
        bl_y = 0;
        br_x = 0;
        br_y = 0;
    }
}