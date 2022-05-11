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
  * Consists of an original rectangle, and a matrix to transform it to the
  * world coordinates.
  */
  public struct Akira.Geometry.TransformedRectangle {
      public Rectangle rect;
      public Cairo.Matrix matrix;

      public TransformedRectangle () {}

      public TransformedRectangle.with_geometry (Rectangle rectangle, Cairo.Matrix matrix) {
          rect = rectangle;
          this.matrix = matrix;
      }

      public TransformedRectangle.empty () {
          rect = Rectangle.empty ();
          this.matrix = Cairo.Matrix.identity ();
      }

      public Quad quad () {
          var quad = Quad.from_rectangle (rect);
          quad.transform (matrix);
          return quad;
      }

      /*
       * Maps x, y from the world coordinates to the rect
       * coordinates.
       */
      public void map_to_local (ref double x, ref double y) {
          var inv = matrix;
          inv.invert ();
          inv.transform_point (ref x, ref y);
      }

      /*
       * Map x, y from the rect coordinates to the world coordinates.
       */
      public void map_from_local (ref double x, ref double y) {
          matrix.transform_point (ref x, ref y);
      }

      /*
       * Returns true if the transformed rectangle contains the x, y position
       * in the world coordinates defined by the `matrix` mapping
       */
      public bool contains (double x, double y) {
          map_to_local (ref x, ref y);
          return rect.contains (x, y);
      }
}
