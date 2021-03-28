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
 * Coordinates component to keep track of the item's initial coordinates.
 */
public class Akira.Lib.Components.Coordinates : Component {
    // Returns the bounds.x1 value updated if the item is inside an artboard.
    public double x {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.x1;
            }

            double item_x = item.bounds.x1 + get_border ();

            if (item.artboard != null) {
                double temp_y = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref item_x, ref temp_y);
            }

            return item_x;
        }
    }

    // Returns the global bounds.x1 value.
    public double x1 {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.x1;
            }

            return item.bounds.x1 + get_border ();
        }
    }

    // Returns the global bounds.x2 value.
    public double x2 {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.x2;
            }

            return item.bounds.x2 - get_border ();
        }
    }

    // Returns the bounds.y1 value updated if the item is inside an artboard.
    public double y {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.y1;
            }

            double item_y = item.bounds.y1 + get_border ();

            if (item.artboard != null) {
                double temp_x = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref temp_x, ref item_y);
            }

            return item_y;
        }
    }

    // Returns the global bounds.y1 value.
    public double y1 {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.y1;
            }

            return item.bounds.y1 + get_border ();
        }
    }

    // Returns the global bounds.y2 value.
    public double y2 {
        get {
            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                return ((Items.CanvasArtboard) item).background.bounds.y2;
            }

            return item.bounds.y2 - get_border ();
        }
    }

    public Coordinates (Items.CanvasItem _item) {
        item = _item;
    }

    /**
     * The item's bounds account also for the border width, but we shouldn't,
     * so we need to account for half the border width since we're only dealing
     * with a centered border. In the future, once borders can be inside or outside,
     * we will need to update this condition.
     */
    private double get_border () {
        if (item.borders == null) {
            return 0;
        }

        // Temporarily return the current line_width of the item
        // since we only support 1 border at the time.
        double stroke;
        item.get ("line-width", out stroke);

        return stroke > 0 ? stroke / 2 : 0;
    }
}
