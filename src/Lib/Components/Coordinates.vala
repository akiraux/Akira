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
    private double _x;
    public double x {
        get {
            double item_x = item.bounds.x1 + get_border ();

            if (item.artboard != null) {
                double temp_y = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref item_x, ref temp_y);
            }

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_x = ((Items.CanvasArtboard) item).background.bounds.x1;
            }

            return item_x;
        }
        set {
            _x = value;
            ((Lib.Canvas) item.canvas).window.event_bus.item_value_changed ();
        }
    }

    public double x1 {
        get {
            double item_x1 = item.bounds.x1 + get_border ();

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_x1 = ((Items.CanvasArtboard) item).background.bounds.x1;
            }

            return item_x1;
        }
    }

    public double x2 {
        get {
            double item_x2 = item.bounds.x2 - get_border ();

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_x2 = ((Items.CanvasArtboard) item).background.bounds.x2;
            }

            return item_x2;
        }
    }

    private double _y;
    public double y {
        get {
            double item_y = item.bounds.y1 + get_border ();

            if (item.artboard != null) {
                double temp_x = 0.0;
                item.canvas.convert_to_item_space (item.artboard, ref temp_x, ref item_y);
            }

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_y = ((Items.CanvasArtboard) item).background.bounds.y1;
            }

            return item_y;
        }
        set {
            _y = value;
            ((Lib.Canvas) item.canvas).window.event_bus.item_value_changed ();
        }
    }

    public double y1 {
        get {
            double item_y1 = item.bounds.y1 + get_border ();

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_y1 = ((Items.CanvasArtboard) item).background.bounds.y1;
            }

            return item_y1;
        }
    }

    public double y2 {
        get {
            double item_y2 = item.bounds.y2 - get_border ();

            // If the item is an artboard we need to get the bounds of the background since
            // the artboard group will have its bounds changing based on the location of the
            // child items.
            if (item is Items.CanvasArtboard) {
                item_y2 = ((Items.CanvasArtboard) item).background.bounds.y2;
            }

            return item_y2;
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
