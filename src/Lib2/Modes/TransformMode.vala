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
public class Akira.Lib2.Modes.TransformMode : AbstractInteractionMode {
    private const double ROTATION_FIXED_STEP = 15.0;

    public unowned Lib2.ViewCanvas view_canvas { get; construct; }
    public unowned Lib2.Managers.ModeManager mode_manager { get; construct; }

    public Utils.Nobs.Nob nob = Utils.Nobs.Nob.NONE;

    public class DragItemData : Object {
        public Lib2.Components.Coordinates item_center;
        public Lib2.Components.Size item_size;
        public Lib2.Components.Rotation item_rotation;
        public Lib2.Components.CompiledGeometry item_geometry;
    }

    public class InitialDragState : Object {
        public double press_x;
        public double press_y;

        // initial_selection_data
        public double sel_tl_x;
        public double sel_tl_y;
        public double sel_tr_x;
        public double sel_tr_y;
        public double sel_bl_x;
        public double sel_bl_y;
        public double sel_br_x;
        public double sel_br_y;
        public double sel_rotation;

        public double selection_center_x {
            get {
                return (sel_tl_x + sel_tr_x + sel_bl_x + sel_br_x) / 4.0;
            }
        }

        public double selection_center_y {
            get {
                return (sel_tl_y + sel_tr_y + sel_bl_y + sel_br_y) / 4.0;
            }
        }

        public void top_bottom (ref double top, ref double bottom) {
            Utils.GeometryMath.min_max_coords (sel_tl_y, sel_tr_y, sel_bl_y, sel_br_y, ref top, ref bottom);
        }

        public void left_right (ref double left, ref double right) {
            Utils.GeometryMath.min_max_coords (sel_tl_x, sel_tr_x, sel_bl_x, sel_br_x, ref left, ref right);
        }

        public void nob_xy (Utils.Nobs.Nob nob, ref double x, ref double y) {
            Utils.Nobs.nob_xy_from_coordinates (
                nob,
                sel_tl_x,
                sel_tl_y,
                sel_tr_x,
                sel_tr_y,
                sel_bl_x,
                sel_bl_y,
                sel_br_x,
                sel_br_y,
                1.0,
                ref x,
                ref y
            );
        }

        public Gee.ArrayList<DragItemData> items_data;

        construct {
            items_data = new Gee.ArrayList<DragItemData> ();
        }
    }

    public class TransformExtraContext : Object {
        public Lib2.Managers.SnapManager.SnapGuideData snap_guide_data;
    }

    private Lib2.Items.ItemSelection selection;
    private InitialDragState initial_drag_state;
    public TransformExtraContext transform_extra_context;


    public TransformMode (
        Akira.Lib2.ViewCanvas canvas,
        Akira.Lib2.Managers.ModeManager? mode_manager,
        Utils.Nobs.Nob selected_nob
    ) {
        Object (
            view_canvas: canvas,
            mode_manager : mode_manager
        );

        nob = selected_nob;

        initial_drag_state = new InitialDragState ();
    }

    construct {
        transform_extra_context = new TransformExtraContext ();
        transform_extra_context.snap_guide_data = new Lib2.Managers.SnapManager.SnapGuideData ();
    }

    public override void mode_begin () {
        if (view_canvas.selection_manager.selection.is_empty ()) {
            if (mode_manager != null) {
                mode_manager.deregister_mode (mode_type ());
            }
            return;
        }

        selection = view_canvas.selection_manager.selection;

        selection.coordinates (
            out initial_drag_state.sel_tl_x,
            out initial_drag_state.sel_tl_y,
            out initial_drag_state.sel_tr_x,
            out initial_drag_state.sel_tr_y,
            out initial_drag_state.sel_bl_x,
            out initial_drag_state.sel_bl_y,
            out initial_drag_state.sel_br_x,
            out initial_drag_state.sel_br_y,
            out initial_drag_state.sel_rotation
        );

        foreach (var item in selection.items) {
            var data = new DragItemData ();
            data.item_center = item.components.center.copy ();
            data.item_size = item.components.size.copy ();
            data.item_rotation = item.components.rotation.copy ();
            data.item_geometry = item.compiled_geometry ().copy ();
            initial_drag_state.items_data.add (data);
        }
    }

    public override void mode_end () {
        transform_extra_context = null;
        view_canvas.window.event_bus.update_snap_decorators ();
    }

    public override AbstractInteractionMode.ModeType mode_type () { return AbstractInteractionMode.ModeType.RESIZE; }

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
        if (mode_manager == null) {
            return false;
        }

