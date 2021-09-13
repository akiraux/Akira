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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerPath : ViewLayer {
    public const double UI_NOB_SIZE = 4;

    private Geometry.Point[]? points = null;
    private Geometry.Point[]? live_pts = null;
    private int length;
    private Geometry.Rectangle extents;

    /*
     * _points = Array of all points in the path.
     * live_pts = Array of live points. (Points that haven't been added to path yet, but may be added in a while).
     * length = No. of points in the live_pts array.
     * _extents = Region in which the path and live points lie.
    */
    public void update_path_data (Geometry.Point[]? _points, Geometry.Point[] _live_pts, int _length, Geometry.Rectangle _extents) {
        points = _points;
        live_pts = _live_pts;
        length = _length;
        extents = _extents;

        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (is_visible == false) {
            return;
        }

        if (canvas == null || points == null) {
            return;
        }

        if (extents.left > target_bounds.right || extents.right < target_bounds.left
            || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
            return;
        }

        draw_points (context);
        draw_live_effect (context);

        context.new_path ();
    }

    public override void update () {
        if (canvas == null || points == null) {
            return;
        }

        canvas.request_redraw (extents);
    }

    private void draw_points (Cairo.Context context) {
        if (points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);

        var reference_point = Geometry.Point (extents.left, extents.top);

        foreach (var pt in points) {
            context.arc (pt.x + reference_point.x, pt.y + reference_point.y, radius, 0, Math.PI * 2);
            context.fill ();
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }

    private void draw_live_effect (Cairo.Context context) {
        context.save ();

        context.new_path ();
        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (1.0 / canvas.scale);

        var reference_point = Geometry.Point (extents.left, extents.top);
        var last_point = points[points.length - 1];

        context.move_to (last_point.x + reference_point.x, last_point.y + reference_point.y);

        switch (length) {
            case 0: break;
            case 1: context.line_to (live_pts[0].x, live_pts[0].y);
                    break;
            case 2: var x1 = points[points.length - 1].x + reference_point.x;
                    var y1 = points[points.length - 1].y + reference_point.y;
                    var x2 = live_pts[0].x;
                    var y2 = live_pts[0].y;
                    var x3 = live_pts[1].x;
                    var y3 = live_pts[1].y;

                    context.curve_to (x1, y1, x2, y2, x3, y3);
                    break;
            case 3: var x1 = live_pts[0].x;
                    var y1 = live_pts[0].y;
                    var x2 = live_pts[1].x;
                    var y2 = live_pts[1].y;
                    var x3 = live_pts[2].x;
                    var y3 = live_pts[2].y;

                    context.curve_to (x1, y1, x2, y2, x3, y3);
                    break;
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }
}
