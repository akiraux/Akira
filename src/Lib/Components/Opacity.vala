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
 * Opacity component to keep track of the item global opacity, which has to account
 * for all fills and borders colors.
 */
public class Akira.Lib.Components.Opacity : Component {
    public double opacity { get; set; }

    public Opacity (Items.CanvasItem _item) {
        item = _item;
        // Set opacity to 100% (fully visible) when the item is first created.
        opacity = 100.0;

        this.notify["opacity"].connect (() => {
            item.fills.reload ();
            item.borders.reload ();
        });
    }
}
