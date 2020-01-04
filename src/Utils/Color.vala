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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Utils.Color : Object {
    public static string rgba_to_hex (string rgba_string) {
        var rgba = Gdk.RGBA ();
        rgba.parse (rgba_string);

        return "#%02x%02x%02x".printf(
            (int) (rgba.red * 255),
            (int) (rgba.green * 255),
            (int) (rgba.blue * 255)
        );
    }

    public static string hex_to_rgba (string hex) {
        debug (@"Hex: $(hex)");
        var hex_values = hex.split ("#") [1];

        debug (@"hex values: $(hex_values)");

        return hex_values;
    }
}
