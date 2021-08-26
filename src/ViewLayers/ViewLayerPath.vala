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

    private Gee.ArrayList<Geometry.Point?>? points = null;
    private Geometry.Rectangle extents;
    private Geometry.Point first_point;

    public void set_reference_point (Geometry.Point reference_point) {
        first_point = reference_point;
        canvas.request_redraw (extents);
    }

    public void update_path_data (Gee.ArrayList<Geometry.Point?> _points) {
        points = _points;
        recalculate_extents ();
        canvas.request_redraw (extents);
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
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

    public void draw_points (Cairo.Context context) {
        if (points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;
        double line_width = UI_LINE_WIDTH / canvas.scale;

        context.save();

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
        context.set_line_width (line_width);

        foreach (var pt in points) {
            context.move_to (pt.x + first_point.x, pt.y + first_point.y);
            context.arc (pt.x + first_point.x, pt.y + first_point.y, radius, 0, Math.PI * 2);
            context.fill();
        }

        context.stroke();
        context.new_path();
        context.restore();
    }

    private void recalculate_extents () {
        extents = new Geometry.Rectangle.empty ();

        foreach (var pt in points) {
            if (pt.x < extents.left) {
                extents.left = pt.x;
            }
            if (pt.x > extents.right) {
                extents.right = pt.x;
            }
            if (pt.y < extents.top) {
                extents.top = pt.y;
            }
            if (pt.y > extents.left) {
                extents.bottom = pt.y;
            }
        }

        // compensation for size of nobs.
        double radius = UI_NOB_SIZE / canvas.scale;
        extents.left -= radius;
        extents.right += radius;
        extents.top -= radius;
        extents.bottom += radius;

        extents.translate (first_point.x, first_point.y);
    }
}
