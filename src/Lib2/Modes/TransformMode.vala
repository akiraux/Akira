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

    public class InitialDragState : Object {
        public double press_x;
        public double press_y;
        public Lib2.Components.Coordinates item_center;
        public Lib2.Components.Size item_size;
        public Lib2.Components.Rotation item_rotation;
        public Lib2.Components.CompiledGeometry item_geometry;
    }

    private Lib2.Items.ItemSelection selection;
    private InitialDragState initial_drag_state;


    public TransformMode (Akira.Lib2.ViewCanvas canvas, Akira.Lib2.Managers.ModeManager? mode_manager) {
        Object (
            view_canvas: canvas,
            mode_manager : mode_manager
        );

        initial_drag_state = new InitialDragState ();
    }

    construct {}

    public override void mode_begin () {
        if (view_canvas.selection_manager.selection.is_empty ()) {
            if (mode_manager != null) {
                mode_manager.deregister_mode (mode_type ());
            }
            return;
        }

        selection = view_canvas.selection_manager.selection;
        var item = selection.items[0];

        initial_drag_state.item_center = item.components.center.copy ();
        initial_drag_state.item_size = item.components.size.copy ();
        initial_drag_state.item_rotation = item.components.rotation.copy ();
        initial_drag_state.item_geometry = item.compiled_geometry ().copy ();
    }

    public override void mode_end () {}

    public override AbstractInteractionMode.ModeType mode_type () { return AbstractInteractionMode.ModeType.RESIZE; }

    public override Gdk.CursorType? cursor_type () {
        //var selected_nob = canvas.nob_manager.selected_nob;
        //return Managers.NobManager.cursor_from_nob (selected_nob);
        return Gdk.CursorType.TOP_LEFT_CORNER;
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
        //var selected_nob = canvas.nob_manager.selected_nob;

        if (selection.items.size != 1) {
            return false;
        }

        scale_from_event (
            view_canvas,
            selection,
            initial_drag_state,
            event.x,
            event.y
        );


        /*
        switch (selected_nob) {
            case Managers.NobManager.Nob.NONE:
                move_from_event (
                    canvas,
                    selected_items,
                    initial_drag_state,
                    event.x,
                    event.y,
                    ref transform_extra_context.snap_guide_data
                );
                break;

            case Managers.NobManager.Nob.ROTATE:
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
        */

        // Notify the X & Y values in the state manager.
        //canvas.window.event_bus.reset_state_coords ();

        return true;
    }

    public static void move_from_event (
        ViewCanvas view_canvas,
        Lib2.Items.ItemSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y
    ) {
        if (selection.items.size != 1) {
            return;
        }

        var item = selection.items[0];

        var delta_x = event_x - initial_drag_state.press_x;
        var delta_y = event_y - initial_drag_state.press_y;

        double new_center_x = initial_drag_state.item_center.x;
        double new_center_y = initial_drag_state.item_center.y;

        Utils.AffineTransform.translate_center (
            initial_drag_state.item_geometry,
            delta_x,
            delta_y,
            ref new_center_x,
            ref new_center_y
        );

        item.components.center = new Lib2.Components.Coordinates (new_center_x, new_center_y);
        item.recompile_geometry (true);
    }

    public static void scale_from_event (
        ViewCanvas view_canvas,
        Lib2.Items.ItemSelection selection,
        InitialDragState initial_drag_state,
        double event_x,
        double event_y
    ) {
        if (selection.items.size != 1) {
            return;
        }

        var item = selection.items[0];

        var item_tr = initial_drag_state.item_geometry.transform ();
        var item_inv_tr = item_tr;

        if (item_inv_tr.invert () != Cairo.Status.SUCCESS) {
            return;
        }

        var delta_x = event_x - initial_drag_state.press_x;
        var delta_y = event_y - initial_drag_state.press_y;

        var tr_delta_x = delta_x;
        var tr_delta_y = delta_y;
        item_inv_tr.transform_distance (ref tr_delta_x, ref tr_delta_y);

        double sx = (tr_delta_x) / (initial_drag_state.item_size.width);
        double sy = (tr_delta_y) / (initial_drag_state.item_size.height);

        var tr = Cairo.Matrix.identity ();
        tr.scale (sx, sy);

        double new_center_x = initial_drag_state.item_center.x;
        double new_center_y = initial_drag_state.item_center.y;
        double cdx = initial_drag_state.item_size.width / 2.0;
        double cdy = initial_drag_state.item_size.height / 2.0;
        tr.transform_distance (ref cdx, ref cdy);
        item_tr.transform_distance (ref cdx, ref cdy);

        double new_width = initial_drag_state.item_size.width;
        double new_height = initial_drag_state.item_size.height;
        tr.transform_distance (ref new_width, ref new_height);

        item.components.center = new Lib2.Components.Coordinates (new_center_x + cdx, new_center_y + cdy);
        item.components.size = new Lib2.Components.Size (
            double.max (1.0, new_width.abs ()),
            double.max (1.0, new_height.abs ()),
            false
        );
        item.recompile_geometry (true);
    }
}
