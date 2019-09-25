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

public class Akira.Partials.InputField : Gtk.EventBox {
    public Gtk.Entry entry { get; construct set; }
    public Gtk.Overlay overlay { get; construct set; }

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
    public Gtk.EventBox button_up { get; construct set; }
    public Gtk.EventBox button_down { get; construct set; }

    public InputField (Unit unit, int chars, bool icon_right = false, bool rtl = false) {
        Object (
            unit: unit,
            chars: chars,
            icon_right: icon_right,
            rtl: rtl
        );
    }

    construct {
        overlay = new Gtk.Overlay ();

        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.width_chars = chars;
        entry.sensitive = false;

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
        spin_grid.halign = Gtk.Align.END;
        spin_grid.valign = Gtk.Align.FILL;
        spin_grid.opacity = 0;

        var button_up_image = new Gtk.Image.from_icon_name ("pan-up-symbolic", Gtk.IconSize.MENU);
        button_up_image.get_style_context ().add_class ("input-button");
        button_up_image.opacity = 0.6;

        button_up = new Gtk.EventBox ();
        button_up.add (button_up_image);
        button_up.event.connect (button_up_event);

        button_up.enter_notify_event.connect (event => {
            button_up_image.opacity = 1;
            return false;
        });
        button_up.leave_notify_event.connect (event => {
            button_up_image.opacity = 0.6;
            return false;
        });

        var button_down_image = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button_down_image.get_style_context ().add_class ("input-button");
        button_down_image.opacity = 0.6;

        button_down = new Gtk.EventBox ();
        button_down.add (button_down_image);
        button_down.event.connect (button_down_event);

        button_down.enter_notify_event.connect (event => {
            button_down_image.opacity = 1;
            return false;
        });
        button_down.leave_notify_event.connect (event => {
            button_down_image.opacity = 0.6;
            return false;
        });

        spin_grid.attach (button_up, 0, 0, 1, 1);
        spin_grid.attach (button_down, 0, 1, 1, 1);

        overlay.add (entry);
        overlay.add_overlay (spin_grid);
        add (overlay);

        enter_notify_event.connect (event => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                spin_grid.opacity = 1;
                if (icon_right) {
                    entry.secondary_icon_name = "";
                } else {
                    entry.primary_icon_name = "";
                }
            }
            return false;
        });

        leave_notify_event.connect (event => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                spin_grid.opacity = 0;
                if (icon_right) {
                    entry.secondary_icon_name = icon;
                } else {
                    entry.primary_icon_name = icon;
                }
            }
            return false;
        });
    }

    private bool handle_key (Gdk.EventKey key) {
        // Arrow UP
        if (key.keyval == 65362) {
            increase_value (key);
            return true;
        }

        // Arrow DOWN
        if (key.keyval == 65364) {
            decrease_value (key);
            return true;
        }

        return false;
    }

    public void increase_value (Gdk.EventKey? key) {
        int num = key != null && key.state == Gdk.ModifierType.SHIFT_MASK ? 10 : 1;
        double src = double.parse (entry.text) + num;
        entry.text = src.to_string ();
    }

    public void decrease_value (Gdk.EventKey? key) {
        int num = key != null && key.state == Gdk.ModifierType.SHIFT_MASK ? 10 : 1;
        double src = double.parse (entry.text) - num;
        entry.text = src.to_string ();
    }

    public bool button_up_event (Gdk.Event event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            increase_value (null);
        }
        return false;
    }

    public bool button_down_event (Gdk.Event event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            decrease_value (null);
        }
        return false;
    }
}
