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
 * PanMode handles panning. This will handle space or middle click panning. This mode should
 * be used as a secondary mode that overrides masks other modes. See ModeManager.
 */
public class Akira.Lib2.Modes.PanMode : AbstractInteractionMode {
    public unowned Akira.Lib2.ViewCanvas canvas { get; construct; }

    private bool space_held = false;
    private bool panning = false;
    private double origin_x = 0;
    private double origin_y = 0;

    public PanMode (Akira.Lib2.ViewCanvas canvas) {
        Object (canvas: canvas);
    }

    public override AbstractInteractionMode.ModeType mode_type () { return AbstractInteractionMode.ModeType.PAN; }


    public override Gdk.CursorType? cursor_type () {
        return panning ? Gdk.CursorType.HAND2 : Gdk.CursorType.HAND1;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);
        if (uppercase_keyval == Gdk.Key.space) {
            space_held = true;
        }
        return true;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);
        if (uppercase_keyval == Gdk.Key.space) {
            space_held = false;

            if (!panning) {
                request_deregistration (mode_type ());
            }
        }
        return true;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (!panning && (space_held || event.button == Gdk.BUTTON_MIDDLE)) {
            origin_x = event.x;
            origin_y = event.y;
            canvas.canvas_scroll_set_origin (origin_x, origin_y);

            toggle_panning (true);
        }
        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        toggle_panning (false);

        if (!space_held) {
            request_deregistration (mode_type ());
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (panning) {
            canvas.canvas_moved (event.x, event.y);
        }
        return true;
    }

    private void toggle_panning (bool new_state) {
        if (panning != new_state) {
            panning = new_state;
            canvas.interaction_mode_changed ();
        }
    }
}
