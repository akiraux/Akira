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


public class Akira.Lib.Modes.ExportMode : Object, InteractionMode {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Lib.Managers.ModeManager mode_manager { get; construct; }

    private bool resizing = false;

    public ExportMode (Akira.Lib.Canvas canvas, Akira.Lib.Managers.ModeManager mode_manager) {
        Object (
            canvas: canvas,
            mode_manager : mode_manager
        );
    }

    public void mode_begin () {}
    public void mode_end () {}
    public InteractionMode.ModeType mode_type () { return InteractionMode.ModeType.EXPORT; }


    public Gdk.CursorType? cursor_type () {
        return Gdk.CursorType.CROSSHAIR;
    }

    public bool key_press_event (Gdk.EventKey event) {
        return false;
    }

    public bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        canvas.selected_bound_manager.reset_selection ();
        canvas.export_manager.create_area (event);
        resizing = true;
        return true;
    }

    public bool button_release_event (Gdk.EventButton event) {
        canvas.export_manager.create_area_snapshot ();
        mode_manager.deregister_mode (mode_type ());
        return true;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        if (resizing) {
            canvas.export_manager.resize_area (event.x, event.y);
        }
        return true;
    }
}


