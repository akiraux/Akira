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


public class Akira.Lib.Managers.ItemsManager : Object {
    public weak Akira.Lib.Canvas canvas { get; construct; }

    public enum InsertType {
        RECT,
        ELLIPSE,
        TEXT
    }

    private List<Models.CanvasItem> items;
    private InsertType? insert_type { get; set; }
    private Goo.CanvasItem root;
    private int border_size;
    private Gdk.RGBA border_color;
    private Gdk.RGBA fill_color;

    public ItemsManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();
        items = new List<Models.CanvasItem> ();

        border_color = Gdk.RGBA ();
        fill_color = Gdk.RGBA ();

        canvas.window.event_bus.insert_item.connect (set_item_to_insert);
    }

    public bool set_insert_type_from_key (uint keyval) {
        // TODO: take those values from preferences/settings and not from hardcoded values
        if (keyval > Gdk.Key.Z || keyval < Gdk.Key.A) {
          return false;
        }

        switch (keyval) {
            case Gdk.Key.R:
                set_item_to_insert ("rectangle");
                break;

            case Gdk.Key.E:
                set_item_to_insert ("ellipse");
                break;

            case Gdk.Key.T:
                set_item_to_insert ("text");
                break;

            default:
                return false;
        }

        return true;
    }

    public Models.CanvasItem? insert_item (Gdk.EventButton event) {
        udpate_default_values ();

        Models.CanvasItem? new_item;

        switch (insert_type) {
            case InsertType.RECT:
                new_item = add_rect (event);
                break;

            case InsertType.ELLIPSE:
                new_item = add_ellipse (event);
                break;

            case InsertType.TEXT:
                new_item = add_text (event);
                break;

            default:
                new_item = null;
                break;
        }

        if (new_item != null) {
            items.append (new_item);
        }

        return new_item;
    }

    public Models.CanvasItem add_rect (Gdk.EventButton event) {
        var rect = new Models.CanvasRect (
            event.x,
            event.y,
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            root
        );

        /*
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (
            window,
            artboard,
            rect,
            "Rectangle",
            "shape-rectangle-symbolic",
            false
        );

        rect.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);

        artboard.container.add (layer);
        artboard.show_all ();
        */

        return rect;
    }

    public Models.CanvasEllipse add_ellipse (Gdk.EventButton event) {
        var ellipse = new Models.CanvasEllipse (
            event.x,
            event.y,
            1,
            1,
            border_size,
            border_color,
            fill_color,
            root
        );

        /*
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, ellipse,
            "Circle", "shape-circle-symbolic", false);
        ellipse.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        artboard.container.add (layer);
        artboard.show_all ();
        */

        return ellipse;
    }

    public Models.CanvasText add_text (Gdk.EventButton event) {
        var text = new Models.CanvasText (
            "Add text here",
            event.x,
            event.y,
            200,
            25f,
            Goo.CanvasAnchorType.NW,
            "Open Sans 18",
            root
        );

        /*
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, text, "Text", "shape-text-symbolic", false);
        text.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        artboard.container.add (layer);
        artboard.show_all ();
        */

        return text;
    }

    private void set_item_to_insert (string type) {
        switch (type) {
            case "rectangle":
                insert_type = InsertType.RECT;
                break;

            case "ellipse":
                insert_type = InsertType.ELLIPSE;
                break;

            case "text":
                insert_type = InsertType.TEXT;
                break;
        }
    }

    private void udpate_default_values () {
        fill_color.parse (settings.fill_color);

        // Do not set the border if the user disabled it.
        if (settings.set_border) {
            border_size = (int) settings.border_size;
            border_color.parse (settings.border_color);
        }
    }
}
