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
  * State manager handling the currently selected objects sizings.
  * This is used to guarantee correct values in the Transform Panel no matter
  * if one or multiple items are selected.
  */
public class Akira.StateManagers.SizeManager : Object {
    public weak Akira.Window window { get; construct; }
    private weak Akira.Lib.Canvas canvas;

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
            update_items_width ();
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
            update_items_height ();
        }
    }

    public SizeManager (Akira.Window window) {
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

    /**
     * Initialize the manager sizes with the selected items sizes.
     * The sizes change comes from a canvas action that already moved the items,
     * therefore we set the do_update to false to prevent updating the selected
     * items' Cairo Matrix.
     */
     private void on_init_state_coords () {
        do_update = false;

        // Get the item WIDTH & HEIGHT.
        width = canvas.nob_manager.bb_width;
        height = canvas.nob_manager.bb_height;

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
     * =========== INFO ===========
     * We don't update width and height in the same method for 2 reasons:
     * 1. It's impossible for the user to update both values when interacting with
     *    the Transform panel as only once field cna be edited at the time.
     * 2. We need to let the Size component handle the locked ratio independently
     *    as the locked size will be properly updated when one of the values changes.
     */

    /**
     * Update the width of all selected items.
     */
     private void update_items_width () {
        if (_width == null || !do_update) {
            return;
        }

        // Get the correct modified amount in order to resize all the selected items equally.
        var delta_w = width - canvas.nob_manager.bb_width;

        // Loop through all the selected items to update their width.
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            item.size.width += delta_w;
        }
    }

    /**
     * Update the height of all selected items.
     */
     private void update_items_height () {
        if (_height == null || !do_update) {
            return;
        }

        // Get the correct modified amount in order to resize all the selected items equally.
        var delta_h = height - canvas.nob_manager.bb_height;

        // Loop through all the selected items to update their height.
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            item.size.height += delta_h;
        }
    }
}
