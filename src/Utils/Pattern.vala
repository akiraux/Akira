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

public class Akira.Utils.Pattern {
    public static Cairo.Pattern convert_to_cairo_pattern (Lib.Components.Pattern pattern) {
        Cairo.Pattern converted;

        switch (pattern.type) {
            case Lib.Components.Pattern.PatternType.SOLID:
                var color = pattern.colors.first ().color;
                converted = new Cairo.Pattern.rgba (color.red, color.green, color.blue, color.alpha);
                return converted;
            case Lib.Components.Pattern.PatternType.LINEAR:
                converted = new Cairo.Pattern.linear (pattern.start.x, pattern.start.y, pattern.end.x, pattern.end.y);
                break;
            case Lib.Components.Pattern.PatternType.RADIAL:
                double distance = Utils.GeometryMath.distance (pattern.start.x, pattern.start.y, pattern.end.x, pattern.end.y);
                converted = new Cairo.Pattern.radial (
                    pattern.start.x,
                    pattern.start.y,
                    0,
                    pattern.start.x,
                    pattern.start.y,
                    distance
                );
                break;
            default:
                assert (false);
                converted = new Cairo.Pattern.rgba (0, 0, 0, 0);
                break;
        }

        // If the pattern was linear or radial, add all the stop colors.
        foreach (var stop_color in pattern.colors) {
            var color = stop_color.color;
            converted.add_color_stop_rgba (
                stop_color.offset,
                color.red,
                color.green,
                color.blue,
                color.alpha
            );
        }

        return converted;
    }

    public static Cairo.Pattern default_pattern () {
        return new Cairo.Pattern.rgba (1, 1, 1, 1);
    }

    // In Components.Pattern, the start and end positions of gradients are stored as 
    // relative positions as percentages of width and height of canvas item.
    // This method will convert those values to actual values, to be stored in CompiledFill.
    public static Lib.Components.Pattern create_pattern_with_converted_positions (Lib.Components.Pattern pattern, Lib.Components.Size size, Lib.Components.Coordinates center) {
        var new_pattern = pattern.copy ();

        new_pattern.start = Geometry.Point (
            pattern.start.x * size.width / 100.0 - size.width / 2.0,
            pattern.start.y * size.height / 100.0 - size.height / 2.0
        );
        new_pattern.end = Geometry.Point (
            pattern.end.x * size.width / 100.0 - size.width / 2.0,
            pattern.end.y * size.height / 100.0 - size.height / 2.0
        );

        return new_pattern;
    }

    public static string convert_to_css_linear_gradient (Lib.Components.Pattern pattern) {
        if (pattern.type == Lib.Components.Pattern.PatternType.SOLID) {
            var color = pattern.get_first_color ().to_string ();
            return """linear-gradient(to right, %s, %s)""".printf (color, color);
        }

        string css_result = "linear-gradient(to right";

        foreach (var stop_color in pattern.colors) {
            css_result += """ ,%s %f""".printf (stop_color.color.to_string (), stop_color.offset * 100.0);
            css_result += "%";
        }

        css_result += ")";
        return css_result;
    }
}
