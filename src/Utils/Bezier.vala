/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.Utils.Bezier {
    public static double[] get_extremes (Geometry.Point p1, Geometry.Point p2, Geometry.Point p3) {
        // Return as[min_x, min_y, max_x, max_y]
        double min_x = double.MAX;
        double max_x = double.MIN;
        double min_y = double.MAX;
        double max_y = double.MIN;

        // Get the t parameter for the bezier where the curve would be extreme.
        // The bounding box has to be enclosed completely within these points.
        double tx = (p1.x - p2.x) / (p1.x - 2 * p2.x + p3.x);
        double ty = (p1.y - p2.y) / (p1.y - 2 * p2.y + p3.y);

        // Temporary var used when calculating min and max.
        double temp;

        if (tx.is_nan () || tx <= 0 || tx >= 1) {
            temp = double.min (p1.x, p3.x);
            min_x = double.min (min_x, temp);

            temp = double.max (p1.x, p3.x);
            max_x = double.max (max_x, temp);
        } else {
            // Get the extreme point wrt x axis for the bezier.
            var ex = point_on_curve (p1, p2, p3, tx);

            temp = double.min (p1.x, double.min (p3.x, ex.x));
            min_x = double.min (min_x, temp);

            temp = double.max (p1.x, double.max (p3.x, ex.x));
            max_x = double.max (max_x, temp);

        }

        if (ty.is_nan () || ty <= 0 || ty >= 1) {
            temp = double.min (p1.y, p3.y);
            min_y = double.min (min_y, temp);

            temp = double.max (p1.y, p3.y);
            max_y = double.max (max_y, temp);
        } else {
            // Get the extreme point wrt y axis for the bezier.
            var ey = point_on_curve (p1, p2, p3, ty);
            temp = double.min (p1.y, double.min (p3.y, ey.y));
            min_y = double.min (min_y, temp);

            temp = double.max (p1.y, double.max (p3.y, ey.y));
            max_y = double.max (max_y, temp);
        }

        double[] res = new double[4];
        res[0] = min_x;
        res[1] = min_y;
        res[2] = max_x;
        res[3] = max_y;

        return res;
    }

    public static Geometry.Point point_on_curve (Geometry.Point p1, Geometry.Point p2, Geometry.Point p3, double t) {
        var c1 = Geometry.Point (p1.x + (p2.x - p1.x) * t, p1.y + (p2.y - p1.y) * t);
        var c2 = Geometry.Point (p2.x + (p3.x - p2.x) * t, p2.y + (p3.y - p2.y) * t);

        var point = Geometry.Point (c1.x + (c2.x - c1.x) * t, c1.y + (c2.y - c1.y) * t);
        return point;
    }
}
