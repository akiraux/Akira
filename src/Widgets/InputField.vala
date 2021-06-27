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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Widgets.InputField : Gtk.EventBox {
    public Gtk.SpinButton entry { get; construct set; }

    public int chars { get; construct set; }
    public bool rtl { get; construct set; }
    public bool icon_right { get; construct set; }
    public Unit unit { get; construct set; }
    public string? icon { get; set; }

    public double step { get; set; default = 1; }

    public enum Unit {
        PIXEL,
        HASH,
        PERCENTAGE,
        DEGREES,
        NONE
    }

    public InputField (
        Unit unit,
        int chars,
        bool icon_right = false,
        bool rtl = false) {
        Object (
            unit: unit,
            chars: chars,
            icon_right: icon_right,
            rtl: rtl
        );
    }

    construct {
        valign = Gtk.Align.CENTER;

        entry = new Gtk.SpinButton.with_range (0, 100, step);
        entry.hexpand = true;
        entry.width_chars = chars;
        entry.sensitive = false;

        entry.key_press_event.connect (handle_key_press);
        entry.scroll_event.connect (handle_scroll_event);
        entry.focus_in_event.connect (handle_focus_in);
        entry.focus_out_event.connect (handle_focus_out);

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
            default:
                icon = null;
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
        // Arrow UP
        if (event.keyval == Gdk.Key.Up && (event.state & Gdk.ModifierType.SHIFT_MASK) > 0) {
            entry.spin (Gtk.SpinType.STEP_FORWARD, 10);
            return true;
        }

        // Arrow DOWN
        if (event.keyval == Gdk.Key.Down && (event.state & Gdk.ModifierType.SHIFT_MASK) > 0) {
            entry.spin (Gtk.SpinType.STEP_BACKWARD, 10);
            return true;
        }

        // Enter or Escape
        if (event.keyval == Gdk.Key.Return || event.keyval == Gdk.Key.Escape) {
            Akira.Window window = get_toplevel () as Akira.Window;
            window.event_bus.set_focus_on_canvas ();
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
        Akira.Window window = get_toplevel () as Akira.Window;
        if (!(window is Akira.Window)) {
            return true;
        }
        window.event_bus.disconnect_typing_accel ();

        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        Akira.Window window = get_toplevel () as Akira.Window;
        if (!(window is Akira.Window)) {
            return true;
        }
        window.event_bus.connect_typing_accel ();

        return false;
    }
}
