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
  * Naive rectangle. It does not guarantee relative positions of left/right, top/left
  * unless the `with_coordinates` constructor is used.
  */
public struct Akira.Geometry.Rectangle {
    public double top;
    public double left;
    public double bottom;
    public double right;

    public double center_x { get { return (left + right) / 2.0; } }
    public double center_y { get { return (bottom + top) / 2.0; } }
    public double width { get { return (right - left).abs (); } }
    public double height { get { return (bottom - top).abs (); } }

    public Rectangle.empty () {
        top = 0;
        bottom = 0;
        left = 0;
        right = 0;
    }

    public Rectangle.with_coordinates (double x0, double y0, double x1, double y1) {
        if (x0 < x1) {
            left = x0;
            right = x1;
        } else {
            right = x0;
            left = x1;
        }

        if (y0 < y1) {
            top = y0;
            bottom = y1;
        } else {
            bottom = y0;
            top = y1;
        }
    }

    public bool contains (double x, double y) {
        return (left < x < right) && (top < y < bottom);
    }

    public bool contains_bound (Geometry.Rectangle bound) {
        return (left <= bound.left) && (top <= bound.top) && (right >= bound.right) && (bottom >= bound.bottom);
    }

    public bool does_not_contain (double x, double y) {
        return x < left || x > right || y < top || y > bottom;
    }

    public void translate (double dx, double dy) {
        left += dx;
        right += dx;
        top += dy;
        bottom += dy;
    }

    public string to_string () {
        return "t: %f l: %f b: %f r: %f".printf (top, left, bottom , right);
    }
}
