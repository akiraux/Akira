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
            if (new_item is Akira.Lib.Models.CanvasArtboard) {
                artboards.append ((Models.CanvasArtboard) new_item);
            } else {
                items.append (new_item);
            }

            window.event_bus.item_inserted (new_item);
            window.event_bus.file_edited ();
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

    // Create an item loaded from an opened file.
    public void load_item (Json.Object obj) {
        udpate_default_values ();

        Models.CanvasItem? item = null;
        Models.CanvasArtboard? artboard = null;

        var transform = obj.get_member ("transform").get_object ();
        var pos_x = transform.get_double_member ("x0");
        var pos_y = transform.get_double_member ("y0");

        // If item is inside an artboard update the coordinates accordingly.
        if (obj.has_member ("artboard")) {
            foreach (var _artboard in artboards) {
                if (_artboard.id == obj.get_string_member ("artboard")) {
                    var matrix = Cairo.Matrix.identity ();
                    _artboard.get_transform (out matrix);
                    pos_x = matrix.x0 + obj.get_double_member ("initial-relative-x");
                    pos_y = matrix.y0 + obj.get_double_member ("initial-relative-y");
                    artboard = _artboard;
                    break;
                }
            }
        }

        switch (obj.get_string_member ("type")) {
            case "AkiraLibModelsCanvasRect":
                item = new Models.CanvasRect (
                    pos_x,
                    pos_y,
                    0.0,
                    0.0,
                    border_size,
                    border_color,
                    fill_color,
                    root,
                    artboard
                    );
                break;

            case "AkiraLibModelsCanvasEllipse":
                item = new Models.CanvasEllipse (
                    pos_x,
                    pos_y,
                    0.0,
                    0.0,
                    border_size,
                    border_color,
                    fill_color,
                    root,
                    artboard
                    );
                break;

            case "AkiraLibModelsCanvasText":
                item = new Models.CanvasText (
                    "Add text here",
                    pos_x,
                    pos_y,
                    200,
                    25f,
                    Goo.CanvasAnchorType.NW,
                    "Open Sans 18",
                    root,
                    artboard
                    );
                break;

            case "AkiraLibModelsCanvasArtboard":
                item = new Models.CanvasArtboard (pos_x, pos_y, root);
                break;
        }

        if (item == null) {
            return;
        }

        if (item is Akira.Lib.Models.CanvasArtboard) {
            artboards.append ((Models.CanvasArtboard) item);
        } else {
            items.append (item);
        }
        window.event_bus.item_inserted (item);
        restore_attributes (item, obj);
        window.event_bus.item_value_changed ();

        restore_selection (obj.get_boolean_member ("selected"), item);
    }

    private void restore_attributes (Models.CanvasItem item, Json.Object obj) {
        // Restore identifiers.
        if (obj.get_string_member ("name") != null) {
            item.name = obj.get_string_member ("name");
        }
        item.id = obj.get_string_member ("id");

        // Restore transform panel values.
        item.set ("width", obj.get_double_member ("width"));
        item.set ("height", obj.get_double_member ("height"));
        item.set ("size-locked", obj.get_boolean_member ("size-locked"));
        item.set ("size-ratio", obj.get_double_member ("size-ratio"));
        item.set ("rotation", obj.get_double_member ("rotation"));
        item.set ("flipped-h", obj.get_boolean_member ("flipped-h"));
        item.set ("flipped-v", obj.get_boolean_member ("flipped-v"));
        item.set ("opacity", obj.get_double_member ("opacity"));

        // Restore border radius.
        if (item is Models.CanvasRect) {
            item.set ("is-radius-uniform", obj.get_boolean_member ("is-radius-uniform"));
            item.set ("is-radius-autoscale", obj.get_boolean_member ("is-radius-autoscale"));
            item.set ("radius-x", obj.get_double_member ("radius-x"));
            item.set ("radius-y", obj.get_double_member ("radius-y"));
            item.set ("global-radius", obj.get_double_member ("global-radius"));
        }

        // Restore layer options.
        var model = window.main_window.right_sidebar.layers_panel.list_model.find_item (item)
            as Akira.Models.LayerModel;
        if (model != null) {
            model.is_visible = obj.get_int_member ("visibility") == 2;
            model.is_locked = obj.get_boolean_member ("locked");
        }

        if (obj.has_member ("artboard")) {
            var child_model = window.main_window.right_sidebar.layers_panel.item_model_map.
                @get (item.artboard.id).get_child_item (item);
            if (child_model != null) {
                child_model.is_visible = obj.get_int_member ("visibility") == 2;
                child_model.is_locked = obj.get_boolean_member ("locked");
            }
        }

        // Restore fill and border.
        if (!(item is Models.CanvasArtboard)) {
            item.has_fill = obj.get_boolean_member ("has-fill");
            item.hidden_fill = obj.get_boolean_member ("hidden-fill");
            item.fill_alpha = (int) obj.get_int_member ("fill-alpha");
            item.color_string = obj.get_string_member ("color-string");

            item.has_border = obj.get_boolean_member ("has-border");
            item.hidden_border = obj.get_boolean_member ("hidden-border");
            item.border_size = (int) obj.get_int_member ("border-size");
            item.stroke_alpha = (int) obj.get_int_member ("stroke-alpha");
            item.border_color_string = obj.get_string_member ("border-color-string");

            item.load_colors ();
        }

        item.set ("relative-x", obj.get_double_member ("relative-x"));
        item.set ("relative-y", obj.get_double_member ("relative-y"));
        item.set ("initial-relative-x", obj.get_double_member ("initial-relative-x"));
        item.set ("initial-relative-y", obj.get_double_member ("initial-relative-y"));
    }

    private void restore_selection (bool selected, Models.CanvasItem item) {
        if (selected) {
            window.main_window.main_canvas.canvas.selected_bound_manager.add_item_to_selection (item);
        }
    }
}
