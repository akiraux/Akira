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
public class Akira.Lib.Modes.TransformMode : InteractionMode {
    private const double ROTATION_FIXED_STEP = 15.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Lib.Managers.ModeManager mode_manager { get; construct; }

    public class InitialDragState {
        public double press_x = 0.0;
        public double press_y = 0.0;
        public double nob_x = 0.0;
        public double nob_y = 0.0;

        public double item_x = 0.0;
        public double item_y = 0.0;
        public double item_width = 0.0;
        public double item_height = 0.0;
        public Cairo.Matrix item_transform;

        public double item_scale_x_adj = 0.0;
        public double item_scale_y_adj = 0.0;

        public double rotation_center_x = 0.0;
        public double rotation_center_y = 0.0;

        public bool wants_snapping = true;
    }

    public class TransformExtraContext : Object {
        public Akira.Lib.Managers.SnapManager.SnapGuideData snap_guide_data;
    }

    public InitialDragState initial_drag_state;
    public TransformExtraContext transform_extra_context;

    public TransformMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager? mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    construct {
        initial_drag_state = new InitialDragState ();
        transform_extra_context = new TransformExtraContext ();
        transform_extra_context.snap_guide_data = new Akira.Lib.Managers.SnapManager.SnapGuideData ();
    }

    public override void mode_begin () {
        unowned var selected_items = canvas.selected_bound_manager.selected_items;
        var success = initialize_items_drag_state (selected_items, ref initial_drag_state);

        if (!success && mode_manager != null) {
            mode_manager.deregister_mode (mode_type ());
            return;
        }
    }

    public override void mode_end () {
        transform_extra_context = null;
        canvas.nob_manager.set_selected_by_name (Utils.Nobs.Nob.NONE);
        canvas.window.event_bus.detect_artboard_change ();
        canvas.window.event_bus.update_snap_decorators ();
    }

