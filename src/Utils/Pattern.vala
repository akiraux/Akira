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
                break;
            case Lib.Components.Pattern.PatternType.LINEAR:
                converted = new Cairo.Pattern.linear (pattern.start.x, pattern.start.y, pattern.end.x, pattern.end.y);

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
                break;
            case Lib.Components.Pattern.PatternType.RADIAL:
                converted = new Cairo.Pattern.radial (
                    pattern.start.x,
                    pattern.start.y,
                    pattern.radius_start,
                    pattern.end.x,
                    pattern.end.y,
                    pattern.radius_end
                );

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
                break;
            default:
                assert (false);
                converted = new Cairo.Pattern.rgba (0, 0, 0, 0);
                break;
        }

        return converted;
    }

    public static Cairo.Pattern default_pattern () {
        return new Cairo.Pattern.rgba (255, 255, 255, 255);
    }
}
