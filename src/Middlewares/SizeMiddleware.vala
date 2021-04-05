/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/**
 * Middleware handling the currently selected objects sizes with the Transform Panel.
 * This is used to guarantee correct values in the Transform Panel no matter if one or
 * multiple items are selected, and to always return the true items' sizes which
 * are held by the GooCanvasItem.
 */
public class Akira.StateManagers.SizeMiddleware : Object {
    public weak Akira.Window window { get; construct; }
    private weak Akira.Lib.Canvas canvas;

    // Store the initial size of the item before the values are edited by
    // the user interacting with the Transform Panel fields.
    private double initial_width;
    private double initial_height;

    // Allow or deny updating the items size.
    private bool do_update = true;

    // These attributes represent only the primary WIDTH & HEIGHT coordinates of the selected shapes.
    // These are not the original sizes of each selected shape, but only the BOTTOM-RIGHT values
    // of the bounding box selection.
    private double? _width = null;
    public double width {
        get {
            return _width != null ? _width : 0;
        }
        set {
            if (value == _width) {
                return;
            }

            _width = Utils.AffineTransform.fix_size (value);
            scale_from_panel ();
        }
    }

    private double? _height = null;
    public double height {
        get {
            return _height != null ? _height : 0;
        }
        set {
            if (value == _height) {
                return;
            }

            _height = Utils.AffineTransform.fix_size (value);
            scale_from_panel ();
        }
    }

    public SizeMiddleware (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        // Get the canvas on construct as we will need to use its methods.
        canvas = window.main_window.main_canvas.canvas;

        // Initialize event listeners.
        window.event_bus.init_state_coords.connect (on_init_state_coords);
        window.event_bus.reset_state_coords.connect (on_reset_state_coords);
    }

    private void get_size_from_items () {
        var dummy_matrix = Cairo.Matrix.identity ();
        double dummy_top_left_x = 0;
        double dummy_top_left_y = 0;
        double dummy_width_offset_x = 0;
        double dummy_width_offset_y = 0;
        double dummy_height_offset_x = 0;
        double dummy_height_offset_y = 0;
        double dummy_x = 0;
        double dummy_y = 0;

        // Reset the selected coordinates to always get correct values.
        initial_width = 0;
        initial_height = 0;

        Lib.Managers.NobManager.populate_nob_bounds_from_items (
            canvas.selected_bound_manager.selected_items,
            ref dummy_matrix,
            ref dummy_top_left_x,
            ref dummy_top_left_y,
            ref dummy_width_offset_x,
            ref dummy_width_offset_y,
            ref dummy_height_offset_x,
            ref dummy_height_offset_y,
            ref initial_width,
            ref initial_height,
            ref dummy_x,
            ref dummy_y
        );
    }

    /**
     * Initialize the manager sizes with the selected items sizes.
     * The sizes change comes from a canvas action that already moved the items,
     * therefore we set the do_update to false to prevent updating the selected
     * items' Cairo Matrix.
     */
     private void on_init_state_coords () {
        do_update = false;

        // Get the items WIDTH & HEIGHT.
        get_size_from_items ();

        width = initial_width;
        height = initial_height;

        do_update = true;
    }

    /**
     * Reset the sizes to get the newly updated sizes from the selected items.
     * This method is called when items are resized from the canvas, so we only need to update
     * the WIDTH & HEIGHT values for the Transform Panel without triggering the update_items_size().
     */
    private void on_reset_state_coords () {
        on_init_state_coords ();

        window.event_bus.item_value_changed ();
        window.event_bus.file_edited ();
    }

    /**
     * Update the size of all selected items.
     */
     private void scale_from_panel () {
        if (_width == null || _height == null || !do_update) {
            return;
        }

        // Loop through all the selected items to update their size.
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            // TODO: We're temporarily applying the exact same size to all selected items.
            // This will change once we implement the multi select and the ability to resize
            // and translate multiple items relative to their position.
            var delta_h = height - item.size.height;
            var delta_w = width - item.size.width;

            item.size.width += delta_w;
            item.size.height += delta_h;
        }
    }
}
