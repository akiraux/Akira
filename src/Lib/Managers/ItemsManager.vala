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

    private List<Models.CanvasItem> items;
    private Models.CanvasItemType? insert_type { get; set; }
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
        canvas.window.event_bus.request_delete_item.connect (on_request_delete_item);
        canvas.window.event_bus.change_item_z_index.connect (on_change_item_z_index);
    }

    public Models.CanvasItem? insert_item (Gdk.EventButton event) {
        udpate_default_values ();

        Models.CanvasItem? new_item;

        switch (insert_type) {
            case Models.CanvasItemType.RECT:
                new_item = add_rect (event);
                break;

            case Models.CanvasItemType.ELLIPSE:
                new_item = add_ellipse (event);
                break;

            case Models.CanvasItemType.TEXT:
                new_item = add_text (event);
                break;

            case Models.CanvasItemType.ARTBOARD:
                new_item = add_artboard (event);
                break;

            default:
                new_item = null;
                break;
        }

        if (new_item != null) {
            items.append (new_item);

            canvas.window.event_bus.item_inserted (new_item);
        }

        return new_item;
    }

    public void add_item (Akira.Lib.Models.CanvasItem item) {
        items.append (item);
    }

    public void on_request_delete_item (Lib.Models.CanvasItem item) {
        item.delete ();
        canvas.window.event_bus.item_deleted (item);
    }

    public Models.CanvasItem add_artboard (Gdk.EventButton event) {
        var artboard = new Models.CanvasArtboard (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            root
        );

        return artboard as Models.CanvasItem;
    }

    public Models.CanvasItem add_rect (Gdk.EventButton event) {
        var rect = new Models.CanvasRect (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            root
        );


        return rect;
    }

    public Models.CanvasEllipse add_ellipse (Gdk.EventButton event) {
        var ellipse = new Models.CanvasEllipse (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            root
            );

        return ellipse;
    }

    public Models.CanvasText add_text (Gdk.EventButton event) {
        var text = new Models.CanvasText (
            "Add text here",
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            200,
            25f,
            Goo.CanvasAnchorType.NW,
            "Open Sans 18",
            root
            );

        return text;
    }

    private void set_item_to_insert (string type) {
        switch (type) {
            case "rectangle":
                insert_type = Models.CanvasItemType.RECT;
                break;

            case "ellipse":
                insert_type = Models.CanvasItemType.ELLIPSE;
                break;

            case "text":
                insert_type = Models.CanvasItemType.TEXT;
                break;

            case "artboard":
                insert_type = Models.CanvasItemType.ARTBOARD;
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

    private void on_change_item_z_index (Lib.Models.CanvasItem item, int position) {
        // Lower `item` behind the item at index `position` or raise
        // it above the item at index `position - 1`
        var root_item = item.get_canvas ().get_root_item ();

        switch (position) {
            case -1:
                // Put the item at the top of the stack
                item.lower (null);
                break;

            case 0:
                // Put the item on bottom of the stack
                var canvas_item_at_top_position = root_item.get_n_children () - 11;
                var canvas_item_at_top = root_item.get_child (canvas_item_at_top_position);

                item.raise (canvas_item_at_top);
                break;

            default:
                Goo.CanvasItem item_at_position = null;

                var current_position = root_item.find_child (item);

                if (current_position > position) {
                    item_at_position = root_item.get_child (position);
                    item.lower (item_at_position);
                } else {
                    item_at_position = root_item.get_child (position - 1);
                    item.raise (item_at_position);
                }
                break;
        }

        canvas.window.event_bus.z_selected_changed ();
    }

}
