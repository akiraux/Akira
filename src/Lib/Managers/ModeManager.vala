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

/**
 * Manages Goo.CanvasItem decorators used to display snap lines and dots.
 */
public class Akira.Lib.Managers.ModeManager : Object {
    public weak Akira.Lib.Canvas canvas { get; construct; }

    private Akira.Lib.Modes.InteractionMode active_mode;

    public ModeManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    public void register_mode (Akira.Lib.Modes.InteractionMode new_mode) {
        if (active_mode != null) {
            inner_deregister_active_mode (false);
        }

        active_mode = new_mode;
        active_mode.mode_begin ();
        canvas.interaction_mode_changed ();
    }

    public void deregister_mode (Akira.Lib.Modes.InteractionMode.ModeType mode_type) {
        if (active_mode != null && active_mode.mode_type () == mode_type) {
            inner_deregister_active_mode (true);
        }
    }

    public void deregister_active_mode () {
        inner_deregister_active_mode (true);
    }

    private void inner_deregister_active_mode (bool notify) {
        active_mode.mode_end ();
        active_mode = null;
    }

    public Gdk.CursorType? active_cursor_type () {
        if (active_mode != null) {
            return active_mode.cursor_type ();
        }

        return null;
    }

    public bool key_press_event (Gdk.EventKey event) {
        if (active_mode != null) {
            return active_mode.key_press_event (event);
        }

        return false;
    }

    public bool key_release_event (Gdk.EventKey event) {
        if (active_mode != null) {
            return active_mode.key_release_event (event);
        }

        return false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        if (active_mode != null) {
            return active_mode.button_press_event (event);
        }

        return false;
    }

    public bool button_release_event (Gdk.EventButton event) {
        if (active_mode != null) {
            return active_mode.button_release_event (event);
        }

        return false;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        if (active_mode != null) {
            return active_mode.motion_notify_event (event);
        }

        return false;
    }

}
