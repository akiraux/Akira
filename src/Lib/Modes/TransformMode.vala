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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

/*
 * TransformMode handles mouse-activated transformations. Static methods can
 * be used to apply the underlying code on top of other modes that may need to
 * use the functionality.
 */
public class Akira.Lib.Modes.TransformMode : AbstractInteractionMode {
    private const double ROTATION_FIXED_STEP = 15.0;

    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public Utils.Nobs.Nob nob = Utils.Nobs.Nob.NONE;

    // Keeps track of the currently used nob to quickly change selection when
    // an item is scaled below its sizing, causing a "flip" in the transformation.
    public Utils.Nobs.Nob effective_nob = Utils.Nobs.Nob.NONE;

    public class DragItemData : Object {
        public Lib.Components.CompiledGeometry item_geometry;
    }

    public class InitialDragState : Object {
        public double press_x;
        public double press_y;

        // initial_selection_data
        public Geometry.Quad area;

        public Gee.HashMap<int, DragItemData> item_data_map;

        construct {
            item_data_map = new Gee.HashMap<int, DragItemData> ();
        }
    }

    // Simply defines whether the drag threshold was met to start transforming the object

    public class TransformExtraContext : Object {
        public Lib.Managers.SnapManager.SnapGuideData snap_guide_data;
    }

    private Lib.Items.NodeSelection selection;
    private InitialDragState initial_drag_state;
    public TransformExtraContext transform_extra_context;


    public TransformMode (Akira.Lib.ViewCanvas canvas, Utils.Nobs.Nob selected_nob) {
        Object (view_canvas: canvas);
        // Set the effective_nob when the transform mode is first initialized in
        // order to get the correct first clicked nob to show when scaling.
        nob = effective_nob = selected_nob;
        initial_drag_state = new InitialDragState ();
    }

    construct {
        transform_extra_context = new TransformExtraContext ();
        transform_extra_context.snap_guide_data = new Lib.Managers.SnapManager.SnapGuideData ();
    }

    public override void mode_begin () {
        if (view_canvas.selection_manager.selection.is_empty ()) {
            request_deregistration (mode_type ());
            return;
        }

        view_canvas.toggle_layer_visibility (ViewLayers.ViewLayer.NOBS_LAYER_ID, true);
        selection = view_canvas.selection_manager.selection;
        initial_drag_state.area = selection.coordinates ();

        foreach (var node in selection.nodes.values) {
            collect_geometries (node.node, ref initial_drag_state);
        }
    }

    private static void collect_geometries (Lib.Items.ModelNode subtree, ref InitialDragState state) {
        if (state.item_data_map.has_key (subtree.id)) {
            return;
        }

        var data = new DragItemData ();
        data.item_geometry = subtree.instance.compiled_geometry.copy ();
        state.item_data_map[subtree.id] = data;

        if (subtree.children == null || subtree.children.length == 0) {
            return;
        }

        foreach (unowned var child in subtree.children.data) {
            collect_geometries (child, ref state);
        }
    }

    public override void mode_end () {
        transform_extra_context = null;
        view_canvas.window.event_bus.update_snap_decorators ();
    }

    public override AbstractInteractionMode.ModeType mode_type () {
        return AbstractInteractionMode.ModeType.TRANSFORM;
    }

    /*
     * Returns the currently active nob the user is holding to resize the item.
     */
    public override Utils.Nobs.Nob active_nob () {
        return effective_nob;
    }

    public override Gdk.CursorType? cursor_type () {
        return Utils.Nobs.cursor_from_nob (nob);
    }

