/*
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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.StateManagers.CoordinatesManager : Object {
    public weak Akira.Window window { get; construct; }
    private weak Akira.Lib.Canvas canvas;

    // These attributes represent only the primary X & Y coordinates of the selected shapes.
    // These are not the origin points of each selected shape, but only the TOP-LEFT values
    // of the selection bounding box.
    private double? _x = null;
    public double x {
        get {
            return _x != null ? _x : 0;
        }
        set {
            if (value == _x) {
                return;
            }

            _x = Utils.AffineTransform.fix_size (value);
            update_items_coordinates ();
        }
    }

    private double? _y = null;
    public double y {
        get {
            return _y != null ? _y : 0;
        }
        set {
            if (value == _y) {
                return;
            }

            _y = Utils.AffineTransform.fix_size (value);
            update_items_coordinates ();
        }
    }

    // Allow or deny updating the items position.
    private bool do_update = true;

    public CoordinatesManager (Akira.Window window) {
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
        window.event_bus.update_state_coords.connect (on_update_state_coords);
    }

    /**
     * Initialize the manager coordinates with the newly created or selected item.
     */
    private void on_init_state_coords (Lib.Models.CanvasItem item) {
        // Get the half border size.
        double half_border = get_border(item.border_size);

        // Get the item X & Y coordinates bounds in order to account for the item's rotation.
        double item_x = item.bounds.x1 + half_border;
        double item_y = item.bounds.y1 + half_border;

        // Update the coordinates if the item is inside an Artboard.
        if (item.artboard != null) {
            item_x -= item.artboard.bounds.x1;
            item_y -= item.artboard.bounds.y1 + item.artboard.get_label_height ();
        }

        // Interrupt if no value has changed.
        if (item_x == x && item_y == y) {
            return;
        }

        // Update the private attributes and not the public as we don't want to trigger the
        // update_items_coordinates () when a new item is created.
        _x = item_x;
        _y = item_y;
    }

    /**
     * Update the coordinates to trigger the shapes transformation.
     */
    private void on_update_state_coords (double moved_x, double moved_y) {
        x += moved_x;
        y += moved_y;

        window.event_bus.file_edited ();
    }

    /**
     * Reset the coordinates to get the newly updated coordinates from the item.
     * The coordinates change came from a canvas action that already moved the items
     * therefore we set the d_update to false to prevent updating  the selected
     * items Cairo transform.
     */
    private void on_reset_state_coords (Lib.Models.CanvasItem item) {
        do_update = false;

        // Get the half border size.
        double half_border = get_border(item.border_size);

        // Get the item X & Y coordinates bounds in order to account for the item's rotation.
        double item_x = item.bounds.x1 + half_border;
        double item_y = item.bounds.y1 + half_border;

        if (item.artboard != null) {
            item_x -= item.artboard.bounds.x1;
            item_y -= item.artboard.bounds.y1 + item.artboard.get_label_height ();
        }

        // Interrupt if no value has changed.
        if (item_x == x && item_y == y) {
            do_update = true;
            return;
        }

        x = item_x;
        y = item_y;

        do_update = true;

        window.event_bus.file_edited ();
    }

    /**
     * Get the newly updated coordinates update the position of all the selected items.
     */
    private void update_items_coordinates () {
        if (_x == null || _y == null) {
            return;
        }

        // Loop through all the selected items to update their position. This is temporary
        // since we currently support only 1 selected item per time. In the future, we will need
        // to account for multiple items and their relative position between each other.
        foreach (Lib.Models.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            if (!do_update) {
                continue;
            }

            // Update the relative coordinates for items inside the canvas.
            // This will need to be removed after we rebuild the artboards.
            if (item.artboard != null) {
                item.relative_x = x;
                item.relative_y = y;
                continue;
            }

            // Store the new coordinates in local variables so we can manipulate them.
            double inc_x = x;
            double inc_y = y;

            // Convert the new coordinates to reflect the item's space on the canvas.
            canvas.convert_to_item_space (item, ref inc_x, ref inc_y);

            // If the item is rotated, we need to calculate the delta between the
            // new coordinates and item's bounds coordinates.
            if (item.rotation != 0) {
                double half_border = get_border(item.border_size);
                double diff_x = item.bounds.x1 - half_border;
                double diff_y = item.bounds.y1 - half_border;

                // Convert the bounds to the item space to get the proper delta between
                // the bounds coordinates and the rotation X & Y coordinates.
                canvas.convert_to_item_space (item, ref diff_x, ref diff_y);

                inc_x -= diff_x;
                inc_y -= diff_y;
            }

            // Move the item with the new coordinates.
            item.translate (inc_x, inc_y);

            //  // Update the bounds of the ghost item.
            item.bounds_manager.update ();
        }

        // Notify the rest of the UI that a value of the select items has changed.
        window.event_bus.item_value_changed ();
    }

    /**
     * The item's bounds account also for the border width, but we shouldn't,
     * so we need to account for half the border width since we're only dealing
     * with a centered border. In the future, once borders can be inside or outside,
     * we will need to update this condition.
     */
    private double get_border (double size) {
        return size > 0 ? size / 2 : 0;
    }
}
