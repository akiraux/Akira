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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public enum Akira.Lib.Models.CanvasItemType {
    RECT,
    ELLIPSE,
    TEXT
}

public interface Akira.Lib.Models.CanvasItem : Goo.CanvasItemSimple, Goo.CanvasItem {
    public static int global_id = 0;

    public abstract string id { get; set; }
    public abstract bool selected { get; set; }
    public abstract double opacity { get; set; }
    public abstract double rotation { get; set; }
    public abstract int fill_alpha { get; set; }
    public abstract int stroke_alpha { get; set; }
    public abstract Gdk.RGBA color { get; set; }
    public abstract Gdk.RGBA border_color { get; set; }
    public abstract Models.CanvasItemType item_type { get; set; }

    public double get_coords (string coord_id, bool convert_to_item_space = false) {
        double _coord = 0.0;
        get (coord_id, out _coord);

        return _coord;
    }

    public void delete () {
        // TODO: emit signal to update SideMenu
        remove ();
    }

    public static string create_item_id (Models.CanvasItem item) {
        string[] type_slug_tokens = item.item_type.to_string ().split ("_");
        string type_slug = type_slug_tokens[type_slug_tokens.length - 1];

        return "%s%d".printf (type_slug, global_id++);
    }

    public static void init_item (Goo.CanvasItem item) {
        item.set ("opacity", 100.0);
        item.set ("fill-alpha", 255);
        item.set ("stroke-alpha", 255);
    }

    public void reset_colors () {
        var rgba_fill = Gdk.RGBA ();
        var rgba_stroke = Gdk.RGBA ();

        //  debug (fill_alpha.to_string ());

        rgba_fill = color;
        rgba_fill.alpha = ((double) fill_alpha) / 255 * opacity / 100;
        //  debug (rgba_fill.alpha.to_string ());

        rgba_stroke = border_color;
        rgba_stroke.alpha = ((double) stroke_alpha) / 255 * opacity / 100;

        uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);
        uint stroke_color_rgba = Utils.Color.rgba_to_uint (rgba_stroke);

        set ("fill-color-rgba", fill_color_rgba);
        set ("stroke-color-rgba", stroke_color_rgba);
    }
}
