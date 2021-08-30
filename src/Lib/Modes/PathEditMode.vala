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

public class Akira.Lib.Modes.PathEditMode : AbstractInteractionMode {

    public weak Lib.ViewCanvas view_canvas { get; construct; }
    public Lib.Items.ModelInstance instance { get; construct; }
    // Keep track of previous point for calculating relative positions of points.
    private Geometry.Point first_point;
    private ViewLayers.ViewLayerPath path_layer;


    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);
    }

    public override AbstractInteractionMode.ModeType mode_type () {
        return AbstractInteractionMode.ModeType.PATH_EDIT;
    }

    public override Utils.Nobs.Nob active_nob () {
        return Utils.Nobs.Nob.NONE;
    }

    public override void mode_begin () {
        // Hide the nobs and show the path layer.
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.NOBS_LAYER_ID, false);
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.PATH_LAYER_ID, true);
    }

    public override void mode_end () {
        // Hide the path layer and show nobs.
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.NOBS_LAYER_ID, true);
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.PATH_LAYER_ID, false);
    }

    public override Gdk.CursorType? cursor_type () {
        return Gdk.CursorType.CROSSHAIR;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        // Everytime the user presses the mouse button, a new point needs to be created and added to the path.
        Akira.Geometry.Point point = Akira.Geometry.Point (event.x, event.y);

        if (first_point.x == -1) {
            first_point = point;
            update_view ();
            return false;
        }

        // This calculates the position of the new point relative to the first point.
        point.x -= first_point.x;
        point.y -= first_point.y;

        // Add the new points to the drawable and path
        add_point_to_path (point);

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

        return true;
    }

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

        instance.components.path = new Lib.Components.Path.from_points (recalculated_points);
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

    public override bool button_release_event (Gdk.EventButton event) {
        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        return false;
    }

    public override Object? extra_context () {
        return null;
    }
}
