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
    public const string LINE = "LINE";
    public const string CURVE = "CURVE";

    public Lib.Items.ModelInstance instance { get; construct; }
    public weak Lib.ViewCanvas view_canvas { get; construct; }

    private ViewLayers.ViewLayerPath path_layer;

    private Geometry.Point[] points;
    private string[] commands;
    // Points in the current command. Mostly used for curves.
    private Geometry.Point[] curr_command_points;

    public Geometry.Point first_point;

    public PathEditModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);
        points = new Geometry.Point[1];
        points[0] = Geometry.Point (0, 0);

        commands = new string[1];
        commands[0] = LINE;

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        update_view ();
    }

    public void add_point (Geometry.Point point) {
        point.x -= first_point.x;
        point.y -= first_point.y;

        set_command (LINE);
        add_point_to_path (point);

        recompute_components ();
    }

    public bool last_command_done () {
        // When we create a line, we immediately add the
        if (commands[commands.length - 1] == LINE) {
            return true;
        }
        return false;
    }

    /*
     * Sets values of command at given index. If index is -1, appends a new command.
     */
    private void set_command (string command, int index = -1) {
        if (index == -1) {
            commands.resize (commands.length + 1);
            commands[commands.length - 1] = command;
        } else {
            commands[index] = command;
        }
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private void add_point_to_path (Geometry.Point point, int index = -1) {
        var old_path_points = instance.components.path.data;
        Geometry.Point[] new_path_points = new Geometry.Point[old_path_points.length + 1];

        index = (index == -1) ? index = old_path_points.length : index;

        for (int i = 0; i < index; ++i) {
            new_path_points[i] = old_path_points[i];
        }

        new_path_points[index] = point;

        for (int i = index + 1; i < old_path_points.length + 1; ++i) {
            new_path_points[i] = old_path_points[i - 1];
        }

        var recalculated_points = recalculate_points (new_path_points);

        instance.components.path = new Lib.Components.Path.from_points (recalculated_points, commands);
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
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

        path_layer.update_path_data (points, extents);
    }

}
