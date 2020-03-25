/*
 * Copyright (c) 2019-2020 Alecaddd (http://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ItemsManager : Object {
    public weak Akira.Window window { get; construct; }

    public List<Models.CanvasItem> items;
    public List<Models.CanvasArtboard> artboards;
    private Models.CanvasItemType? insert_type { get; set; }
    private Goo.CanvasItem root;
    private int border_size;
    private Gdk.RGBA border_color;
    private Gdk.RGBA fill_color;

    public ItemsManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        root = window.main_window.main_canvas.canvas.get_root_item ();

        items = new List<Models.CanvasItem> ();
        artboards = new List<Models.CanvasArtboard> ();

        border_color = Gdk.RGBA ();
        fill_color = Gdk.RGBA ();

        window.event_bus.insert_item.connect (set_item_to_insert);
        window.event_bus.request_delete_item.connect (on_request_delete_item);
        window.event_bus.change_item_z_index.connect (on_change_item_z_index);
    }

    public Models.CanvasItem? insert_item (Gdk.EventButton event, Json.Object? obj = null) {
        udpate_default_values ();

        Models.CanvasItem? new_item;
        Models.CanvasArtboard? artboard = null;

        foreach (var _artboard in artboards) {
            if (_artboard.is_inside (event.x, event.y)) {
                artboard = _artboard;
            }
        }

        switch (insert_type) {
            case Models.CanvasItemType.RECT:
                new_item = add_rect (event, root, artboard);
                break;

            case Models.CanvasItemType.ELLIPSE:
                new_item = add_ellipse (event, root, artboard);
                break;

            case Models.CanvasItemType.TEXT:
                new_item = add_text (event, root, artboard);
                break;

            case Models.CanvasItemType.ARTBOARD:
                new_item = add_artboard (event);
                break;

            default:
                new_item = null;
                break;
        }

        if (new_item != null) {
            // Restore the attributes of an item loaded from a saved file.
            if (obj != null) {
                restore_attributes (new_item, obj);
            }

            if (new_item is Akira.Lib.Models.CanvasArtboard) {
                artboards.append ((Models.CanvasArtboard) new_item);
            } else {
                items.append (new_item);
            }

            window.event_bus.item_inserted (new_item);

            // Don't trigger the edit file signal if the item was loaded from a saved file.
            if (obj == null) {
                window.event_bus.file_edited ();
            }
        }

        return new_item;
    }

    public void add_item (Akira.Lib.Models.CanvasItem item) {
        items.append (item);
        window.event_bus.file_edited ();
    }

    public void on_request_delete_item (Lib.Models.CanvasItem item) {
        if (item is Models.CanvasArtboard) {
            artboards.remove (item as Models.CanvasArtboard);
        } else {
            items.remove (item);
        }

        item.delete ();
        window.event_bus.item_deleted (item);
        window.event_bus.file_edited ();
    }

    public Models.CanvasItem add_artboard (Gdk.EventButton event) {
        var artboard = new Models.CanvasArtboard (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            root
            );

        return artboard as Models.CanvasItem;
    }

    // Create an item loaded from an opened file.
    public void load_item (Json.Object obj) {
        var transform = obj.get_member ("transform").get_object ();
        var event = new Gdk.Event (Gdk.EventType.BUTTON_PRESS);

        var new_x = transform.get_double_member ("x0");
        var new_y = transform.get_double_member ("y0");
        // If item is inside an artboard update the coordinates accordingly.
        if (obj.has_member ("artboard")) {
            foreach (var artboard in artboards) {
                if (artboard.id == obj.get_string_member ("artboard")) {
                    var matrix = Cairo.Matrix.identity ();
                    artboard.get_transform (out matrix);
                    new_x = matrix.x0 + obj.get_double_member ("initial-relative-x");
                    new_y = matrix.y0 + obj.get_double_member ("initial-relative-y");
                    break;
                }
            }
        }

        ((Gdk.EventButton) event).x = new_x;
        ((Gdk.EventButton) event).y = new_y;

        switch (obj.get_string_member ("type")) {
            case "AkiraLibModelsCanvasRect":
                insert_type = Models.CanvasItemType.RECT;
                break;

            case "AkiraLibModelsCanvasEllipse":
                insert_type = Models.CanvasItemType.ELLIPSE;
                break;

            case "AkiraLibModelsCanvasText":
                insert_type = Models.CanvasItemType.TEXT;
                break;

            case "AkiraLibModelsCanvasArtboard":
                insert_type = Models.CanvasItemType.ARTBOARD;
                break;
        }
        var item = insert_item ((Gdk.EventButton) event, obj);
        restore_selection (obj.get_boolean_member ("selected"), item);
    }

    private void restore_attributes (Models.CanvasItem item, Json.Object obj) {
        if (obj.get_string_member ("name") != null) {
            item.set ("name", obj.get_string_member ("name"));
        }
        item.set ("id", obj.get_string_member ("id"));
        item.set ("width", obj.get_double_member ("width"));
        item.set ("height", obj.get_double_member ("height"));
        item.set ("opacity", obj.get_double_member ("opacity"));
        item.set ("size_locked", obj.get_boolean_member ("size-locked"));
        item.set ("size_ratio", obj.get_double_member ("size-ratio"));
        item.set ("flipped_h", obj.get_boolean_member ("flipped-h"));
        item.set ("flipped_v", obj.get_boolean_member ("flipped-v"));
        item.set ("locked", obj.get_boolean_member ("locked"));

        //  // If item is inside an artboard.
        if (obj.has_member ("artboard")) {
            foreach (var artboard in artboards) {
                if (artboard.id == obj.get_string_member ("artboard")) {
                    item.set ("artboard", artboard);
                    break;
                }
            }
        }
        item.set ("relative-x", obj.get_double_member ("relative-x"));
        item.set ("relative-y", obj.get_double_member ("relative-y"));
        item.set ("initial-relative-x", obj.get_double_member ("initial-relative-x"));
        item.set ("initial-relative-y", obj.get_double_member ("initial-relative-y"));

        // Update fills and borders.
    }

    private void restore_selection (bool selected, Models.CanvasItem item) {
        if (selected) {
            window.main_window.main_canvas.canvas.selected_bound_manager.add_item_to_selection (item);
        }
    }

    public Models.CanvasItem add_rect (Gdk.EventButton event, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var rect = new Models.CanvasRect (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            parent,
            artboard
            );

        return rect;
    }

    public Models.CanvasEllipse add_ellipse (Gdk.EventButton event, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var ellipse = new Models.CanvasEllipse (
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            parent,
            artboard
            );

        return ellipse;
    }

    public Models.CanvasText add_text (Gdk.EventButton event, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var text = new Models.CanvasText (
            "Add text here",
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            200,
            25f,
            Goo.CanvasAnchorType.NW,
            "Open Sans 18",
            parent,
            artboard
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

        window.event_bus.z_selected_changed ();
    }
}
