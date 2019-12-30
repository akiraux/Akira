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

public enum InsertType {
    RECT,
    ELLIPSE,
    TEXT
}

public class Akira.Lib.Managers.ItemsManager : Object {

    public weak Goo.Canvas canvas { get; construct; }

    private List<Goo.CanvasItem> items;
    private InsertType? insert_type { get; set; }
    private Goo.CanvasItem root;
    private double border_size;
    private string border_color;
    private string fill_color;

    public ItemsManager (Goo.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();
        items = new List<Goo.CanvasItem> ();

        event_bus.insert_item.connect (set_item_to_insert);
    }

    public void set_insert_type_from_key (uint keyval) {
        // TODO: take those values from preferences/settings and not from hardcoded values

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

        }
    }

    public Goo.CanvasItem? insert_item (Gdk.EventButton event) {
        udpate_default_values ();

        Goo.CanvasItem? new_item;

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
            init_item (new_item);

            items.append (new_item);
        }

        return new_item;
    }

    public Goo.CanvasRect add_rect (Gdk.EventButton event) {
        var rect = new Goo.CanvasRect (
            null,
            event.x, event.y,
            1, 1,
            "line-width", border_size,
            "radius-x", 0.0,
            "radius-y", 0.0,
            "stroke-color", border_color,
            "fill-color", fill_color,
            null
        );

        rect.set ("parent", root);
        rect.set_transform (Cairo.Matrix.identity ());
        rect.set_data<double?> ("rotation", 0);

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

    public Goo.CanvasEllipse add_ellipse (Gdk.EventButton event) {
        var ellipse = new Goo.CanvasEllipse (
            null,
            event.x, event.y,
            1, 1,
            "line-width", border_size,
            "stroke-color", border_color,
            "fill-color", fill_color,
            null
        );

        ellipse.set ("parent", root);
        ellipse.set_transform (Cairo.Matrix.identity ());
        ellipse.set_data<double?> ("rotation", 0);

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

    public Goo.CanvasText add_text (Gdk.EventButton event) {
        var text = new Goo.CanvasText (
            null,
            "Add text here",
            event.x, event.y,
            200,
            Goo.CanvasAnchorType.NW,
            "font", "Open Sans 18",
            null
        );

        text.set ("parent", root);
        text.set ("height", 25f);
        text.set_transform (Cairo.Matrix.identity ());
        text.set_data<double?> ("rotation", 0);

        /*
        var artboard = window.main_window.right_sidebar.layers_panel.artboard;
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, text, "Text", "shape-text-symbolic", false);
        text.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        artboard.container.add (layer);
        artboard.show_all ();
        */

        return text;
    }

    private void init_item (Object object) {
        object.set_data<int?> ("fill-alpha", 255);
        object.set_data<int?> ("stroke-alpha", 255);
        object.set_data<double?> ("opacity", 100);
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
        border_size = settings.set_border ? settings.border_size : 0.0;
        border_color = settings.set_border ? settings.border_color: "";
        fill_color = settings.fill_color;
    }
}
