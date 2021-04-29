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
 * ItemInsertMode handles item insertion. After the first click, this mode will use static methods
 * in the TransformMode to transform the inserted items.
 *
 * In the future, this mode can be kept alive during multiple clicks when inserting items like polylines.
 */
public class Akira.Lib.Modes.ItemInsertMode : InteractionMode {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Lib.Managers.ModeManager mode_manager { get; construct; }

    private bool resizing = false;
    public Akira.Lib.Modes.TransformMode.InitialDragState initial_drag_state;
    public Akira.Lib.Modes.TransformMode.TransformExtraContext transform_extra_context;

    public ItemInsertMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    construct {
        initial_drag_state = new Akira.Lib.Modes.TransformMode.InitialDragState ();
        transform_extra_context = new Akira.Lib.Modes.TransformMode.TransformExtraContext ();
        transform_extra_context.snap_guide_data = new Akira.Lib.Managers.SnapManager.SnapGuideData ();
    }

    public override InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.ITEM_INSERT; }

    public override void mode_end () {
        transform_extra_context = null;
        canvas.window.event_bus.update_snap_decorators ();
    }

    public override Gdk.CursorType? cursor_type () {
        if (resizing) {
            return Akira.Lib.Managers.NobManager.cursor_from_nob (Akira.Lib.Managers.NobManager.Nob.BOTTOM_RIGHT);
        }

        return Gdk.CursorType.CROSSHAIR;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.button == Gdk.BUTTON_PRIMARY) {
            var sel_manager = canvas.selected_bound_manager;
            sel_manager.reset_selection ();

            var new_item = canvas.window.items_manager.insert_item (event.x, event.y);

            sel_manager.add_item_to_selection (new_item);

            canvas.nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;
            canvas.update_canvas ();
            resizing = true;

            if (!Akira.Lib.Modes.TransformMode.initialize_items_drag_state (
                sel_manager.selected_items,
                ref initial_drag_state
            )) {
                mode_manager.deregister_mode (mode_type ());
                return true;
            }

            initial_drag_state.press_x = event.x;
            initial_drag_state.press_y = event.y;

            return true;
        }

        return false;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (resizing) {
            mode_manager.deregister_mode (mode_type ());
            return true;
        }

        return resizing;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (resizing) {
            TransformMode.handle_motion_event (event, canvas, initial_drag_state, ref transform_extra_context.snap_guide_data);
            return true;
        }

        return resizing;
    }

    public override Object? extra_context ()
    {
        return transform_extra_context;
    }

}
