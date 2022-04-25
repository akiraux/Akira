
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
    }

    public PatternType type;
    public Gee.TreeSet<StopColor?> colors;
    public bool hidden;

    // These values denote the position of guide points of gradients.
    // The values are relative to the canvas item's position.
    public Geometry.Point start;
    public Geometry.Point end;
    // These values are only used for radial gradients to denote radii.
    public double radius_start;
    public double radius_end;

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
        colors.add (StopColor () {offset = 0, color = Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 255}});
        colors.add (StopColor () {offset = 1, color = Gdk.RGBA () {red = 255, green = 255, blue = 255, alpha = 255}});

        this.type = PatternType.LINEAR;
        this.hidden = hidden;
    }

    public Pattern.radial () {
        // TODO:
    }

    public Pattern copy () {
        Pattern new_pattern = new Pattern ();

        new_pattern.type = this.type;
        new_pattern.colors = this.colors;
        new_pattern.hidden = this.hidden;
        new_pattern.start = this.start;
        new_pattern.end = this.end;
        new_pattern.radius_start = this.radius_start;
        new_pattern.radius_end = this.radius_end;

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
        // TODO: 
        hidden = obj.get_boolean_member ("hidden");
    }

    public Json.Node serialize () {
        // TODO: 
        var obj = new Json.Object ();
        //  obj.set_double_member ("r", rgba.red);
        //  obj.set_double_member ("g", rgba.green);
        //  obj.set_double_member ("b", rgba.blue);
        //  obj.set_double_member ("a", rgba.alpha);
        //  obj.set_boolean_member ("hidden", hidden);
        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (obj);
        return node;
    }
}
