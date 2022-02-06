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
        //var tr = Utils.GeometryMath.multiply_matrices (path_data.transform, context.get_matrix ());
        var tr = path_data.transform;
        // For all path points, the origin is in top left corner. Move there.
        tr.translate (path_data.center.x, path_data.center.y);

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
        context.set_line_width (1.0 / canvas.scale);

        var points = path_data.points;

        // Draw circles for all points.
        for (int i = 0; i < points.length; ++i) {
            var line_end = points[i].line_end;

            var curve_begin = points[i].curve_begin;
            var tangent_1 = points[i].tangent_1;
            var tangent_2 = points[i].tangent_2;
            var curve_end = points[i].curve_end;

            if (points[i].type == Lib.Modes.PathEditMode.Type.LINE) {
                //  var pt = points[point_idx].line_end;
                tr.transform_point (ref line_end.x, ref line_end.y);

                context.arc (line_end.x, line_end.y, radius, 0, Math.PI * 2);
                context.fill ();
            } else if (points[i].type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
                tr.transform_point (ref curve_begin.x, ref curve_begin.y);
                tr.transform_point (ref tangent_1.x, ref tangent_1.y);
                tr.transform_point (ref curve_end.x, ref curve_end.y);

                // Draw control point for curve begin.
                context.arc (curve_begin.x, curve_begin.y, radius, 0, Math.PI * 2);
                context.fill ();

                // Draw control point for first tangent.
                context.arc (tangent_1.x, tangent_1.y, radius, 0, Math.PI * 2);
                context.fill ();

                // Draw control point for curve end.
                context.arc (curve_end.x, curve_end.y, radius, 0, Math.PI * 2);
                context.fill ();

                context.move_to (tangent_1.x, tangent_1.y);
                context.line_to (curve_begin.x, curve_begin.y);

                context.stroke ();
            } else if (points[i].type == Lib.Modes.PathEditMode.Type.CUBIC) {
                tr.transform_point (ref curve_begin.x, ref curve_begin.y);
                tr.transform_point (ref tangent_1.x, ref tangent_1.y);
                tr.transform_point (ref tangent_2.x, ref tangent_2.y);
                tr.transform_point (ref curve_end.x, ref curve_end.y);

                // Draw control point for curve begin.
                context.arc (curve_begin.x, curve_begin.y, radius, 0, Math.PI * 2);
                context.fill ();

                // Draw control point for first tangent.
                context.arc (tangent_1.x, tangent_1.y, radius, 0, Math.PI * 2);
                context.fill ();

                // Draw control point for second tangent.
                context.arc (tangent_2.x, tangent_2.y, radius, 0, Math.PI * 2);
                context.fill ();

                // Draw control point for curve end.
                context.arc (curve_end.x, curve_end.y, radius, 0, Math.PI * 2);
                context.fill ();

                context.move_to (tangent_1.x, tangent_1.y);
                context.line_to (curve_begin.x, curve_begin.y);

                context.move_to (curve_begin.x, curve_begin.y);
                context.line_to (tangent_2.x, tangent_2.y);

                context.stroke ();
            }
        }

        foreach (var sel_pnt in path_data.selected_pts) {
            context.set_source_rgba (0.7, 0, 0, 1);

            var segment = points[sel_pnt.sel_index];
            var pt = segment.get_by_type (sel_pnt.sel_type);
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

        var live_segment = path_data.live_segment;
        var live_point_type = path_data.live_point_type;

        context.move_to (path_data.last_point.x, path_data.last_point.y);

        if (live_segment.type == Lib.Modes.PathEditMode.Type.LINE) {
            if (live_point_type == Lib.Modes.PathEditMode.PointType.LINE_END) {
                context.line_to (live_segment.line_end.x, live_segment.line_end.y);
            }
        } else if (live_segment.type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
        } else if (live_segment.type == Lib.Modes.PathEditMode.Type.CUBIC) {
            if (live_point_type == Lib.Modes.PathEditMode.PointType.TANGENT_SECOND) {
                context.curve_to (
                    path_data.last_point.x,
                    path_data.last_point.y,
                    live_segment.tangent_1.x,
                    live_segment.tangent_1.y,
                    live_segment.curve_begin.x,
                    live_segment.curve_begin.y
                );
            } else if (live_point_type == Lib.Modes.PathEditMode.PointType.CURVE_END) {
                context.curve_to (
                    path_data.last_point.x,
                    path_data.last_point.y,
                    live_segment.tangent_1.x,
                    live_segment.tangent_1.y,
                    live_segment.curve_begin.x,
                    live_segment.curve_begin.y
                );
                context.curve_to (
                    live_segment.curve_begin.x,
                    live_segment.curve_begin.y,
                    live_segment.tangent_2.x,
                    live_segment.tangent_2.y,
                    live_segment.curve_end.x,
                    live_segment.curve_end.y
                );
            }
        }

        context.stroke ();

        context.new_path ();
        context.restore ();
    }
}
