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

    public void reload () {
        // If we don't have any fills associated with this item, remove the background color.
        if (count () == 0) {
            if (item is Items.CanvasArtboard) {
                ((Items.CanvasArtboard) item).background.set ("fill-color-rgba", null);
            } else {
                item.set ("fill-color-rgba", null);
            }
            return;
        }

        // Loop through all the configured fill and reload the color.
        foreach (Fill fill in fills) {
            fill.reload ();
        }
    }

    public void remove_fill (Fill fill) {
        fills.remove (fill);
        reload ();
    }
}
