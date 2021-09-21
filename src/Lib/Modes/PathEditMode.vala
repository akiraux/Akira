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
    // Also acts as buffer for curves.
    private string live_command;
    private Geometry.Point[] live_points;
    private int live_idx;

    // This flag tells if we are adding a path or editing an existing one.
    private bool is_edit_path = true;

    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );
        edit_model = new Models.PathEditModel (instance, view_canvas);
        live_points = new Geometry.Point[4];
        live_command = LINE;
        live_idx = -1;
    }

    public void toggle_functionality (bool is_edit_path) {
        this.is_edit_path = is_edit_path;
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
        if (!is_edit_path) {
            // When editing path, we dont know yet what point will be selected.
            // So don't delete points, but mark this event as handled.
            return true;
        }

        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        if (uppercase_keyval == Gdk.Key.BackSpace) {
            if (live_idx > 0) {
                --live_idx;

                // Note that for curve, there are 2 tangent points that depend on each other.
                // If one of them gets deleted, delete the other too. This leaves only 1 live point.
                // So the live command becomes LINE.
                if (live_idx == 1 && live_command == CURVE) {
                    live_command = LINE;
                    live_idx = 0;
                }

                edit_model.set_live_points (live_points, live_idx + 1);
            } else {
                var possible_live_pts = edit_model.delete_last_point ();

                if (possible_live_pts == null || possible_live_pts.length == 0) {
                    live_idx = -1;
                    live_command = LINE;
                } else {
                    live_points[0] = possible_live_pts[0];
                    live_points[1] = possible_live_pts[1];
                    live_points[2] = possible_live_pts[2];

                    live_idx = 2;
                    live_command = CURVE;
                    edit_model.set_live_points (live_points, 3);
                }
            }

            if (instance.components.path.data.length == 0) {
                // Sometimes the line from live effect rendered in ViewLayerPath remains even after
                // all points have been deleted. Erase this line.
                var update_extents = Geometry.Rectangle ();
                update_extents.left = instance.components.center.x;
                update_extents.top = instance.components.center.y;
                update_extents.right = live_points[0].x;
                update_extents.bottom = live_points[0].y;

                view_canvas.request_redraw (update_extents);

                // If there are no points in the path, no point to stay in PathEditMode.
                view_canvas.window.event_bus.delete_selected_items ();
                view_canvas.mode_manager.deregister_active_mode ();
            }

            return true;
        }
        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (!is_edit_path) {
            return true;
        }

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
            live_idx = 3;
            live_points[3] = point;
        }

        edit_model.set_live_points (live_points, live_idx + 1);

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!is_edit_path) {
            return true;
        }

        if (is_curr_command_done ()) {
            edit_model.add_live_points_to_path (live_points, live_command, live_idx + 1);

            live_idx = 0;
            live_command = LINE;
        }

        is_click = false;

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        Geometry.Point point = Geometry.Point (event.x, event.y);

        if (!is_edit_path) {
            return true;
        }

        // If there is click and drag, then this is the second point of curve.
        if (is_click) {
            live_command = CURVE;
            live_idx = 2;

            // Points at index 1 and 2 are the two tangents required by the 2 curves.
            live_points[1] = reflection (point, live_points[0]);
            live_points[2] = point;

            edit_model.set_live_points (live_points, 3);
        } else {
            // If we are hovering in CURVE mode, current position could be our third curve point.
            if (live_command == CURVE) {
                live_points[3] = point;
                live_idx = 3;
                edit_model.set_live_points (live_points, 4);
            } else {
                // If we are hovering in LINE mode, this could be a potential line point.
                live_points[0] = point;
                edit_model.set_live_points (live_points, 1);
            }
        }

        return true;
    }

    public override Object? extra_context () {
        return null;
    }

    private bool is_curr_command_done () {
        if (live_command == LINE && live_idx != -1) {
            return true;
        }

        if (live_command == CURVE && live_idx == 3) {
            return true;
        }

        return false;
    }

    private Geometry.Point reflection (Geometry.Point pt1, Geometry.Point pt2) {
        var x = pt2.x + (pt2.x - pt1.x);
        var y = pt2.y + (pt2.y - pt1.y);

        return Geometry.Point (x, y);
    }
}
