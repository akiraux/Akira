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
 * BorderRadius component to handle the border radius of an item.
 */
public class Akira.Lib.Components.BorderRadius : Component {
    public double x { get; set; }
    public double y { get; set; }

    public bool uniform { get; set; }
    public bool autoscale { get; set; }

    public BorderRadius (Items.CanvasItem _item) {
        item = _item;
        x = y = 0.0;

        uniform = true;
        autoscale = false;
    }

    public void update () {
        // We use the X value for both radii in case the radius is set to uniform.
        if (uniform) {
            item.set ("radius-x", x);
            item.set ("radius-y", x);
        }
    }
}
