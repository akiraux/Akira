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
        NONE,
        LINE,
        QUADRATIC,
        CUBIC
    }

    // We are using this to check what kind of point was selected.
    public enum PointType {
        // This means no point was selected.
        NONE=-1,
        // This point signifies a simple line end.
        LINE_END=0,
        // This is the first point you draw in a curve.
        CURVE_BEGIN=1,
        // This denotes one end of the tangent.
        TANGENT_FIRST=2,
        // This is the other end of the tangent.
        TANGENT_SECOND=3,
        // This is the last point of the curve.
        CURVE_END=4
    }

    public weak Lib.ViewCanvas view_canvas { get; construct; }
    public Lib.Items.ModelInstance instance { get; construct; }
    private Models.PathEditModel edit_model;

    // Flag to track click and drag events.
    private bool is_click = false;

    // The points in live command will be drawn every time user moves cursor.
    // Also acts as buffer for curves.
    //  private Type live_command;
    //  private Geometry.Point[] live_points;
    //  private int live_idx;
    private Utils.PathSegment live_segment;
    private PointType live_pnt_type;

    // This flag tells if we are adding a path or editing an existing one.
    // Basically decides is we are in "edit" mode or "append" mode.
    private enum Submode {
        APPEND,
        EDIT
    }

    private Submode mode;

    private const int MIN_TANGENT_ALLOWED_LENGTH = 5;

    public PathEditMode (Lib.ViewCanvas canvas, Lib.Items.ModelInstance instance) {
        Object (
            view_canvas: canvas,
            instance: instance
        );
        edit_model = new Models.PathEditModel (instance, view_canvas);
        live_segment = Utils.PathSegment ();
        live_pnt_type = PointType.NONE;
        mode = Submode.APPEND;
    }

    public void toggle_functionality (bool is_append_path) {
        mode = is_append_path ? Submode.APPEND : Submode.EDIT;

        // If we are editing the path, we need to set the first point in edit_model
        if (mode == Submode.EDIT) {
            double width = instance.compiled_geometry.source_width;
            double height = instance.compiled_geometry.source_height;

            var first_point = Geometry.Point (-width / 2.0, -height / 2.0);
            var tr = instance.drawable.transform;
            tr.transform_point (ref first_point.x, ref first_point.y);

            edit_model.set_first_point (first_point);
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
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        if (mode == Submode.EDIT) {
            if (uppercase_keyval == Gdk.Key.C) {
                // If C is pressed in edit_mode, we enter back to append mode.
                mode = Submode.APPEND;
                return true;
            }

            return false;
        }

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
        if (mode == Submode.EDIT) {
            return handle_button_press_in_edit_mode (event);
        }

        handle_button_press_in_append_mode (event);
        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (mode == Submode.EDIT) {
            edit_model.tangents_inline = false;

            // If the user modified the last point and placed on top of first point,
            // make the path closed.
            if (edit_model.check_can_path_close ()) {
                view_canvas.window.event_bus.request_escape ();
                return true;
            }
        }

        if (is_curr_command_done ()) {
            edit_model.add_live_points_to_path (live_segment);
            live_segment = Utils.PathSegment ();
            live_pnt_type = PointType.NONE;
        }

        is_click = false;

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        Geometry.Point point = Geometry.Point (event.x, event.y);

        if (mode == Submode.EDIT) {
            if (!edit_model.selected_pts.is_empty && is_click) {
                // If user selected a point and clicked and dragged it, change its position.
                edit_model.modify_point_value (point);
            }
            return true;
        }

        // If there is click and drag, then this is the second point of curve.
        if (is_click) {
            live_segment.type = Type.CUBIC;

            if (Utils.GeometryMath.compare_points (point, live_segment.curve_begin, MIN_TANGENT_ALLOWED_LENGTH)) {
                // Prevent user from drawing really small curves due to mouse glitches.
                live_segment.type = Type.LINE;
                live_pnt_type = PointType.LINE_END;
            } else {
                // Points at index 1 and 2 are the two tangents required by the 2 curves.
                live_segment.tangent_1 = reflection (point, live_segment.curve_begin);
                live_segment.tangent_2 = point;
                live_pnt_type = PointType.TANGENT_SECOND;
            }


        } else {
            // If we are hovering in CURVE mode, current position could be our third curve point.
            if (live_segment.type == Type.CUBIC) {
                live_segment.curve_end = point;
                live_pnt_type = PointType.CURVE_END;
            } else {
                // If we are hovering in LINE mode, this could be a potential line point.
                live_segment.line_end = point;
                live_segment.type = Type.LINE;
                live_pnt_type = PointType.LINE_END;
            }
        }

        edit_model.set_live_points (live_segment, live_pnt_type);

        return true;
    }

    public override Object? extra_context () {
        return null;
    }

    private bool is_curr_command_done () {
        if (live_segment.type == Type.NONE) {
            return false;
        }

        if (live_segment.type == Type.LINE && live_pnt_type != PointType.LINE_END) {
            return false;
        }

        if (live_segment.type == Type.CUBIC && live_pnt_type != PointType.CURVE_END) {
            return false;
        }

        return true;
    }

    private Geometry.Point reflection (Geometry.Point pt1, Geometry.Point pt2) {
        var x = pt2.x + (pt2.x - pt1.x);
        var y = pt2.y + (pt2.y - pt1.y);

        return Geometry.Point (x, y);
    }

    private void handle_backspace_event () {
        //  if (live_idx > 0) {
        //      --live_idx;

        //      // Note that for curve, there are 2 tangent points that depend on each other.
        //      // If one of them gets deleted, delete the other too. This leaves only 1 live point.
        //      // So the live command becomes LINE.
        //      if (live_idx == 1 && live_segment.type == CUBIC) {
        //          live_segment.type = Type.LINE;
        //          live_idx = 0;
        //      }

        //      edit_model.set_live_points (live_points, live_idx + 1);
        //  } else {
        //      var possible_live_pts = edit_model.delete_last_point ();

        //      if (possible_live_pts == null || possible_live_pts.length == 0) {
        //          live_idx = -1;
        //          live_command = Type.LINE;
        //      } else {
        //          live_points[0] = possible_live_pts[0];
        //          live_points[1] = possible_live_pts[1];
        //          live_points[2] = possible_live_pts[2];

        //          live_idx = 2;
        //          live_command = Type.CUBIC;
        //          edit_model.set_live_points (live_points, 3);
        //      }
        //  }

        //  if (instance.components.path.data.length == 0) {
        //      // Sometimes the line from live effect rendered in ViewLayerPath remains even after
        //      // all points have been deleted. Erase this line.
        //      var update_extents = Geometry.Rectangle ();
        //      update_extents.left = instance.components.center.x;
        //      update_extents.top = instance.components.center.y;
        //      update_extents.right = live_points[0].x;
        //      update_extents.bottom = live_points[0].y;

        //      view_canvas.request_redraw (update_extents);

        //      // If there are no points in the path, no point to stay in PathEditMode.
        //      view_canvas.window.event_bus.delete_selected_items ();
        //      view_canvas.mode_manager.deregister_active_mode ();
        //  }
    }

    private bool handle_button_press_in_edit_mode (Gdk.EventButton event) {
        is_click = true;

        var sel_point = Utils.SelectedPoint ();
        bool is_selected = edit_model.hit_test (event.x, event.y, ref sel_point);

        bool is_shift = (event.state == Gdk.ModifierType.SHIFT_MASK);
        bool is_alt = (event.state == Gdk.ModifierType.MOD1_MASK);

        if (!is_selected) {
            return false;
        }

        // If this point has already been selected before, make it the reference.
        foreach (var segment in edit_model.selected_pts) {
            if (segment.sel_index == sel_point.sel_index && segment.sel_type == sel_point.sel_type) {
                edit_model.reference_point = sel_point;
                return true;
            }
        }

        if (is_shift) {
            if (sel_point.sel_type != PointType.TANGENT_FIRST && sel_point.sel_type != PointType.TANGENT_SECOND) {
                edit_model.set_selected_points (sel_point, true);
                return true;
            }
        } else if (is_alt) {
            if (sel_point.sel_type == PointType.TANGENT_FIRST || sel_point.sel_type == PointType.TANGENT_SECOND) {
                sel_point.tangents_staggered = true;
                edit_model.set_selected_points (sel_point, false);
                return true;
            }
        } else {
            edit_model.set_selected_points (sel_point, false);
            return true;
        }

        return false;
    }

    private void handle_button_press_in_append_mode (Gdk.EventButton event) {
        // If we are not in edit mode (we are creating the path), then
        // everytime the user presses the mouse button, a new point needs to be created and added to the path.
        if (edit_model.first_point.x == -1) {
            edit_model.set_first_point (Geometry.Point (event.x, event.y));
            return;
        }

        Geometry.Point point = Geometry.Point (event.x, event.y);

        // If this is the first point we are adding, make it a line.
        if (live_segment.type == Type.LINE) {
            // Check if we are clicking on the first point. If yes, then close the path.
            var sel_point = Utils.SelectedPoint ();
            if (edit_model.hit_test (event.x, event.y, ref sel_point, 0)) {
                edit_model.make_path_closed ();
                // We are triggering the escape signal because after joining the path,
                // no more points can be added. So this mode must end.
                view_canvas.window.event_bus.request_escape ();
                return;
            }

            is_click = true;
            live_segment = Utils.PathSegment.line (point);
            live_pnt_type = PointType.LINE_END;
        } else {
            live_segment.curve_end = point;
            live_pnt_type = PointType.CURVE_END;
        }

        edit_model.set_live_points (live_segment, live_pnt_type);
    }
}
