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

using Akira.Lib.Components;

/**
 * Generate a simple Image item.
 */
public class Akira.Lib.Items.CanvasImage : Goo.CanvasImage, Akira.Lib.Items.CanvasItem {
    public Gee.ArrayList<Component> components { get; set; }

    public Items.CanvasArtboard? artboard { get; set; }

    // CanvasImage unique attributes.
    public Lib.Managers.ImageManager manager { get; set; }
    private Gdk.Pixbuf original_pixbuf;

    public CanvasImage (
        double _x,
        double _y,
        Lib.Managers.ImageManager _manager,
        Goo.CanvasItem? _parent,
        Items.CanvasArtboard? _artboard
    ) {
        parent = _artboard != null ? _artboard : _parent;
        artboard = _artboard;

        // Set the ImageManager.
        manager = _manager;

        // Create the image item.
        x = y = 0;
        width = height = 1;
        scale_to_fit = true;
        init_position (this, _x, _y);

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);

        // Initialize the imported image.
        init_pixbuf ();

        // Force the generation of the item bounds on creation.
        Goo.CanvasBounds bounds;
        this.get_bounds (out bounds);

        // Add all the components that this item uses.
        components = new Gee.ArrayList<Component> ();
        components.add (new Name (this));
        components.add (new Coordinates (this));
        components.add (new Opacity (this));
        components.add (new Rotation (this));
        components.add (new Size (this));
        components.add (new Flipped (this));
        components.add (new Layer ());

        check_add_to_artboard (this);

        ((Lib.Canvas) canvas).window.event_bus.detect_image_size_change.connect (check_resize_pixbuf);
    }

    private void init_pixbuf () {
        // Load the pixbuf at full resolution to properly define the size ratio of the item.
        manager.get_pixbuf.begin (-1, -1, (obj, res) => {
            try {
                original_pixbuf = manager.get_pixbuf.end (res);
                pixbuf = original_pixbuf;

                // Define the item's size based on the images size.
                size.width = original_pixbuf.width;
                size.height = original_pixbuf.height;
                // Imported images should have their size ratio locked by default.
                // Change the locked attribute after the size has been defined to let
                // the Size component properly calculate the correct size ratio.
                size.locked = true;

                var adjusted_height = 2 * size.height / size.width;
                var adjusted_width = size.width / size.height;

                print(adjusted_width.to_string());

                if (adjusted_height < 1) {
                    size.height = 1;
                    return;
                }

                if (adjusted_width < 1) {
                    size.width = 2;
                    return;
                }

                // Reset the size to a 2px initial value after the size ratio was properly defined
                // in order to allow the user to decide the initial image size. We use 2px in order
                // to avoid issues when dividing by the ratio in case of narrow images.
                //  size.width = 2;
            } catch (Error e) {
                warning (e.message);
                ((Lib.Canvas) canvas).window.event_bus.canvas_notification (e.message);
            }
        });
    }

    /**
     * Trigger the pixbuf resampling.
     */
    public void check_resize_pixbuf () {
        // Interrupt if this image isn't part of the selection.
        if (!layer.selected) {
            return;
        }

        // Interrupt if the size of the image didn't change.
        if (size.width == manager.pixbuf.get_width () && size.height == manager.pixbuf.get_height ()) {
            return;
        }

        resize_pixbuf ((int) size.width, (int) size.height);
    }

    /**
     * Resample the pixbuf size.
     *
     * @param {int} w - The new width.
     * @param {int} h - The new height.
     * @param {bool} update - If the updated pixbuf size should be applied to the CanvasItem.
     */
    public void resize_pixbuf (int w, int h, bool update = false) {
        manager.get_pixbuf.begin (w, h, (obj, res) => {
            try {
                var _pixbuf = manager.get_pixbuf.end (res);
                pixbuf = _pixbuf;
                if (update) {
                    width = _pixbuf.get_width ();
                    height = _pixbuf.get_height ();
                }
            } catch (Error e) {
                warning (e.message);
                ((Lib.Canvas) canvas).window.event_bus.canvas_notification (e.message);
            }
        });
    }
}
