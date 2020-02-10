/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Models.CanvasArtboard : Goo.CanvasItemSimple, Models.CanvasItem {
    // Identifiers.
    public Models.CanvasItemType item_type { get; set; }
    public string id { get; set; }
    public string name { get; set; }

    // Transform Panel attributes.
    public double opacity { get; set; }
    public double rotation { get; set; }

    // Fill Panel attributes.
    public bool has_fill { get; set; default = true; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = true; }
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
    public string layer_icon { get; set; default = "shape-rectangle-symbolic"; }

    // Shape's unique identifiers.
    public bool is_radius_uniform { get; set; }
    public bool is_radius_autoscale { get; set; }

    // CanvasItemSimple basic properties
    public double x { get; set; }
    public double y { get; set; }
    public double width { get; set; }
    public double height { get; set; }

    public CanvasArtboard (
        double _x = 0,
        double _y = 0,
        Goo.CanvasItem? parent = null
    ) {
        item_type = Models.CanvasItemType.ARTBOARD;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        width = 1;
        height = 1;
        x = 0;
        y = 0;

        this.notify["width"].connect((w) => {
            debug (@"New width: $(width)");
        });

        canvas = parent.get_canvas ();

        show_border_radius_panel = false;
        show_fill_panel = false;
        show_border_panel = false;
        is_radius_uniform = true;
        is_radius_autoscale = false;

        set_transform (Cairo.Matrix.identity ());

        // Keep the item always in the origin
        // move the entire coordinate system every time
        translate (_x, _y);

        // Get colors from settings
    }

    public override void simple_update (Cairo.Context cr) {
        //(this as Goo.CanvasItemSimple).simple_update (cr);

        this.bounds.x1 = x;
        this.bounds.y1 = y;
        this.bounds.x2 = x + width;
        this.bounds.y2 = y + height;
    }

    public override void simple_paint (Cairo.Context cr, Goo.CanvasBounds bounds) {
        //(this as Goo.CanvasItemSimple).simple_paint (cr, bounds);

        cr.set_source_rgba (1, 0, 0, 1);
        cr.set_line_width (2);

        cr.move_to (x, y);
        cr.line_to (x, y + height);
        cr.line_to (x + width, y + height);
        cr.line_to (x + width, y);

        cr.stroke ();

    }

    public override bool simple_is_item_at (double x, double y, Cairo.Context cr, bool is_pointer_event) {
        return true;
    }

    /*
    public void create_path (Cairo.Context cr) {
    }
    */
}
