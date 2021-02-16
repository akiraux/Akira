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
 * Border component to keep track of a single border, which includes different attributes.
 */
public class Akira.Lib.Components.Border : Component {
    // Since items can have multiple border colors, we need to keep track of each
    // with a unique identifier in order to properly update them.
    public int id { get; set; }

    public Gdk.RGBA color { get; set; }

    // Store the hexadecimal string version of the color (E.g.: #FF00CC)
    public string hex { get; set; }
    public int size { get; set; }
    public int alpha { get; set; }
    public bool hidden { get; set; }

    public Border (Items.CanvasItem _item, Gdk.RGBA init_color, int init_size, int border_id) {
        item = _item;
        id = border_id;
        color = init_color;
        size = init_size;
        alpha = 255;

        set_border ();
    }

    /**
     * Apply the properly converted border color to the item.
     */
    private void set_border () {
        // Make the item transparent if the color is set by hidden.
        if (hidden) {
            item.set ("stroke-color-rgba", null);
            item.set ("line-width", 0.0);
            hex = "";
            return;
        }

        // Store the color in a new RGBA variable so we can manipulate it.
        var rgba_fill = Gdk.RGBA ();
        rgba_fill = color;

        // Keep in consideration the global opacity to properly update the border color.
        rgba_fill.alpha = ((double) alpha) / 255 * item.opacity.opacity / 100;
        hex = Utils.Color.rgba_to_hex (rgba_fill.to_string ());

        // Temporarily set the item color here. This will be moved to the Borders component
        // once we enable multiple borders.
        item.set ("stroke-color-rgba", Utils.Color.rgba_to_uint (rgba_fill));
        // The "line-width" property expects a DOUBLE type, but we don't support subpixels
        // so we always handle the border size as INT, therefore we need to type cast it here.
        item.set ("line-width", (double) size);
    }

    /**
     * Helper method used by the Borders component to force a reset of of the applied colors.
     * This will most likely be removed once we start supporting multiple borders.
     */
    public void reload () {
        set_border ();
    }

    /**
     * Get the new hexadecimal string defined by the user and update the border color.
     */
    public void set_border_hex (string new_hex) {
        // Interrupt if the value didn't change.
        if (new_hex == hex) {
            return;
        }

        hex = new_hex;
        color.parse (hex);

        set_border ();
    }
}
