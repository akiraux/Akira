/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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

public class Akira.Lib.Managers.SelectedBoundManager : Object {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Window window { get; construct; }

    private unowned List<Models.CanvasItem> _selected_items;
    public unowned List<Models.CanvasItem> selected_items {
        get {
            return _selected_items;
        }
        set {
            _selected_items = value;
            update_selected_items ();
        }
    }

    private Goo.CanvasBounds select_bb;
    private double initial_event_x;
    private double initial_event_y;
    private double delta_x_accumulator;
    private double delta_y_accumulator;
    private double initial_width;
    private double initial_height;

    public SelectedBoundManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas,
            window: canvas.window
        );

        canvas.window.event_bus.change_z_selected.connect (change_z_selected);
        canvas.window.event_bus.item_value_changed.connect (update_selected_items);
        canvas.window.event_bus.flip_item.connect (on_flip_item);
        canvas.window.event_bus.move_item_from_canvas.connect (on_move_item_from_canvas);
        canvas.window.event_bus.item_deleted.connect (remove_item_from_selection);
        canvas.window.event_bus.request_add_item_to_selection.connect (add_item_to_selection);
        canvas.window.event_bus.item_locked.connect (remove_item_from_selection);
    }

    construct {
        reset_selection ();
    }

    public void set_initial_coordinates (double event_x, double event_y) {
        if (selected_items.length () == 1) {
            var selected_item = selected_items.nth_data (0);

            selected_item.store_relative_position ();

            delta_x_accumulator = 0.0;
            delta_y_accumulator = 0.0;

            initial_event_x = event_x;
            initial_event_y = event_y;

            initial_width = selected_item.get_coords ("width");
            initial_height = selected_item.get_coords ("height");

            return;
        }

        initial_event_x = event_x;
        initial_event_y = event_y;

        initial_width = select_bb.x2 - select_bb.x1;
        initial_height = select_bb.y2 - select_bb.y1;
    }

    public void transform_bound (double event_x, double event_y, Managers.NobManager.Nob selected_nob) {
        Models.CanvasItem selected_item = selected_items.nth_data (0);

        if (selected_item == null) {
            return;
        }

        switch (selected_nob) {
            case Managers.NobManager.Nob.NONE:
                Utils.AffineTransform.move_from_event (
                    selected_item, event_x, event_y,
                    ref initial_event_x, ref initial_event_y
                );
                update_selected_items ();
                break;

            case Managers.NobManager.Nob.ROTATE:
                Utils.AffineTransform.rotate_from_event (
                    event_x, event_y,
                    initial_event_x, initial_event_y,
                    selected_item
                );
                break;

            default:
                Utils.AffineTransform.scale_from_event (
                    event_x, event_y,
                    ref initial_event_x, ref initial_event_y,
                    ref delta_x_accumulator, ref delta_y_accumulator,
                    initial_width, initial_height,
                    selected_nob,
                    selected_item
                );
                break;
        }

        // Notify the X & Y values in the transform panel.
        canvas.window.event_bus.item_coord_changed ();
    }

    public void add_item_to_selection (Models.CanvasItem item) {
        // Don't clear and reselect the same element if it's already selected.
        if (selected_items.index (item) != -1) {
            return;
        }

        // Just 1 selected element at the same time
        // TODO: allow for multi selection with shift pressed
        reset_selection ();

        if (item.locked) {
            return;
        }

        item.selected = true;
        selected_items.append (item);

        // Move focus back to the canvas.
        canvas.window.event_bus.set_focus_on_canvas ();
    }

    public void delete_selection () {
        if (selected_items.length () == 0) {
            return;
        }

        for (var i = 0; i < selected_items.length (); i++) {
            var item = selected_items.nth_data (i);
            canvas.window.event_bus.request_delete_item (item);
        }

        // By emptying the selected_items list, the select_effect gets dropped
        selected_items = new List<Models.CanvasItem> ();
    }

    public void reset_selection () {
        if (selected_items.length () == 0) {
            return;
        }

        foreach (var item in selected_items) {
            item.selected = false;
        }

        selected_items = new List<Models.CanvasItem> ();
    }

    private void update_selected_items () {
        canvas.window.event_bus.selected_items_changed (selected_items);
    }

    private void change_z_selected (bool raise, bool total) {
        if (selected_items.length () == 0) {
            return;
        }

        Models.CanvasItem selected_item = selected_items.nth_data (0);

        // Cannot move artboard z-index wise
        if (selected_item is Models.CanvasArtboard) {
            return;
        }

        int items_count = 0;
        int pos_selected = -1;

        if (selected_item.artboard != null) {
            // Inside an artboard
            items_count = (int) selected_item.artboard.items.get_n_items ();
            pos_selected = items_count - 1 - selected_item.artboard.items.index (selected_item);
        } else {
            items_count = window.items_manager.get_free_items_count ();
            pos_selected = items_count - 1 - window.items_manager.get_item_position (selected_item);
        }

        // Interrupt if item position doesn't exist.
        if (pos_selected == -1) {
            return;
        }

        int target_position = -1;

        if (raise) {
            if (pos_selected < (items_count - 1)) {
                target_position = pos_selected + 1;
            }

            if (total) {
                target_position = items_count - 1;
            }
        } else {
            if (pos_selected > 0) {
                target_position = pos_selected - 1;
            }

            if (total) {
                target_position = 0;
            }
        }

        if (target_position == -1) {
            // Invalid position, return
            return;
        }

        Models.CanvasItem target_item = null;

        // z-index is the exact opposite of items placement
        // inside the free_items list
        // last in is the topmost element
        var source = items_count - 1 - pos_selected;
        var target = items_count - 1 - target_position;

        if (selected_item.artboard != null) {
            selected_item.artboard.items.swap_items (source, target);

            canvas.window.event_bus.z_selected_changed ();
            selected_item.artboard.changed (true);

            // There is no need to raise or lower the selection
            // since the z stacking is done inside the paint method
            // and it is calculated based on the artboard's children list index
            return;
        }

        target_item = window.items_manager.get_item_at_z_index (target_position);
        window.items_manager.free_items.swap_items (source, target);

        if (raise) {
            selected_item.raise (target_item);
        } else {
            selected_item.lower (target_item);
        }

        canvas.window.event_bus.z_selected_changed ();
    }

    private void on_flip_item (bool clicked, bool vertical) {
        if (selected_items.length () == 0 || selected_items.nth_data (0) is Lib.Models.CanvasArtboard) {
            return;
        }

        selected_items.foreach ((item) => {
            if (vertical) {
                item.flipped_v = !item.flipped_v;
                Utils.AffineTransform.flip_item (clicked, item, 1, -1);
                update_selected_items ();
                return;
            }
            item.flipped_h = !item.flipped_h;
            Utils.AffineTransform.flip_item (clicked, item, -1, 1);
            update_selected_items ();
        });
    }

    private void on_move_item_from_canvas (Gdk.EventKey event) {
        if (selected_items.length () == 0 || !canvas.has_focus) {
            return;
        }

        var amount = (event.state & Gdk.ModifierType.SHIFT_MASK) > 0 ? 10 : 1;

        selected_items.foreach ((item) => {
            var position = Akira.Utils.AffineTransform.get_position (item);

            switch (event.keyval) {
                case Gdk.Key.Up:
                    if (item is Models.CanvasEllipse && item.artboard == null) {
                        amount--;
                    }
                    Utils.AffineTransform.set_position (item, null, position["y"] - amount);
                    break;
                case Gdk.Key.Down:
                    if (item is Models.CanvasEllipse && item.artboard == null) {
                        amount++;
                    }
                    Utils.AffineTransform.set_position (item, null, position["y"] + amount);
                    break;
                case Gdk.Key.Right:
                    if (item is Models.CanvasEllipse && item.artboard == null) {
                        amount++;
                    }
                    Utils.AffineTransform.set_position (item, position["x"] + amount);
                    break;
                case Gdk.Key.Left:
                    if (item is Models.CanvasEllipse && item.artboard == null) {
                        amount--;
                    }
                    Utils.AffineTransform.set_position (item, position["x"] - amount);
                    break;
            }

            canvas.window.event_bus.item_coord_changed ();
            update_selected_items ();
        });
    }

    private void remove_item_from_selection (Lib.Models.CanvasItem item) {
        if (selected_items.index (item) > -1) {
            selected_items.remove (item);
        }

        canvas.window.event_bus.set_focus_on_canvas ();
    }
}
