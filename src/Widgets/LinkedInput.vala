/*
 * Copyright (c) 2019-2022 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ana Gelez <ana@gelez.xyz>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 * A digit input with a label next to it.
 */
public class Akira.Widgets.LinkedInput : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public InputField input_field { get; set; }

    /**
    * Used to avoid to infinitely updating when value is set externally.
    */
    private bool dragging = false;
    private double dragging_direction = 0;

    public LinkedInput (
        Lib.ViewCanvas canvas,
        string label,
        string tooltip = "",
        InputField.Unit icon = InputField.Unit.PIXEL,
        bool reversed = false
    ) {
        Object (view_canvas: canvas);

        valign = Gtk.Align.CENTER;
        hexpand = true;
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        var entry_label = new Gtk.Label (label) {
            halign = Gtk.Align.CENTER,
            width_request = 20,
            hexpand = false,
            tooltip_text = tooltip
        };
        entry_label.get_style_context ().add_class ("entry-label");

        input_field = new Widgets.InputField (view_canvas, icon, 7, true, false);

        if (reversed) {
            attach (input_field, 0, 0);
            attach (entry_label, 1, 0);
        } else {
            attach (entry_label, 0, 0);
            attach (input_field, 1, 0);
        }
    }

    public bool handle_event (Gdk.Event event) {
        if (!input_field.entry.sensitive) {
            return false;
        }

        if (event.type == Gdk.EventType.ENTER_NOTIFY) {
            set_cursor_from_name ("ew-resize");
        }

        if (event.type == Gdk.EventType.LEAVE_NOTIFY) {
            set_cursor (Gdk.CursorType.ARROW);
        }

        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            dragging = true;
        }

        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            dragging = false;
            dragging_direction = 0;
        }

        if (event.type == Gdk.EventType.MOTION_NOTIFY && dragging) {
            if (dragging_direction == 0) {
                dragging_direction = event.motion.x;
            }

            if (dragging_direction > event.motion.x || event.motion.x_root == 0) {
                input_field.entry.spin (Gtk.SpinType.STEP_BACKWARD, 1);
            } else {
                input_field.entry.spin (Gtk.SpinType.STEP_FORWARD, 1);
            }
            dragging_direction = event.motion.x;
        }

        return false;
    }

    private void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    private void set_cursor_from_name (string name) {
        var cursor = new Gdk.Cursor.from_name (Gdk.Display.get_default (), name);
        get_window ().set_cursor (cursor);
    }
}
