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
    public const double UI_LINE_WIDTH = 1.01;

    private Geometry.Point[]? points = null;
    private Geometry.Rectangle extents;

    public void update_path_data (Geometry.Point[]? _points, Geometry.Rectangle _extents) {
        points = recalculate_points (_points);
        extents = _extents;
        canvas.request_redraw (extents);
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
        context.new_path ();
    }

    private void draw_points (Cairo.Context context) {
        if (points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;
        double line_width = UI_LINE_WIDTH / canvas.scale;

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
        context.set_line_width (line_width);

        var reference_point = Geometry.Point (extents.left, extents.top);

        foreach (var pt in points) {
            context.move_to (pt.x + reference_point.x, pt.y + reference_point.y);
            context.arc (pt.x + reference_point.x, pt.y + reference_point.y, radius, 0, Math.PI * 2);
            context.fill ();
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }

    private Geometry.Point[] recalculate_points (Geometry.Point[] points) {
        double min_x = 0, min_y = 0;

        foreach (var pt in points) {
            if (pt.x < min_x) {
                min_x = pt.x;
            }
            if (pt.y < min_y) {
                min_y = pt.y;
            }
        }

        Geometry.Point[] translated_points = new Geometry.Point[points.length];

        for (int i = 0; i < points.length; ++i) {
            translated_points[i] = Geometry.Point (points[i].x - min_x, points[i].y - min_y);
        }

        return translated_points;
    }
}
