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

public class Akira.Lib.Components.CompiledFill : Copyable<CompiledFill> {
    private Pattern _pattern;
    private bool _visible;

    public Pattern pattern {
        get { return _pattern; }
    }

    public bool is_visible {
        get { return _visible; }
    }

    public CompiledFill (Pattern pattern, bool visible) {
        _pattern = pattern;
        _visible = visible;
    }

    public CompiledFill.as_empty () {
        _pattern = new Pattern.solid (Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 0}, false);
        _visible = false;
    }

    public CompiledFill copy () {
        return new CompiledFill (_pattern, _visible);
    }

    public static CompiledFill compile (Components? components, Lib.Items.ModelNode? node) {
        var pattern_fill = new Pattern ();
        bool has_colors = false;

        if (components == null) {
            return new CompiledFill (pattern_fill, has_colors);
        }

        unowned var fills = components.fills;
        unowned var opacity = components.opacity;

        if (fills == null) {
            return new CompiledFill (pattern_fill, has_colors);
        }

        // Loop through all the configured fills.
        for (var i = 0; i < fills.data.length; ++i) {
            // Skip if the fill is hidden as we don't need to blend colors.
            if (fills.data[i].hidden) {
                continue;
            }

            // Set the new blended color.
            //  rgba_fill = Utils.Color.blend_colors (rgba_fill, fills.data[i].pattern.get_first_color ());
            pattern_fill = fills.data[i].pattern;
            has_colors = true;

            // TODO: Temporarily disable blending patterns. Not implemented.
            break;
        }

        // Apply the mixed RGBA value only if we had one.
        if (has_colors && opacity != null) {
            // Keep in consideration the global opacity to properly update the fill color.
            // TODO: Disable this too.
            //  rgba_fill.alpha = rgba_fill.alpha * opacity.opacity / 100;
        }

        return new CompiledFill (pattern_fill, has_colors);
    }
}
