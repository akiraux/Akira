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
 * Rotation component to keep track of the item's rotation.
 */
public class Akira.Lib.Components.Rotation : Component {
    private double _rotation;
    public double rotation {
        get {
            return _rotation;
        }
        set {
            // Interrupt if nothing changed.
            if (_rotation == value) {
                return;
            }

            var center_x = item.size.width / 2;
            var center_y = item.size.height / 2;
            var new_rotation = value - _rotation;

            item.rotate (new_rotation, center_x, center_y);

            _rotation += new_rotation;

            ((Lib.Canvas) item.canvas).window.event_bus.item_value_changed ();
        }
    }

    public Rotation (Items.CanvasItem _item) {
        item = _item;
        // Set rotation to 0 when the item is first created.
        _rotation = 0.0;
    }
}
