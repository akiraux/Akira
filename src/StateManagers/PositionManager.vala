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

public class Akira.StateManagers.PositionManager : Object {
    public weak Akira.Window window { get; construct; }
    private weak Akira.Lib.Canvas canvas;

    // These attributes represent only the primary X & Y coordinates of the selected shapes.
    // These are not the origin points of each selected shape, but only the TOP-LEFT most values
    // representing the current user selection.
    private double _x = 0;
    public double x {
        get {
            return _x;
        }
        set {
            if (value == _x) {
                return;
            }

            _x = Utils.AffineTransform.fix_size (value);
            update_selected_items ();
        }
    }

    private double _y = 0;
    public double y {
        get {
            return _y;
        }
        set {
            if (value == _y) {
                return;
            }

            _y = Utils.AffineTransform.fix_size (value);
            update_selected_items ();
        }
    }

    public PositionManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        canvas = window.main_window.main_canvas.canvas;

        window.event_bus.init_state_coords.connect (on_init_state_coords);
        window.event_bus.update_state_coords.connect (on_update_state_coords);
    }

    private void on_init_state_coords (Lib.Models.CanvasItem item) {
        // Get the matrix transform coordinates.
        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        //  warning ("MATRIX X: %f - Y: %f", matrix.x0, matrix.y0);
        //  warning ("BOUNDS X: %f - Y: %f", item.bounds_manager.x1, item.bounds_manager.y1);

        // Store the coordinates into local variables for later manipulation.
        var new_x = matrix.x0;
        var new_y = matrix.y0;

        // Account for the item rotation and get the difference between
        // its bounds and matrix coordinates.
        //  if (item.rotation != 0) {
        //      new_x -= (matrix.x0 - item.bounds_manager.x1);
        //      new_y -= (matrix.y0 - item.bounds_manager.y1);
        //  }

        // Interrupt if no value has changed.
        if (new_x == x && new_y == y) {
            return;
        }

        // Update the value to reflect the origin point relative to the parent artboard.
        if (item.artboard != null) {
            //  warning ("ARTBOARD");
            new_x -= item.artboard.bounds.x1;
            new_y -= item.artboard.bounds.y1 + item.artboard.get_label_height ();
        }

        // Update the values.
        x = new_x;
        y = new_y;
    }

    private void on_update_state_coords (double new_x, double new_y) {
        if (new_x == 0 && new_y == 0) {
            return;
        }

        if (new_x != 0) {
            x += new_x;
        }

        if (new_y != 0) {
            y += new_y;
        }
    }

    private void update_selected_items () {
        foreach (Lib.Models.CanvasItem item in canvas.selected_bound_manager.selected_items) {
            if (item.artboard != null) {
                item.relative_x = x;
                item.relative_y = y;
            } else {
                Cairo.Matrix matrix;
                item.get_transform (out matrix);

                matrix.x0 = x;
                matrix.y0 = y;

                item.set_transform (matrix);
            }
            item.bounds_manager.update ();
        }

        window.event_bus.item_value_changed ();
    }
}