        mode_manager.deregister_mode (mode_type ());
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
                scale_from_event (
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
        Lib2.Items.ItemSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y,
        ref Lib2.Managers.SnapManager.SnapGuideData guide_data
    ) {
        var blocker = new Lib2.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        var delta_x = event_x - initial_drag_state.press_x;
        var delta_y = event_y - initial_drag_state.press_y;

        double top = 0.0;
        double left = 0.0;
        double bottom = 0.0;
        double right = 0.0;
        initial_drag_state.top_bottom (ref top, ref bottom);
        initial_drag_state.left_right (ref left, ref right);

        Utils.AffineTransform.add_grid_snap_delta (top, left, ref delta_x, ref delta_y);

        int snap_offset_x = 0;
        int snap_offset_y = 0;

        if (settings.enable_snaps) {
            guide_data.type = Akira.Lib2.Managers.SnapManager.SnapGuideType.NONE;
            var sensitivity = Utils.Snapping2.adjusted_sensitivity (view_canvas.current_scale);
            var selection_area = Goo.CanvasBounds () {
                    x1 = left + delta_x,
                    x2 = right + delta_x,
                    y1 = top + delta_y,
                    y2 = bottom + delta_y
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
                    guide_data.type = Akira.Lib2.Managers.SnapManager.SnapGuideType.SELECTION;
                }

                if (matches.v_data.snap_found ()) {
                    snap_offset_y = matches.v_data.snap_offset ();
                    guide_data.type = Akira.Lib2.Managers.SnapManager.SnapGuideType.SELECTION;
                }
            }
        }

        var ct = 0;
        foreach (var item in selection.items) {
            var item_drag_data = initial_drag_state.items_data[ct];
            var new_center_x = item_drag_data.item_center.x + delta_x + snap_offset_x;
            var new_center_y = item_drag_data.item_center.y + delta_y + snap_offset_y;
            item.components.center = new Lib2.Components.Coordinates (new_center_x, new_center_y);
            item.recompile_geometry (true);
            ++ct;
        }

