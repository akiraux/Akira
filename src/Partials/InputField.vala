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

public class Akira.Partials.InputField : Gtk.Entry {
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

    public InputField (Unit unit, int chars, bool icon_right = false, bool rtl = false) {
        Object (
            unit: unit,
            chars: chars,
            icon_right: icon_right,
            rtl: rtl
        );
    }

    construct {
        hexpand = true;
        width_chars = chars;

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
            secondary_icon_name = icon;
            secondary_icon_sensitive = false;
        } else {
            primary_icon_name = icon;
            primary_icon_sensitive = false;
        }

        if (rtl) {
            xalign = 1.0f;
        }
    }
}
