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
        canvas.nob_manager.set_selected_by_name (Akira.Lib.Managers.NobManager.Nob.NONE);
        canvas.selected_bound_manager.reset_snap_decorators ();
    }
    public InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.RESIZE; }

    public Gdk.CursorType? cursor_type () {
        var selected_nob = canvas.nob_manager.selected_nob;
        return Managers.NobManager.cursor_from_nob (selected_nob);
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
}
