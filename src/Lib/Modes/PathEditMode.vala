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
    public bool is_insert { get; construct; }
    // keep track of previous point for calculating relative positions of points
    private Geometry.Point first_point;
    private ViewLayers.ViewLayerPath path_layer;


    public PathEditMode (Lib.ViewCanvas canvas, bool is_insert, Lib.Items.ModelInstance instance) {
        Object(
            view_canvas: canvas,
            is_insert: is_insert,
            instance: instance
        );

        first_point = Geometry.Point(-1, -1);

        // layer to show when editing paths
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
        print("begin mode\n");
        // hide the nobs and show the path layer
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.NOBS_LAYER_ID, false);
        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.PATH_LAYER_ID, true);
    }

    public override void mode_end () {
        // hide the path layer and show nobs
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
        // everytime the user presses the mouse button, a new point needs to be created and added to the path.
        Akira.Geometry.Point point = Akira.Geometry.Point (event.x, event.y);

        if (first_point.x == -1) {
            first_point = point;
            var coords = view_canvas.selection_manager.selection.coordinates();
            path_layer.set_reference_point ( Geometry.Point (coords.center_x, coords.center_y));
            return false;
        }

        // this calculates the position of the new point relative to the first point.
        point.x -= first_point.x;
        point.y -= first_point.y;

        // add the new points to the drawable and path
        instance.components.path.add_point (point, -1);

        // To calculate the new center of bounds of rectangle,
        // move the center to point where user placed first point. This is represented as (0,0) internally
        // then translate it to the relative center of bounding box of path.
        var bounds = instance.components.path.calculate_extents ();
        double center_x = first_point.x + bounds.center_x;
        double center_y = first_point.y + bounds.center_y;

        instance.components.center = new Lib.Components.Coordinates (center_x, center_y);
        instance.components.size = new Lib.Components.Size (bounds.width, bounds.height, false);

        // update the component
        view_canvas.items_manager.item_model.mark_node_geometry_dirty (view_canvas.items_manager.node_from_id (instance.id));
        view_canvas.items_manager.compile_model ();

        path_layer.update_path_data (instance.components.path.data);

        return true;
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
