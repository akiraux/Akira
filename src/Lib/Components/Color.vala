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

public struct Akira.Lib.Components.Color {
    public Gdk.RGBA rgba;
    public bool hidden;

    public Color (double r = 0.0, double g = 0.0, double b = 0.0, double a = 1.0, bool hidden = false) {
        rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = a };
    }

    public Color.from_rgba (Gdk.RGBA rgba, bool hidden = false) {
        this.rgba = rgba;
        this.hidden = hidden;
    }

    public Color.deserialized (Json.Object obj) {
        var r = obj.get_double_member ("r");
        var g = obj.get_double_member ("g");
        var b = obj.get_double_member ("b");
        var a = obj.get_double_member ("a");
        rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = a };
        hidden = obj.get_boolean_member ("hidden");
    }

    public Json.Node serialize () {
            var obj = new Json.Object ();
            obj.set_double_member ("r", rgba.red);
            obj.set_double_member ("g", rgba.green);
            obj.set_double_member ("b", rgba.blue);
            obj.set_double_member ("a", rgba.alpha);
            obj.set_boolean_member ("hidden", hidden);
            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (obj);
            return node;
    }

    // Mutators
    public Color with_hidden (bool hidden) { return Color (rgba.red, rgba.green, rgba.blue, rgba.alpha, hidden); }
}
