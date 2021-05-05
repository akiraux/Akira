/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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

    // Keep track of newly imported images before creation.
    public Lib.Managers.ImageManager? image_manager;

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
        image_manager = manager;
        window.event_bus.insert_item ("image");
    }

    public Items.CanvasItem? insert_item (
        double x,
        double y,
        Lib.Managers.ImageManager? manager = null,
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
            new_item = add_rect (x, y, root, artboard);
        }

        if (item_type == typeof (Items.CanvasEllipse)) {
            new_item = add_ellipse (x, y, root, artboard);
        }

        if (item_type == typeof (Items.CanvasText)) {
            new_item = add_text (x, y, root, artboard);
        }

        if (item_type == typeof (Items.CanvasImage)) {
            // If we don't have a manager passed to this method but a general image manager
            // is available in the class, it means the user is importing a new image.
            if (manager == null && image_manager != null) {
                manager = image_manager;
            }
            new_item = add_image (x, y, manager, root, artboard);

            // Empty the image manager since we used it.
            image_manager = null;
        }

        if (new_item == null) {
            return null;
        }

        if (new_item is Items.CanvasArtboard) {
            artboards.add_item.begin ((Items.CanvasArtboard) new_item);
        } else {
            // Add it to "free items" if it doesn't belong to an artboard.
            if (new_item.artboard == null) {
                free_items.add_item.begin ((Items.CanvasItem) new_item);
            }

            // We need to additionally store images in a dedicated list in order
            // to easily access them when saving the .akira/Pictures folder.
            // If we don't curate this dedicated list, it would be a nightamer to
            // loop through all the free items and artboard items to check for images.
            if (new_item is Items.CanvasImage) {
                images.add_item.begin ((new_item as Akira.Lib.Items.CanvasImage));
            }
        }

        window.event_bus.item_inserted ();
        window.event_bus.file_edited ();

        return new_item;
    }

    /**
     * Helper method to add an item to the canvas, used when dragging an item
     * outside an artboard where a reset of the parent root is necessary.
     */
    public void add_item_to_canvas (Lib.Items.CanvasItem item) {
        item.set_parent (root);
        item.parent.add_child (item, -1);
        free_items.add_item.begin (item);
        window.event_bus.file_edited ();
        ((Lib.Canvas) item.canvas).update_canvas ();
    }

    /**
     * Helper method to add an item to an artboard, used when dragging an item
     * from the canvas or another artboard where a reset of the parent root is necessary.
     */
    public void add_item_to_artboard (Lib.Items.CanvasItem item, Lib.Items.CanvasArtboard artboard) {
        item.set_parent (artboard);
        item.artboard = artboard;
        item.parent.add_child (item, -1);
        item.check_add_to_artboard (item);
        window.event_bus.file_edited ();
    }

    public void on_request_delete_item (Lib.Items.CanvasItem item) {
        // Remove the layer from the Artboards list if it's an artboard.
        if (item is Items.CanvasArtboard) {
            artboards.remove_item.begin (item as Items.CanvasArtboard);
        }

        // Remove the image from the list so we don't keep it in the saved file.
        if (item is Items.CanvasImage) {
            images.remove_item.begin ((item as Akira.Lib.Items.CanvasImage));

            // Mark it for removal if we have a saved file.
            if (window.akira_file != null) {
                window.akira_file.remove_image.begin (
                    ((Akira.Lib.Items.CanvasImage) item).manager.filename
                );
            }
        }

        // Remove the layer from the Free Items list only if the item doesn't
        // belong to an artboard, and it's not an artboard itself.
        if (item.artboard == null && !(item is Items.CanvasArtboard)) {
            free_items.remove_item.begin (item);
        }

        // Let the app know we're deleting an item.
        window.event_bus.item_deleted (item);
        item.delete ();
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
        Items.CanvasArtboard? artboard
    ) {
        return new Items.CanvasRect (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            border_size,
            border_color,
            fill_color,
            parent,
            artboard
        );
    }

    public Items.CanvasEllipse add_ellipse (
        double x,
        double y,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard
    ) {
        return new Items.CanvasEllipse (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            border_size,
            border_color,
            fill_color,
            parent,
            artboard
        );
    }

    public Items.CanvasText add_text (
        double x,
        double y,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard
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
            artboard
        );
    }

    public Items.CanvasImage add_image (
        double x,
        double y,
        Lib.Managers.ImageManager manager,
        Goo.CanvasItem parent,
        Items.CanvasArtboard? artboard
    ) {
        return new Items.CanvasImage (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            manager,
            parent,
            artboard
        );
    }

    public int get_item_z_index (Items.CanvasItem item) {
        if (item.artboard != null) {
            var items_count = (int) item.artboard.items.get_n_items ();
            return items_count - 1 - item.artboard.items.index (item);
        }

        return (int) free_items.get_n_items () - 1 - free_items.index (item);
    }

    public int get_item_top_position (Items.CanvasItem item) {
        if (item.artboard != null) {
            return (int) item.artboard.items.get_n_items () - 1;
        }

        return (int) free_items.get_n_items () - 1;
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
        var free_items_length = (int) free_items.get_n_items ();

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

        var components = obj.get_member ("Components").get_object ();
        var coordinates = components.get_member ("Coordinates").get_object ();
        var pos_x = coordinates.get_double_member ("x");
        var pos_y = coordinates.get_double_member ("y");

        // If item is inside an artboard update the coordinates accordingly.
        if (obj.has_member ("artboard")) {
            foreach (var _artboard in artboards) {
                if (_artboard.name.id == obj.get_string_member ("artboard")) {
                    window.main_window.main_canvas.canvas.convert_from_item_space (
                        _artboard, ref pos_x, ref pos_y
                    );
                    artboard = _artboard;
                    break;
                }
            }
        }

        switch (obj.get_string_member ("type")) {
            case "rectangle":
                item_type = typeof (Items.CanvasRect);
                item = insert_item (pos_x, pos_y, null, artboard);
                break;

            case "ellipse":
                item_type = typeof (Items.CanvasEllipse);
                item = insert_item (pos_x, pos_y, null, artboard);
                break;

            case "text":
                item_type = typeof (Items.CanvasText);
                item = insert_item (pos_x, pos_y, null, artboard);
                break;

            case "artboard":
                item_type = typeof (Items.CanvasArtboard);
                item = insert_item (pos_x, pos_y, null, artboard);
                break;

            case "image":
                item_type = typeof (Items.CanvasImage);
                var filename = obj.get_string_member ("image_id");
                var file = File.new_for_path (
                    Path.build_filename (
                        window.akira_file.pictures_folder.get_path (),
                        filename
                    )
                );
                var manager = new Lib.Managers.ImageManager.from_archive (file, filename);
                item = insert_item (pos_x, pos_y, manager, artboard);
                break;
        }

        var selected_bound_manager = window.main_window.main_canvas.canvas.selected_bound_manager;
        selected_bound_manager.add_item_to_selection (item);

        restore_attributes (item, artboard, components);

        // Restore the matrix transform to properly reset position and rotation.
        var matrix = obj.get_member ("matrix").get_object ();
        var new_matrix = Cairo.Matrix (
            matrix.get_double_member ("xx"),
            matrix.get_double_member ("yx"),
            matrix.get_double_member ("xy"),
            matrix.get_double_member ("yy"),
            matrix.get_double_member ("x0"),
            matrix.get_double_member ("y0")
        );
        item.set_transform (new_matrix);

        selected_bound_manager.reset_selection ();
    }

    /*
     * Restore the saved attributes of a loaded object.
     *
     * @param Items.CanvasItem item - The newly created item.
     * @param Json.Object obj - The json object containing the item's attributes.
     */
    private void restore_attributes (Items.CanvasItem item, Items.CanvasArtboard? artboard, Json.Object components) {
        // Restore identifiers.
        if (components.has_member ("Name")) {
            var name = components.get_member ("Name").get_object ();
            item.name.id = name.get_string_member ("id");
            item.name.name = name.get_string_member ("name");
            item.name.icon = name.get_string_member ("icon");
        }

        // Restore opacity.
        if (components.has_member ("Opacity")) {
            var opacity = components.get_member ("Opacity").get_object ();
            item.opacity.opacity = opacity.get_double_member ("opacity");
        }

        // Restore rotation.
        if (components.has_member ("Rotation")) {
            var rotation = components.get_member ("Rotation").get_object ();
            item.rotation.rotation = rotation.get_double_member ("rotation");
        }

        // Restore size.
        if (components.has_member ("Size")) {
            var size = components.get_member ("Size").get_object ();
            item.size.locked = size.get_boolean_member ("locked");
            item.size.ratio = size.get_double_member ("ratio");
            item.size.width = size.get_double_member ("width");
            item.size.height = size.get_double_member ("height");
        }

        // Restore flipped.
        if (components.has_member ("Flipped")) {
            var flipped = components.get_member ("Flipped").get_object ();
            item.flipped.horizontal = flipped.get_boolean_member ("horizontal");
            item.flipped.vertical = flipped.get_boolean_member ("vertical");
        }

        // Restore border radius.
        if (components.has_member ("BorderRadius")) {
            var border_radius = components.get_member ("BorderRadius").get_object ();
            item.border_radius.x = border_radius.get_double_member ("x");
            item.border_radius.y = border_radius.get_double_member ("y");
            item.border_radius.uniform = border_radius.get_boolean_member ("uniform");
            item.border_radius.autoscale = border_radius.get_boolean_member ("autoscale");
        }

        // Restore layer.
        if (components.has_member ("Layer")) {
            var layer = components.get_member ("Layer").get_object ();
            item.layer.locked = layer.get_boolean_member ("locked");
        }

        // Restore fills.
        if (components.has_member ("Fills")) {
            // Delete all pre-existing fills to be sure we're starting with a clean slate.
            foreach (Lib.Components.Fill fill in item.fills.fills) {
                item.fills.fills.remove (fill);
            }

            var fills = components.get_member ("Fills").get_object ();
            fills.foreach_member ((i, name, node) => {
                var obj = node.get_object ();
                var color = Gdk.RGBA ();
                color.parse (obj.get_string_member ("color"));
                var fill = item.fills.add_fill_color (color);
                fill.alpha = (int) obj.get_int_member ("alpha");
                fill.hidden = obj.get_boolean_member ("hidden");
            });

            item.fills.reload ();
        }

        // Restore borders.
        if (components.has_member ("Borders")) {
            // Delete all pre-existing borders to be sure we're starting with a clean slate.
            foreach (Lib.Components.Border border in item.borders.borders) {
                item.borders.borders.remove (border);
            }

            var borders = components.get_member ("Borders").get_object ();
            borders.foreach_member ((i, name, node) => {
                var obj = node.get_object ();
                var color = Gdk.RGBA ();
                color.parse (obj.get_string_member ("color"));
                var border = item.borders.add_border_color (color, (int) obj.get_int_member ("size"));
                border.alpha = (int) obj.get_int_member ("alpha");
                border.hidden = obj.get_boolean_member ("hidden");
            });

            item.borders.reload ();
        }

        // Restore image size.
        if (item is Items.CanvasImage) {
            ((Items.CanvasImage) item).resize_pixbuf (
                (int) item.size.width,
                (int) item.size.height,
                true
            );
        }
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
            if (item.artboard != null && !item.artboard.is_outside (item)) {
                continue;
            }

            Items.CanvasArtboard? new_artboard = null;

            foreach (Items.CanvasArtboard artboard in artboards) {
                // Interrupt the loop if we find an artboard that matches the dropped coordinate.
                if (!artboard.is_outside (item)) {
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
        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        // If the item was moved from inside an Artboard to the empty Canvas.
        if (item.artboard != null && new_artboard == null) {
            debug ("Artboard => Free Item");

            // Convert the matrix transform before removing the item from the artboard.
            item.canvas.convert_from_item_space (item.artboard, ref matrix.x0, ref matrix.y0);

            // Remove the item from the Artboard.
            item.artboard.remove_item (item);

            // Remove the item from the selection and redraw the layers panel.
            window.event_bus.item_deleted (item);

            // Attach the item to the Canvas.
            add_item_to_canvas (item);

            // Apply the updated coordinates.
            item.set_transform (matrix);

            window.event_bus.item_inserted ();
            window.event_bus.request_add_item_to_selection (item);

            return;
        }

        // If the item was moved from the empty Canvas to an Artboard.
        if (item.artboard == null && new_artboard != null) {
            debug ("Free Item => Artboard");

            // Convert the matrix transform to the new artboard.
            item.canvas.convert_to_item_space (new_artboard, ref matrix.x0, ref matrix.y0);

            // Remove the child from the GooCanvasItem parent.
            item.parent.remove_child (item.parent.find_child (item));

            // Remove the item from the free items list.
            free_items.remove_item.begin (item);

            // Remove the item from the selection and redraw the layers panel.
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            add_item_to_artboard (item, new_artboard);

            // Apply the updated coordinates.
            item.set_transform (matrix);

            window.event_bus.item_inserted ();
            window.event_bus.request_add_item_to_selection (item);

            return;
        }

        // If the item was moved from inside an Artboard to another Artboard.
        if (item.artboard != null && new_artboard != null) {
            debug ("Artboard => Artboard");

            // Passing from an artboard to another we need to first convert the coordinates
            // from the old artboard to the global canvas, and then convert them again
            // to the new artboard.
            item.canvas.convert_from_item_space (item.artboard, ref matrix.x0, ref matrix.y0);
            item.canvas.convert_to_item_space (new_artboard, ref matrix.x0, ref matrix.y0);

            // Remove the item from the Artboard.
            item.artboard.remove_item (item);

            // Remove the item from the selection and redraw the layers panel.
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            add_item_to_artboard (item, new_artboard);

            // Apply the updated coordinates.
            item.set_transform (matrix);

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted ();
            window.event_bus.request_add_item_to_selection (item);

            return;
        }
    }
}
