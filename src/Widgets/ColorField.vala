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

public class Akira.Widgets.ColorField : Gtk.Entry {
    private unowned Models.ColorModel model;

    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    public class SignalBlocker {
        private unowned ColorField item;

        public SignalBlocker (ColorField fill_item) {
            item = fill_item;
            item.block_signal += 1;
        }

        ~SignalBlocker () {
            item.block_signal -= 1;
        }
    }

    protected int block_signal = 0;

    public ColorField (Akira.Lib.ViewCanvas canvas) {
        Object (view_canvas: canvas);

        margin_end = margin_start = 10;
        width_chars = 8;
        max_length = 7;
        hexpand = true;

        changed.connect (on_changed);
        focus_in_event.connect (on_focus_in);
        focus_out_event.connect (on_focus_out);
        insert_text.connect (on_insert_text);
        key_press_event.connect (on_key_press);
    }

    ~ColorField () {
        focus_in_event.disconnect (on_focus_in);
        focus_out_event.disconnect (on_focus_out);
        insert_text.disconnect (on_insert_text);
        key_press_event.disconnect (on_key_press);
        model.value_changed.disconnect (on_model_changed);
    }

    public void assign (Models.ColorModel model) {
        this.model = model;
        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    private void on_model_changed () {
        var blocker = new SignalBlocker (this);
        (blocker);

        text = Utils.Color.rgba_to_hex_string (model.pattern.get_first_color ());
        sensitive = !model.hidden;
    }

    private void on_changed () {
        if (block_signal > 0) {
            return;
        }

        // Interrupt if what's written is not a valid color value.
        if (!Utils.Color.is_valid_hex (text)) {
            return;
        }

        var new_rgba = Utils.Color.hex_to_rgba (text);
        model.pattern = new Lib.Components.Pattern.solid (new_rgba, false);
    }

    private void on_insert_text (string text, int length, ref int position) {
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

    private bool on_focus_in (Gdk.EventFocus event) {
        view_canvas.window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private bool on_focus_out (Gdk.EventFocus event) {
        view_canvas.window.event_bus.connect_typing_accel ();
        return false;
    }

    private bool on_key_press (Gdk.EventKey event) {
        // Enter or Escape
        if (event.keyval == Gdk.Key.Return || event.keyval == Gdk.Key.Escape) {
            view_canvas.window.event_bus.set_focus_on_canvas ();
            return true;
        }

        return false;
    }
}
