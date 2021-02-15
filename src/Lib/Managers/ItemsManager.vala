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

    public Akira.Models.ListModel<Lib.Items.CanvasItem> free_items;
    public Akira.Models.ListModel<Lib.Items.CanvasArtboard> artboards;
    public Akira.Models.ListModel<Lib.Items.CanvasImage> images;
    private GLib.Type item_type { get; set; }
    private Goo.CanvasItem root;
    private int border_size;
    private Gdk.RGBA border_color;
    private Gdk.RGBA fill_color;

    // Keep track of the expensive Artboard change method.
    private bool is_changing = false;

    public ItemsManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        free_items = new Akira.Models.ListModel<Lib.Items.CanvasItem> ();
        artboards = new Akira.Models.ListModel<Lib.Items.CanvasArtboard> ();
        images = new Akira.Models.ListModel<Lib.Items.CanvasImage> ();

        border_color = Gdk.RGBA ();
        fill_color = Gdk.RGBA ();

        window.event_bus.insert_item.connect (set_item_to_insert);
        window.event_bus.request_delete_item.connect (on_request_delete_item);
        window.event_bus.detect_artboard_change.connect (on_detect_artboard_change);
    }

    public void insert_image (Lib.Managers.ImageManager manager) {
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
            }
        }

        set_item_to_insert ("image");
        var new_item = insert_item (start_x, start_y, manager);

        selected_bound_manager.set_initial_coordinates (start_x, start_y);
        selected_bound_manager.add_item_to_selection (new_item);
    }

    public Items.CanvasItem? insert_item (
        double x,
        double y,
        Lib.Managers.ImageManager? manager = null,
        bool loaded = false,
        Items.CanvasArtboard? artboard = null
    ) {
        update_default_values ();

        Items.CanvasItem? new_item = null;

        // Populate root item here and not in the construct @since
        // there the canvas is not yet defined, so we need to wait for
        // the first item to be created to fill this variable
        if (root == null) {
            root = window.main_window.main_canvas.canvas.get_root_item ();
        }

        if (artboard == null) {
            foreach (Items.CanvasArtboard _artboard in artboards) {
                if (_artboard.is_inside (x, y)) {
                    artboard = _artboard;
                    break;
                }
            }
        }

        // We can't use a switch () method here because the typeof () method is not supported.
        if (item_type == typeof (Items.CanvasArtboard)) {
            new_item = add_artboard (x, y);
        }

        if (item_type == typeof (Items.CanvasRect)) {
            new_item = add_rect (x, y, root, artboard, loaded);
        }

        if (item_type == typeof (Items.CanvasEllipse)) {
            new_item = add_ellipse (x, y, root, artboard, loaded);
        }

        if (item_type == typeof (Items.CanvasText)) {
            new_item = add_text (x, y, root, artboard, loaded);
        }

        if (item_type == typeof (Items.CanvasImage)) {
            new_item = add_image (x, y, manager, root, artboard, loaded);
        }

        if (new_item == null) {
            return null;
        }

        if (new_item.item_type.item_type == typeof (Items.CanvasArtboard)) {
            artboards.add_item.begin ((Items.CanvasArtboard) new_item);
        } else {
            // Add it to "free items" if it doesn't belong to an artboard.
            if (new_item.artboard == null) {
                free_items.add_item.begin ((Items.CanvasItem) new_item, loaded);
            }

            // We need to additionally store images in a dedicated list in order
            // to easily access them when saving the .akira/Pictures folder.
            // If we don't curate this dedicated list, it would be a nightamer to
            // loop through all the free items and artboard items to check for images.
            if (new_item.item_type.item_type == typeof (Items.CanvasImage)) {
                images.add_item.begin ((new_item as Akira.Lib.Items.CanvasImage), loaded);
            }
        }

        window.event_bus.item_inserted (new_item);
        window.event_bus.file_edited ();

        return new_item;
    }

    public void add_item (Akira.Lib.Items.CanvasItem item) {
        free_items.add_item.begin (item);
        window.event_bus.file_edited ();
    }

    public void on_request_delete_item (Lib.Items.CanvasItem item) {
        if (item.item_type.item_type == typeof (Items.CanvasArtboard)) {
            artboards.remove_item.begin (item as Items.CanvasArtboard);
        }

        // Remove the image from the list so we don't keep it in the saved file.
        if (item.item_type.item_type == typeof (Items.CanvasImage)) {
            images.remove_item.begin ((item as Akira.Lib.Items.CanvasImage));

            // Mark it for removal if we have a saved file.
            if (window.akira_file != null) {
                window.akira_file.remove_image.begin (
                    ((Akira.Lib.Items.CanvasImage) item).manager.filename
                );
            }
        }

        if (item.artboard == null) {
            free_items.remove_item.begin (item);
        }

        item.delete ();
        window.event_bus.item_deleted (item);
        window.event_bus.file_edited ();
    }

    public Items.CanvasItem add_artboard (double x, double y) {
        var artboard = new Items.CanvasArtboard (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            root
        );

        return artboard as Items.CanvasItem;
    }

    public Items.CanvasItem add_rect (
        double x,
        double y,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Items.CanvasRect (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            border_size,
            border_color,
            fill_color,
            parent,
            artboard,
            loaded
        );
    }

    public Items.CanvasEllipse add_ellipse (
        double x,
        double y,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Items.CanvasEllipse (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            border_size,
            border_color,
            fill_color,
            parent,
            artboard,
            loaded
        );
    }

    public Items.CanvasText add_text (
        double x,
        double y,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Items.CanvasText (
            "Akira is awesome :)",
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            200,
            25f,
            Goo.CanvasAnchorType.NW,
            "Open Sans 18",
            parent,
            artboard,
            loaded
        );
    }

    public Items.CanvasImage add_image (
        double x,
        double y,
        Lib.Managers.ImageManager manager,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Items.CanvasImage (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            manager,
            parent,
            artboard,
            loaded
        );
    }

    public int get_item_position (Lib.Items.CanvasItem item) {
        if (item.artboard != null) {
            return -1;
        }

        return free_items.index (item);
    }

    public Lib.Items.CanvasItem get_item_at_z_index (uint z_index) {
        var item_position = free_items.get_n_items () - 1 - z_index;
        var item_model = free_items.get_item (item_position) as Akira.Lib.Items.CanvasItem;

        return item_model;
    }

    public int get_item_z_index (Items.CanvasItem item) {
        if (item.artboard != null) {
            var items_count = (int) item.artboard.items.get_n_items ();
            return items_count - 1 - item.artboard.items.index (item);
        }

        return get_free_items_count () - 1 - free_items.index (item);
    }

    public int get_item_top_position (Items.CanvasItem item) {
        if (item.artboard != null) {
            return (int) item.artboard.items.get_n_items () - 1;
        }

        return get_free_items_count () - 1;
    }

    public int get_free_items_count () {
        return (int) free_items.get_n_items ();
    }

    public void set_item_to_insert (string insert_type) {
        switch (insert_type) {
            case "rectangle":
                item_type = typeof (Items.CanvasRect);
                break;

            case "ellipse":
                item_type = typeof (Items.CanvasEllipse);
                break;

            case "text":
                item_type = typeof (Items.CanvasText);
                break;

            case "artboard":
                item_type = typeof (Items.CanvasArtboard);
                break;

            case "image":
                item_type = typeof (Items.CanvasImage);
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

    private void update_default_values () {
        fill_color.parse (settings.fill_color);

        // Do not set the border if the user disabled it.
        if (settings.set_border) {
            border_size = (int) settings.border_size;
            border_color.parse (settings.border_color);
        }
    }

    /*
     * Create an item loaded from an opened file.
     *
     * @param Json.Object obj - The json object containing the item to load.
     */
    public void load_item (Json.Object obj) {
        Items.CanvasItem? item = null;
        Items.CanvasArtboard? artboard = null;

        var transform = obj.get_member ("transform").get_object ();
        var pos_x = transform.get_double_member ("x0");
        var pos_y = transform.get_double_member ("y0");

        // If item is inside an artboard update the coordinates accordingly.
        if (obj.has_member ("artboard")) {
            foreach (var _artboard in artboards) {
                if (_artboard.name.id == obj.get_string_member ("artboard")) {
                    var matrix = Cairo.Matrix.identity ();
                    _artboard.get_transform (out matrix);
                    pos_x = matrix.x0 + obj.get_double_member ("relative-x");
                    pos_y = matrix.y0 + obj.get_double_member ("relative-y");
                    artboard = _artboard;
                    break;
                }
            }
        }

        switch (obj.get_string_member ("type")) {
            case "AkiraLibItemsCanvasRect":
                item_type = typeof (Items.CanvasRect);
                item = insert_item (pos_x, pos_y, null, true, artboard);
                break;

            case "AkiraLibItemsCanvasEllipse":
                item_type = typeof (Items.CanvasEllipse);
                item = insert_item (pos_x, pos_y, null, true, artboard);
                break;

            case "AkiraLibItemsCanvasText":
                item_type = typeof (Items.CanvasText);
                item = insert_item (pos_x, pos_y, null, true, artboard);
                break;

            case "AkiraLibItemsCanvasArtboard":
                item_type = typeof (Items.CanvasArtboard);
                item = insert_item (pos_x, pos_y, null, true, artboard);
                break;

            case "AkiraLibItemsCanvasImage":
                item_type = typeof (Items.CanvasImage);
                var filename = obj.get_string_member ("image_id");
                var file = File.new_for_path (
                    Path.build_filename (
                        window.akira_file.pictures_folder.get_path (),
                        filename
                    )
                );
                var manager = new Akira.Lib.Managers.ImageManager.from_archive (file, filename);
                item = insert_item (pos_x, pos_y, manager, true, artboard);
                break;
        }

        restore_attributes (item, artboard, obj);
    }

    /*
     * Restore the saved attributes of a loaded object.
     *
     * @param Items.CanvasItem item - The newly created item.
     * @param Json.Object obj - The json object containing the item's attributes.
     */
    private void restore_attributes (Items.CanvasItem item, Items.CanvasArtboard? artboard, Json.Object obj) {
        // Restore identifiers.
        if (obj.get_string_member ("name") != null) {
            item.name.name = obj.get_string_member ("name");
        }
        item.name.id = obj.get_string_member ("id");

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
        if (item is Items.CanvasRect) {
            item.set ("border-radius-uniform", obj.get_boolean_member ("border-radius-uniform"));
            item.set ("border-radius-autoscale", obj.get_boolean_member ("border-radius-autoscale"));
            item.set ("radius-x", obj.get_double_member ("radius-x"));
            item.set ("radius-y", obj.get_double_member ("radius-y"));
            item.set ("global-radius", obj.get_double_member ("global-radius"));
        }

        // Restore image size.
        if (item is Items.CanvasImage) {
            ((Items.CanvasImage) item).resize_pixbuf (
                (int) obj.get_double_member ("width"),
                (int) obj.get_double_member ("height"),
                true
            );
        }

        // Restore layer options.
        item.layer.locked = obj.get_boolean_member ("locked");
        item.visibility =
            obj.get_int_member ("visibility") == 2
                ? Goo.CanvasItemVisibility.VISIBLE
                : Goo.CanvasItemVisibility.INVISIBLE;

        // Restore the fill attributes.
        // item.has_fill = obj.get_boolean_member ("has-fill");
        // item.hidden_fill = obj.get_boolean_member ("hidden-fill");
        // item.fill_alpha = (int) obj.get_int_member ("fill-alpha");
        // If an item doesn't have any fill color, set a default white in case
        // this is an artboard and it needs to be rendered.
        // item.color_string =
        //     obj.get_string_member ("color-string") != null
        //     ? obj.get_string_member ("color-string")
        //     : "#ffffff";

        // Restore the border attributes.
        // item.has_border = obj.get_boolean_member ("has-border");
        // item.hidden_border = obj.get_boolean_member ("hidden-border");
        // item.border_size = (int) obj.get_int_member ("border-size");
        // item.stroke_alpha = (int) obj.get_int_member ("stroke-alpha");
        // item.border_color_string = obj.get_string_member ("border-color-string");

        // item.load_colors ();

        // Trigger the simple_update () method for artboards.
        // if (item is Items.CanvasArtboard) {
        //     ((Items.CanvasArtboard) item).trigger_change ();
        // }

        item.set ("relative-x", obj.get_double_member ("relative-x"));
        item.set ("relative-y", obj.get_double_member ("relative-y"));

        Cairo.Matrix matrix;
        item.get_transform (out matrix);
        var transform = obj.get_member ("transform").get_object ();

        // Apply the Cairo Matrix to properly update position and rotation.
        var new_matrix = Cairo.Matrix (
            transform.get_double_member ("xx"),
            transform.get_double_member ("yx"),
            transform.get_double_member ("xy"),
            transform.get_double_member ("yy"),
            transform.get_double_member ("x0"),
            transform.get_double_member ("y0")
        );
        item.set_transform (new_matrix);

        // If the item is an Artboard, we need to restore bounding coordinates otherwise
        // new child items won't be properly restored into it.
        if (item is Items.CanvasArtboard) {
            item.bounds.x1 = transform.get_double_member ("x0");
            item.bounds.y1 = transform.get_double_member ("y0");
            item.bounds.x2 = transform.get_double_member ("x0") + obj.get_double_member ("width");
            item.bounds.y2 = transform.get_double_member ("y0") + obj.get_double_member ("height");
        }

        // Since free items are loaded upside down, always raise to the top position
        // the newly added free item.
        if (artboard == null & !(item is Items.CanvasArtboard)) {
            item.lower (null);
        }

        // Reset the loaded attribute to prevent sorting issues inside artboards.
        item.is_loaded = false;
    }

    /**
     * Handle the aftermath of an item transformation, like size changes or movement
     * to see if we need to add or remove an item to an Artboard.
     */
    private async void on_detect_artboard_change () {
        // Interrupt if no artboard is currently present.
        if (artboards.get_n_items () == 0) {
            return;
        }

        // Interrupt if this is already running.
        if (is_changing) {
            return;
        }

        // Interrupt if no item is selected.
        if (window.main_window.main_canvas.canvas.selected_bound_manager.selected_items.length () == 0) {
            return;
        }

        is_changing = true;

        // We need to copy the array of selected items as we need to remove and add items once
        // moved to force the natural redraw of the canvas.
        var items = window.main_window.main_canvas.canvas.selected_bound_manager.selected_items.copy ();

        // If we have images in the canvas, check if they're part of the selection to recalculate the size.
        if (images.get_n_items () > 0) {
            foreach (var image in images) {
                if (items.find (image) != null) {
                    image.check_resize_pixbuf ();
                }
            }
        }

        // Update the size ratio to always be faithful to the updated size.
        foreach (var item in items) {
            if (item is Items.CanvasArtboard) {
                continue;
            }
            item.size.update_ratio ();
        }

        // Check if any of the currently moved items was dropped inside or outside any artboard.
        foreach (var item in items) {
            if (item is Items.CanvasArtboard) {
                continue;
            }

            // Interrupt if the item is already inside an artboard and was only moved within it.
            if (item.artboard != null && item.artboard.dropped_inside (item)) {
                continue;
            }

            Items.CanvasArtboard? new_artboard = null;

            foreach (Items.CanvasArtboard artboard in artboards) {
                // Interrupt the loop if we find an artboard that matches the dropped coordinate.
                if (artboard.dropped_inside (item)) {
                    new_artboard = artboard;
                    break;
                }
            }

            yield change_artboard (item, new_artboard);
        }

        is_changing = false;
    }

    /**
     * Add or remove an item from an artboard.
     */
    public async void change_artboard (Items.CanvasItem item, Items.CanvasArtboard? new_artboard) {
        // Interrupt if the item was moved within its original artboard.
        if (item.artboard == new_artboard) {
            debug ("Same parent");
            return;
        }

        // Save the coordinates before removing the item.
        // var x = item.bounds.x1;
        // var y = item.bounds.y1;

        // If the item was moved from inside an Artboard to the empty Canvas.
        if (item.artboard != null && new_artboard == null) {
            debug ("Artboard => Free Item");

            // Apply the matrix transform before removing the item from the artboard.
            // item.set_transform (item.get_real_transform ());

            // Remove the item from the Artboard.
            item.artboard.remove_child (item.artboard.find_child (item));
            window.event_bus.item_deleted (item);

            // Attach the item to the Canvas.
            item.set_parent (root);

            // Insert the item back into the Canvas, add the Layer,
            // reset its position, and add it back to the selection.
            add_item (item);
            // item.position_item (x, y);

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }

        // If the item was moved from the empty Canvas to an Artboard.
        if (item.artboard == null && new_artboard != null) {
            debug ("Free Item => Artboard");

            // Apply the matrix transform before removing the item from the artboard.
            // item.set_transform (item.get_real_transform ());

            // Remove the item from the free items.
            free_items.remove_item.begin (item);
            item.parent.remove_child (item.parent.find_child (item));
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            item.artboard = new_artboard;

            // Insert the item back into the Artboard, add the Layer,
            // reset its position, and add it back to the selection.
            // item.position_item (x, y);
            // item.connect_to_artboard ();

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }

        // If the item was moved from inside an Artboard to another Artboard.
        if (item.artboard != null && new_artboard != null) {
            debug ("Artboard => Artboard");
            // Remove the item from the Artboard.
            item.artboard.remove_child (item.artboard.find_child (item));
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            item.artboard = new_artboard;

            // Insert the item back into the Artboard, add the Layer,
            // reset its position, and add it back to the selection.
            // item.position_item (x, y);
            // item.connect_to_artboard ();
            item.artboard.add_child (item, -1);

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }
    }
}