    public override InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.RESIZE; }

    public override Gdk.CursorType? cursor_type () {
        var selected_nob = canvas.nob_manager.selected_nob;
        return Utils.Nobs.cursor_from_nob (selected_nob);
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

        Akira.Lib.Managers.NobManager.nob_position_from_items (
            canvas.selected_bound_manager.selected_items,
            canvas.nob_manager.selected_nob,
            ref initial_drag_state.nob_x,
            ref initial_drag_state.nob_y
        );

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (mode_manager != null) {
            mode_manager.deregister_mode (mode_type ());
        }
        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        var selected_nob = canvas.nob_manager.selected_nob;

        unowned var selected_items = canvas.selected_bound_manager.selected_items;

        if (selected_items.length () != 1) {
            return false;
        }

        switch (selected_nob) {
            case Utils.Nobs.Nob.NONE:
                move_from_event (
                    canvas,
                    selected_items,
                    initial_drag_state,
                    event.x,
                    event.y,
                    ref transform_extra_context.snap_guide_data
                );
                break;

            case Utils.Nobs.Nob.ROTATE:
                rotate_from_event (
                    canvas,
                    selected_items,
                    initial_drag_state,
                    event.x,
                    event.y,
                    ref transform_extra_context.snap_guide_data
                );
                break;

            default:
                scale_from_event (
                    canvas,
                    selected_items,
                    initial_drag_state,
                    selected_nob,
                    event.x,
                    event.y,
                    ref transform_extra_context.snap_guide_data
                );
                break;
        }

        // Notify the X & Y values in the state manager.
        canvas.window.event_bus.reset_state_coords ();

        return true;
    }

    public override Object? extra_context () {
        return transform_extra_context;
    }

    /*
     * Initialize the initial drag state of an item. Return true on success.
     */
    public static bool initialize_items_drag_state (
        GLib.List<Akira.Lib.Items.CanvasItem> selected_items,
        ref InitialDragState drag_state
    ) {
        if (selected_items.length () != 1) {
            return false;
        }

        var item = selected_items.nth_data (0);

        drag_state.item_x = item.coordinates.x;
        drag_state.item_y = item.coordinates.y;

        item.get_transform (out drag_state.item_transform);

        if (selected_items.length () == 1) {
            drag_state.item_width = item.size.width;
            drag_state.item_height = item.size.height;
        } else {
            // TODO there should probably be a nice method to get a bounding box from a list of items.
        }

        drag_state.item_scale_x_adj = 0;
        drag_state.item_scale_y_adj = 0;

        // If rotation is multiple of 90, then snap to pixel grid before scale.
        if (item.rotation != null && GLib.Math.fmod (item.rotation.rotation, 90) == 0) {
            drag_state.item_scale_x_adj = Utils.AffineTransform.fix_size (drag_state.item_x) - drag_state.item_x;
            drag_state.item_scale_y_adj = Utils.AffineTransform.fix_size (drag_state.item_y) - drag_state.item_y;
            drag_state.item_width = Utils.AffineTransform.fix_size (drag_state.item_width);
            drag_state.item_height = Utils.AffineTransform.fix_size (drag_state.item_height);
        }

        drag_state.rotation_center_x = (item.coordinates.x1 + item.coordinates.x2) / 2.0;
        drag_state.rotation_center_y = (item.coordinates.y1 + item.coordinates.y2) / 2.0;

        return true;
    }

    public static void move_from_event (
        Akira.Lib.Canvas canvas,
        GLib.List<Akira.Lib.Items.CanvasItem> selected_items,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y,
        ref Akira.Lib.Managers.SnapManager.SnapGuideData guide_data
    ) {
        if (selected_items.length () != 1) {
            return;
        }

        // for now we only transform one item
        Akira.Lib.Items.CanvasItem item = selected_items.nth_data (0);

        // Keep reset and delta values for future adjustments.

        // Calculate values needed to reset to the original position.
        var reset_x = item.coordinates.x - initial_drag_state.item_x;
        var reset_y = item.coordinates.y - initial_drag_state.item_y;

        // Calculate the change based on the event.
        var delta_x = event_x - initial_drag_state.press_x;
        var delta_y = event_y - initial_drag_state.press_y;

        // Keep reset and delta values for future adjustments.
        // fix_size should be called right before a transform.
        var first_move_x = Utils.AffineTransform.fix_size (delta_x - reset_x);
        var first_move_y = Utils.AffineTransform.fix_size (delta_y - reset_y);

        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        // Increment the cairo matrix coordinates so we can ignore the item's rotation.
        matrix.x0 += first_move_x;
        matrix.y0 += first_move_y;
        item.set_transform (matrix);

        // Interrupt if the user disabled the snapping or we don't have any
        // adjacent item to snap to.
        if (!settings.enable_snaps) {
            return;
        }

        // Make adjustment basted on snaps.
        // Double the sensitivity to allow for reuse of grid after snap.
        var sensitivity = Utils.Snapping.adjusted_sensitivity (canvas.current_scale);
        var snap_grid = Utils.Snapping.generate_best_snap_grid (canvas, selected_items, sensitivity);

        // Interrupt if we don't have any snap to use.
        if (snap_grid.is_empty ()) {
            return;
        }

        int snap_offset_x = 0;
        int snap_offset_y = 0;
        var matches = Utils.Snapping.generate_snap_matches (snap_grid, selected_items, sensitivity);

        // Don't force the offset translation on items. This is mostly
        // used when moving items from the Transform Panel where we want to show
        // the snapping guides but ignore the magnetic effect.
        if (initial_drag_state.wants_snapping) {
            if (matches.h_data.snap_found ()) {
                snap_offset_x = matches.h_data.snap_offset ();
                matrix.x0 += snap_offset_x;
            }

            if (matches.v_data.snap_found ()) {
                snap_offset_y = matches.v_data.snap_offset ();
                matrix.y0 += snap_offset_y;
            }

            item.set_transform (matrix);
        }

        guide_data.type = Akira.Lib.Managers.SnapManager.SnapGuideType.SELECTION;
        canvas.window.event_bus.update_snap_decorators ();
    }

    private static void scale_from_event (
        Akira.Lib.Canvas canvas,
        GLib.List<Akira.Lib.Items.CanvasItem> selected_items,
        InitialDragState initial_drag_state,
        Utils.Nobs.Nob selected_nob,
        double event_x,
        double event_y,
        ref Akira.Lib.Managers.SnapManager.SnapGuideData guide_data
    ) {
        if (selected_items.length () != 1) {
            return;
        }

        // for now we only transform one item
        Akira.Lib.Items.CanvasItem item = selected_items.nth_data (0);

        event_x = Akira.Utils.AffineTransform.fix_size (event_x);
        event_y = Akira.Utils.AffineTransform.fix_size (event_y);

        double rel_event_x = event_x;
        double rel_event_y = event_y;
        double rel_press_x = initial_drag_state.nob_x;
        double rel_press_y = initial_drag_state.nob_y;

        // Convert the coordinates from the canvas to the item so we know the real
        // values even if the item is rotated.
        canvas.convert_to_item_space (item, ref rel_event_x, ref rel_event_y);
        canvas.convert_to_item_space (item, ref rel_press_x, ref rel_press_y);

        // Calculate the change based on the event.
        var delta_x = rel_event_x - rel_press_x;
        var delta_y = rel_event_y - rel_press_y;

        bool ratio_locked = canvas.ctrl_is_pressed || item.size.locked;

        // These values will be populated.
        double inc_width = 0;
        double inc_height = 0;
        double inc_x = 0;
        double inc_y = 0;

        Utils.AffineTransform.calculate_size_adjustments (
            selected_nob,
            initial_drag_state.item_width,
            initial_drag_state.item_height,
            delta_x,
            delta_y,
            initial_drag_state.item_width / initial_drag_state.item_height,
            ratio_locked,
            canvas.shift_is_pressed,
            initial_drag_state.item_transform,
            ref inc_x,
            ref inc_y,
            ref inc_width,
            ref inc_height
        );

        var reset_width = item.size.width - initial_drag_state.item_width;
        var reset_height = item.size.height - initial_drag_state.item_height;

        Cairo.Matrix new_matrix;
        item.get_transform (out new_matrix);
        new_matrix.x0 = initial_drag_state.item_transform.x0 + inc_x + initial_drag_state.item_scale_x_adj;
        new_matrix.y0 = initial_drag_state.item_transform.y0 + inc_y + initial_drag_state.item_scale_y_adj;
        item.set_transform (new_matrix);

        Utils.AffineTransform.adjust_size (item, inc_width - reset_width, inc_height - reset_height);
    }

    private static void rotate_from_event (
        Akira.Lib.Canvas canvas,
        GLib.List<Akira.Lib.Items.CanvasItem> selected_items,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y,
        ref Akira.Lib.Managers.SnapManager.SnapGuideData guide_data
    ) {
        if (selected_items.length () != 1) {
            return;
        }

        var radians = GLib.Math.atan2 (
            event_x - initial_drag_state.rotation_center_x,
            initial_drag_state.rotation_center_y - event_y
        );

        var new_rotation = radians * (180 / Math.PI) + 360;

        if (canvas.ctrl_is_pressed) {
            var step_num = GLib.Math.round (new_rotation / 15.0);
            new_rotation = 15.0 * step_num;
        }

        Akira.Lib.Items.CanvasItem item = selected_items.nth_data (0);
        // Cap new_rotation to the [0, 360] range.
        new_rotation = GLib.Math.fmod (new_rotation + 360, 360);
        item.rotation.rotation = Akira.Utils.AffineTransform.fix_size (new_rotation);
    }
}
