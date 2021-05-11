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

    public weak Akira.Lib2.ViewCanvas view_canvas { get; construct; }
    public weak Akira.Lib2.Managers.ModeManager mode_manager { get; construct; }

    public TransformMode (Akira.Lib2.ViewCanvas canvas, Akira.Lib2.Managers.ModeManager? mode_manager) {
        Object (
            view_canvas: canvas,
            mode_manager : mode_manager
        );
    }

    construct {
    }

    public override void mode_begin () {}

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
        return true;
    }
}
