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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Widgets.InputField : Gtk.Grid {
    public enum Unit {
        PIXEL,
        HASH,
        PERCENTAGE,
        DEGREES,
        NONE
    }

    public unowned Lib.ViewCanvas view_canvas { get; construct; }
    public Gtk.SpinButton entry { get; construct set; }

    private double step { get; set; default = 1; }

    public InputField (
        Lib.ViewCanvas canvas,
        Unit unit,
        int chars,
        bool icon_right = false,
        bool rtl = false
    ) {
        Object (view_canvas: canvas);

        valign = Gtk.Align.CENTER;


        Gtk.Adjustment adj = new Gtk.Adjustment (0, -double.MAX, double.MAX, 0.01, 0.1, 0.0);
        double climb_rate = 0.01;
        uint digits = 2;
        if (unit == Unit.PERCENTAGE) {
            digits = 0;
            adj.configure (0, 0, 100, 1.0, 1.0, 0.0);
        }

        entry = new Gtk.SpinButton (adj, climb_rate, digits) {
            hexpand = true,
            width_chars = chars,
            sensitive = false
        };

        entry.key_press_event.connect (handle_key_press);
        entry.scroll_event.connect (handle_scroll_event);
        entry.focus_in_event.connect (handle_focus_in);
        entry.focus_out_event.connect (handle_focus_out);

        string? icon = null;
        switch (unit) {
            case Unit.HASH:
                icon = "input-hash-symbolic";
                break;
            case Unit.PERCENTAGE:
                icon = "input-percentage-symbolic";
                break;
            case Unit.PIXEL:
                icon = "input-pixel-symbolic";
                break;
            case Unit.DEGREES:
                icon = "input-degrees-symbolic";
                break;
            case Unit.NONE:
                // No icon needs to be shown.
                break;
        }

        if (icon != null) {
            if (icon_right) {
                entry.get_style_context ().add_class ("input-icon-right");
                entry.secondary_icon_name = icon;
                entry.secondary_icon_sensitive = false;
                entry.secondary_icon_activatable = false;
            } else {
                entry.get_style_context ().add_class ("input-icon-left");
                entry.primary_icon_name = icon;
                entry.primary_icon_sensitive = false;
                entry.primary_icon_activatable = false;
            }
        }

        if (rtl) {
            entry.xalign = 1.0f;
        }

        add (entry);
    }

    public void set_range (double min_value, double max_value) {
        entry.set_range (min_value, max_value);
    }

    private bool handle_key_press (Gdk.EventKey event) {
        // Arrow UP.
        if (event.keyval == Gdk.Key.Up && view_canvas.shift_is_pressed) {
            entry.spin (Gtk.SpinType.STEP_FORWARD, 10);
            return true;
        }

        // Arrow DOWN.
        if (event.keyval == Gdk.Key.Down && view_canvas.shift_is_pressed) {
            entry.spin (Gtk.SpinType.STEP_BACKWARD, 10);
            return true;
        }

        // Enter or Escape.
        if (event.keyval == Gdk.Key.Return || event.keyval == Gdk.Key.Escape) {
            view_canvas.window.event_bus.set_focus_on_canvas ();
            return true;
        }

        return false;
    }

    private bool handle_scroll_event (Gdk.EventScroll event) {
        // If the input field is not focused, don't change the value.
        if (!entry.has_focus) {
            return true;
        }
        return false;
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        view_canvas.window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        view_canvas.window.event_bus.connect_typing_accel ();
        return false;
    }
}
