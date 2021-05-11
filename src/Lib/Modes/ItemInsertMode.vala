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

    private Akira.Lib.Modes.TransformMode transform_mode;

    public ItemInsertMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    construct {
        transform_mode = null;
    }

    public override InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.ITEM_INSERT; }

    public override void mode_end () {
        if (transform_mode != null) {
            transform_mode.mode_end ();
        }
    }

    public override Gdk.CursorType? cursor_type () {
        if (transform_mode != null) {
            return transform_mode.cursor_type ();
        }

        return Gdk.CursorType.CROSSHAIR;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        if (transform_mode != null) {
            return transform_mode.key_press_event (event);
        }
        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        if (transform_mode != null) {
            return transform_mode.key_press_event (event);
        }
        return false;
     }

    public override bool button_press_event (Gdk.EventButton event) {
        if (transform_mode != null) {
            return transform_mode.button_press_event (event);
        }

        if (event.button == Gdk.BUTTON_PRIMARY) {
            var sel_manager = canvas.selected_bound_manager;
            sel_manager.reset_selection ();

            var new_item = canvas.window.items_manager.insert_item (event.x, event.y);

            sel_manager.add_item_to_selection (new_item);

            canvas.nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;
            canvas.update_canvas ();

            transform_mode = new Akira.Lib.Modes.TransformMode (canvas, null);
            transform_mode.mode_begin ();
            transform_mode.button_press_event (event);

            return true;
        }

        return false;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (transform_mode != null) {
            transform_mode.button_release_event (event);
            mode_manager.deregister_mode (mode_type ());
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (transform_mode != null) {
            return transform_mode.motion_notify_event (event);
        }

        return true;
    }

    public override Object? extra_context () {
        if (transform_mode != null) {
            return transform_mode.extra_context ();
        }

        return null;
    }

}
