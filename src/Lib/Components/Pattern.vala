
/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.Lib.Components.Pattern {
    public enum PatternType {
        SOLID = 0,
        LINEAR = 1,
        RADIAL = 2,
    }

    public struct StopColor {
        // Value between 0 and 1. Represents what distance the stop color is located at.
        public double offset;
        public Gdk.RGBA color;

        public StopColor.deserialized (Json.Object obj) {
            offset = obj.get_double_member ("offset");

            color = Gdk.RGBA ();
            color.red = obj.get_double_member ("red");
            color.green = obj.get_double_member ("green");
            color.blue = obj.get_double_member ("blue");
            color.alpha = obj.get_double_member ("alpha");
        }

        public Json.Node serialize () {
            var obj = new Json.Object ();

            obj.set_double_member ("offset", offset);
            obj.set_double_member ("red", color.red);
            obj.set_double_member ("green", color.green);
            obj.set_double_member ("blue", color.blue);
            obj.set_double_member ("alpha", color.alpha);

            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (obj);
            return node;
        }
    }

    public PatternType type;
    public Gee.TreeSet<StopColor?> colors;
    public bool hidden;

    // These values denote the position of guide points of gradients.
    // The values are relative to the canvas item's position.
    public Geometry.Point start;
    public Geometry.Point end;

    public Pattern.solid (Gdk.RGBA color, bool hidden) {
        this.type = PatternType.SOLID;
        this.hidden = hidden;

        colors = new Gee.TreeSet<StopColor?> (are_equal);
        colors.add (StopColor () {offset = 0, color = color});
    }

    public Pattern.linear (Geometry.Point start, Geometry.Point end, bool hidden) {
        this.start = start;
        this.end = end;

        // By default, all linear gradients will be created with black and white colors at start and end.
        colors = new Gee.TreeSet<StopColor?> (are_equal);
        colors.add (StopColor () {offset = 0, color = Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 1}});
        colors.add (StopColor () {offset = 1, color = Gdk.RGBA () {red = 1, green = 1, blue = 1, alpha = 1}});

        this.type = PatternType.LINEAR;
        this.hidden = hidden;
    }

    public Pattern.radial (Geometry.Point start, Geometry.Point end, bool hidden) {
        this.start = start;
        this.end = end;

        // By default, all linear gradients will be created with black and white colors at start and end.
        colors = new Gee.TreeSet<StopColor?> (are_equal);
        colors.add (StopColor () {offset = 0, color = Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 1}});
        colors.add (StopColor () {offset = 1, color = Gdk.RGBA () {red = 1, green = 1, blue = 1, alpha = 1}});

        this.type = PatternType.RADIAL;
        this.hidden = hidden;
    }

    public Pattern copy () {
        Pattern new_pattern = new Pattern ();

        new_pattern.type = this.type;
        new_pattern.colors = this.colors;
        new_pattern.hidden = this.hidden;
        new_pattern.start = this.start;
        new_pattern.end = this.end;

        return new_pattern;
    }

    public void add_stop_color (Gdk.RGBA color, double offset) {
        if (type == PatternType.SOLID) {
            // Adding stop colors for solid pattern is not allowed.
            assert (false);
        }

        colors.add (StopColor () {offset = offset, color = color});
    }

    public Gdk.RGBA get_first_color () {
        return colors.first ().color;
    }

    private int are_equal (StopColor? first, StopColor? second) {
        if (first.offset < second.offset) {
            return -1;
        } else if (first.offset > second.offset) {
            return 1;
        }

        return 0;
    }

    public Pattern.deserialized (Json.Object obj) {
        this.start = Geometry.Point.deserialized (obj.get_object_member ("start"));
        this.end = Geometry.Point.deserialized (obj.get_object_member ("end"));
        this.type = (PatternType) obj.get_int_member ("type");
        this.hidden = obj.get_boolean_member ("hidden");

        var color_array = obj.get_array_member ("colors");
        this.colors = new Gee.TreeSet<StopColor?> (are_equal);
        foreach (var color_item in color_array.get_elements ()) {
            colors.add (StopColor.deserialized (color_item.get_object ()));
        }
    }

    public Json.Node serialize () {
        var obj = new Json.Object ();
        obj.set_member ("start", start.serialize ());
        obj.set_member ("end", end.serialize ());
        obj.set_int_member ("type", (int) type);
        obj.set_boolean_member ("hidden", hidden);

        var color_array = new Json.Array ();
        foreach (var color in colors) {
            color_array.add_element (color.serialize ());
        }

        obj.set_array_member ("colors", color_array);

        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (obj);
        return node;
    }
}
