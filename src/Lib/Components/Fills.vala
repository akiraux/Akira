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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/**
 * Fills component to keep track of the item's filling colors, which have to account
 * for the global opacity as well when rendering the item.
 */
public class Akira.Lib.Components.Fills : Component {
    // A list of all the fills the item might have.
    public Gee.ArrayList<Fill> fills { get; set; }

    // Keep track of the newly created Fill child components.
    private int id { get; set; default = 0; }

    public Fills (Items.CanvasItem _item, Gdk.RGBA color) {
        item = _item;
        fills = new Gee.ArrayList<Fill> ();

        add_fill_color (color);
    }

    /**
     * Create a new fill color component.
     *
     * @param {Gdk.RGBA} color - The initial color of the fill.
     * @return Fill - The newly created fill component.
     */
    public Fill add_fill_color (Gdk.RGBA color) {
        var new_fill = new Fill (this, item, color, id);
        fills.add (new_fill);

        // Increase the ID to keep an incremental unique identifier.
        id++;

        // Trigger the generation of the fill color.
       reload ();

        return new_fill;
    }

    public int count () {
        return fills.size;
    }

    /**
     * Loop through all the fill colors and create a final blend.
     */
    public void reload () {
        // If we don't have any fill associated with this item, remove the background color.
        if (count () == 0) {
            if (item is Items.CanvasArtboard) {
                ((Items.CanvasArtboard) item).background.set ("fill-color-rgba", null);
                ((Items.CanvasArtboard) item).background.set ("fill-pattern", null);
            } else {
                item.set ("fill-color-rgba", null);
                item.set ("fill-pattern", null);
            }
            return;
        }

        bool has_colors = false;
        // Set an initial arbitrary color with full transparency.
        var rgba_fill = Gdk.RGBA ();
        rgba_fill.alpha = 0;

        // Loop through all the configured fills.
        foreach (Fill fill in fills) {
            // Skip if the fill is hidden as we don't need to blend colors.
            if (fill.hidden) {
                continue;
            }

            var stop_colors = 0;
            fill.gradient_pattern.get_color_stop_count (out stop_colors);

            // if for this fill, either of the gradient modes have been selected,
            // the stop_colors value would not be zero.
            if (stop_colors != 0 && has_colors == false) {
                if (item is Items.CanvasArtboard) {
                    ((Items.CanvasArtboard) item).background.set ("fill-pattern", fill.gradient_pattern);
                } else {
                    item.set ("fill-pattern", fill.gradient_pattern);                    double x0, y0, x1, y1;
                    fill.gradient_pattern.get_linear_points(out x0, out y0, out x1, out y1);
                }

                // since we dont have the functionality of blending gradients,
                return;
            }
            // Set the new blended color.
            rgba_fill = Utils.Color.blend_colors (rgba_fill, fill.color);
            has_colors = true;
        }

        // Apply the mixed RGBA value only if we had one.
        if (has_colors) {
            // Keep in consideration the global opacity to properly update the fill color.
            rgba_fill.alpha = rgba_fill.alpha * item.opacity.opacity / 100;

            uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);

            if (item is Items.CanvasArtboard) {
                ((Items.CanvasArtboard) item).background.set ("fill-color-rgba", fill_color_rgba);
            } else {
                item.set ("fill-color-rgba", fill_color_rgba);
            }
        } else {
            if (item is Items.CanvasArtboard) {
                ((Items.CanvasArtboard) item).background.set ("fill-color-rgba", null);
            } else {
                item.set ("fill-color-rgba", null);
            }
        }
    }

    public void remove_fill (Fill fill) {
        fills.remove (fill);
        reload ();
    }

    /**
     * Helper method to allow the global shortcut action to update the fill color.
     */
     public void update_color_from_action (Gdk.RGBA color) {
        // If no fill color is available, create a new one.
        if (count () == 0) {
            add_fill_color (color);
            return;
        }

        // Get the first fill color since the user is using the global color picker.
        Fill first = fills.get (0);
        first.color = color;
        reload ();
    }
}