    public override bool key_press_event (Gdk.EventKey event) {
        return true;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        initial_drag_state.press_x = event.x;
        initial_drag_state.press_y = event.y;
        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        request_deregistration (mode_type ());
        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {

        switch (nob) {
            case Utils.Nobs.Nob.NONE:
                move_from_event (
                    view_canvas,
                    selection,
                    initial_drag_state,
                    event.x,
                    event.y,
                    ref transform_extra_context.snap_guide_data
                );
                break;
            case Utils.Nobs.Nob.ROTATE:
                rotate_from_event (
                    view_canvas,
                    selection,
                    initial_drag_state,
                    event.x,
                    event.y
                );
                break;
            default:
                effective_nob = scale_from_event (
                    view_canvas,
                    selection,
                    initial_drag_state,
                    nob,
                    event.x,
                    event.y
                );
                break;
        }

        return true;
    }

    public override Object? extra_context () {
        return transform_extra_context;
    }

    public static void move_from_event (
        ViewCanvas view_canvas,
        Lib.Items.NodeSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y,
        ref Lib.Managers.SnapManager.SnapGuideData guide_data
    ) {
        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        var delta_x = event_x - initial_drag_state.press_x;
        var delta_y = event_y - initial_drag_state.press_y;

        double top = 0.0;
        double left = 0.0;
        double bottom = 0.0;
        double right = 0.0;
        initial_drag_state.area.top_bottom (ref top, ref bottom);
        initial_drag_state.area.left_right (ref left, ref right);

        Utils.AffineTransform.add_grid_snap_delta (top, left, ref delta_x, ref delta_y);

        int snap_offset_x = 0;
        int snap_offset_y = 0;

        if (settings.enable_snaps) {
            guide_data.type = Akira.Lib.Managers.SnapManager.SnapGuideType.NONE;
            var sensitivity = Utils.Snapping2.adjusted_sensitivity (view_canvas.current_scale);
            var selection_area = Geometry.Rectangle () {
                    left = left + delta_x,
                    top = top + delta_y,
                    right = right + delta_x,
                    bottom = bottom + delta_y
            };

            var snap_grid = Utils.Snapping2.generate_best_snap_grid (
                view_canvas,
                selection,
                selection_area,
                sensitivity
            );

            if (!snap_grid.is_empty ()) {
                var matches = Utils.Snapping2.generate_snap_matches (
                    snap_grid,
                    selection,
                    selection_area,
                    sensitivity
                );


                if (matches.h_data.snap_found ()) {
                    snap_offset_x = matches.h_data.snap_offset ();
                    guide_data.type = Akira.Lib.Managers.SnapManager.SnapGuideType.SELECTION;
                }

                if (matches.v_data.snap_found ()) {
                    snap_offset_y = matches.v_data.snap_offset ();
                    guide_data.type = Akira.Lib.Managers.SnapManager.SnapGuideType.SELECTION;
                }
            }
        }

        unowned var items_manager = view_canvas.items_manager;
        foreach (var sel_node in selection.nodes.values) {
            unowned var item = sel_node.node.instance;

            if (item.is_group) {
                translate_group (
                    view_canvas,
                    sel_node.node,
                    initial_drag_state,
                    delta_x, delta_y,
                    snap_offset_x,
                    snap_offset_y
                );

                if (item.components.center == null) {
                    continue;
                }
            }

            var item_drag_data = initial_drag_state.item_data_map[sel_node.node.id];
            var new_center_x = item_drag_data.item_geometry.area.center_x + delta_x + snap_offset_x;
            var new_center_y = item_drag_data.item_geometry.area.center_y + delta_y + snap_offset_y;
            item.components.center = new Lib.Components.Coordinates (new_center_x, new_center_y);
            items_manager.item_model.alert_node_changed (
                sel_node.node,
                Lib.Components.Component.Type.COMPILED_GEOMETRY
            );
        }

        items_manager.compile_model ();
        view_canvas.window.event_bus.update_snap_decorators ();
    }

    private static void translate_group (
        ViewCanvas view_canvas,
        Lib.Items.ModelNode group,
        InitialDragState initial_drag_state,
        double delta_x,
        double delta_y,
        double snap_offset_x,
        double snap_offset_y
    ) {
        if (group.children == null) {
            return;
        }

        unowned var model = view_canvas.items_manager.item_model;

        foreach (unowned var child in group.children.data) {
            if (child.instance.is_group) {
                translate_group (
                    view_canvas,
                    group,
                    initial_drag_state,
                    delta_x,
                    delta_y,
                    snap_offset_x,
                    snap_offset_y
                );
                continue;
            }

            unowned var item = child.instance;
            var item_drag_data = initial_drag_state.item_data_map[child.id];
            var new_center_x = item_drag_data.item_geometry.area.center_x + delta_x + snap_offset_x;
            var new_center_y = item_drag_data.item_geometry.area.center_y + delta_y + snap_offset_y;
            item.components.center = new Lib.Components.Coordinates (new_center_x, new_center_y);
            model.alert_node_changed (child, Lib.Components.Component.Type.COMPILED_GEOMETRY);
        }
    }

    public static Utils.Nobs.Nob scale_from_event (
        ViewCanvas view_canvas,
        Lib.Items.NodeSelection selection,
        InitialDragState initial_drag_state,
        Utils.Nobs.Nob nob,
        double event_x,
        double event_y
    ) {
        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        double rot_center_x = initial_drag_state.area.center_x;
        double rot_center_y = initial_drag_state.area.center_y;

        var itr = initial_drag_state.area.transformation;
        itr.invert ();

        var local_area = initial_drag_state.area;
        Utils.GeometryMath.transform_quad (itr, ref local_area);

        var adjusted_event_x = event_x - rot_center_x;
        var adjusted_event_y = event_y - rot_center_y;
        itr.transform_distance (ref adjusted_event_x, ref adjusted_event_y);
        adjusted_event_x += rot_center_x;
        adjusted_event_y += rot_center_y;

        var start_width = double.max (1.0, local_area.width);
        var start_height = double.max (1.0, local_area.height);

        double nob_x = 0.0;
        double nob_y = 0.0;

        Utils.Nobs.nob_xy_from_coordinates (
            nob,
            local_area,
            1.0,
            ref nob_x,
            ref nob_y
        );

        double inc_width = 0;
        double inc_height = 0;
        double inc_x = 0;
        double inc_y = 0;

        var tr = Cairo.Matrix.identity ();
        var updated_nob = Utils.AffineTransform.calculate_size_adjustments2 (
            nob,
            start_width,
            start_height,
            adjusted_event_x - nob_x,
            adjusted_event_y - nob_y,
            start_width / start_height,
            view_canvas.ctrl_is_pressed,
            view_canvas.shift_is_pressed,
            tr,
            ref inc_x,
            ref inc_y,
            ref inc_width,
            ref inc_height
        );

        double size_off_x = inc_width / 2.0;
        double size_off_y = inc_height / 2.0;
        tr.transform_distance (ref size_off_x, ref size_off_y);

        var local_offset_x = inc_x + size_off_x;
        var local_offset_y = inc_y + size_off_y;

        var new_area = Geometry.Quad.from_components (
            rot_center_x + local_offset_x,
            rot_center_y + local_offset_y,
            start_width + inc_width,
            start_height + inc_height,
            tr
        );

        var global_offset_x = local_offset_x;
        var global_offset_y = local_offset_y;
        initial_drag_state.area.transformation.transform_distance (ref global_offset_x, ref global_offset_y);

        var local_sx = new_area.bounding_box.width / local_area.bounding_box.width;
        var local_sy = new_area.bounding_box.height / local_area.bounding_box.height;

        unowned var item_model = view_canvas.items_manager.item_model;
        foreach (var node in selection.nodes.values) {
            node.node.instance.type.apply_scale_transform (
                item_model,
                node.node,
                initial_drag_state,
                itr,
                global_offset_x,
                global_offset_y,
                local_sx,
                local_sy
            );
        }

        view_canvas.items_manager.compile_model ();

        return updated_nob;
    }

    public static void rotate_from_event (
        ViewCanvas view_canvas,
        Lib.Items.NodeSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y
    ) {
        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        double original_center_x = initial_drag_state.area.center_x;
        double original_center_y = initial_drag_state.area.center_y;

        var radians = GLib.Math.atan2 (
            event_x - original_center_x,
            original_center_y - event_y
        );

        var added_rotation = radians * (180 / Math.PI);

        if (view_canvas.ctrl_is_pressed) {
            var step_num = GLib.Math.round (added_rotation / 15.0);
            added_rotation = 15.0 * step_num;
        }

        var rot = Utils.GeometryMath.matrix_rotation_component (initial_drag_state.area.transformation);

        foreach (var node in selection.nodes.values) {
            rotate_node (
                view_canvas,
                node.node,
                initial_drag_state,
                added_rotation * Math.PI / 180 - rot,
                original_center_x,
                original_center_y
            );
        }

        view_canvas.items_manager.compile_model ();
    }

    private static void rotate_node (
        ViewCanvas view_canvas,
        Lib.Items.ModelNode node,
        InitialDragState initial_drag_state,
        double added_rotation,
        double rotation_center_x,
        double rotation_center_y
    ) {
        unowned var item = node.instance;
        if (item.components.transform != null) {
            var item_drag_data = initial_drag_state.item_data_map[item.id];

            var old_center_x = item_drag_data.item_geometry.area.center_x;
            var old_center_y = item_drag_data.item_geometry.area.center_y;

            var new_transform = item_drag_data.item_geometry.transformation_matrix;

            var tr = Cairo.Matrix.identity ();
            tr.rotate (added_rotation);

            if (old_center_x != rotation_center_x || old_center_y != rotation_center_y) {
                var new_center_delta_x = old_center_x - rotation_center_x;
                var new_center_delta_y = old_center_y - rotation_center_y;
                tr.transform_point (ref new_center_delta_x, ref new_center_delta_y);

                item.components.center = new Lib.Components.Coordinates (
                    rotation_center_x + new_center_delta_x,
                    rotation_center_y + new_center_delta_y
                );
            }

            new_transform = Utils.GeometryMath.multiply_matrices (new_transform, tr);

            double new_rotation = Utils.GeometryMath.matrix_rotation_component (new_transform);

            if (item.components.transform != null) {
                new_rotation = GLib.Math.fmod (new_rotation + GLib.Math.PI * 2, GLib.Math.PI * 2);
                item.components.transform = item.components.transform.with_main_rotation (new_rotation);
            }

            view_canvas.items_manager.item_model.alert_node_changed (
                node,
                Lib.Components.Component.Type.COMPILED_GEOMETRY
            );
        }

        if (node.children != null && node.children.length > 0) {
            foreach (unowned var child in node.children.data) {
                rotate_node (
                    view_canvas,
                    child,
                    initial_drag_state,
                    added_rotation,
                    rotation_center_x,
                    rotation_center_y
                );
            }
        }
    }
}
