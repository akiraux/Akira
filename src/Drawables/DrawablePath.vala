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
    public Geometry.Point[]? points = null;
    // Control the path edit mode between straight line and curves.
    // Line requires 1 points whereas, path requires 4 points.
    public Lib.Modes.PathEditMode.Type[]? commands = null;
    // This flag tells us if the first and last point need to be joined.
    public bool close;

    public DrawablePath (Geometry.Point[]? points = null, Lib.Modes.PathEditMode.Type[]? commands = null, bool close = false) {
       if (points != null && commands != null) {
           this.points = points;
           this.commands = commands;
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
        cr.move_to (points[0].x, points[0].y);

        int point_idx = 0;
        for (int i = 0; i < commands.length && point_idx < points.length; ++i) {
            if (commands[i] == Lib.Modes.PathEditMode.Type.LINE) {
                cr.line_to (points[point_idx].x, points[point_idx].y);
                ++point_idx;
            } else if (commands[i] == Lib.Modes.PathEditMode.Type.CURVE) {
                var x0 = points[point_idx - 1].x;
                var y0 = points[point_idx - 1].y;

                var x1 = points[point_idx].x;
                var y1 = points[point_idx].y;

                var x2 = points[point_idx + 1].x;
                var y2 = points[point_idx + 1].y;

                var x3 = points[point_idx + 2].x;
                var y3 = points[point_idx + 2].y;

                var x4 = points[point_idx + 3].x;
                var y4 = points[point_idx + 3].y;

                cr.curve_to (x0, y0, x2, y2, x1, y1);
                cr.curve_to (x1, y1, x3, y3, x4, y4);

                point_idx += 4;
            }
        }

        if (close) {
            cr.line_to (points[0].x, points[0].y);
        }

        cr.restore ();
    }
}
