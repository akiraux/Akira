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

    // These attributes represent only the primary X & Y coordiantes of the selected shapes.
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

    // The items matrix transformation.
    private Cairo.Matrix matrix;

    // Allow or deny updating the items position.
    private bool do_update = true;

    public CoordinatesManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        canvas = window.main_window.main_canvas.canvas;

        window.event_bus.init_state_coords.connect (on_init_state_coords);
        window.event_bus.update_state_coords.connect (on_update_state_coords);
    }

    private void on_init_state_coords (Lib.Models.CanvasItem? item) {
        // Get the items X & Y coordinates.
        double item_x = item.bounds.x1;
        double item_y = item.bounds.y1;

        // Update the coordiantes if the items is inside an Artboard.
        if (item.artboard != null) {
            item_x = item.relative_x;
            item_y = item.relative_y;
        }

        // Interrupt if no value has changed.
        if (item_x == x && item_y == y) {
            //  warning ("SAME");
            return;
        }

        // Update the private attributes and not the public as we don't want to trigger the
        // update_items_coordiantes () when a new item is created.
        _x = item_x;
        _y = item_y;
    }

    /**
     * Update the coordinates to reflect the new position in the transform panel.
     * If the update attribute is FALSE, it means updating the selected items Ciaro.Matrix
     * is not necessary as the coordinates change came from a canvas action that already
     * moved the item.
     */
    private void on_update_state_coords (double moved_x, double moved_y, bool update) {
        do_update = update;

        x += moved_x;
        y += moved_y;

        do_update = true;
    }

    private void update_items_coordinates () {
        if (_x == null || _y == null) {
            return;
        }

        foreach (Lib.Models.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            if (!do_update) {
                item.bounds_manager.update ();
                continue;
            }

            var diff_x = 0.0;
            var diff_y = 0.0;

            if (item.artboard != null) {
                item.relative_x = x;
                item.relative_y = y;
                continue;
            }

            item.get_transform (out matrix);

            // Account for the item rotation and get the difference between
            // its bounds and matrix coordinates.
            diff_x = item.bounds_manager.x1 - matrix.x0;
            diff_y = item.bounds_manager.y1 - matrix.y0;

            matrix.x0 = x - diff_x;
            matrix.y0 = y - diff_y;

            item.set_transform (matrix);
            item.bounds_manager.update ();
        }

        window.event_bus.item_value_changed ();
    }
}
