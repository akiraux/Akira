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
    private Geometry.Rectangle? old_extents = null;

    public void update_path_data (Models.PathDataModel _path_data) {
        path_data = _path_data;

        if (old_live_extents == null) {
          // Initial values for old extents of live effect will span the entire canvas.
          old_live_extents = Geometry.Rectangle.empty ();
          old_live_extents.right = old_live_extents.bottom = 1000.0;
        }

        if (old_extents == null) {
          old_extents = Geometry.Rectangle.empty ();
          old_extents.right = old_extents.bottom = 1000.0;
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

        canvas.request_redraw (old_extents);
        canvas.request_redraw (path_data.extents);

        canvas.request_redraw (old_live_extents);
        canvas.request_redraw (path_data.live_extents);

        //  print("LIve extents are %f %f %f %f\n", path_data.live_extents.top, path_data.live_extents.left, path_data.live_extents.bottom, path_data.live_extents.right);

        old_live_extents = path_data.live_extents;
        old_extents = path_data.extents;
    }

    private void draw_points (Cairo.Context context) {
        if (path_data.points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;

        context.save ();

        // Apply transform matrix of drawable so we don't have to rotate or scale.
        var tr = path_data.transform;
        // For all path points, the origin is in top left corner. Move there.
        tr.translate (path_data.center.x, path_data.center.y);

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
        context.set_line_width (1.0 / canvas.scale);

        var points = path_data.points;

        // Draw circles for all points.
        for (int i = 0; i < points.length; ++i) {
            var curve_begin = points[i].curve_begin;
            var tangent_1 = points[i].tangent_1;
            var tangent_2 = points[i].tangent_2;
            var curve_end = points[i].curve_end;

            tr.transform_point (ref curve_begin.x, ref curve_begin.y);
            tr.transform_point (ref tangent_1.x, ref tangent_1.y);
            tr.transform_point (ref tangent_2.x, ref tangent_2.y);
            tr.transform_point (ref curve_end.x, ref curve_end.y);

            if (points[i].type == Lib.Modes.PathEditMode.Type.LINE) {
                draw_control_point (context, curve_begin, radius);
                context.fill ();
            } else if (points[i].type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
                // Draw control point for curve begin and tangent.
                draw_control_point (context, curve_begin, radius);
                draw_control_point (context, tangent_1, radius);
                context.fill ();

                draw_line (context, curve_begin, tangent_1);
                context.stroke ();
            } else if (
                points[i].type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE ||
                points[i].type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE
            ) {
                // Draw control points.
                draw_control_point (context, curve_begin, radius);
                draw_control_point (context, tangent_1, radius);
                context.fill ();
                draw_control_point (context, tangent_2, radius);
                draw_control_point (context, curve_end, radius);
                context.fill ();

                draw_line (context, tangent_1, curve_begin);

                if (points[i].type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE) {
                    draw_line (context, curve_end, tangent_2);
                } else {
                    draw_line (context, curve_begin, tangent_2);
                }

                context.stroke ();
            }
        }

        foreach (var sel_pnt in path_data.selected_pts) {
            context.set_source_rgba (0.7, 0, 0, 1);

            var segment = points[sel_pnt.sel_index];
            var pt = segment.get_by_type (sel_pnt.sel_type);

            draw_control_point (context, pt, radius);
        }

        context.new_path ();
        context.restore ();
    }

    private void draw_live_effect (Cairo.Context context) {
        context.save ();

        context.new_path ();
        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (1.0 / canvas.scale);

        var live_segment = path_data.live_segment;
        var live_point_type = path_data.live_point_type;

        context.move_to (path_data.last_point.x, path_data.last_point.y);

        draw_segment (context, live_segment, path_data.last_point, live_point_type);

        context.new_path ();
        context.restore ();
    }

    private void draw_segment (Cairo.Context context, Geometry.PathSegment segment, Geometry.Point point_before, Lib.Modes.PathEditMode.PointType upto) {
        double radius = UI_NOB_SIZE / canvas.scale;

        // First draw the curve.
        if (segment.type == Lib.Modes.PathEditMode.Type.LINE) {
            // Line only contains 1 point so no need to check 'upto'.
            context.line_to (segment.line_end.x, segment.line_end.y);
        } else if (segment.type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
            // Quadratic will always have all 3 points, otherwise it just becomes a line.
            context.curve_to (
                point_before.x,
                point_before.y,
                segment.tangent_1.x,
                segment.tangent_1.y,
                segment.curve_begin.x,
                segment.curve_begin.y
            );
        } else if (segment.type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE) {
            context.move_to (segment.curve_begin.x, segment.curve_begin.y);
            context.curve_to (
                segment.tangent_1.x,
                segment.tangent_1.y,
                segment.tangent_2.x,
                segment.tangent_2.y,
                segment.curve_end.x,
                segment.curve_end.y
            );
        } else if (segment.type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE) {
            context.curve_to (
                path_data.last_point.x,
                path_data.last_point.y,
                segment.tangent_1.x,
                segment.tangent_1.y,
                segment.curve_begin.x,
                segment.curve_begin.y
            );

            if (upto == Lib.Modes.PathEditMode.PointType.CURVE_END) {
                context.curve_to (
                    segment.curve_begin.x,
                    segment.curve_begin.y,
                    segment.tangent_2.x,
                    segment.tangent_2.y,
                    segment.curve_end.x,
                    segment.curve_end.y
                );
            }
        }

        // Now draw all the control points.
        if (segment.type == Lib.Modes.PathEditMode.Type.LINE) {
            context.stroke ();
        } else if (segment.type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
            draw_line (context, point_before, segment.tangent_1);
            context.stroke ();

            draw_control_point (context, point_before, radius);
            draw_control_point (context, segment.tangent_1, radius);
            context.fill ();
        } else if (segment.type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE) {
            draw_line (context, segment.tangent_1, segment.curve_begin);
            draw_line (context, segment.tangent_2, segment.curve_end);
            context.stroke ();

            draw_control_point (context, segment.curve_begin, radius);
            context.fill ();
            draw_control_point (context, segment.tangent_1, radius);
            draw_control_point (context, segment.tangent_2, radius);
            context.fill ();
        } else if (segment.type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE) {
            draw_line (context, segment.tangent_1, segment.curve_begin);
            draw_line (context, segment.tangent_2, segment.curve_begin);
            context.stroke ();

            draw_control_point (context, segment.curve_begin, radius);
            draw_control_point (context, segment.tangent_1, radius);
            draw_control_point (context, segment.tangent_2, radius);
            context.fill ();
        }

        context.stroke ();
    }

    private void draw_line (Cairo.Context context, Geometry.Point start, Geometry.Point end) {
        context.move_to (start.x, start.y);
        context.line_to (end.x, end.y);
    }

    private void draw_control_point (Cairo.Context context, Geometry.Point point, double radius) {
        context.arc (point.x, point.y, radius, 0, Math.PI * 2);
    }
}
