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
    private void on_init_state_coords (Lib.Items.CanvasItem item) {
        // Get the item X & Y coordinates.
        double item_x = item.coordinates.x;
        double item_y = item.coordinates.y;

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
    private void on_reset_state_coords (Lib.Items.CanvasItem item) {
        do_update = false;

        // Get the item X & Y coordinates.
        double item_x = item.coordinates.x;
        double item_y = item.coordinates.y;

        // Interrupt if no value has changed.
        if (item_x == x && item_y == y) {
            do_update = true;
            return;
        }

        x = item_x;
        y = item_y;

        // Set the same values we just fetched to the Transform attributes
        // in order to trigger the redraw of all the elements using them.
        item.coordinates.x = item_x;
        item.coordinates.y = item_y;

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
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            if (!do_update) {
                continue;
            }

            // Store the new coordinates in local variables so we can manipulate them.
            double inc_x = x - item.coordinates.x;
            double inc_y = y - item.coordinates.y;

            Cairo.Matrix matrix;
            item.get_transform (out matrix);

            // Increment the cairo matrix coordinates so we can ignore the item's rotation.
            matrix.x0 += inc_x;
            matrix.y0 += inc_y;

            item.set_transform (matrix);

            // Update the Transform component attributes.
            item.coordinates.x += inc_x;
            item.coordinates.y += inc_y;
        }
    }
}
