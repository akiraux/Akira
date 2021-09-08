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
    private Models.PathEditModel edit_model;

    // Flag to track click and drag events.
    private bool is_click = false;
    private bool is_click_drag = false;

    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );
        edit_model = new Models.PathEditModel (instance, view_canvas);
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

        if (edit_model.first_point.x == -1) {
            edit_model.first_point = point;
            return false;
        }

        // // Add this point to the edit model.
        // edit_model.set_command (Models.PathEditModel.LINE);
        // edit_model.add_point (point);
        //
        // if (edit_model.last_command_done ()) {
        //
        // }

        if (edit_model.live_command == Models.PathEditModel.LINE) {
            is_click = true;
            edit_model.set_live_point (point);
        } else {
            edit_model.live_idx = 2;
            edit_model.set_live_point (point);
        }

        // ++edit_model.live_idx;

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (edit_model.is_live_command_done ()) {
            edit_model.add_live_points_to_path ();
            edit_model.live_command = Models.PathEditModel.LINE;
            is_click = false;
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (is_click) {
            edit_model.live_command = Models.PathEditModel.CURVE;
            edit_model.live_idx = 1;
            edit_model.set_live_point (Geometry.Point (event.x, event.y));

            return true;
        }
        return false;
    }

    public override Object? extra_context () {
        return null;
    }
}

/*
in PathEditModel, create live_command, live_command_point.

when the user clicks, add the current point to curve_points. mark is_click as true.

In motion, if is_click == true, then click and drag. mark is_click_drag as true. Add first point of click and drag to curve_points.

In release, if is_click_drag == true, then this is second point of curve. add to curve_points
else, it is line. add


===========================================================================================
when user clicks, then check if all points of last command were done.
    If done, then create line command and put the point in it. Mark is_click as true.
    Else, just add the current point.

In motion, if is_click == true, then there is drag. So mark the last inserted command as CURVE.
Mark a flag is_click_drag = true to show that there was click and drag.

In release, if is_click_drag == true, it means that the first point of curve was just entered. Take coordinates of release event and put in path.
Mark flags is_click = false, is_click_drag = false



When inserting a path, the first point will already be there from the previous path.
When the user clicks and drags, the point where they click will be the second point.
When dragging, the line joining the point where user clicked and where they released will be tangent.
The last point where they click will be the final point.
*/
