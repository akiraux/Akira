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
    public string unit { get; construct set; }
    public string icon { get; set; }

    public InputField (string unit, int chars, bool rtl) {
        Object (
            unit: unit,
            chars: chars,
            rtl: rtl
        );
    }

    construct {
        hexpand = false;
        width_chars = chars;

        switch (unit) {
            case "%":
                icon = "input-percentage-symbolic";
            break;
            case "px":
                icon = "input-pixel-symbolic";
            break;
        }
        
        secondary_icon_name = icon;
        secondary_icon_sensitive = false;

        if (rtl) {
            xalign = 1.0f;
        }
    }
}