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
    public Gee.ArrayList<Fill> fills { get; set construct; }

    public Fills (Gdk.RGBA init_color) {
        fills = new Gee.ArrayList<Fill> ();

        fills.add (new Fill (init_color));
    }
}
