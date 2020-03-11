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

public class Akira.Lib.Models.CanvasImage : Goo.CanvasImage, CanvasItem {
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
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = false; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
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
    public Models.CanvasArtboard artboard { get; set; }

    public double relative_x { get; set; }
    public double relative_y { get; set; }

    public CanvasImage (Akira.Services.ImageProvider provider, Goo.CanvasItem? parent = null) {
        Object (
            parent: parent
        );

        canvas = parent.get_canvas () as Akira.Lib.Canvas;
        parent.add_child (this, -1);

        item_type = Models.CanvasItemType.IMAGE;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        width = 1;
        height = 1;
        x = 0;
        y = 0;
        scale_to_fit = true;

        set_transform (Cairo.Matrix.identity ());

        provider.get_pixbuf.begin (-1, -1, (obj, res) => {
            try {
                var _pixbuf = provider.get_pixbuf.end (res);
                pixbuf = _pixbuf;
                width = _pixbuf.get_width ();
                height = _pixbuf.get_height ();
                fix_image_size ();
            } catch (Error e) {
                warning (e.message);
                // TODO: handle error here
            }
        });

        reset_colors ();
    }

    public void fix_image_size () {
        // Imported images should keep their aspect ratio by default.
        size_ratio = width / height;
        size_locked = true;
    }
}
