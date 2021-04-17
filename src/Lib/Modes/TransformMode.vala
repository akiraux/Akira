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
 * TransformMode handles mouse-activated transformations. Static methods can
 * be used to apply the underlying code on top of other modes that may need to
 * use the functionality.
 */
public class Akira.Lib.Modes.TransformMode : Object, InteractionMode {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Lib.Managers.ModeManager mode_manager { get; construct; }

    public TransformMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    public void mode_begin () {}
    public void mode_end () {
        canvas.selected_bound_manager.reset_snap_decorators ();
    }
    public InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.RESIZE; }

    public Gdk.CursorType? cursor_type () {
        var selected_nob = canvas.nob_manager.selected_nob;
        return cursor_type_from_nob_state (selected_nob);
    }

    public bool key_press_event (Gdk.EventKey event) {
        return true;
    }

    public bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        return true;
    }

    public bool button_release_event (Gdk.EventButton event) {
        mode_manager.deregister_mode (mode_type ());
        return true;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        handle_motion_event (event, canvas);
        return true;
    }

    /*
     * Handle a motion event on a canvas. Will forward event to the canvas for now.
     */
    public static bool handle_motion_event (Gdk.EventMotion event, Akira.Lib.Canvas canvas) {
        var selected_nob = canvas.nob_manager.selected_nob;
        canvas.selected_bound_manager.transform_bound (event.x, event.y, selected_nob);
        return true;
    }


    /*
     * Returns a cursor type based on a NobManager.Nob.
     */
    public static Gdk.CursorType? cursor_type_from_nob_state (Akira.Lib.Managers.NobManager.Nob nob) {
        switch (nob) {
            case Managers.NobManager.Nob.TOP_LEFT:
                return Gdk.CursorType.TOP_LEFT_CORNER;
            case Managers.NobManager.Nob.TOP_CENTER:
                return Gdk.CursorType.TOP_SIDE;
            case Managers.NobManager.Nob.TOP_RIGHT:
                return Gdk.CursorType.TOP_RIGHT_CORNER;
            case Managers.NobManager.Nob.RIGHT_CENTER:
                return Gdk.CursorType.RIGHT_SIDE;
            case Managers.NobManager.Nob.BOTTOM_RIGHT:
                return Gdk.CursorType.BOTTOM_RIGHT_CORNER;
            case Managers.NobManager.Nob.BOTTOM_CENTER:
                return Gdk.CursorType.BOTTOM_SIDE;
            case Managers.NobManager.Nob.BOTTOM_LEFT:
                return Gdk.CursorType.BOTTOM_LEFT_CORNER;
            case Managers.NobManager.Nob.LEFT_CENTER:
                return Gdk.CursorType.LEFT_SIDE;
            case Managers.NobManager.Nob.ROTATE:
                return Gdk.CursorType.EXCHANGE;
        }

        return null;
    }

}
