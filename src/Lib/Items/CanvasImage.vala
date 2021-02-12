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

    public bool is_loaded { get; set; }

    // CanvasImage unique attributes.
    public Lib.Managers.ImageManager manager { get; set; }
    private Gdk.Pixbuf original_pixbuf;

    public CanvasImage (
        double _x,
        double _y,
        Lib.Managers.ImageManager _manager,
        Goo.CanvasItem? _parent,
        Items.CanvasArtboard? _artboard,
        bool _loaded = false
    ) {
        parent = _artboard != null ? _artboard : _parent;
        artboard = _artboard;
        canvas = parent.get_canvas () as Akira.Lib.Canvas;

        // Set the ImageManager.
        manager = _manager;

        // Create the image item.
        x = _x;
        y = _y;
        width = height = 1;
        scale_to_fit = true;

        // Add all the components that this item uses.
        components = new Gee.ArrayList<Component> ();
        components.add (new Components.Type (typeof (CanvasImage)));
        // Only the Name component needs the class to be passed on construct.
        // All the other components after this will inherit the class from the
        // main Component.
        components.add (new Name (this));
        components.add (new Transform ());
        components.add (new Opacity ());
        components.add (new Rotation ());
        components.add (new Size ());
        components.add (new Flipped ());
        components.add (new Layer ());

        // Add extra attributes.
        is_loaded = _is_loaded;

        init_pixbuf ();
    }

    private void init_pixbuf () {
        // Save the unedited pixbuf to enable resampling and restoring.
        manager.get_pixbuf.begin (-1, -1, (obj, res) => {
            try {
                original_pixbuf = manager.get_pixbuf.end (res);
                pixbuf = original_pixbuf;
                width = original_pixbuf.get_width ();
                height = original_pixbuf.get_height ();

                // Imported images should have their size ratio locked by default.
                size_locked = true;
                // ratio = width / height;
            } catch (Error e) {
                warning (e.message);
                // canvas.window.event_bus.canvas_notification (e.message);
            }
        });
    }

    /**
     * Trigger the pixbuf resampling only if the image size changed.
     */
     public void check_resize_pixbuf () {
        if (width == manager.pixbuf.get_width () && height == manager.pixbuf.get_height ()) {
            return;
        }

        resize_pixbuf ((int) width, (int) height);
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
                // canvas.window.event_bus.canvas_notification (e.message);
            }
        });
    }
}
