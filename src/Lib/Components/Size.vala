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
    // Keep track of the size changed internally based on the size ratio.
    private bool auto_resize = false;

    public bool locked { get; set; }
    public double ratio { get; set; }

    public double width {
        get {
            double w = 0.0;
            item.get ("width", out w);

            return w;
        }
        set {
            item.set ("width", value);

            if (locked && !auto_resize) {
                auto_resize = true;
                if (item is Items.CanvasImage && Utils.AffineTransform.fix_size (value / ratio) < 1) {
                    height = 1;
                    print("SHit");
                }
                else {
                    height = Utils.AffineTransform.fix_size (value / ratio);
                }
                auto_resize = false;
            }

            if (!auto_resize) {
                Lib.Canvas canvas = item.canvas as Lib.Canvas;
                canvas.window.event_bus.item_value_changed ();

                // If the value wasn't changed automatically by the auto resize,
                // and the image is selected, recalculate the pixbuf quality.
                if (item is Items.CanvasImage && item.layer.selected && !canvas.holding) {
                    canvas.window.event_bus.detect_image_size_change ();
                }
            }
        }
    }

    public double height {
        get {
            double h = 0.0;
            item.get ("height", out h);

            return h;
        }
        set {
            item.set ("height", value);

            if (locked && !auto_resize) {
                auto_resize = true;
                if (item is Items.CanvasImage && Utils.AffineTransform.fix_size (value / ratio) < 1) {
                    width = 2;
                }
                else {
                    width = Utils.AffineTransform.fix_size (value / ratio);
                }
                auto_resize = false;
            }

            if (!auto_resize) {
                Lib.Canvas canvas = item.canvas as Lib.Canvas;
                canvas.window.event_bus.item_value_changed ();

                // If the value wasn't changed automatically by the auto resize,
                // and the image is selected, recalculate the pixbuf quality.
                if (item is Items.CanvasImage && item.layer.selected && !canvas.holding) {
                    canvas.window.event_bus.detect_image_size_change ();
                }
            }
        }
    }

    public Size (Items.CanvasItem _item) {
        item = _item;
        locked = false;
        ratio = 1.0;

        this.notify["locked"].connect (update_ratio);
    }

    /**
     * Helper method to update the size ratio of an item.
     */
    public void update_ratio () {
        // Avoid divding by 0.
        if (width == 0 || height == 0) {
            return;
        }

        ratio = width / height;
    }
}
