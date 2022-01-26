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

    private Models.PathDataModel path_data;
    private Geometry.Rectangle? old_live_extents = null;

    public void update_path_data (Models.PathDataModel _path_data) {
        path_data = _path_data;

        if (old_live_extents == null) {
          // Initial values for old extents of live effect will span the entire canvas.
          old_live_extents = Geometry.Rectangle.empty ();
          old_live_extents.right = old_live_extents.bottom = 1000.0;
        }

        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (is_visible == false) {
            return;
        }

        if (canvas == null || path_data.points == null) {
            return;
        }

        if (path_data.extents.left > target_bounds.right || path_data.extents.right < target_bounds.left
            || path_data.extents.top > target_bounds.bottom || path_data.extents.bottom < target_bounds.top) {

            if (path_data.live_extents.left > target_bounds.right || path_data.live_extents.right < target_bounds.left
            || path_data.live_extents.top > target_bounds.bottom || path_data.live_extents.bottom < target_bounds.top) {
                return;
            }

            draw_live_effect (context);
            return;
        }

        draw_points (context);
        draw_live_effect (context);

        context.new_path ();
    }

    public override void update () {
        if (canvas == null) {
            return;
        }

        canvas.request_redraw (old_live_extents);
        canvas.request_redraw (path_data.live_extents);
        old_live_extents = path_data.live_extents;
    }

    private void draw_points (Cairo.Context context) {
        if (path_data.points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;

        context.save ();

        // Apply transform matrix of drawable so we don't have to rotate or scale.
        //var tr = Utils.GeometryMath.multiply_matrices (path_data.transform, context.get_matrix ());
        var tr = path_data.transform;
        // For all path points, the origin is in top left corner. Move there.
        tr.translate (path_data.center.x, path_data.center.y);

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
        context.set_line_width (1.0 / canvas.scale);

        int point_idx = 0;
        var points = path_data.points;
        var commands = path_data.commands;

        // Draw circles for all points.
        for (int i = 0; i < commands.length; ++i) {
            var pt = points[point_idx];
            tr.transform_point (ref pt.x, ref pt.y);

            if (commands[i] == Lib.Modes.PathEditMode.Type.LINE) {
                context.arc (pt.x, pt.y, radius, 0, Math.PI * 2);
                context.fill ();

                ++point_idx;
            } else {
                for (int j = 0; j < 4; ++j) {
                    var pti = points[j + point_idx];
                    tr.transform_point (ref pti.x, ref pti.y);

                    context.arc (pti.x, pti.y, radius, 0, Math.PI * 2);
                    context.fill ();
                }

                var pt1 = points[point_idx + 1];
                var pt2 = points[point_idx + 2];
                tr.transform_point (ref pt1.x, ref pt1.y);
                tr.transform_point (ref pt2.x, ref pt2.y);
                context.move_to (pt.x, pt.y);
                context.line_to (pt1.x, pt1.y);

                context.move_to (pt.x, pt.y);
                context.line_to (pt2.x, pt2.y);

                context.stroke ();

                point_idx += 4;
            }
        }

        foreach (var idx in path_data.selected_pts) {
            context.set_source_rgba (0.7, 0, 0, 1);

            var pt = points[idx];
            tr.transform_point (ref pt.x, ref pt.y);
            context.arc (pt.x, pt.y, radius, 0, Math.PI * 2);
            context.fill ();
        }

        context.new_path ();
        context.restore ();
    }

    private void draw_live_effect (Cairo.Context context) {
        double radius = UI_NOB_SIZE / canvas.scale;

        context.save ();

        context.new_path ();
        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (1.0 / canvas.scale);

        var live_pts = path_data.live_pts;
        var last_point = path_data.last_point;

        context.move_to (last_point.x, last_point.y);

        switch (path_data.length) {
            case 0:
                break;
            case 1:
                context.line_to (live_pts[0].x, live_pts[0].y);
                break;
            case 2:
                break;
            case 3:
                var x0 = last_point.x;
                var y0 = last_point.y;
                var x1 = live_pts[0].x;
                var y1 = live_pts[0].y;
                var x2 = live_pts[1].x;
                var y2 = live_pts[1].y;
                var x3 = live_pts[2].x;
                var y3 = live_pts[2].y;

                // Draw the actual live curve.
                context.curve_to (x0, y0, x2, y2, x1, y1);
                context.stroke ();

                // Draw the first haldf of tangent for curve.
                context.line_to (x2, y2);
                context.line_to (x3, y3);
                context.stroke ();

                // Draw circles for all concerned points.
                context.arc (x0, y0, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x1, y1, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x2, y2, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x3, y3, radius, 0, Math.PI * 2);
                context.fill ();

                break;
            case 4:
                var x0 = last_point.x;
                var y0 = last_point.y;
                var x1 = live_pts[0].x;
                var y1 = live_pts[0].y;
                var x2 = live_pts[1].x;
                var y2 = live_pts[1].y;
                var x3 = live_pts[2].x;
                var y3 = live_pts[2].y;
                var x4 = live_pts[3].x;
                var y4 = live_pts[3].y;

                // Draw the actual curves.
                context.curve_to (x0, y0, x2, y2, x1, y1);
                context.stroke ();
                context.curve_to (x1, y1, x3, y3, x4, y4);
                context.stroke ();

                // Draw line for the tangent of the curve.
                context.move_to (x2, y2);
                context.line_to (x3, y3);
                context.stroke ();

                // Draw circles for all points in the live curve.
                context.arc (x0, y0, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x1, y1, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x2, y2, radius, 0, Math.PI * 2);
                context.fill ();
                context.arc (x3, y3, radius, 0, Math.PI * 2);
                context.fill ();
                break;

            default:
                break;
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }
}