        view_canvas.window.event_bus.update_snap_decorators ();
    }

    public static void scale_from_event (
        ViewCanvas view_canvas,
        Lib2.Items.ItemSelection selection,
        InitialDragState initial_drag_state,
        Utils.Nobs.Nob nob,
        double event_x,
        double event_y
    ) {
        // TODO WIP
        var blocker = new Lib2.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        if (selection.items.size != 1) {
            return;
        }

        var opposite_nob = Utils.Nobs.opposite_nob (nob);

        double nob0_x = 0.0;
        double nob0_y = 0.0;
        double nob1_x = 0.0;
        double nob1_y = 0.0;

        initial_drag_state.nob_xy (nob, ref nob0_x, ref nob0_y);
        initial_drag_state.nob_xy (opposite_nob, ref nob1_x, ref nob1_y);

        var delta_x = event_x - nob0_x;
        var delta_y = event_y - nob0_y;

        var tr = Cairo.Matrix.identity ();
        tr.rotate (-initial_drag_state.sel_rotation);

        tr.transform_distance (ref delta_x, ref delta_y);


        Utils.Nobs.rectify_nob_xy (nob, ref delta_x, ref delta_y);

        var grid_offset_x = 0.0;
        var grid_offset_y = 0.0;
        Utils.AffineTransform.add_grid_snap_delta (nob1_x, nob1_y, ref grid_offset_x, ref grid_offset_y);

        var sel_width = (nob1_x + grid_offset_x - nob0_x).abs ();
        var sel_height = (nob1_y + grid_offset_y - nob0_y).abs ();

        delta_x = Utils.AffineTransform.fix_size (delta_x);
        delta_y = Utils.AffineTransform.fix_size (delta_y);
        delta_x += (sel_width + delta_x == 0) ? 1 : 0;
        delta_y += (sel_height + delta_y == 0) ? 1 : 0;

        double sx = sel_width == 0 ? 1 : delta_x / (sel_width);
        double sy = sel_height == 0 ? 1 : delta_y / (sel_height);

        var ct = 0;
        foreach (var item in selection.items) {
            var item_drag_data = initial_drag_state.items_data[ct];
            double width_change = Utils.AffineTransform.fix_size (item_drag_data.item_size.width * sx);
            double height_change = Utils.AffineTransform.fix_size (item_drag_data.item_size.height * sy);

            double new_width_tmp = item_drag_data.item_size.width + width_change;
            double new_height_tmp = item_drag_data.item_size.height + height_change;

            double new_width = new_width_tmp.abs ();
            double new_height = new_height_tmp.abs ();
            double new_center_x = nob1_x + grid_offset_x + new_width / 2.0;
            double new_center_y = nob1_y + grid_offset_y + new_height / 2.0;

            if (new_width_tmp < 0) {
                new_center_x += width_change;
            }

            if (new_height_tmp < 0) {
                new_center_y += height_change;
            }

            item.components.center = new Lib2.Components.Coordinates (new_center_x, new_center_y);
            item.components.size = new Lib2.Components.Size (new_width, new_height, false);
            item.recompile_geometry (true);
            ct++;
        }

        return;

        /*
        if (selection.items.size == 1) {
            var item_drag_data = initial_drag_state.items_data[0];
            var tr = Cairo.Matrix.identity ();
            tr.rotate (-item_drag_data.item_rotation.in_radians ());
            var tr_delta_x = delta_x;
            var tr_delta_y = delta_y;
            tr.transform_distance (ref tr_delta_x, ref tr_delta_y);
            item.components.center = new Lib2.Components.Coordinates (new_center_x + cdx, new_center_y + cdy);
            item.components.size = new Lib2.Components.Size (
                double.max (1.0, new_width.abs ()),
                double.max (1.0, new_height.abs ()),
                false
            );
            item.recompile_geometry (true);

            return;
        }



        ct = 0;
        foreach (var item in selection.items) {
            var item_drag_data = initial_drag_state.items_data[ct];
            double width_change = Utils.AffineTransform.fix_size (item_drag_data.item_size.width * sx);
            double height_change = Utils.AffineTransform.fix_size (item_drag_data.item_size.height * sy);

            double new_width_tmp = item_drag_data.item_size.width + width_change;
            double new_height_tmp = item_drag_data.item_size.height + height_change;

            double new_width = new_width_tmp.abs ();
            double new_height = new_height_tmp.abs ();
            double new_center_x = nob1_x + grid_offset_x + new_width / 2.0;
            double new_center_y = nob1_y + grid_offset_y + new_height / 2.0;

            if (new_width_tmp < 0) {
                new_center_x += width_change;
            }

            if (new_height_tmp < 0) {
                new_center_y += height_change;
            }

            item.components.center = new Lib2.Components.Coordinates (new_center_x, new_center_y);
            item.components.size = new Lib2.Components.Size (new_width, new_height, false);
            item.recompile_geometry (true);
            ct++;
        }
        */
    }


    public static void rotate_from_event (
        ViewCanvas view_canvas,
        Lib2.Items.ItemSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y
    ) {
        var blocker = new Lib2.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        double original_center_x = initial_drag_state.selection_center_x;
        double original_center_y = initial_drag_state.selection_center_y;

        var radians = GLib.Math.atan2 (
            event_x - original_center_x,
            original_center_y - event_y
        );

        var new_rotation = radians * (180 / Math.PI);

        if (view_canvas.ctrl_is_pressed) {
            var step_num = GLib.Math.round (new_rotation / 15.0);
            new_rotation = 15.0 * step_num;
        }

        var single_item = selection.items.size == 1;

        var ct = 0;
        foreach (var item in selection.items) {
            if (single_item) {
                new_rotation = GLib.Math.fmod (new_rotation + 360, 360);
                item.components.rotation = new Lib2.Components.Rotation (new_rotation);
                item.recompile_geometry (true);
                return;
            }

            var item_drag_data = initial_drag_state.items_data[ct];
            var old_center_x = item_drag_data.item_center.x;
            var old_center_y = item_drag_data.item_center.y;

            var tmp_rotation = new_rotation;
            var item_rotation = item_drag_data.item_rotation.in_degrees ();

            if (old_center_x != original_center_x || old_center_y != original_center_y) {
                var tr = Cairo.Matrix.identity ();
                tr.rotate (tmp_rotation * Math.PI / 180);
                var new_center_delta_x = old_center_x - original_center_x;
                var new_center_delta_y = old_center_y - original_center_y;
                tr.transform_point (ref new_center_delta_x, ref new_center_delta_y);

                item.components.center = new Lib2.Components.Coordinates (
                    original_center_x + new_center_delta_x,
                    original_center_y + new_center_delta_y
                );
            }

            tmp_rotation = GLib.Math.fmod (item_rotation + tmp_rotation + 360, 360);
            item.components.rotation = new Lib2.Components.Rotation (tmp_rotation);

            item.recompile_geometry (true);
            ct++;
        }
    }
}
