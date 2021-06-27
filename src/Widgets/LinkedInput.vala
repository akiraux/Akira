/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
    public string label { get; construct set; }
    public string tooltip { get; construct set; }
    public InputField input_field { get; construct set; }

    /**
    * Indicates whether the label or the entry should be first
    */
    public bool reversed { get; construct set; }
    public string unit { get; construct set; }
    public double limit { get; set; }
    public double value { get; set; }
    public InputField.Unit icon { get; construct set;}
    /**
    * Used to avoid to infinitely updating when value is set externally.
    */
    private bool dragging = false;
    private double dragging_direction = 0;
    public bool enabled {
        get {
            return input_field.entry.sensitive;
        }
        set {
            input_field.entry.sensitive = value;
        }
    }

    public LinkedInput (string label, string tooltip = "", string unit = "",
                        bool reversed = false, double default_val = 0, double limit = 0.0) {
        Object (
            label: label,
            tooltip: tooltip,
            reversed: reversed,
            value: default_val,
            limit: limit,
            unit: unit
        );
    }

    construct {
        valign = Gtk.Align.CENTER;
        hexpand = true;
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        var event_box = new Gtk.EventBox ();
        event_box.event.connect (handle_event);

        var entry_label = new Gtk.Label (label);
        entry_label.get_style_context ().add_class ("entry-label");
        entry_label.halign = Gtk.Align.CENTER;
        entry_label.width_request = 20;
        entry_label.hexpand = false;
        entry_label.tooltip_text = tooltip;

        switch (unit) {
            case "#":
                icon = InputField.Unit.HASH;
            break;
            case "%":
                icon = InputField.Unit.PERCENTAGE;
            break;
            case "px":
                icon = InputField.Unit.PIXEL;
            break;
            case "°":
                icon = InputField.Unit.DEGREES;
            break;
            default:
                icon = InputField.Unit.PIXEL;
            break;
        }

        input_field = new Widgets.InputField (icon, 7, true, false);
        bind_property (
            "value", input_field.entry, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

        event_box.add (entry_label);

        if (reversed) {
            attach (input_field, 0, 0);
            attach (event_box, 1, 0);
        } else {
            attach (event_box, 0, 0);
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
                dragging_direction = event.motion.x;
            } else {
                input_field.entry.spin (Gtk.SpinType.STEP_FORWARD, 1);
                dragging_direction = event.motion.x;
            }
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
