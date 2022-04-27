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

public class Akira.Lib.Components.CompiledBorder : Copyable<CompiledBorder> {
    private Pattern _pattern;
    private double _size;
    private bool _visible;

    public Pattern pattern {
        get { return _pattern; }
    }

    public double size {
        get { return _size; }
    }

    public bool is_visible {
        get { return _visible; }
    }

    public CompiledBorder (Pattern pattern, double size, bool visible) {
        _pattern = pattern;
        _size = size;
        _visible = visible;
    }

    public CompiledBorder.as_empty () {
        _pattern = new Pattern.solid (Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 0}, false);
        _size = 0;
        _visible = false;
    }

    public CompiledBorder copy () {
        return new CompiledBorder (_pattern, size, _visible);
    }

    public static CompiledBorder compile (Components? components, Lib.Items.ModelNode? node) {
        var pattern_border = new Pattern ();
        bool has_colors = false;
        double border_size = 0;

        if (components == null) {
            return new CompiledBorder (pattern_border, border_size, has_colors);
        }

        unowned var borders = components.borders;
        unowned var opacity = components.opacity;
        unowned var size = components.size;
        unowned var center = components.center;

        if (borders == null) {
            return new CompiledBorder (pattern_border, border_size, has_colors);
        }

        // Loop through all the configured borders.
        for (var i = 0; i < borders.data.length; ++i) {
            // Skip if the border is hidden as we don't need to blend colors.
            if (borders.data[i].hidden) {
                continue;
            }

            // Set the new blended color.
            //  rgba_border = Utils.Color.blend_colors (rgba_border, borders.data[i].pattern.get_first_color ());
            pattern_border = Utils.Pattern.create_pattern_with_converted_positions (borders.data[i].pattern, size, center);
            has_colors = true;

            // TODO: Temporarily disable blending patterns. Not implemented.
            break;
        }

        // Apply the mixed RGBA value only if we had one.
        if (has_colors && opacity != null) {
            // Keep in consideration the global opacity to properly update the fill color.
            // TODO: Disable this too.
            //  rgba_border.alpha = rgba_border.alpha * opacity.opacity / 100;
        }

        return new CompiledBorder (pattern_border, border_size, has_colors);
    }
}
