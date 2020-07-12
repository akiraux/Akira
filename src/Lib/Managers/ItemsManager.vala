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
    public Akira.Models.ListModel<Lib.Models.CanvasImage> images;
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
        images = new Akira.Models.ListModel<Lib.Models.CanvasImage> ();

        border_color = Gdk.RGBA ();
        fill_color = Gdk.RGBA ();

        window.event_bus.insert_item.connect (set_item_to_insert);
        window.event_bus.request_delete_item.connect (on_request_delete_item);
        window.event_bus.change_item_z_index.connect (on_change_item_z_index);
        window.event_bus.hold_released.connect (on_hold_released);
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
                start_x += item.relative_x;
                start_y += item.relative_y;
            }
        }

        set_item_to_insert ("image");
        var new_item = insert_item (start_x, start_y, manager);
        (new_item as Models.CanvasImage).resize_pixbuf (-1, -1, true);

        selected_bound_manager.add_item_to_selection (new_item);
        selected_bound_manager.set_initial_coordinates (start_x, start_y);
    }

    public Models.CanvasItem? insert_item (
        double x,
        double y,
        Lib.Managers.ImageManager? manager = null,
        bool loaded = false
    ) {
        udpate_default_values ();

        Models.CanvasItem? new_item = null;
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
                break;
            }
        }

        switch (insert_type) {
            case Models.CanvasItemType.RECT:
                new_item = add_rect (x, y, root, artboard, loaded);
                break;

            case Models.CanvasItemType.ELLIPSE:
                new_item = add_ellipse (x, y, root, artboard, loaded);
                break;

            case Models.CanvasItemType.TEXT:
                new_item = add_text (x, y, root, artboard, loaded);
                break;

            case Models.CanvasItemType.ARTBOARD:
                new_item = add_artboard (x, y);
                break;

            case Models.CanvasItemType.IMAGE:
                new_item = add_image (x, y, manager, root, artboard, loaded);
                break;
        }

        if (new_item != null) {
            switch (new_item.item_type) {
                case Akira.Lib.Models.CanvasItemType.ARTBOARD:
                    artboards.add_item.begin ((Models.CanvasArtboard) new_item);
                    break;

                case Akira.Lib.Models.CanvasItemType.IMAGE:
                default:
                    // We need to store images in a dedicated list since we will need
                    // to easily access them and save them in the .akira/Pictures folder.
                    if (new_item.item_type == Akira.Lib.Models.CanvasItemType.IMAGE) {
                        images.add_item.begin ((new_item as Akira.Lib.Models.CanvasImage), loaded);
                    }

                    if (new_item.artboard == null) {
                        // Add it to "free items"
                        free_items.add_item.begin (new_item, loaded);
                    }
                    break;
            }

            window.event_bus.item_inserted (new_item);
            window.event_bus.file_edited ();
        }

        return new_item;
    }

    public void add_item (Akira.Lib.Models.CanvasItem item) {
        free_items.add_item.begin (item);
        window.event_bus.file_edited ();
    }

    public void on_request_delete_item (Lib.Models.CanvasItem item) {
        switch (item.item_type) {
            case Akira.Lib.Models.CanvasItemType.ARTBOARD:
                artboards.remove_item.begin (item as Models.CanvasArtboard);
                break;

            case Akira.Lib.Models.CanvasItemType.IMAGE:
            default:
                // Remove the image from the list so we don't keep it in the saved file.
                if (item.item_type == Akira.Lib.Models.CanvasItemType.IMAGE) {
                    images.remove_item.begin ((item as Akira.Lib.Models.CanvasImage));

                    // Mark it for removal if we have a saved file.
                    if (window.akira_file != null) {
                        window.akira_file.remove_image.begin (
                            (item as Akira.Lib.Models.CanvasImage).manager.filename
                        );
                    }
                }

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
            root);

        return artboard as Models.CanvasItem;
    }

    public Models.CanvasItem add_rect (
        double x,
        double y,
        Goo.CanvasItem parent,
        Models.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Models.CanvasRect (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            parent,
            artboard,
            loaded
        );
    }

    public Models.CanvasEllipse add_ellipse (
        double x,
        double y,
        Goo.CanvasItem parent,
        Models.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Models.CanvasEllipse (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            0.0,
            0.0,
            border_size,
            border_color,
            fill_color,
            parent,
            artboard,
            loaded
        );
    }

    public Models.CanvasText add_text (
        double x,
        double y,
        Goo.CanvasItem parent,
        Models.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Models.CanvasText (
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

    public Models.CanvasImage add_image (
        double x,
        double y,
        Lib.Managers.ImageManager manager,
        Goo.CanvasItem parent,
        Models.CanvasArtboard? artboard,
        bool loaded
    ) {
        return new Models.CanvasImage (
            Utils.AffineTransform.fix_size (x),
            Utils.AffineTransform.fix_size (y),
            manager,
            parent,
            artboard,
            loaded
        );
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

    /*
     * Create an item loaded from an opened file.
     *
     * @param Json.Object obj - The json object containing the item to load.
     */
    public void load_item (Json.Object obj) {
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
                insert_type = Models.CanvasItemType.RECT;
                item = insert_item (pos_x, pos_y, null, true);
                break;

            case "AkiraLibModelsCanvasEllipse":
                insert_type = Models.CanvasItemType.ELLIPSE;
                item = insert_item (pos_x, pos_y, null, true);
                break;

            case "AkiraLibModelsCanvasText":
                insert_type = Models.CanvasItemType.TEXT;
                item = insert_item (pos_x, pos_y, null, true);
                break;

            case "AkiraLibModelsCanvasArtboard":
                insert_type = Models.CanvasItemType.ARTBOARD;
                item = insert_item (pos_x, pos_y, null, true);
                break;

            case "AkiraLibModelsCanvasImage":
                insert_type = Models.CanvasItemType.IMAGE;
                var filename = obj.get_string_member ("image_id");
                var file = File.new_for_path (
                    Path.build_filename (
                        window.akira_file.pictures_folder.get_path (),
                        filename
                    )
                );
                var manager = new Akira.Lib.Managers.ImageManager.from_archive (file, filename);
                item = insert_item (pos_x, pos_y, manager, true);
                break;
        }

        restore_attributes (item, artboard, obj);
        restore_selection (obj.get_boolean_member ("selected"), item);
    }

    /*
     * Restore the saved attributes of a loaded object.
     *
     * @param Models.CanvasItem item - The newly created item.
     * @param Json.Object obj - The json object containing the item's attributes.
     */
    private void restore_attributes (Models.CanvasItem item, Models.CanvasArtboard? artboard, Json.Object obj) {
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

        // Restore image size.
        if (item is Models.CanvasImage) {
            (item as Models.CanvasImage).resize_pixbuf (
                (int) obj.get_double_member ("width"),
                (int) obj.get_double_member ("height"),
                true
            );
        }

        // Restore layer options.
        item.locked = obj.get_boolean_member ("locked");
        item.visibility =
            obj.get_int_member ("visibility") == 2
                ? Goo.CanvasItemVisibility.VISIBLE
                : Goo.CanvasItemVisibility.INVISIBLE;

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
        if (item is Models.CanvasArtboard) {
            item.bounds.x1 = transform.get_double_member ("x0");
            item.bounds.y1 = transform.get_double_member ("y0");
            item.bounds.x2 = transform.get_double_member ("x0") + obj.get_double_member ("width");
            item.bounds.y2 = transform.get_double_member ("y0") + obj.get_double_member ("height");
        }

        // Since free items are loaded upside down, always raise to the top position
        // the newly added free item.
        if (artboard == null & !(item is Models.CanvasArtboard)) {
            item.lower (null);
        }

        // Reset the loaded attribute to prevent sorting issues inside artboards.
        item.loaded = false;
    }

    /**
     * Restore the selected status of an object.
     *
     * @param bool selected - If the object is selected.
     * @param Models.CanvasItem item - The newly created item.
     */
    private void restore_selection (bool selected, Models.CanvasItem item) {
        if (selected) {
            window.main_window.main_canvas.canvas.selected_bound_manager.add_item_to_selection (item);
        }
    }

    /**
     * Handle the aftermath of an item transformation, like size changes or movement.
     */
    private void on_hold_released () {
        // We need to copy the array of selected items as we need to remove and add items once
        // moved to force the natural redraw of the canvas.
        var items = window.main_window.main_canvas.canvas.selected_bound_manager.selected_items.copy ();

        if (items.length () == 0) {
            return;
        }

        // If we have images in the canvas, check if they're part of the selection to recalculate the size.
        if (images.get_n_items () > 0) {
            foreach (var image in images) {
                if (items.find (image) != null) {
                    image.check_resize_pixbuf ();
                }
            }
        }

        // Interrupt if no artboard is currently present.
        if (artboards.get_n_items () == 0) {
            return;
        }

        // Check if any of the currently moved items was dropped inside or outside any artboard.
        foreach (var item in items) {
            if (item is Models.CanvasArtboard) {
                continue;
            }

            // Interrupt if the item is already inside an artboard and was only moved within it.
            if (item.artboard != null && item.artboard.dropped_inside (item)) {
                continue;
            }

            Models.CanvasArtboard? new_artboard = null;

            foreach (Models.CanvasArtboard artboard in artboards) {
                // Interrupt the loop if we find an artboard that matches the dropped coordinate.
                if (artboard.dropped_inside (item)) {
                    new_artboard = artboard;
                    break;
                }
            }

            change_artboard (item, new_artboard);
        }
    }

    /**
     * Add or remove an item from an artboard.
     */
    public void change_artboard (Models.CanvasItem item, Models.CanvasArtboard? new_artboard) {
        // Interrupt if the item was moved within its original artboard.
        if (item.artboard == new_artboard) {
            debug ("Same parent");
            return;
        }

        // Save the coordinates before removing the item.
        var x = item.get_global_coord ("x");
        var y = item.get_global_coord ("y");

        // If the item was moved from inside an Artboard to the emtpy Canvas.
        if (item.artboard != null && new_artboard == null) {
            debug ("Artbord => Free Item");
            // Remove the item from the Artboard.
            item.artboard.remove_item (item);
            window.event_bus.item_deleted (item);

            // Attach the item to the Canvas.
            item.set_parent (root);

            // Insert the item back into the Canvas, add the Layer,
            // reset its position, and add it back to the selection.
            add_item (item);
            item.position_item (x, y);

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }

        // If the item was moved from the empty Canvas to an Artboard.
        if (item.artboard == null && new_artboard != null) {
            debug ("Free Item => Artboard");
            // Remove the item from the free items.
            free_items.remove_item.begin (item);
            item.parent.remove_child (item.parent.find_child (item));
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            item.artboard = new_artboard;

            // Insert the item back into the Artboard, add the Layer,
            // reset its position, and add it back to the selection.
            item.position_item (x, y);
            item.connect_to_artboard ();

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }

        // If the item was moved from inside an Artboard to another Artboard.
        if (item.artboard != null && new_artboard != null) {
            debug ("Artbord => Artboard");
            // Remove the item from the Artboard.
            item.artboard.remove_item (item);
            window.event_bus.item_deleted (item);

            // Attach the item to the Artboard.
            item.artboard = new_artboard;

            // Insert the item back into the Artboard, add the Layer,
            // reset its position, and add it back to the selection.
            item.position_item (x, y);
            item.connect_to_artboard ();

            // Trigger the canvas repaint after the item was added back.
            window.event_bus.item_inserted (item);
            window.event_bus.request_add_item_to_selection (item);
            window.event_bus.file_edited ();

            return;
        }
    }
}
