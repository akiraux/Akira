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
    public unowned Borders borders { get; set; }
    // Since items can have multiple border colors, we need to keep track of each
    // with a unique identifier in order to properly update them.
    public int id { get; set; }

    public Gdk.RGBA color { get; set; }

    // Store the hexadecimal string version of the color (E.g.: #FF00CC)
    public string hex { get; set; }
    public int size { get; set; }
    public int alpha { get; set; }
    public bool hidden { get; set; }

    public Border (Borders _borders, Items.CanvasItem _item, Gdk.RGBA init_color, int init_size, int border_id) {
        borders = _borders;
        item = _item;
        id = border_id;
        color = init_color;
        size = init_size;
        alpha = 255;

        // Listen for changed to the border attributes to properly trigger the color generation.
        this.notify["color"].connect (() => {
            hex = Utils.Color.rgba_to_hex (color.to_string ());
            borders.reload ();
        });

        this.notify["size"].connect (() => {
            borders.reload ();
        });

        this.notify["hidden"].connect (() => {
            borders.reload ();
        });
    }

    public void remove () {
        borders.remove_border (this);
    }
}
