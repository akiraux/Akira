/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
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
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Models.CanvasRect : Goo.CanvasRect, Models.CanvasItem {
    public string id { get; set; }
    public bool selected { get; set; }
    public double rotation { get; public set; }

    private double _opacity;
    public double opacity {
        get {
            return _opacity;
        }
        public set {
            _opacity = value;

            reset_colors ();
        }
    }

    private int _fill_alpha;
    public int fill_alpha {
        get {
            return _fill_alpha;
        }
        set {
            _fill_alpha = value;
            reset_colors ();
        }
    }
    public int stroke_alpha { get; set; }

    private Gdk.RGBA _color;
    public Gdk.RGBA color {
        get {
            return _color;
        }
        set {
            _color = value;

            reset_colors ();
        }
    }

    private Gdk.RGBA _border_color;
    public Gdk.RGBA border_color {
        get {
            return _border_color;
        }
        set {
            _border_color = value;

            reset_colors ();
        }
    }

    public Models.CanvasItemType item_type { get; set; }

    public CanvasRect (
        double _x = 0,
        double _y = 0,
        double _radius_x = 0,
        double _radius_y = 0,
        double _border_size = 1.0,
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

        set_transform (Cairo.Matrix.identity ());

        // Keep the item always in the origin
        // move the entire coordinate system every time
        translate (_x, _y);

        color = _fill_color;
        border_color = _border_color;

        debug (@"BorderColor: $border_color");

        set ("line-width", _border_size);
        set ("stroke-color", _border_color);
    }
}
