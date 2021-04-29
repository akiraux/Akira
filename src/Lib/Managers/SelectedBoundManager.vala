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
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.SelectedBoundManager : Object {
    public weak Akira.Lib.Canvas canvas { get; construct; }
    public weak Akira.Window window { get; construct; }

    private unowned List<Items.CanvasItem> _selected_items;
    public unowned List<Items.CanvasItem> selected_items {
        get {
            return _selected_items;
        }
        set {
            _selected_items = value;
            canvas.window.event_bus.selected_items_list_changed (value);
        }
    }

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

    public void add_item_to_selection (Items.CanvasItem item) {
        // Don't clear and reselect the same element if it's already selected.
        if (selected_items.index (item) != -1) {
            return;
        }

        // Just 1 selected element at the same time
        // TODO: allow for multi selection with shift pressed
        reset_selection ();

        item.layer.selected = true;
        item.size.update_ratio ();

        selected_items.append (item);
        // Initialize the state manager coordinates.
        canvas.window.event_bus.init_state_coords ();

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
        selected_items = new List<Items.CanvasItem> ();
    }

    public void reset_selection () {
        if (selected_items.length () == 0) {
            return;
        }

        foreach (var item in selected_items) {
            item.layer.selected = false;
        }

        selected_items = new List<Items.CanvasItem> ();
    }

    private void update_selected_items () {
        canvas.window.event_bus.selected_items_changed (selected_items);

        foreach (var item in selected_items) {
            if (!(item is Items.CanvasArtboard)) {
                continue;
            }

            Cairo.Matrix matrix;
            item.get_transform (out matrix);
            ((Items.CanvasArtboard) item).label.set_transform (matrix);
        }
    }

    private void change_z_selected (bool raise, bool total) {
        if (selected_items.length () == 0) {
            return;
        }

        Items.CanvasItem selected_item = selected_items.nth_data (0);

        // Cannot move artboard z-index wise.
        if (selected_item is Items.CanvasArtboard) {
            return;
        }

        int items_count = 0;
        int pos_selected = -1;

        if (selected_item.artboard != null) {
            // Inside an artboard.
            items_count = (int) selected_item.artboard.items.get_n_items ();
            pos_selected = items_count - 1 - selected_item.artboard.items.index (selected_item);
        } else {
            items_count = (int) window.items_manager.free_items.get_n_items ();
            pos_selected = items_count - 1 - window.items_manager.free_items.index (selected_item);
        }

        // Interrupt if item position doesn't exist.
        if (pos_selected == -1) {
            warning ("item position doesn't exist");
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

        // Interrupt if the target position is invalid.
        if (target_position == -1) {
            debug ("Target position invalid");
            return;
        }

        Items.CanvasItem target_item = null;

        // z-index is the exact opposite of items placement inside the items list model
        // as the last item is actually the topmost element.
        var source = items_count - 1 - pos_selected;
        var target = items_count - 1 - target_position;

        if (selected_item.artboard != null) {
            target_item = selected_item.artboard.items.get_item (target) as Lib.Items.CanvasItem;
            selected_item.artboard.items.swap_items (source, target);
        } else {
            target_item = window.items_manager.free_items.get_item (target) as Lib.Items.CanvasItem;
            window.items_manager.free_items.swap_items (source, target);
        }

        if (raise) {
            selected_item.raise (target_item);
        } else {
            selected_item.lower (target_item);
        }

        canvas.window.event_bus.z_selected_changed ();
    }

    private void on_flip_item (bool vertical) {
        if (selected_items.length () == 0) {
            return;
        }

        // Loop through all the currently selected items.
        foreach (Items.CanvasItem item in selected_items) {
            // Skip if the item is an Artboard.
            if (item is Items.CanvasArtboard) {
                continue;
            }

            if (vertical) {
                item.flipped.vertical = !item.flipped.vertical;
                continue;
            }

            item.flipped.horizontal = !item.flipped.horizontal;
        }
    }

    private void on_move_item_from_canvas (Gdk.EventKey event) {
        if (selected_items.length () == 0 || !canvas.has_focus) {
            return;
        }

        var amount = (event.state & Gdk.ModifierType.SHIFT_MASK) > 0 ? 10 : 1;
        double x = 0.0, y = 0.0;

        switch (event.keyval) {
            case Gdk.Key.Up:
                y -= amount;
                break;
            case Gdk.Key.Down:
                y += amount;
                break;
            case Gdk.Key.Right:
                x += amount;
                break;
            case Gdk.Key.Left:
                x -= amount;
                break;
        }

        window.event_bus.update_state_coords (x, y);
    }

    private void remove_item_from_selection (Lib.Items.CanvasItem item) {
        if (selected_items.index (item) > -1) {
            selected_items.remove (item);
        }

        canvas.window.event_bus.set_focus_on_canvas ();
    }

}
