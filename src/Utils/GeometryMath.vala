/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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

public class Akira.Utils.GeometryMath : Object {

    public static void min_max (ref double x0, ref double x1) {
        if (x1 < x0) {
            double t = x0;
            x0 = x1;
            x1 = t;
        }
    }

    public static void min_max_coords(double x0, double x1, double x2, double x3, ref double min, ref double max) {
        min_max(ref x0, ref x1);
        min_max(ref x2, ref x3);

        min = x0 < x2 ? x0 : x2;
        max = x1 > x3 ? x1 : x3;
    }

}
