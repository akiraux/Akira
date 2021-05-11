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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

public struct Akira.Lib2.Components.Color {
    public Gdk.RGBA _rgba;
    public bool _hidden;

    public Color (double r = 0.0, double g = 0.0, double b = 0.0, double a = 1.0, bool hidden = false) {

        _rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = a };
    }

    public static Color from_rgba (Gdk.RGBA rgba, bool hidden = false) {
        return Color (rgba.red, rgba.green, rgba.blue, rgba.alpha, hidden);
    }

    // Recommended accessors

    public Gdk.RGBA rgba () { return _rgba; }
    public bool is_hidden () { return _hidden; }

    // Mutators
    public Color with_hidden (bool hidden) { return Color (_rgba.red, _rgba.green, _rgba.blue, _rgba.alpha, _hidden); }
}
