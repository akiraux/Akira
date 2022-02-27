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

/*
 * Drawable for paths.
 */
public class Akira.Drawables.DrawablePath : Drawable {
    // In the future we will probably want control points with more data.

    // This array stores the list of all points required to draw the point.
    public Geometry.PathSegment[]? points = null;
    // This flag tells us if the first and last point need to be joined.
    public bool close;

    public DrawablePath (Geometry.PathSegment[]? points = null, bool close = false) {
       if (points != null) {
           this.points = points;
           this.close = close;
       }
    }

    public override void simple_create_path (Cairo.Context cr) {
        if (points == null || points.length < 2) {
            return;
        }

        cr.save ();
        cr.translate (center_x, center_y);
        cr.new_path ();
        cr.move_to (points[0].line_end.x, points[0].line_end.y);


        for (int i = 0; i < points.length; ++i) {
            var point = points[i];
            if (point.type == Lib.Modes.PathEditMode.Type.LINE) {
                cr.line_to (point.line_end.x, point.line_end.y);
            } else if (point.type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
                var pb = points[i - 1].last_point;
                var cb = point.curve_begin;
                var t1 = point.tangent_1;
                cr.curve_to (pb.x, pb.y, t1.x, t1.y, cb.x, cb.y);
            } else if (point.type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE) {
                var cb = point.curve_begin;
                var t1 = point.tangent_1;
                var t2 = point.tangent_2;
                var ce = point.curve_end;
                cr.move_to (cb.x, cb.y);
                cr.curve_to (t1.x, t1.y, t2.x, t2.y, ce.x, ce.y);
            } else if (point.type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE) {
                var pb = points[i - 1].last_point;
                var cb = point.curve_begin;
                var t1 = point.tangent_1;
                var t2 = point.tangent_2;
                var ce = point.curve_end;
                cr.curve_to (pb.x, pb.y, t1.x, t1.y, cb.x, cb.y);
                cr.curve_to (cb.x, cb.y, t2.x, t2.y, ce.x, ce.y);
            }
        }

        if (close) {
            cr.line_to (points[0].line_end.x, points[0].line_end.y);
        }

        cr.restore ();
    }
}
