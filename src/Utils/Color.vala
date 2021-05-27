/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

/**
 * Helper object class containing all static methods for RGBA manipulation.
 */
public class Akira.Utils.Color : Object {
    public static string rgba_to_hex (string rgba_string) {
        var rgba = Gdk.RGBA ();
        rgba.parse (rgba_string);

        return rgba_to_hex_string (rgba);
    }

    public static string rgba_to_hex_string (Gdk.RGBA rgba) {
        return "#%02x%02x%02x".printf (
            (int) (rgba.red * 255),
            (int) (rgba.green * 255),
            (int) (rgba.blue * 255)
        );
    }

    public static Gdk.RGBA hex_to_rgba (string hex) {
        var rgba = Gdk.RGBA ();
        rgba.parse (hex);

        return rgba;
    }

    public static bool is_valid_hex (string hex) {
        if (hex == "") {
            return false;
        }

        // Interrupt if there is no '#' in the hex value. This prevents the app
        // from crashing when the user deletes the '#' already present in a
        // valid hex value.
        if (!hex.contains ("#")) {
            return false;
        }

        var hex_values = hex.split ("#") [1];

        if (hex_values.length != 3 && hex_values.length != 6) {
            return false;
        }

        // Since validation is done inside the insert-text
        // we can assume that, if it's arrived here
        // the content is only 0-9A-F
        return true;
    }

    public static uint rgba_to_uint (Gdk.RGBA rgba) {
        uint uint_rgba = 0;

        uint_rgba |= ((uint) (rgba.red * 255)) << 24;
        uint_rgba |= ((uint) (rgba.green * 255)) << 16;
        uint_rgba |= ((uint) (rgba.blue * 255)) << 8;
        uint_rgba |= ((uint) (rgba.alpha * 255));

        return uint_rgba;
    }

    public static Gdk.RGBA blend_colors (Gdk.RGBA base_color, Gdk.RGBA added_color) {
        // If the newly added color alpha is 0 we don't need to do any color mixing
        // as the added color won't alter the base color.
        if (added_color.alpha == 0.0) {
            return base_color;
        }

        // If the newly added color alpha is 1 or the base color alpha is 0
        // we don't need to do any color mixing, as the added color will be
        // the only one visible.
        if (added_color.alpha == 1.0 || base_color.alpha == 0) {
            return added_color;
        }

        // Simple blend using Alpha channels. In the future we will support
        // different blending modes.
        double alpha = 1 - (1 - added_color.alpha) * (1 - base_color.alpha);
        double ar1 = added_color.alpha / alpha;
        double ar2 = (1 - added_color.alpha) / alpha;

        double red = added_color.red * ar1 + base_color.red * base_color.alpha * ar2;
        double green = added_color.green * ar1 + base_color.green * base_color.alpha * ar2;
        double blue = added_color.blue * ar1 + base_color.blue * base_color.alpha * ar2;

        var rgba = Gdk.RGBA ();
        rgba.alpha = alpha;
        rgba.red = red;
        rgba.green = green;
        rgba.blue = blue;

        return rgba;
    }

    public static uint color_string_to_uint (string color) {
        var rgba = Gdk.RGBA ();
        rgba.parse (color);

        return rgba_to_uint (rgba);
    }
}
