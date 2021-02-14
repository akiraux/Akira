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
 * Transform component to keep track of the item's initial coordinates.
 */
public class Akira.Lib.Components.Transform : Component {
    private double? _x = null;
    public double x {
        get {
            if (_x != null) {
                return _x;
            }

            double item_x = item.bounds.x1 + get_border ();

            if (item.artboard != null) {
                double temp_y = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref item_x, ref temp_y);
            }

            _x = item_x;

            return item_x;
        }
        set {
            _x = value;
        }
    }

    private double? _y = null;
    public double y {
        get {
            if (_y != null) {
                return _y;
            }

            double item_y = item.bounds.y1 + get_border ();

            if (item.artboard != null) {
                double temp_x = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref temp_x, ref item_y);
            }

            _y = item_y;

            return item_y;
        }
        set {
            _y = value;
        }
    }

    public Transform (double new_x, double new_y) {
        x = new_x;
        y = new_y;
    }

    /**
     * The item's bounds account also for the border width, but we shouldn't,
     * so we need to account for half the border width since we're only dealing
     * with a centered border. In the future, once borders can be inside or outside,
     * we will need to update this condition.
     */
    private double get_border () {
        if (!item.has_borders) {
            return 0;
        }

        // Temporarily return the current line_width of the item
        // since we only support 1 border at the time.
        return item.line_width > 0 ? item.line_width / 2 : 0;
    }
}
