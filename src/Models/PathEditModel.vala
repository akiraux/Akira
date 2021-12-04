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

    private Lib.Modes.PathEditMode.Type[] commands;
    private Geometry.Point[] points;

    public Geometry.Point first_point;
    private Geometry.Point[] live_pts;
    private int live_pts_len = -1;

    public Gee.HashSet<int> selected_pts;
    public int reference_point;

    public bool tangents_inline = false;

    public PathEditModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        commands = instance.components.path.commands;
        points = instance.components.path.data;

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        // The selected_pts will contain the list of all points that we want to modify.
        selected_pts = new Gee.HashSet<int> ();

        update_view ();
    }

    public void add_live_points_to_path (Geometry.Point[] points, Lib.Modes.PathEditMode.Type live_command, int length) {
        commands.resize (commands.length + 1);
        commands[commands.length - 1] = live_command;

        for (int i = 0; i < length; ++i) {
            var new_pt = Geometry.Point (points[i].x - first_point.x, points[i].y - first_point.y);
            add_point_to_path (new_pt);
        }

        live_pts = new Geometry.Point[0];
        live_pts_len = 0;

        recompute_components ();
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private void add_point_to_path (Geometry.Point point, int index = -1) {
        // var old_path_points = instance.components.path.data;
        Geometry.Point[] new_path_points = new Geometry.Point[points.length + 1];

        index = (index == -1) ? index = points.length : index;

        for (int i = 0; i < index; ++i) {
            new_path_points[i] = points[i];
        }

        new_path_points[index] = point;

        for (int i = index + 1; i < points.length + 1; ++i) {
            new_path_points[i] = points[i - 1];
        }

        points = recalculate_points (new_path_points);
        bool close = instance.components.path.close;
        instance.components.path = new Lib.Components.Path.from_points (points, commands, close);
    }

    public void set_live_points (Geometry.Point[] live_pts, int length) {
        this.live_pts = live_pts;
        this.live_pts_len = length;

        update_view ();
    }

    public Geometry.Point[] delete_last_point () {
        bool close = instance.components.path.close;

        if (commands[commands.length - 1] == Lib.Modes.PathEditMode.Type.LINE) {
            commands.resize (commands.length - 1);
            points.resize (points.length - 1);

            points = recalculate_points (points);
            instance.components.path = new Lib.Components.Path.from_points (points, commands, close);
            recompute_components ();

            return new Geometry.Point[0];
        }

        var new_live_pts = new Geometry.Point[4];
        new_live_pts[2] = Geometry.Point (points[points.length - 2].x + first_point.x, points[points.length - 2].y + first_point.y);
        new_live_pts[1] = Geometry.Point (points[points.length - 3].x + first_point.x, points[points.length - 3].y + first_point.y);
        new_live_pts[0] = Geometry.Point (points[points.length - 4].x + first_point.x, points[points.length - 4].y + first_point.y);

        commands.resize (commands.length - 1);
        points.resize (points.length - 4);

        points = recalculate_points (points);
        instance.components.path = new Lib.Components.Path.from_points (points, commands, close);
        recompute_components ();

        return new_live_pts;
    }

    /*
     * This method is used to check if user clicked on a point in the path.
     * Returns true if clicked, false otherwise.
     * If a point was clicked, index refers to its location.
     */
    public Lib.Modes.PathEditMode.PointType hit_test (double x, double y, ref int[] index) {
        Geometry.Point point = Geometry.Point (x, y);
        tangents_inline = false;

        int j = 0;
        for (int i = 0; i < commands.length + 1; ++i) {
            if (commands[i] == Lib.Modes.PathEditMode.Type.LINE) {
                if (compare_points (points[j], point)) {
                    index[0] = j;

                    return Lib.Modes.PathEditMode.PointType.LINE_END;
                }

                ++j;
            } else {
                // We need to check if the middle point of tangent is selected.
                // If it is selected, then other two points of tangent must also
                // be selected to keep the curve intact.
                if (compare_points (points[j], point)) {
                    index[0] = j;
                    index[1] = j + 1;
                    index[2] = j + 2;

                    return Lib.Modes.PathEditMode.PointType.CURVE_BEGIN;
                }

                // If either of the tangent points is selected and moved,
                // then the other needs to be rotated too.
                if (compare_points (points[j + 1], point)) {
                    if (are_points_in_line (j + 1, j, j + 2)) {
                        index[0] = j + 1;
                        index[1] = j + 2;
                    } else {
                        index[0] = j + 1;
                    }

                    return Lib.Modes.PathEditMode.PointType.TANGENT_FIRST;
                }

                if (compare_points (points[j + 2], point)) {
                    if (are_points_in_line (j + 1, j, j + 2)) {
                        index[0] = j + 1;
                        index[1] = j + 2;
                    } else {
                        index[0] = j + 2;
                    }

                    return Lib.Modes.PathEditMode.PointType.TANGENT_SECOND;
                }

                if (compare_points (points[j + 3], point)) {
                    index[0] = j + 3;

                    return Lib.Modes.PathEditMode.PointType.CURVE_END;
                }
                j += 4;
            }
        }

        return Lib.Modes.PathEditMode.PointType.NONE;
    }

    /*
     * This method will be used when editing paths to update the position of a point.
     */
    public void modify_point_value (Geometry.Point new_pos) {
        new_pos.x -= first_point.x;
        new_pos.y -= first_point.y;

        if (selected_pts.size == 1) {
            // If only one point is selected, it will act as reference point.
            reference_point = selected_pts.to_array ()[0];
        }

        Geometry.Point original_ref = Geometry.Point (points[reference_point].x, points[reference_point].y);

        // Calculate by how much the reference point changed, then move other points by this amount.
        double delta_x = original_ref.x - new_pos.x;
        double delta_y = original_ref.y - new_pos.y;

        if (tangents_inline) {
            print("tangents inline\n");
            // If a tangent line was selected and they were inline,
            // they need to be moved in a special way.
            move_tangents_rel_to_curve (delta_x, delta_y);
        } else {
            foreach (var item in selected_pts) {
                points[item].x -= delta_x;
                points[item].y -= delta_y;
            }
        }

        points = recalculate_points (points);
        bool close = instance.components.path.close;
        instance.components.path = new Lib.Components.Path.from_points (points, commands, close);
        recompute_components ();
    }

    /*
     * This method is used to change the selected points.
     * idx is index of point to be added to selection. if -1, it is not added.
     * If append is true, add the item to the list, otherwise, clear the list then add.
     */
    public void set_selected_points (int idx, bool append = false) {
        if (!append) {
            selected_pts.clear ();
        }

        if (idx != -1) {
            selected_pts.add (idx);
        }

        update_view ();
    }

    /*
     * This method is used to join the first and last point of path
     * to make it a closed curve.
     */
    public void make_path_closed () {
        instance.components.path = new Lib.Components.Path.from_points (points, commands, true);
        recompute_components ();
    }

    public bool check_can_path_close () {
        int last = points.length - 1;

        double delta_x = (points[0].x - points[last].x).abs ();
        double delta_y = (points[0].y - points[last].y).abs ();

        if (delta_x <= 2 && delta_y <= 2) {
            make_path_closed ();
            return true;
        }

        return false;
    }

    private bool compare_points (Geometry.Point a, Geometry.Point b) {
        double thresh = 4 / view_canvas.scale;
        double delta_x = Math.ceil ((a.x + first_point.x - b.x).abs ());
        double delta_y = Math.ceil ((a.y + first_point.y - b.y).abs ());

        return (delta_x <= thresh && delta_y <= thresh);
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private Geometry.Point[] recalculate_points (Geometry.Point[] points) {
        double min_x = 100000, min_y = 100000;

        foreach (var pt in points) {
            if (pt.x < min_x) {
                min_x = pt.x;
            }
            if (pt.y < min_y) {
                min_y = pt.y;
            }
        }

        Geometry.Point[] recalculated_points = new Geometry.Point[points.length];

        // Shift all the points.
        for (int i = 0; i < points.length; ++i) {
            recalculated_points[i] = Geometry.Point (points[i].x - min_x, points[i].y - min_y);
        }

        // Then shift the reference point.
        first_point.x += min_x;
        first_point.y += min_y;

        return recalculated_points;
    }

    private void recompute_components () {
        // To calculate the new center of bounds of rectangle,
        // Move the center to point where user placed first point. This is represented as (0,0) internally.
        // Then translate it to the relative center of bounding box of path.
        var bounds = instance.components.path.calculate_extents ();
        double center_x = first_point.x + bounds.center_x;
        double center_y = first_point.y + bounds.center_y;

        instance.components.center = new Lib.Components.Coordinates (center_x, center_y);
        instance.components.size = new Lib.Components.Size (bounds.width, bounds.height, false);
        // Update the component.
        view_canvas.items_manager.item_model.mark_node_geometry_dirty_by_id (instance.id);
        view_canvas.items_manager.compile_model ();

        update_view ();
    }

    /*
     * Recalculates the extents and updates the ViewLayerPath
     */
    private void update_view () {
        var points = instance.components.path.data;

        var coordinates = view_canvas.selection_manager.selection.coordinates ();

        Geometry.Rectangle extents = Geometry.Rectangle.empty ();
        extents.left = coordinates.center_x - coordinates.width / 2.0;
        extents.right = coordinates.center_x + coordinates.width / 2.0;
        extents.top = coordinates.center_y - coordinates.height / 2.0;
        extents.bottom = coordinates.center_y + coordinates.height / 2.0;

        PathDataModel path_data = PathDataModel ();
        path_data.points = points;
        path_data.commands = commands;
        path_data.live_pts = live_pts;
        path_data.length = live_pts_len;
        path_data.extents = extents;
        path_data.rot_angle = instance.components.transform.rotation;
        path_data.selected_pts = selected_pts;

        path_data.live_extents = get_extents_using_live_pts (extents);

        path_layer.update_path_data (path_data);
    }

    private Geometry.Rectangle get_extents_using_live_pts (Geometry.Rectangle extents) {
        if (points.length == 0 || live_pts_len == -1) {
            return extents;
        }

        var data = new Geometry.Point[live_pts_len + 1];

        data[0] = Geometry.Point ();
        data[0].x = points[points.length - 1].x + first_point.x;
        data[0].y = points[points.length - 1].y + first_point.y;

        for (int i = 0; i < live_pts_len; ++i) {
            data[i + 1].x = live_pts[i].x;
            data[i + 1].y = live_pts[i].y;
        }

        // The array of commands isn't really needed for calculating extents. So just keep it empty.
        var cmds = new Lib.Modes.PathEditMode.Type[0];
        var live_path = new Lib.Components.Path.from_points (data, cmds);

        return live_path.calculate_extents ();
    }

    private bool are_points_in_line (int tangent_1_idx, int curve_begin_idx, int tangent_2_idx) {
        Geometry.Point first_tangent = points[tangent_1_idx];
        Geometry.Point second_tangent = points[tangent_2_idx];
        Geometry.Point curve_begin = points[curve_begin_idx];

        // Slope and intercept of line formed by tangents.
        double slope_tangents = (second_tangent.y - first_tangent.y) / (second_tangent.x - first_tangent.x);
        double intercept = first_tangent.y - slope_tangents * first_tangent.x;

        // Check if the curve_begin point lies on this tangent.
        if (curve_begin.y == (slope_tangents * curve_begin.x + intercept)) {
            tangents_inline = true;
            return true;
        }

        tangents_inline = false;
        return false;
    }

    private void move_tangents_rel_to_curve (double delta_x, double delta_y) {
        points[reference_point].x -= delta_x;
        points[reference_point].y -= delta_y;

        var sel_pts_array = selected_pts.to_array ();
        int other_tangent = (sel_pts_array[0] == reference_point) ? sel_pts_array[1] : sel_pts_array[0];
        points[other_tangent].x += delta_x;
        points[other_tangent].y += delta_y;
        
    }
}

public struct Akira.Models.PathDataModel {
    public Geometry.Point[] points;
    public Lib.Modes.PathEditMode.Type[] commands;

    public Geometry.Point[] live_pts;
    public int length;

    public Geometry.Rectangle extents;
    public Geometry.Rectangle live_extents;

    public double rot_angle;
    public Gee.HashSet<int> selected_pts;
}
