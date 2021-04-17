/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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
public class Akira.Lib.Modes.ItemInsertMode : Object, InteractionMode {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Lib.Managers.ModeManager mode_manager { get; construct; }

    private bool resizing = false;

    public ItemInsertMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    public void mode_begin () {}
    public void mode_end () {}
    public InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.ITEM_INSERT; }


    public Gdk.CursorType? cursor_type () {
        if (resizing) {
            return TransformMode.cursor_type_from_nob_state (Akira.Lib.Managers.NobManager.Nob.BOTTOM_RIGHT);
        }

        return Gdk.CursorType.CROSSHAIR;
    }

    public bool key_press_event (Gdk.EventKey event) {
        return false;
    }

    public bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        if (event.button == Gdk.BUTTON_PRIMARY) {
            var sel_manager = canvas.selected_bound_manager;
            sel_manager.reset_selection ();

            var new_item = canvas.window.items_manager.insert_item (event.x, event.y);

            sel_manager.add_item_to_selection (new_item);
            sel_manager.set_initial_coordinates (event.x, event.y);

            canvas.nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;

            canvas.update_canvas();

            resizing = true;
            return true;
        }

        return false;
    }

    public bool button_release_event (Gdk.EventButton event) {
        if (resizing) {
            mode_manager.deregister_mode (mode_type ());
            return true;
        }

        return resizing;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        if (resizing) {
            TransformMode.handle_motion_event (event, canvas);
        }

        return false;
    }

}
