/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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

public class Akira.Models.PathEditModel : Object {

    public Lib.Items.ModelInstance instance { get; construct; }
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private ViewLayers.ViewLayerPath path_layer;

    private Geometry.PathSegment[] points;

    public Geometry.Point first_point;

    private Geometry.PathSegment live_segment;
    private Lib.Modes.PathEditMode.PointType live_point_type;

    public Gee.HashSet<Geometry.SelectedPoint?> selected_pts;
    public Geometry.SelectedPoint reference_point;

    public bool tangents_inline = false;

    // This is the diameter of the blue points drawn in ViewLayerPath.
    // It is used for checking if user clicked withing the region.
    public const int HIT_SIZE = 4;

    public PathEditModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        points = instance.components.path.data;

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        // The selected_pts will contain the list of all points that we want to modify.
        selected_pts = new Gee.HashSet<Geometry.SelectedPoint?> ();

        live_segment = Geometry.PathSegment ();
        live_point_type = Lib.Modes.PathEditMode.PointType.NONE;

        update_view ();
    }

    public void set_first_point (Geometry.Point first_point) {
        this.first_point = first_point;
        update_view ();
    }

    public void add_live_points_to_path (Geometry.PathSegment live_pts) {
        var transform_matrix = instance.components.transform.transformation_matrix;
        var orig_first_pt = transform_point_around_item_origin (first_point, transform_matrix, true);

        if (live_pts.type == Lib.Modes.PathEditMode.Type.LINE) {
            var line_end = transform_point_around_item_origin (live_pts.line_end, transform_matrix, true);
            line_end.x -= orig_first_pt.x;
            line_end.y -= orig_first_pt.y;

            line_end = Geometry.Point (Math.round (line_end.x), Math.round (line_end.y));

            var segment = Geometry.PathSegment.line (line_end);
            add_point_to_path (segment);
        } else if (live_pts.type == Lib.Modes.PathEditMode.Type.CUBIC) {
            var curve_begin = transform_point_around_item_origin (live_pts.curve_begin, transform_matrix, true);
            var tangent_1 = transform_point_around_item_origin (live_pts.tangent_1, transform_matrix, true);
            var tangent_2 = transform_point_around_item_origin (live_pts.tangent_2, transform_matrix, true);
            var curve_end = transform_point_around_item_origin (live_pts.curve_end, transform_matrix, true);

            curve_begin.x -= orig_first_pt.x;
            curve_begin.y -= orig_first_pt.y;

            tangent_1.x -= orig_first_pt.x;
            tangent_1.y -= orig_first_pt.y;

            tangent_2.x -= orig_first_pt.x;
            tangent_2.y -= orig_first_pt.y;

            curve_end.x -= orig_first_pt.x;
            curve_end.y -= orig_first_pt.y;

            curve_begin = Geometry.Point (Math.round (curve_begin.x), Math.round (curve_begin.y));
            tangent_1 = Geometry.Point (Math.round (tangent_1.x), Math.round (tangent_1.y));
            tangent_2 = Geometry.Point (Math.round (tangent_2.x), Math.round (tangent_2.y));
            curve_end = Geometry.Point (Math.round (curve_end.x), Math.round (curve_end.y));

            var segment = Geometry.PathSegment.cubic_bezier (curve_begin, tangent_1, tangent_2, curve_end);
            add_point_to_path (segment);
        } else if (live_pts.type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
            var curve_begin = transform_point_around_item_origin (live_pts.curve_begin, transform_matrix, true);
            var tangent_1 = transform_point_around_item_origin (live_pts.tangent_1, transform_matrix, true);
            var curve_end = transform_point_around_item_origin (live_pts.curve_end, transform_matrix, true);

            curve_begin.x -= orig_first_pt.x;
            curve_begin.y -= orig_first_pt.y;

            tangent_1.x -= orig_first_pt.x;
            tangent_1.y -= orig_first_pt.y;

            curve_end.x -= orig_first_pt.x;
            curve_end.y -= orig_first_pt.y;

            curve_begin = Geometry.Point (Math.round (curve_begin.x), Math.round (curve_begin.y));
            tangent_1 = Geometry.Point (Math.round (tangent_1.x), Math.round (tangent_1.y));
            curve_end = Geometry.Point (Math.round (curve_end.x), Math.round (curve_end.y));

            var segment = Geometry.PathSegment.quadratic_bezier (curve_begin, tangent_1, curve_end);
            add_point_to_path (segment);
        }

        live_segment = Geometry.PathSegment ();
        live_point_type = Lib.Modes.PathEditMode.PointType.NONE;

        recompute_components ();
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private void add_point_to_path (Geometry.PathSegment point, int index = -1) {
        index = (index == -1) ? index = points.length : index;

        points.resize (points.length + 1);

        // Add the given segment at the correct position and shift rest of the elements.
        for (int i = index; i < points.length; ++i) {
            var temp = points[i];
            points[i] = point;
            point = temp;
        }

        points = recalculate_points (points);
        bool close = instance.components.path.close;
        instance.components.path = new Lib.Components.Path.from_points (points, close);
    }

    public void set_live_points (Geometry.PathSegment live_segment, Lib.Modes.PathEditMode.PointType type) {
        this.live_segment = live_segment;
        this.live_point_type = type;

        update_view ();
    }

    public Geometry.PathSegment delete_point (int index = -1) {
        if (index == -1) {
            index = points.length - 1;
        }

        var last_segment = points[index];
        var new_live_pts = Geometry.PathSegment ();

        var orig_first_pt = transform_point_around_item_origin (
            first_point,
            instance.components.transform.transformation_matrix,
            true
        );

        var transform_matrix = instance.components.transform.transformation_matrix;

        // If the last segment from path is a line,
        if (last_segment.type == Lib.Modes.PathEditMode.Type.LINE) {
            var line_end = points[points.length - 2].line_end;
            line_end.x += orig_first_pt.x;
            line_end.y += orig_first_pt.y;
            line_end = transform_point_around_item_origin (line_end, transform_matrix);

            new_live_pts.line_end = line_end;
            new_live_pts.type = Lib.Modes.PathEditMode.Type.LINE;
        } else if (last_segment.type == Lib.Modes.PathEditMode.Type.CUBIC) {
            var curve_begin = last_segment.curve_begin;
            curve_begin.x += orig_first_pt.x;
            curve_begin.y += orig_first_pt.y;
            curve_begin = transform_point_around_item_origin (curve_begin, transform_matrix);

            var tangent_1 = last_segment.tangent_1;
            tangent_1.x += orig_first_pt.x;
            tangent_1.y += orig_first_pt.y;
            tangent_1 = transform_point_around_item_origin (tangent_1, transform_matrix);

            var tangent_2 = last_segment.tangent_2;
            tangent_2.x += orig_first_pt.x;
            tangent_2.y += orig_first_pt.y;
            tangent_2 = transform_point_around_item_origin (tangent_2, transform_matrix);

            var curve_end = last_segment.curve_end;
            curve_end.x += orig_first_pt.x;
            curve_end.y += orig_first_pt.y;
            curve_end = transform_point_around_item_origin (curve_end, transform_matrix);

            new_live_pts.type = Lib.Modes.PathEditMode.Type.CUBIC;
            new_live_pts.curve_begin = curve_begin;
            new_live_pts.tangent_1 = tangent_1;
            new_live_pts.tangent_2 = tangent_2;
            new_live_pts.curve_end = curve_end;
        }

        var new_points = new Geometry.PathSegment[points.length - 1];
        for (int i = 0, seg_idx = 0; i < points.length; ++i) {
            if (i == index) {
                continue;
            }

            new_points[seg_idx] = points[i];
            ++seg_idx;
        }

        points = recalculate_points (new_points);
        instance.components.path = new Lib.Components.Path.from_points (points, false);
        recompute_components ();

        return new_live_pts;
    }

    /*
     * This method is used to check if user clicked on a point in the path.
     * Returns true if clicked, false otherwise.
     * If a point was clicked, index refers to its location.
     * If check_idx is -1, do hit test with all the points. Otherwise
     * only with the given point.
     */
    public bool hit_test (double x, double y, ref Geometry.SelectedPoint sel_pnt, int check_idx = -1) {
        // In order to check if user clicked on a point, we need to rotate the first point and the event
        // around the item center. Then the difference between these values gives the location
        // event in the same coordinate system as the points.
        var transform_matrix = instance.components.transform.transformation_matrix;
        var orig_first_pt = transform_point_around_item_origin (first_point, transform_matrix, true);

        Geometry.Point point = Geometry.Point (x, y);
        point = transform_point_around_item_origin (point, transform_matrix, true);
        point = Geometry.Point (point.x - orig_first_pt.x, point.y - orig_first_pt.y);

        tangents_inline = false;
        double thresh = HIT_SIZE / view_canvas.scale;

        if (check_idx != -1) {
            if (Utils.GeometryMath.compare_points (points[check_idx].last_point, point, thresh)) {
                sel_pnt.sel_type = Lib.Modes.PathEditMode.PointType.LINE_END;
                sel_pnt.sel_index = check_idx;
                return true;
            }

            sel_pnt.sel_type = Lib.Modes.PathEditMode.PointType.NONE;
            sel_pnt.sel_index = -1;
            return false;
        }

        for (int i = 0; i < points.length; ++i) {
            var hit_type = points[i].hit_test (point, thresh);

            if (hit_type == Lib.Modes.PathEditMode.PointType.NONE) {
                continue;
            }

            if (
                hit_type == Lib.Modes.PathEditMode.PointType.TANGENT_FIRST ||
                hit_type == Lib.Modes.PathEditMode.PointType.TANGENT_SECOND
            ) {
                if (!points[i].check_tangents_inline ()) {
                    sel_pnt.tangents_staggered = true;
                }

                if (points[i].type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
                    sel_pnt.tangents_staggered = true;
                }
            }

            sel_pnt.sel_type = hit_type;
            sel_pnt.sel_index = i;
            return true;
        }

        //  return Lib.Modes.PathEditMode.PointType.NONE;
        sel_pnt.sel_type = Lib.Modes.PathEditMode.PointType.NONE;
        sel_pnt.sel_index = -1;
        return false;
    }

    /*
     * This method will be used when editing paths to update the position of a point.
     */
    public void modify_point_value (Geometry.Point new_pos) {
        var transform_matrix = instance.components.transform.transformation_matrix;
        var orig_first_pt = transform_point_around_item_origin (first_point, transform_matrix, true);
        new_pos = transform_point_around_item_origin (new_pos, transform_matrix, true);

        new_pos.x -= orig_first_pt.x;
        new_pos.y -= orig_first_pt.y;

        if (selected_pts.size == 1) {
            // If only one point is selected, it will act as reference point.
            reference_point = selected_pts.to_array ()[0];
        }

        Geometry.Point original_ref = points[reference_point.sel_index].get_by_type (reference_point.sel_type);

        // Calculate by how much the reference point changed, then move other points by this amount.
        // We are rounding this value to the nearest integer. This is the spacing used in ViewLayerGrid.
        double delta_x = Math.round (original_ref.x - new_pos.x);
        double delta_y = Math.round (original_ref.y - new_pos.y);

        foreach (var sel_pnt in selected_pts) {
            switch (sel_pnt.sel_type) {
                case Lib.Modes.PathEditMode.PointType.LINE_END:
                    var old = points[sel_pnt.sel_index].line_end;
                    points[sel_pnt.sel_index].line_end = Geometry.Point (old.x - delta_x, old.y - delta_y);
                    break;
                case Lib.Modes.PathEditMode.PointType.CURVE_BEGIN:
                    // When this points moves, tangents must be moved with it too.
                    // To make this easier, move the whole segment then return
                    // CURVE_BEGIN to its original position.
                    points[sel_pnt.sel_index].translate (delta_x, delta_y);
                    var old = points[sel_pnt.sel_index].curve_end;
                    points[sel_pnt.sel_index].curve_end = Geometry.Point (old.x + delta_x, old.y + delta_y);
                    break;
                case Lib.Modes.PathEditMode.PointType.TANGENT_FIRST:
                    if (sel_pnt.tangents_staggered) {
                        var old = points[sel_pnt.sel_index].tangent_1;
                        points[sel_pnt.sel_index].tangent_1 = Geometry.Point (old.x - delta_x, old.y - delta_y);
                    } else {
                        points[sel_pnt.sel_index].move_tangents (delta_x, delta_y, true);
                    }
                    break;
                case Lib.Modes.PathEditMode.PointType.TANGENT_SECOND:
                    if (sel_pnt.tangents_staggered) {
                        var old = points[sel_pnt.sel_index].tangent_2;
                        points[sel_pnt.sel_index].tangent_2 = Geometry.Point (old.x - delta_x, old.y - delta_y);
                    } else {
                        points[sel_pnt.sel_index].move_tangents (delta_x, delta_y, false);
                    }
                    break;
                case Lib.Modes.PathEditMode.PointType.CURVE_END:
                    var old = points[sel_pnt.sel_index].curve_end;
                    points[sel_pnt.sel_index].curve_end = Geometry.Point (old.x - delta_x, old.y - delta_y);
                    break;
            }
        }

        points = recalculate_points (points);
        bool close = instance.components.path.close;
        instance.components.path = new Lib.Components.Path.from_points (points, close);
        recompute_components ();
    }

    /*
     * This method is used to change the selected points.
     * idx is index of point to be added to selection. if -1, it is not added.
     * If append is true, add the item to the list, otherwise, clear the list then add.
     */
    public void set_selected_points (Geometry.SelectedPoint sel_pnt, bool append = false) {
        if (!append) {
            selected_pts.clear ();
        }

        if (sel_pnt.sel_index != -1) {
            selected_pts.add (sel_pnt);
        }

        update_view ();
    }

    /*
     * This method is used to join the first and last point of path
     * to make it a closed curve.
     */
    public void make_path_closed () {
        instance.components.path = new Lib.Components.Path.from_points (points, true);
        recompute_components ();
    }

    public bool check_can_path_close () {
        int last = points.length - 1;

        if (last == 0) {
            return false;
        }

        double thresh = HIT_SIZE / view_canvas.scale;
        if (Utils.GeometryMath.compare_points (points[0].last_point, points[last].last_point, thresh)) {
            make_path_closed ();
            return true;
        }

        return false;
    }

    public void toggle_point_type (Geometry.SelectedPoint sel_point) {
        if (points[sel_point.sel_index].type == Lib.Modes.PathEditMode.Type.LINE) {
            // Segment before and after the segment being toggled. Needed for calculating tangents.
            Geometry.PathSegment? segment_before = null;
            Geometry.PathSegment? segment_after = null;

            if (sel_point.sel_index != 0) {
                segment_before = points[sel_point.sel_index - 1];
            }

            if (sel_point.sel_index != points.length - 1) {
                segment_after = points[sel_point.sel_index + 1];
            }

            // If first segment needs to be toggled, we toggle the segment after that.
            // This is because of the way quadratics are drawn.
            if (segment_before == null) {
                points[sel_point.sel_index + 1].line_to_curve (points[0], null);
            } else {
                points[sel_point.sel_index].line_to_curve (segment_before, segment_after);

                // When line is turned to a curve, the segment after line becomes CURVE_END.
                // So the next segment needs to be deleted.
                if (segment_after != null) {
                    delete_point (sel_point.sel_index + 1);
                }
            }

        } else {
            // After converting a curve to a line, the curve_end must be made a line segment,
            // so that we dont lose a segment.
            var curr_segment = points[sel_point.sel_index];
            var segment_after = Geometry.PathSegment.line (curr_segment.curve_end);
            points[sel_point.sel_index].curve_to_line ();

            if (curr_segment.type == Lib.Modes.PathEditMode.Type.CUBIC) {
                add_point_to_path (segment_after, sel_point.sel_index + 1);
            }
        }

        bool close = instance.components.path.close;
        points = recalculate_points (points);
        instance.components.path = new Lib.Components.Path.from_points (points, close);
        recompute_components ();
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private Geometry.PathSegment[] recalculate_points (Geometry.PathSegment[] points) {
        double min_x = double.MAX, min_y = double.MAX;

        var path = new Lib.Components.Path.from_points (points);
        var ext = path.calculate_extents ();

        min_x = ext.left;
        min_y = ext.top;

        // Shift all the points.
        for (int i = 0; i < points.length; ++i) {
            points[i].translate (min_x, min_y);
        }

        // The amount by which the first point changed must be rotated before adding to first point.
        Geometry.Point delta = Geometry.Point (min_x, min_y);

        var transform_matrix = instance.components.transform.transformation_matrix;
        var rotated_delta = transform_point_around_item_origin (delta, transform_matrix);

        first_point.x += rotated_delta.x;
        first_point.y += rotated_delta.y;

        return points;
    }

    private void recompute_components () {
        var bounds = instance.components.path.calculate_extents ();

        double center_x = bounds.width / 2.0;
        double center_y = bounds.height / 2.0;

        var tr = instance.components.transform.transformation_matrix;
        tr.transform_point (ref center_x, ref center_y);

        center_x += first_point.x;
        center_y += first_point.y;

        instance.components.center = new Lib.Components.Coordinates (center_x, center_y);
        instance.components.size = new Lib.Components.Size (bounds.width, bounds.height, false);

        // Update the component.
        unowned var im = view_canvas.items_manager;
        im.item_model.alert_item_changed (instance.id, Lib.Components.Component.Type.COMPILED_GEOMETRY);
        im.compile_model ();

        update_view ();
    }

    /*
     * Recalculates the extents and updates the ViewLayerPath
     */
    public void update_view () {
        // Since the bounding box for the instance may not include the tangents,
        // we need to calculate the bounding box for all points.
        var tr = instance.components.transform.transformation_matrix;

        var extents_from_pts = Utils.GeometryMath.bounds_from_points (points);
        var extents_from_path = instance.components.path.calculate_extents ();

        double offset_x = extents_from_path.center_x - extents_from_pts.center_x;
        double offset_y = extents_from_path.center_y - extents_from_pts.center_y;
        tr.transform_point (ref offset_x, ref offset_y);

        double pts_center_x = instance.components.center.x - offset_x;
        double pts_center_y = instance.components.center.y - offset_y;

        var quad = Geometry.Quad.from_components (
            pts_center_x,
            pts_center_y,
            extents_from_pts.width,
            extents_from_pts.height,
            tr
        );

        var new_ext = quad.bounding_box;

        double radius = ViewLayers.ViewLayerPath.UI_NOB_SIZE / view_canvas.scale;
        new_ext.left -= radius;
        new_ext.top -= radius;
        new_ext.right += radius;
        new_ext.bottom += radius;

        PathDataModel path_data = PathDataModel ();
        path_data.points = points;
        //  path_data.live_pts = live_pts;
        path_data.live_segment = live_segment;
        path_data.live_point_type = live_point_type;
        //  path_data.length = live_pts_len;
        path_data.extents = new_ext;
        path_data.transform = instance.drawable.transform;
        path_data.selected_pts = selected_pts;
        path_data.last_point = get_last_point_from_path ();

        path_data.live_extents = get_extents_using_live_pts (extents_from_pts);

        double center_x = -instance.compiled_geometry.source_width / 2.0;
        double center_y = -instance.compiled_geometry.source_height / 2.0;
        path_data.center = Geometry.Point (center_x, center_y);

        path_layer.update_path_data (path_data);
    }

    private Geometry.Rectangle get_extents_using_live_pts (Geometry.Rectangle extents) {
        if (points.length == 0 || live_point_type == Lib.Modes.PathEditMode.PointType.NONE) {
            return extents;
        }

        var live_pnts = new Geometry.PathSegment[2];
        live_pnts[0] = Geometry.PathSegment.line ( get_last_point_from_path ());
        live_pnts[1] = live_segment;

        var live_extents = Utils.GeometryMath.bounds_from_points (live_pnts);

        double radius = ViewLayers.ViewLayerPath.UI_NOB_SIZE / view_canvas.scale;
        live_extents.left -= radius;
        live_extents.top -= radius;
        live_extents.right += radius;
        live_extents.bottom += radius;

        return live_extents;
    }

    private Geometry.Point transform_point_around_item_origin (
        Geometry.Point point,
        Cairo.Matrix mat,
        bool invert = false
    ) {
        var matrix = Utils.GeometryMath.multiply_matrices (Cairo.Matrix.identity (), mat);

        if (invert) {
            matrix.invert ();
        }

        var new_point = Geometry.Point (point.x, point.y);
        matrix.transform_point (ref new_point.x, ref new_point.y);
        return new_point;
    }

    public Geometry.Point get_last_point_from_path () {
        Cairo.Matrix transform_matrix = instance.components.transform.transformation_matrix;
        var orig_first_pt = transform_point_around_item_origin (first_point, transform_matrix, true);

        if (instance.components.path.data.length == 0) {
            return orig_first_pt;
        }

        Geometry.Point last_point = points[points.length - 1].last_point;

        last_point.x += orig_first_pt.x;
        last_point.y += orig_first_pt.y;
        last_point = transform_point_around_item_origin (last_point, transform_matrix);

        return last_point;
    }
}

public struct Akira.Models.PathDataModel {
    public Geometry.PathSegment[] points;

    public Geometry.PathSegment live_segment;
    public Lib.Modes.PathEditMode.PointType live_point_type;

    public Geometry.Point last_point;

    public Geometry.Rectangle extents;
    public Geometry.Rectangle live_extents;

    public Geometry.Point center;

    public Cairo.Matrix transform;
    public Gee.HashSet<Geometry.SelectedPoint?> selected_pts;
}
