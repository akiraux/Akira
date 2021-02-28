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
            } else {
                item.set ("fill-color-rgba", null);
            }
            return;
        }

        bool has_colors = false;
        double alpha = 0;
        double red = 0;
        double blue = 0;
        double green = 0;

        // alpha = 0.25 + 0.85 * (1 - 0.25) = 0.8875
        // red   = (57 * 0.25 + 255 * 0.85 * (1 - 0.25)) / 0.8875 = 199.2
        // green = (40 * 0.25 + 255 * 0.85 * (1 - 0.25)) / 0.8875 = 194.4
        // blue  = (28 * 0.25 + 255 * 0.85 * (1 - 0.25)) / 0.8875 = 191.1

        // Loop through all the configured fill.
        foreach (Fill fill in fills) {
            // Skip if the fill is hidden.
            if (fill.hidden) {
                continue;
            }

            // warning ("%f, %f, %f, %f", fill.color.red, fill.color.green, fill.color.blue, fill.color.alpha);

            // alpha += ((double) fill.alpha) / 255;
            // red += ((double) fill.color.red) * fill.color.alpha;
            // green += ((double) fill.color.green) * fill.color.alpha;
            // blue += ((double) fill.color.blue) * fill.color.alpha;
            alpha += fill.color.alpha;
            red += fill.color.red * fill.color.alpha;
            green += fill.color.green * fill.color.alpha;
            blue += fill.color.blue * fill.color.alpha;

            has_colors = true;
        }

        // Calculate the mixed RGBA only if all the values are valid.
        if (has_colors) {
            // Keep in consideration the global opacity to properly update the fill color.
            // double final_alpha = alpha * (1 - 0.25);

            // var rgba_fill = Gdk.RGBA ();
            // rgba_fill.red = (red * (1 - 0.25)) / final_alpha;
            // rgba_fill.green = (green * (1 - 0.25)) / final_alpha;
            // rgba_fill.blue = (blue * (1 - 0.25)) / final_alpha;
            // rgba_fill.alpha = final_alpha;
            double final_alpha = alpha / count ();

            var rgba_fill = Gdk.RGBA ();
            rgba_fill.red = red / final_alpha;
            rgba_fill.green = green / final_alpha;
            rgba_fill.blue = blue / final_alpha;
            rgba_fill.alpha = final_alpha * item.opacity.opacity / 100;

            warning ("%f, %f, %f, %f", rgba_fill.red, rgba_fill.green, rgba_fill.blue, rgba_fill.alpha);

            uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);

            if (item is Items.CanvasArtboard) {
                ((Items.CanvasArtboard) item).background.set ("fill-color-rgba", fill_color_rgba);
            } else {
                item.set ("fill-color-rgba", fill_color_rgba);
            }
        } else {
            warning ("HERE");
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
