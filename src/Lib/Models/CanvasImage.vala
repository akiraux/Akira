/*
* Copyright (c) 2020 Adam Bieńkowski
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
* Authored by: Adam Bieńkowski <donadigos159@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Models.CanvasImage : Goo.CanvasImage, Models.CanvasItem {
    // Identifiers.
    public Models.CanvasItemType item_type { get; set; }
    public string id { get; set; }
    public string name { get; set; }

    // Transform Panel attributes.
    public double opacity {
        get {
            return alpha * 100.0;
        }
        set {
            set ("alpha", value / 100.0);
        }
    }
    public double rotation { get; set; }

    // Fill Panel attributes.
    public bool has_fill { get; set; default = false; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public string color_string { get; set; }
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = false; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
    public string border_color_string { get; set; }
    public int stroke_alpha { get; set; }
    public bool hidden_border { get; set; }

    // Style Panel attributes.
    public bool size_locked { get; set; }
    public double size_ratio { get; set; }
    public bool flipped_h { get; set; }
    public bool flipped_v { get; set; }
    public bool show_border_radius_panel { get; set; }
    public bool show_fill_panel { get; set; }
    public bool show_border_panel { get; set; }

    // Layers panel attributes.
    public bool selected { get; set; }
    public bool locked { get; set; }
    public string layer_icon { get; set; default = "shape-image-symbolic"; }
    public int z_index { get; set; }

    public new Akira.Lib.Canvas canvas { get; set; }
    public Models.CanvasArtboard? artboard { get; set; }

    public double relative_x { get; set; }
    public double relative_y { get; set; }

    public double initial_relative_x { get; set; }
    public double initial_relative_y { get; set; }

    // Knows if an item was created or loaded for ordering purpose.
    public bool loaded { get; set; default = false; }

    // CanvasImage unique attributes.
    public Lib.Managers.ImageManager manager { get; set; }
    private Gdk.Pixbuf original_pixbuf;

    public CanvasImage (
        double _x = 0,
        double _y = 0,
        Lib.Managers.ImageManager _manager,
        Goo.CanvasItem? _parent = null,
        Models.CanvasArtboard? _artboard = null,
        bool _loaded = false
    ) {
        loaded = _loaded;
        artboard = _artboard;
        parent = _artboard != null ? _artboard : _parent;
        canvas = parent.get_canvas () as Akira.Lib.Canvas;

        // Set the ImageManager.
        manager = _manager;

        item_type = Models.CanvasItemType.IMAGE;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);
        if (artboard != null) {
            connect_to_artboard ();
        }

        width = 1;
        height = 1;
        x = 0;
        y = 0;
        relative_x = 0;
        relative_y = 0;
        scale_to_fit = true;

        set_transform (Cairo.Matrix.identity ());

        position_item (_x, _y);

        // Save the unedited pixbuf to enable resampling and restoring.
        manager.get_pixbuf.begin (-1, -1, (obj, res) => {
            try {
                original_pixbuf = manager.get_pixbuf.end (res);
                pixbuf = original_pixbuf;
                width = original_pixbuf.get_width ();
                height = original_pixbuf.get_height ();

                // Imported images should have their size ratio locked by default.
                size_locked = true;
                size_ratio = width / height;
            } catch (Error e) {
                warning (e.message);
                canvas.window.event_bus.canvas_notification (e.message);
            }
        });

        reset_colors ();
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
                canvas.window.event_bus.canvas_notification (e.message);
            }
        });
    }
}
