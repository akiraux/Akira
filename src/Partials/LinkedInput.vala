/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Ana Gelez <ana@gelez.xyz>
*/

/**
* A digit input with a label next to it.
*/
public class Akira.Partials.LinkedInput : Gtk.Grid {
    public string label { get; construct set; }
    public Akira.Partials.InputField input_field { get; construct set; }

    /**
    * Indicates wheter the label or the entry should be first
    */
    public bool reversed { get; construct set; }
    public string unit { get; construct set; }
    public double limit { get; set; }
    public double value { get; set; }
    public InputField.Unit icon { get; construct set;}

    /**
    * Used to avoid to infinitely updating two linked data
    * (for instance width and height when their ratio is locked).
    */
    private bool manually_edited = true;

    public LinkedInput (string label, string unit = "", bool reversed = false,
                        double default_val = 0, double limit = 0.0) {
        Object (
            label: label,
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

        var entry_label = new Gtk.Label (label);
        entry_label.get_style_context ().add_class ("entry-label");
        entry_label.halign = Gtk.Align.CENTER;
        entry_label.width_request = 20;
        entry_label.hexpand = false;

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

        input_field = new Akira.Partials.InputField (icon, 7, true, false);
        input_field.entry.notify["text"].connect (() => {
            if (manually_edited) {
                // Remove unwanted characters.
                var text_canon = input_field.entry.text.replace (",", ".");
                text_canon.canon ("-0123456789.", '?');
                input_field.entry.text = text_canon.replace ("?", "");

                // If limit is specified, force it as a value.
                var new_val = double.parse (input_field.entry.text);
                if (limit > 0.0 && new_val > limit) {
                    input_field.entry.text = limit.to_string ();
                }
            }
        });
        notify["value"].connect (() => {
            // Remove trailing 0.
            var format_value = "%f".printf (value).replace (",", ".");
            while (format_value.has_suffix ("0") && format_value != "0") {
                format_value = format_value.slice (0, -1);
            }
            if (format_value.has_suffix (".")) {
                format_value += "0";
            }

            manually_edited = false;
            input_field.entry.text = "%s".printf (format_value);
            manually_edited = true;
        });

        if (reversed) {
            attach (input_field, 0, 0);
            attach (entry_label, 1, 0);
        } else {
            attach (entry_label, 0, 0);
            attach (input_field, 1, 0);
        }
    }
}
