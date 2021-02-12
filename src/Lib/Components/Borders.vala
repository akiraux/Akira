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

    public Borders (Gdk.RGBA init_color, int init_size) {
        borders = new Gee.ArrayList<Border> ();

        int count = this.count ();
        borders.@set (count, new Border (init_color, init_size, count));
    }

    public int count () {
        return borders.size;
    }

    public void reload () {
        foreach (Border border in borders) {
            border.reload ();
        }
    }
}
