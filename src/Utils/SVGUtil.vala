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

/**
 * Utility to manage small svg conversions.
 */
 public class Akira.Utils.SVGUtil : Object {
     public static string rect_to_svg_path (
         double shift_x, 
         double shift_y, 
         double top, 
         double left, 
         double bottom, 
         double right
    ) {
         var dx = right - left;
         var dy = bottom - top;

         //var str = "m %f, %f h %f v %f h %f z".printf (shift_x + top, shift_y + left, dx, dy, -dx);
         return "m %f, %f h %f v %f h %f z".printf (shift_x + top, shift_y + left, dx, dy, -dx);
     }
 }