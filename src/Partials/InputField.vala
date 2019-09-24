/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Partials.InputField : Gtk.Grid {
    public Gtk.Entry entry { get; construct set; }

    public int chars { get; construct set; }
    public bool rtl { get; construct set; }
    public bool icon_right { get; construct set; }
    public Unit unit { get; construct set; }
    public string icon { get; set; }

    public enum Unit {
        PIXEL,
        HASH,
        PERCENTAGE,
        DEGREES
    }

    public Gtk.Grid spin_grid { get; construct set; }
    public Gtk.Button button_up { get; construct set; }
    public Gtk.Button button_down { get; construct set; }

    public InputField (Unit unit, int chars, bool icon_right = false, bool rtl = false) {
        Object (
            unit: unit,
            chars: chars,
            icon_right: icon_right,
            rtl: rtl
        );
    }

    construct {
        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.width_chars = chars;
        //  entry.sensitive = false;

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
        }

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

        if (rtl) {
            entry.xalign = 1.0f;
        }

        entry.key_press_event.connect (handle_key);

        spin_grid = new Gtk.Grid ();
        spin_grid.get_style_context ().add_class ("input-button-grid");
        spin_grid.visible = false;
        spin_grid.no_show_all = true;

        button_up = new Gtk.Button.from_icon_name ("pan-up-symbolic", Gtk.IconSize.MENU);
        button_up.get_style_context ().add_class ("input-button-up");
        button_down = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button_down.get_style_context ().add_class ("input-button-down");
        spin_grid.attach (button_up, 0, 0, 1, 1);
        spin_grid.attach (button_down, 0, 1, 1, 1);

        attach (entry, 0, 0, 1, 1);
        attach (spin_grid, 1, 0, 1, 1);

        entry.enter_notify_event.connect (event => {
            spin_grid.visible = true;
            spin_grid.show_all ();
            return false;
        });

        entry.leave_notify_event.connect (event => {
            spin_grid.visible = false;
            spin_grid.no_show_all = true;
            return false;
        });
    }

    private bool handle_key (Gdk.EventKey key) {
        debug (Gdk.Key.uparrow.to_string ());
        // Arrow UP
        if (key.keyval == 65362) {
            int num = key.state == Gdk.ModifierType.SHIFT_MASK ? 10 : 1;
            double src = double.parse (entry.text) + num;
            entry.text = src.to_string ();
            return true;
        }

        // Arrow DOWN
        if (key.keyval == 65364) {
            int num = key.state == Gdk.ModifierType.SHIFT_MASK ? 10 : 1;
            double src = double.parse (entry.text) - num;
            entry.text = src.to_string ();
            return true;
        }

        return false;
    }
}
