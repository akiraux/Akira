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
 * Flipped component to handle the flipped (mirrored) state of an item.
 */
public class Akira.Lib.Components.Flipped : Component {
    public bool horizontal { get; set; }
    public bool vertical { get; set; }

    public Flipped (Items.CanvasItem _item) {
        item = _item;

        horizontal = false;
        vertical = false;

        this.notify["horizontal"].connect (() => {
            flip_item (-1, 1);
        });

        this.notify["vertical"].connect (() => {
            flip_item (1, -1);
        });
    }

    /**
     * GooCanvas doesn't come with a mirror or flip method out of the box,
     * therefore we need to use Cairo and do it manually.
     */
    private void flip_item (double sx, double sy) {
        double center_x = item.size.width / 2;
        double center_y = item.size.height / 2;

        Cairo.Matrix transform;
        item.get_transform (out transform);

        double radians = Utils.AffineTransform.deg_to_rad (item.rotation.rotation);

        transform.translate (center_x, center_y);
        transform.rotate (-radians);
        transform.scale (sx, sy);
        transform.rotate (radians);
        transform.translate (-center_x, -center_y);

        item.set_transform (transform);

        ((Lib.Canvas) item.canvas).window.event_bus.item_value_changed ();
    }
}
