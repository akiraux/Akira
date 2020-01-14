/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Models.CanvasRect : Goo.CanvasRect, Models.CanvasItem {
    public string id { get; set; }
    public bool selected { get; set; }
    public double rotation { get; set; }
    public double opacity { get; set; }
    public bool has_fill { get; set; default = true; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public bool hidden_fill { get; set; }
    public bool has_border { get; set; default = true; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
    public int stroke_alpha { get; set; }
    public bool hidden_border { get; set; }
    public bool has_border_radius { get; set; }
    public bool is_radius_uniform { get; set; }
    public bool is_radius_autoscale { get; set; }

    public Models.CanvasItemType item_type { get; set; }

    public CanvasRect (
        double _x = 0,
        double _y = 0,
        double _radius_x = 0,
        double _radius_y = 0,
        int _border_size = 1,
        Gdk.RGBA _border_color,
        Gdk.RGBA _fill_color,
        Goo.CanvasItem? parent = null
        ) {
        Object (
            parent: parent
        );

        item_type = Models.CanvasItemType.RECT;

        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        radius_x = _radius_x;
        radius_y = _radius_y;
        width = 1;
        height = 1;
        x = 0;
        y = 0;
        has_border_radius = true;
        is_radius_uniform = true;
        is_radius_autoscale = false;

        set_transform (Cairo.Matrix.identity ());

        // Keep the item always in the origin
        // move the entire coordinate system every time
        translate (_x, _y);

        color = _fill_color;
        has_border = settings.set_border;
        if (has_border) {
            border_color = _border_color;
            border_size = _border_size;
        }
        reset_colors ();
    }

    public void update_border () {
        if (is_radius_uniform) {
            set ("radius-x", radius_x);
            set ("radius-y", radius_x);
        }

        // TODO: handle uneven border radius.
    }
}
