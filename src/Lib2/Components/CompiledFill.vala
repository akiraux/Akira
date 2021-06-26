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

public class Akira.Lib2.Components.CompiledFill : Copyable<CompiledFill> {
    private Gdk.RGBA _color;
    private bool _visible;

    public Gdk.RGBA color {
        get { return _color; }
    }

    public bool is_visible {
        get { return _visible; }
    }

    public CompiledFill (Gdk.RGBA color, bool visible) {
        _color = color;
        _visible = visible;
    }

    public CompiledFill copy () {
        return new CompiledFill (_color, _visible);
    }

    public static CompiledFill compile (Components? components, Lib2.Items.ModelNode? node) {
        var rgba_fill = Gdk.RGBA ();
        bool has_colors = false;
        // Set an initial arbitrary color with full transparency.
        rgba_fill.alpha = 0;

        if (components == null) {
            return new CompiledFill (rgba_fill, has_colors);
        }

        unowned var fills = components.fills;
        unowned var opacity = components.opacity;

        if (fills == null) {
            return new CompiledFill (rgba_fill, has_colors);
        }

        // Loop through all the configured fills.
        for (var i = 0; i < fills.data.length; ++i) {
            // Skip if the fill is hidden as we don't need to blend colors.
            if (fills.data[i].is_color_hidden ()) {
                continue;
            }

            // Set the new blended color.
            rgba_fill = Utils.Color.blend_colors (rgba_fill, fills.data[i].color ());
            has_colors = true;
        }

        // Apply the mixed RGBA value only if we had one.
        if (has_colors && opacity != null) {
            // Keep in consideration the global opacity to properly update the fill color.
            rgba_fill.alpha = rgba_fill.alpha * opacity.opacity / 100;
        }

        return new CompiledFill (rgba_fill, has_colors);
    }
}
