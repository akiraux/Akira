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
 * Borders component to keep track of the item's border colors, which have to account
 * for the global opacity as well when rendering the item.
 */
public class Akira.Lib.Components.Borders : Component {
    // A list of all the borders the item might have.
    public Gee.ArrayList<Border> borders { get; set; }

    // Keep track of the newly created Fill child components.
    private int id { get; set; default = 0; }

    public Borders (Items.CanvasItem _item, Gdk.RGBA init_color, int init_size) {
        item = _item;
        borders = new Gee.ArrayList<Border> ();

        // Only add the initial border if the user configured it in the Settings.
        if (settings.set_border) {
            add_border_color (init_color, init_size);
        } else {
            reload ();
        }
    }

    /**
     * Create a new border color component.
     *
     * @param {Gdk.RGBA} color - The initial color of the border.
     * @return Fill - The newly created border component.
     */
    public Border add_border_color (Gdk.RGBA init_color, int init_size) {
        var new_border = new Border (this, item, init_color, init_size, id);
        borders.add (new_border);

        // Increase the ID to keep an incremental unique identifier.
        id++;

        return new_border;
    }

    public int count () {
        return borders.size;
    }

    public void reload () {
        // If we don't have any border associated with this item, remove the border color.
        if (count () == 0) {
            item.set ("stroke-color-rgba", null);
            item.set ("line-width", 0.0);
            return;
        }

        // Loop through all the configured borders and reload the color.
        foreach (Border border in borders) {
            border.reload ();
        }
    }

    public void remove_border (Border border) {
        borders.remove (border);
        reload ();
    }

    /**
     * Helper method to allow the global shortcut action to update the border color.
     */
    public void update_color_from_action (Gdk.RGBA color) {
        // If no border color is available, create a new one.
        if (count () == 0) {
            add_border_color (color, 1);
            return;
        }

        // Get the first border color since the user is using the global color picker.
        Border first = borders.get (0);
        first.color = color;
        reload ();
    }
}
