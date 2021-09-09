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
    public const string LINE = "LINE";
    public const string CURVE = "CURVE";

    public weak Lib.ViewCanvas view_canvas { get; construct; }
    public Lib.Items.ModelInstance instance { get; construct; }
    private Models.PathEditModel edit_model;

    // Flag to track click and drag events.
    private bool is_click = false;

    // The points in live command will be drawn every time user moves cursor.
    // Also acts as buffer fro curves.
    public string live_command;
    public Geometry.Point[] live_points;
    public int live_idx;

    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );
        edit_model = new Models.PathEditModel (instance, view_canvas);
        live_points = new Geometry.Point[3];
        live_command = "LINE";
        live_idx = -1;
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

        if (edit_model.first_point.x == -1) {
            edit_model.first_point = Geometry.Point (event.x, event.y);
            return true;
        }

        Akira.Geometry.Point point = Akira.Geometry.Point (event.x, event.y);

        if (live_command == LINE) {
            is_click = true;
            live_points[0] = point;
            live_idx = 0;
        } else {
            live_idx = 2;
            live_points[2] = point;
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (is_curr_command_done ()) {
            edit_model.add_live_points_to_path (live_points, live_command, live_idx + 1);

            live_idx = 0;
            live_command = LINE;
            is_click = false;
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (is_click) {
            live_command = CURVE;
            live_idx = 1;
            live_points[1] = Geometry.Point (event.x, event.y);

            return true;
        }
        return false;
    }

    public override Object? extra_context () {
        return null;
    }

    private bool is_curr_command_done () {
        if (live_command == LINE && live_idx != -1) {
            return true;
        }

        if (live_command == CURVE && live_idx == 2) {
            return true;
        }

        return false;
    }
}

/*
in PathEditModel, create live_command, live_command_point.

when the user clicks, add the current point to curve_points. mark is_click as true.

In motion, if is_click == true, then click and drag. mark is_click_drag as true. Add first point of click and drag to curve_points.

In release, if is_click_drag == true, then this is second point of curve. add to curve_points
else, it is line. add
================================================================================================
When inserting a path, the first point will already be there from the previous path.
When the user clicks and drags, the point where they click will be the second point.
When dragging, the line joining the point where user clicked and where they released will be tangent.
The last point where they click will be the final point.
*/
