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
 * Size component to keep track of the item's size ratio attributes.
 */
public class Akira.Lib.Components.Size : Component {
    public bool locked { get; set construct; }
    public double ratio { get; set construct; }

    public Size () {
        locked = false;
        ratio = 1.0;
    }

    // Update the size ratio to respect the updated size.
    public void update_ratio () {
        ratio = item.width / item.height;
    }
}
