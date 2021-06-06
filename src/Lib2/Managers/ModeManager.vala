/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/**
 * Manages InteractionMode's via registration. This class can be plugged into the event methods of a Canvas
 * in order to allow these modes to affect items in the canvas as well as allowing them to absorb said
 * events.
 *
 * Only one InteractionMode is guaranteed to exist at a time, and this manager will correctly alert the
 * beginning and end of a registered mode.
 *
 * The exception to the above rule is pan_mode, which can be running on top of another mode in certain cases and
 * masks events appropriately.
 *
 * See InteractionMode.vala for more details on how to create modes.
 */
public class Akira.Lib2.Managers.ModeManager : Object {
    public unowned Lib2.ViewCanvas view_canvas { get; construct; }

    private Akira.Lib2.Modes.PanMode pan_mode;
    private Akira.Lib2.Modes.AbstractInteractionMode active_mode;

    public ModeManager (Akira.Lib2.ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    /*
     * Register a new mode as the active mode. Any prior mode will be deregistered.
     */
    public void register_mode (Akira.Lib2.Modes.AbstractInteractionMode new_mode) {
        if (active_mode != null) {
            inner_deregister_active_mode (false);
        }

        active_mode = new_mode;
        active_mode.request_deregistration.connect (on_deregistration_request);
        active_mode.mode_begin ();
        view_canvas.interaction_mode_changed ();
    }

    /*
     * Deregister active mode or pan mode if it matches the mode_type.
     * This should generally be used for safety since a new mode may already have been
     * registered by the time this method is called.
     */
    public void deregister_mode (Akira.Lib2.Modes.AbstractInteractionMode.ModeType mode_type) {
        if (active_mode != null && active_mode.mode_type () == mode_type) {
            inner_deregister_active_mode (true);
        } else if (pan_mode != null && pan_mode.mode_type () == mode_type) {
            stop_panning_mode ();
        }
    }

    /*
     * Deregister the currently active mode.
     */
    public void deregister_active_mode () {
        if (active_mode != null) {
            inner_deregister_active_mode (true);
        }
    }

    /*
     * Start panning mode that will mask any existing mode. Also, other modes may be started
     * during panning mode in certain conditions.
     */
    public void start_panning_mode () {
        if (pan_mode != null) {
            return;
        }

        pan_mode = new Akira.Lib2.Modes.PanMode (view_canvas);
        pan_mode.request_deregistration.connect (on_deregistration_request);
        pan_mode.mode_begin ();

        view_canvas.interaction_mode_changed ();
    }

    /*
     * Stops panning mode.
     */
    public void stop_panning_mode () {
        if (pan_mode != null) {
            inner_stop_panning_mode (true);
        }
    }

    /*
     * Inner panning mode stop method with optional notification to canvas.
     */
    private void inner_stop_panning_mode (bool notify) {
        pan_mode.request_deregistration.disconnect (on_deregistration_request);
        pan_mode.mode_end ();
        pan_mode = null;

        if (notify) {
            view_canvas.interaction_mode_changed ();
        }
    }

    /*
     * Inner mode deregistration method with optional notification to canvas.
     */
    private void inner_deregister_active_mode (bool notify) {
        active_mode.request_deregistration.disconnect (on_deregistration_request);
        active_mode.mode_end ();
        active_mode = null;

        if (notify) {
            view_canvas.interaction_mode_changed ();
        }
    }

    /*
     * Returns optional extra context. See InteractionMode for more details.
     */
    public Object? active_mode_extra_context () {
        if (pan_mode != null) {
            return pan_mode.extra_context ();
        }

        return active_mode != null ? active_mode.extra_context () : null;
    }

    /*
     * Returns cursor that should be used based on active modes.
     */
    public Gdk.CursorType? active_cursor_type () {
        if (pan_mode != null) {
            return pan_mode.cursor_type ();
        }

        return active_mode != null ? active_mode.cursor_type () : null;
    }

    public bool key_press_event (Gdk.EventKey event) {
        if (pan_mode != null && pan_mode.key_press_event (event)) {
            return false;
        }

        return (active_mode != null) ? active_mode.key_press_event (event) : false;
    }

    public bool key_release_event (Gdk.EventKey event) {
        if (pan_mode != null && pan_mode.key_release_event (event)) {
            return true;
        }

        return (active_mode != null) ? active_mode.key_release_event (event) : false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        if (pan_mode != null && pan_mode.button_press_event (event)) {
            return true;
        }

        return (active_mode != null) ? active_mode.button_press_event (event) : false;
    }

    public bool button_release_event (Gdk.EventButton event) {
        if (pan_mode != null && pan_mode.button_release_event (event)) {
            return true;
        }

        return (active_mode != null) ? active_mode.button_release_event (event) : false;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        if (pan_mode != null && pan_mode.motion_notify_event (event)) {
            return true;
        }

        return (active_mode != null) ? active_mode.motion_notify_event (event) : false;
    }

    private void on_deregistration_request (Lib2.Modes.AbstractInteractionMode.ModeType type) {
        deregister_mode (type);
    }
}
