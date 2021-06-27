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

public class Akira.Widgets.ColorField : Gtk.Entry {
    private unowned Akira.Window window;

    public ColorField (Akira.Window window) {
        this.window = window;

        margin_end = margin_start = 10;
        width_chars = 8;
        max_length = 7;
        hexpand = true;

        focus_in_event.connect (handle_focus_in);
        focus_out_event.connect (handle_focus_out);
        insert_text.connect (handle_insert_text);
        key_press_event.connect (handle_key_press);
    }

    ~ColorField () {
        focus_in_event.disconnect (handle_focus_in);
        focus_out_event.disconnect (handle_focus_out);
        insert_text.disconnect (handle_insert_text);
        key_press_event.disconnect (handle_key_press);
    }

    private void handle_insert_text (string text, int length, ref int position) {
        string new_text = text.strip ();

        if (new_text.contains ("#")) {
            new_text = new_text.substring (1, new_text.length - 1);
        } else if (!this.text.contains ("#")) {
            GLib.Signal.stop_emission_by_name (this, "insert-text");

            var builder = new StringBuilder ();
            builder.append (new_text);
            builder.prepend ("#");
            this.text = builder.str;

            position = this.text.length;
        }

        bool is_valid_hex = true;
        bool char_is_numeric = true;
        bool char_is_valid_alpha = true;

        char keyval;

        for (var i = 0; i < new_text.length; i++) {
            keyval = new_text [i];

            char_is_numeric = keyval >= Gdk.Key.@0 && keyval <= Gdk.Key.@9;
            char_is_valid_alpha = keyval >= Gdk.Key.A && keyval <= Gdk.Key.F;

            is_valid_hex &= keyval.isxdigit ();
        }

        if (!is_valid_hex) {
            GLib.Signal.stop_emission_by_name (this, "insert-text");
            return;
        }
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        window.event_bus.connect_typing_accel ();
        return false;
    }

    private bool handle_key_press (Gdk.EventKey event) {
        // Enter or Escape
        if (event.keyval == Gdk.Key.Return || event.keyval == Gdk.Key.Escape) {
            window.event_bus.set_focus_on_canvas ();
            return true;
        }

        return false;
    }
}
