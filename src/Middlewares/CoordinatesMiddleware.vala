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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/**
 * Middleware handling the currently selected objects coordinates with the Transform Panel.
 * This is used to guarantee correct values in the Transform Panel no matter if one or
 * multiple items are selected, and to always return the true items' coordinates which
 * are held by the GooCanvasItem.
 */
public class Akira.StateManagers.CoordinatesMiddleware : Object {
    public weak Akira.Window window { get; construct; }
    private weak Akira.Lib.Canvas canvas;

    // Store the initial coordinates of the item before the values are edited by
    // the user interacting with the Transform Panel fields.
    private double initial_x;
    private double initial_y;

    // These attributes represent only the primary X & Y coordinates of the selected shapes.
    // These are not the origin points of each selected shape, but only the TOP-LEFT values
    // of the bounding box selection.
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
            move_from_panel ();
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
            move_from_panel ();
        }
    }

    // Allow or deny updating the items position.
    private bool do_update = true;

    public CoordinatesMiddleware (Akira.Window window) {
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

    private void get_coordinates_from_items () {
        // Reset the selected coordinates to always get correct values.
        initial_x = 0;
        initial_y = 0;

        var nob_data = new Akira.Lib.Managers.NobManager.ItemNobData ();
        Lib.Managers.NobManager.populate_nob_bounds_from_items (
            canvas.selected_bound_manager.selected_items,
            ref nob_data
        );

        initial_x = nob_data.selected_x;
        initial_y = nob_data.selected_y;
    }

    /**
     * Initialize the manager coordinates with the selected items coordinates.
     * The coordinates change comes from a canvas action that already moved the items,
     * therefore we set the do_update to false to prevent updating the selected
     * items' Cairo Matrix.
     */
    private void on_init_state_coords () {
        do_update = false;

        // Get the items X & Y coordinates.
        get_coordinates_from_items ();

        x = initial_x;
        y = initial_y;

        do_update = true;
    }

    /**
     * Update the coordinates to trigger the shapes transformation.
     * This action comes from an arrow keypress event from the Canvas.
     */
    private void on_update_state_coords (double moved_x, double moved_y) {
        x += moved_x;
        y += moved_y;

        window.event_bus.file_edited ();
    }

    /**
     * Reset the coordinates to get the newly updated coordinates from the selected items.
     * This method is called when items are moved from the canvas, so we only need to update
     * the X and Y values for the Transform Panel without triggering the update_items_*().
     */
    private void on_reset_state_coords () {
        on_init_state_coords ();

        window.event_bus.item_value_changed ();
        window.event_bus.file_edited ();
    }

    /**
     * Update the position of all selected items.
     */
     private void move_from_panel () {
        if (_x == null || _y == null || !do_update) {
            return;
        }

        // Get the current item X & Y coordinates before translating.
        get_coordinates_from_items ();

        // Loop through all the selected items to update their position.
        foreach (Lib.Items.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            // Set the ignore_offset attribute to true to avoid the forced
            // respositioning of the item (magnetic offset snapping).

            var drag_state = new Akira.Lib.Modes.TransformMode.InitialDragState ();
            var tmp = new GLib.List<Lib.Items.CanvasItem> ();
            tmp.append (item);
            if (Akira.Lib.Modes.TransformMode.initialize_items_drag_state (tmp, ref drag_state)) {
                drag_state.wants_snapping = false;
                drag_state.press_x = initial_x;
                drag_state.press_y = initial_y;
                var guide_data = new Akira.Lib.Managers.SnapManager.SnapGuideData ();
                Akira.Lib.Modes.TransformMode.move_from_event (canvas, tmp, drag_state, x, y, ref guide_data);
            }
        }

        window.event_bus.item_value_changed ();
    }
}
