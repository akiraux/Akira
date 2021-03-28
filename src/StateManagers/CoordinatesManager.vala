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

 /*
  * State manager handling the currently selected objects coordinates.
  * This is used to guarantee correct values in the Transform Panel no matter
  * if one or multiple items are selected.
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

    /*
     * Initialize the manager coordinates with the selected items coordinates.
     * The coordinates change comes from a canvas action that already moved the items,
     * therefore we set the do_update to false to prevent updating the selected
     * items' Cairo Matrix.
     */
    private void on_init_state_coords () {
        do_update = false;

        // Get the item X & Y coordinates.
        x = canvas.nob_manager.selected_x;
        y = canvas.nob_manager.selected_y;

        do_update = true;
    }

    /*
     * Update the coordinates to trigger the shapes transformation.
     * This action comes from an arrow keypress event from the Canvas.
     */
    private void on_update_state_coords (double moved_x, double moved_y) {
        x += moved_x;
        y += moved_y;

        window.event_bus.file_edited ();
    }

    /*
     * Reset the coordinates to get the newly updated coordinates from the selected items.
     * This method is called when items are moved from the canvas, so we only need to update
     * the X and Y values for the Transform Panel without triggering the update_items_coordinates().
     */
    private void on_reset_state_coords () {
        on_init_state_coords ();

        window.event_bus.item_value_changed ();
        window.event_bus.file_edited ();
    }

    /*
     * Get the newly updated coordinates and update the position of all selected items.
     */
    private void update_items_coordinates () {
        if (_x == null || _y == null || !do_update) {
            return;
        }

        // Loop through all the selected items to update their position. This is temporary
        // since we currently support only 1 selected item per time. In the future, we will need
        // to account for multiple items and their relative position between each other.
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            Cairo.Matrix matrix;
            item.get_transform (out matrix);

            // Increment the cairo matrix coordinates so we can ignore the item's rotation.
            matrix.x0 += Utils.AffineTransform.fix_size (x - item.coordinates.x);
            matrix.y0 += Utils.AffineTransform.fix_size (y - item.coordinates.y);

            item.set_transform (matrix);

            window.event_bus.item_value_changed ();
        }
    }
}
