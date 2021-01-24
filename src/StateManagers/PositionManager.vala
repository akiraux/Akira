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

    private Lib.Models.CanvasItem? selected_item;
    public double x;
    public double y;

    public PositionManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    construct {
        window.event_bus.selected_items_changed.connect (on_selected_items_changed);
        window.event_bus.item_coord_changed.connect (on_item_coord_changed);
        window.event_bus.init_panel_coord.connect (on_init_panel_coord);
        window.event_bus.panel_x_coord_changed.connect (on_panel_x_coord_changed);
        window.event_bus.panel_y_coord_changed.connect (on_panel_y_coord_changed);
    }

    private void on_selected_items_changed (List<Lib.Models.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            selected_item = null;
            x = 0;
            y = 0;
            return;
        }

        // Temporarily handle only 1 item. This will need to change when
        // implementing multiselection.

        // Interrupt if the selected item didn't change.
        if (selected_item == selected_items.nth_data (0)) {
            return;
        }

        selected_item = selected_items.nth_data (0);
        on_item_coord_changed ();
    }

    private void on_init_panel_coord (double init_x, double init_y) {
        x = init_x;
        y = init_y;

        if (selected_item.artboard != null) {
            x -= selected_item.artboard.bounds.x1;
            y -= selected_item.artboard.bounds.y1 + selected_item.artboard.get_label_height ();
        }

        update_position (true);
    }

    private void on_item_coord_changed () {
        var position = Utils.AffineTransform.get_position (selected_item);

        // Interrupt if nothing changed.
        if (x == position["x"] && y == position["y"]) {
            return;
        }

        x = position["x"];
        y = position["y"];

        update_position (true);
    }

    private void on_panel_x_coord_changed (double panel_x) {
        // Interrupt if nothing changed.
        if (x == panel_x) {
            return;
        }

        x = panel_x;

        update_position ();
    }

    private void on_panel_y_coord_changed (double panel_y) {
        // Interrupt if nothing changed.
        if (y == panel_y) {
            return;
        }

        y = panel_y;

        update_position ();
    }

    private void update_position (bool is_from_shape = false) {
        // Notify that the file has been edited.
        window.event_bus.file_edited ();

        // If the change request comes from a shape, update the value in the
        // Transform Panel.
        if (is_from_shape) {
            window.event_bus.coord_state_changed ();
            return;
        }

        // Otherwise, update the value for the selected shape.
        Utils.AffineTransform.set_position (selected_item, x, y);
        window.event_bus.item_value_changed ();
    }
}