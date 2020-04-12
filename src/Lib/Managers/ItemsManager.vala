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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ItemsManager : Object {
    public weak Akira.Window window { get; construct; }

    public Akira.Models.ListModel<Lib.Models.CanvasItem> free_items;
    public Akira.Models.ListModel<Lib.Models.CanvasArtboard> artboards;
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
        free_items = new Akira.Models.ListModel<Lib.Models.CanvasItem> ();
        artboards = new Akira.Models.ListModel<Lib.Models.CanvasArtboard> ();

        border_color = Gdk.RGBA ();
        fill_color = Gdk.RGBA ();

        window.event_bus.insert_item.connect (set_item_to_insert);
        window.event_bus.request_delete_item.connect (on_request_delete_item);
        window.event_bus.change_item_z_index.connect (on_change_item_z_index);
    }

    public void insert_image (Services.FileImageProvider provider) {
        var selected_bound_manager = window.main_window.main_canvas.canvas.selected_bound_manager;

        double start_x, start_y, scale, rotation;
        start_x = Akira.Layouts.MainCanvas.CANVAS_SIZE / 2;
        start_y = Akira.Layouts.MainCanvas.CANVAS_SIZE / 2;

        if (selected_bound_manager.selected_items.length () > 0) {
            var item = selected_bound_manager.selected_items.nth_data (0);

            if (item.artboard == null) {
                item.get_simple_transform (
                    out start_x, out start_y, out scale, out rotation
                );
            } else {
                item.artboard.get_simple_transform (
                    out start_x, out start_y, out scale, out rotation
                );
                start_x += item.relative_x;
                start_y += item.relative_y;
            }
        }

        set_item_to_insert ("image");
        var new_item = insert_item (start_x, start_y, provider);

        selected_bound_manager.add_item_to_selection (new_item);
        selected_bound_manager.set_initial_coordinates (start_x, start_y);
    }

    public Models.CanvasItem? insert_item (
        double x,
        double y,
        Services.FileImageProvider? provider = null
    ) {
        udpate_default_values ();

        Models.CanvasItem? new_item;
        Models.CanvasArtboard? artboard = null;

        // Populate root item here and not in the construct @since
        // there the canvas is not yet defined, so we need to wait for
        // the first item to be created to fill this variable
        if (root == null) {
            root = window.main_window.main_canvas.canvas.get_root_item ();
        }

        foreach (Models.CanvasArtboard _artboard in artboards) {
            if (_artboard.is_inside (x, y)) {
                artboard = _artboard;
            }
        }

        switch (insert_type) {
            case Models.CanvasItemType.RECT:
                new_item = add_rect (x, y, root, artboard);
                break;

            case Models.CanvasItemType.ELLIPSE:
                new_item = add_ellipse (x, y, root, artboard);
                break;

            case Models.CanvasItemType.TEXT:
                new_item = add_text (x, y, root, artboard);
                break;

            case Models.CanvasItemType.ARTBOARD:
                new_item = add_artboard (x, y);
                break;

            case Models.CanvasItemType.IMAGE:
                new_item = add_image (x, y, provider, root, artboard);
                break;

            default:
                new_item = null;
                break;
        }

        if (new_item != null) {
            switch (new_item.item_type) {
                case Akira.Lib.Models.CanvasItemType.ARTBOARD:
                    artboards.add_item.begin ((Models.CanvasArtboard) new_item);
                    break;

                default:
                    if (new_item.artboard == null) {
                        // Add it to "free items"
                        free_items.add_item.begin (new_item, false);
                    }

                    break;
            }

            window.event_bus.item_inserted (new_item);
            window.event_bus.file_edited ();
        }

        return new_item;
    }

    public void add_item (Akira.Lib.Models.CanvasItem item) {
        free_items.add_item.begin (item, false);
        window.event_bus.file_edited ();
    }

    public void on_request_delete_item (Lib.Models.CanvasItem item) {
        switch (item.item_type) {
            case Akira.Lib.Models.CanvasItemType.ARTBOARD:
                artboards.remove_item.begin (item as Models.CanvasArtboard);
                break;

            default:
                if (item.artboard == null) {
                    free_items.remove_item.begin (item);
                }
                break;
        }

        item.delete ();
        window.event_bus.item_deleted (item);
        window.event_bus.file_edited ();
    }

    public Models.CanvasItem add_artboard (double x, double y) {
        var artboard = new Models.CanvasArtboard (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            root
            );

        return artboard as Models.CanvasItem;
    }

    public Models.CanvasItem add_rect (double x, double y, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var rect = new Models.CanvasRect (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
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

    public Models.CanvasEllipse add_ellipse (double x, double y, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var ellipse = new Models.CanvasEllipse (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
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

    public Models.CanvasText add_text (double x, double y, Goo.CanvasItem parent, Models.CanvasArtboard? artboard) {
        var text = new Models.CanvasText (
            "Akira is awesome :)",
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            200,
            25f,
            Goo.CanvasAnchorType.NW,
            "Open Sans 18",
            parent,
            artboard
            );

        return text;
    }

    public Models.CanvasImage add_image (
        double x,
        double y,
        Services.FileImageProvider provider,
        Goo.CanvasItem parent,
        Models.CanvasArtboard? artboard
    ) {
        var image = new Models.CanvasImage (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            provider,
            parent,
            artboard);

        return image;
    }

    public int get_item_position (Lib.Models.CanvasItem item) {
        if (item.artboard != null) {
            return -1;
        }

        return free_items.index (item);
    }

    public Lib.Models.CanvasItem get_item_at_z_index (uint z_index) {
        var item_position = free_items.get_n_items () - 1 - z_index;

        var item_model = free_items.get_item (item_position) as Akira.Lib.Models.CanvasItem;

        return item_model;
    }

    public int get_item_z_index (Models.CanvasItem item) {
        if (item.artboard != null) {
            var items_count = (int) item.artboard.items.get_n_items ();
            return items_count - 1 - item.artboard.items.index (item);
        }

        return get_free_items_count () - 1 - free_items.index (item);
    }

    public int get_item_top_position (Models.CanvasItem item) {
        if (item.artboard != null) {
            return (int) item.artboard.items.get_n_items () - 1;
        }

        return get_free_items_count () - 1;
    }

    public int get_free_items_count () {
        return (int) free_items.get_n_items ();
    }

    public void set_item_to_insert (string type) {
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

            case "image":
                insert_type = Models.CanvasItemType.IMAGE;
                break;
        }
    }

    public void swap_items (int source_z_index, int target_z_index) {
        // z-index is the exact opposite of items placement
        // inside the free_items list
        // last in is the topmost element
        var free_items_length = get_free_items_count ();

        var source = free_items_length - 1 - source_z_index;
        var target = free_items_length - 1 - target_z_index;

        // Remove item at source position
        var item_to_swap = free_items.remove_at (source);

        // Insert item at target position
        free_items.insert_at (target, item_to_swap);
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
