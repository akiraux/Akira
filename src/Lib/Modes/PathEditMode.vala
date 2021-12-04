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
    public enum Type {
        LINE,
        CURVE
    }

    // We are using this to check what kind of point was selected.
    public enum PointType {
        // This means no point was selected.
        NONE,
        // This point signifies a simple line end.
        LINE_END,
        // This is the first point you draw in a curve.
        CURVE_BEGIN,
        // This denotes one end of the tangent.
        TANGENT_FIRST,
        // This is the other end of the tangent.
        TANGENT_SECOND,
        // This is the last point of the curve.
        CURVE_END
    }

    public weak Lib.ViewCanvas view_canvas { get; construct; }
    public Lib.Items.ModelInstance instance { get; construct; }
    private Models.PathEditModel edit_model;

    // Flag to track click and drag events.
    private bool is_click = false;

    // The points in live command will be drawn every time user moves cursor.
    // Also acts as buffer for curves.
    private Type live_command;
    private Geometry.Point[] live_points;
    private int live_idx;

    // This flag tells if we are adding a path or editing an existing one.
    private bool is_edit_path = false;

    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );
        edit_model = new Models.PathEditModel (instance, view_canvas);
        live_points = new Geometry.Point[4];
        live_command = Type.LINE;
        live_idx = -1;
    }

    public void toggle_functionality (bool is_edit_path) {
        this.is_edit_path = is_edit_path;

        // If we are editing the path, we need to set the first point in edit_model
        if (is_edit_path) {
            double center_x = instance.components.center.x;
            double center_y = instance.components.center.y;
            double width = instance.components.size.width;
            double height = instance.components.size.height;

            var first_point = Geometry.Point (center_x - width / 2.0, center_y - height / 2.0);

            edit_model.first_point = first_point;
        }
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
        if (is_edit_path) {
            // When editing path, we dont know yet what point will be selected.
            // So don't delete points, but mark this event as handled.
            return true;
        }

        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        if (uppercase_keyval == Gdk.Key.BackSpace) {
            handle_backspace_event ();
            return true;
        } else if (uppercase_keyval == Gdk.Key.Z) {
            edit_model.make_path_closed ();

            // We are triggering the escape signal because after joining the path,
            // no more points can be added. So this mode must end.
            view_canvas.window.event_bus.request_escape ();
            return true;
        }

        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        // If button is clicked in edit mode, check if some point was clicked.
        if (is_edit_path) {
            int[] index = new int[3];
            index[0] = index[1] = index[2] = -1;

            var sel_type = edit_model.hit_test (event.x, event.y, ref index);

            bool is_shift = (event.state == Gdk.ModifierType.SHIFT_MASK);
            bool is_alt = (event.state == Gdk.ModifierType.MOD1_MASK);

            // If no point was selected, then just get out. Don't do anything.
            if (sel_type == PointType.NONE) {
                edit_model.set_selected_points (-1);
                return false;
            }

            if (sel_type == PointType.LINE_END ||
                sel_type == PointType.CURVE_BEGIN ||
                sel_type == PointType.CURVE_END
            ) {
                // If the selected point already exists, then set it as the reference point.
                if (edit_model.selected_pts.contains (index[0])) {
                    edit_model.reference_point = index[0];
                    is_click = true;
                    return true;
                }

                // If shift was clicked, then append the points to selection
                if (is_shift) {
                    for (int i = 0; i < 3; ++i) {
                        if (index[i] != -1) {
                            edit_model.set_selected_points (index[i], true);
                        }
                    }
                } else {
                    // If shift was not used, the clear the selection, then append the points to selection.
                    // This is because, with CURVE_BEGIN, we are also adding TANGENT_FIRST and TANGENT_SECOND
                    edit_model.selected_pts.clear ();

                    for (int i = 0; i < 3; ++i) {
                        if (index[i] != -1) {
                            edit_model.set_selected_points (index[i], true);
                        }
                    }

                    edit_model.reference_point = index[0];
                }
            }

            // Tangents behave in a different way. So we are placing the logic for that seperately.
            if (sel_type == PointType.TANGENT_FIRST || sel_type == PointType.TANGENT_SECOND) {
                // If alt was not clicked and the selected tangent already exists in the selection,
                // It means we want to use this point as reference when moving.
                if (!is_alt) {
                    if (sel_type == PointType.TANGENT_FIRST && edit_model.selected_pts.contains (index[0])) {
                        edit_model.reference_point = index[0];
                        is_click = true;
                        return true;
                    } else if (sel_type == PointType.TANGENT_SECOND && edit_model.selected_pts.contains (index[1])) {
                        edit_model.reference_point = index[1];
                        is_click = true;
                        return true;
                    }
                }

                // When shift is clicked, we add all the selected points to the selection.
                // But for tangent, the selected points will also contain the other tangent.
                // So add only the selected tangent to the selection.
                if (is_shift) {
                    if (sel_type == PointType.TANGENT_FIRST) {
                        edit_model.set_selected_points (index[0], true);
                    } else {
                        edit_model.set_selected_points (index[1], true);
                    }
                } else if (is_alt) {
                    // When alt is pressed, we want to move the only the selected tangent
                    // and other one should stay put. So clear the selection and add only selected tangent.
                    if (sel_type == PointType.TANGENT_FIRST) {
                        edit_model.set_selected_points (index[0], false);
                        edit_model.reference_point = index[0];
                    } else {
                        edit_model.set_selected_points (index[1], false);
                        edit_model.reference_point = index[1];
                    }

                    edit_model.tangents_inline = false;
                } else {
                    // If no modifier was used, move the tangents in the reflected way.
                    // This means we move the selected tangent with the mouse, but move the other tangent
                    // in the opposite direction. see PathEditModel.move_tangents_rel_to_curve
                    // If there are any other points in the selection, remove them first.
                    edit_model.selected_pts.clear ();

                    edit_model.set_selected_points (index[0], true);
                    edit_model.set_selected_points (index[1], true);

                    if (sel_type == PointType.TANGENT_FIRST) {
                        edit_model.reference_point = index[0];
                    } else {
                        edit_model.reference_point = index[1];
                    }
                }
            }

            is_click = true;

            return true;
        }

        // If we are not in edit mode (we are creating the path), then
        // everytime the user presses the mouse button, a new point needs to be created and added to the path.
        if (edit_model.first_point.x == -1) {
            edit_model.first_point = Geometry.Point (event.x, event.y);
            return true;
        }

        Akira.Geometry.Point point = Akira.Geometry.Point (event.x, event.y);

        if (live_command == Type.LINE) {
            // Check if we are clicking on the first point. If yes, then close the path.
            int[] index = new int[3];
            edit_model.hit_test (event.x, event.y, ref index);

            if (index[0] == 0) {
                edit_model.make_path_closed ();
                // We are triggering the escape signal because after joining the path,
                // no more points can be added. So this mode must end.
                view_canvas.window.event_bus.request_escape ();
                return true;
            }

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
        if (is_edit_path) {
            edit_model.tangents_inline = false;

            // If the user modified the last point and placed on top of first point,
            // make the path closed.
            if (edit_model.check_can_path_close ()) {
                view_canvas.window.event_bus.request_escape ();
                return true;
            }
        }

        if (is_curr_command_done ()) {
            edit_model.add_live_points_to_path (live_points, live_command, live_idx + 1);

            live_idx = 0;
            live_command = Type.LINE;
        }

        is_click = false;

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        Geometry.Point point = Geometry.Point (event.x, event.y);

        if (is_edit_path) {
            if (!edit_model.selected_pts.is_empty && is_click) {
                // If user selected a point and clicked and dragged it, change its position.
                edit_model.modify_point_value (point);
            }
            return true;
        }

        // If there is click and drag, then this is the second point of curve.
        if (is_click) {
            live_command = Type.CURVE;
            live_idx = 2;

            // Points at index 1 and 2 are the two tangents required by the 2 curves.
            live_points[1] = reflection (point, live_points[0]);
            live_points[2] = point;

            edit_model.set_live_points (live_points, 3);
        } else {
            // If we are hovering in CURVE mode, current position could be our third curve point.
            if (live_command == Type.CURVE) {
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
        if (live_command == Type.LINE && live_idx != -1) {
            return true;
        }

        if (live_command == Type.CURVE && live_idx == 3) {
            return true;
        }

        return false;
    }

    private Geometry.Point reflection (Geometry.Point pt1, Geometry.Point pt2) {
        var x = pt2.x + (pt2.x - pt1.x);
        var y = pt2.y + (pt2.y - pt1.y);

        return Geometry.Point (x, y);
    }

    private void handle_backspace_event () {
        if (live_idx > 0) {
            --live_idx;

            // Note that for curve, there are 2 tangent points that depend on each other.
            // If one of them gets deleted, delete the other too. This leaves only 1 live point.
            // So the live command becomes LINE.
            if (live_idx == 1 && live_command == CURVE) {
                live_command = Type.LINE;
                live_idx = 0;
            }

            edit_model.set_live_points (live_points, live_idx + 1);
        } else {
            var possible_live_pts = edit_model.delete_last_point ();

            if (possible_live_pts == null || possible_live_pts.length == 0) {
                live_idx = -1;
                live_command = Type.LINE;
            } else {
                live_points[0] = possible_live_pts[0];
                live_points[1] = possible_live_pts[1];
                live_points[2] = possible_live_pts[2];

                live_idx = 2;
                live_command = Type.CURVE;
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
    }
}
