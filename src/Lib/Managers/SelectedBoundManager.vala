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

    private Managers.SnapManager snap_manager;

    private Goo.CanvasBounds select_bb;
    private double initial_event_x;
    private double initial_event_y;
    private double delta_x_accumulator;
    private double delta_y_accumulator;
    private double initial_width;
    private double initial_height;

    // Attributes to keep track of the mouse dragging coordinates.
    private double initial_drag_press_x;
    private double initial_drag_press_y;
    private bool initial_drag_registered = false;
    private double initial_drag_item_x;
    private double initial_drag_item_y;
    private Cairo.Matrix initial_item_transform;

    // Adjustment applied to scaling to snap it to the pixel grid.
    private double scale_item_x_adj;
    private double scale_item_y_adj;

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
        canvas.window.event_bus.zoom.connect (on_canvas_zoom);
    }

    construct {
        snap_manager = new Managers.SnapManager (canvas);
        reset_selection ();
    }

    public void set_initial_coordinates (double event_x, double event_y) {
        initial_event_x = event_x;
        initial_event_y = event_y;

        initial_drag_press_x = event_x;
        initial_drag_press_y = event_y;
        // We deregister any old drag, and the next will be registered on the
        // first drag move_from_event call.
        initial_drag_registered = false;

        if (selected_items.length () == 1) {
            var selected_item = selected_items.nth_data (0);

            delta_x_accumulator = 0.0;
            delta_y_accumulator = 0.0;

            initial_width = selected_item.size.width;
            initial_height = selected_item.size.height;

            return;
        }

        initial_width = select_bb.x2 - select_bb.x1;
        initial_height = select_bb.y2 - select_bb.y1;
    }

    public void transform_bound (
        double event_x,
        double event_y,
        Managers.NobManager.Nob selected_nob
    ) {
        Items.CanvasItem selected_item = selected_items.nth_data (0);

        if (selected_item == null) {
            return;
        }

        switch (selected_nob) {
            case Managers.NobManager.Nob.NONE:
                move_from_event (selected_item, event_x, event_y);
                break;

            case Managers.NobManager.Nob.ROTATE:
                Utils.AffineTransform.rotate_from_event (
                    selected_item, event_x, event_y,
                    ref initial_event_x, ref initial_event_y
                );
                break;

            default:
                scale_from_event (selected_item, selected_nob, event_x, event_y);
                break;
        }

        // Notify the X & Y values in the state manager.
        canvas.window.event_bus.reset_state_coords (selected_item);
    }

    public void add_item_to_selection (Items.CanvasItem item) {
        // Don't clear and reselect the same element if it's already selected.
        if (selected_items.index (item) != -1) {
            return;
        }

        // Just 1 selected element at the same time
        // TODO: allow for multi selection with shift pressed
        reset_selection ();

        if (item.layer.locked) {
            return;
        }

        item.layer.selected = true;
        item.size.update_ratio ();

        // Initialize the state manager coordinates before adding the item to the selection.
        canvas.window.event_bus.init_state_coords (item);

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

    public void alert_held_button_release () {
        snap_manager.reset_decorators ();
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

    /**
     * Move the item based on the mouse click and drag event.
     */
    private void move_from_event (Lib.Items.CanvasItem item, double event_x, double event_y) {
        if (!initial_drag_registered) {
            initial_drag_registered = true;
            initial_drag_item_x = item.coordinates.x;
            initial_drag_item_y = item.coordinates.y;
        }

        // Keep reset and delta values for future adjustments.

        // Calculate values needed to reset to the original position.
        var reset_x = item.coordinates.x - initial_drag_item_x;
        var reset_y = item.coordinates.y - initial_drag_item_y;

        // Calculate the change based on the event.
        var delta_x = event_x - initial_drag_press_x;
        var delta_y = event_y - initial_drag_press_y;

        // Keep reset and delta values for future adjustments. fix_size should.
        // be called right before a transform.
        var first_move_x = Utils.AffineTransform.fix_size (delta_x - reset_x);
        var first_move_y = Utils.AffineTransform.fix_size (delta_y - reset_y);

        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        // Increment the cairo matrix coordinates so we can ignore the item's rotation.
        matrix.x0 += first_move_x;
        matrix.y0 += first_move_y;
        item.set_transform (matrix);

        // Interrupt if the user disabled the snapping or we don't have any
        // adjacent item to snap to.
        if (!settings.enable_snaps || window.items_manager.get_items_count () == 1) {
            return;
        }

        // Make adjustment basted on snaps.
        // Double the sensitivity to allow for reuse of grid after snap.
        var sensitivity = Utils.Snapping.adjusted_sensitivity (canvas.current_scale);
        var snap_grid = Utils.Snapping.generate_best_snap_grid (canvas, selected_items, sensitivity);

        // Interrupt if we don't have any snap to use.
        if (snap_grid.is_empty ()) {
            return;
        }

        int snap_offset_x = 0;
        int snap_offset_y = 0;
        var matches = Utils.Snapping.generate_snap_matches (snap_grid, selected_items, sensitivity);

        if (matches.h_data.snap_found ()) {
            snap_offset_x = matches.h_data.snap_offset ();
            matrix.x0 += snap_offset_x;
        }

        if (matches.v_data.snap_found ()) {
            snap_offset_y = matches.v_data.snap_offset ();
            matrix.y0 += snap_offset_y;
        }

        item.set_transform (matrix);
        update_grid_decorators (true);
    }

    private void on_canvas_zoom () {
        update_grid_decorators (false);
    }

    private void update_grid_decorators (bool force) {
        if (force || snap_manager.is_active ()) {
            var sensitivity = Utils.Snapping.adjusted_sensitivity (canvas.current_scale);
            var snap_grid = Utils.Snapping.generate_best_snap_grid (canvas, selected_items, sensitivity);
            var matches = Utils.Snapping.generate_snap_matches (snap_grid, selected_items, sensitivity);
            snap_manager.populate_decorators_from_data (matches, snap_grid);
        }
    }

    private void scale_from_event (
        Lib.Items.CanvasItem item,
        Managers.NobManager.Nob selected_nob,
        double event_x,
        double event_y
    ) {
        if (!initial_drag_registered) {
            item.get_transform (out initial_item_transform);
            initial_drag_registered = true;
            initial_drag_item_x = item.coordinates.x1;
            initial_drag_item_y = item.coordinates.y1;
            scale_item_x_adj = 0;
            scale_item_y_adj = 0;

            // If rotation is multiple of 90, then snap to pixel grid before scale.
            if (item.rotation != null && GLib.Math.fmod (item.rotation.rotation, 90) == 0) {
                scale_item_x_adj = Utils.AffineTransform.fix_size (initial_drag_item_x) - initial_drag_item_x;
                scale_item_y_adj = Utils.AffineTransform.fix_size (initial_drag_item_y) - initial_drag_item_y;
                initial_width = Utils.AffineTransform.fix_size (initial_width);
                initial_height = Utils.AffineTransform.fix_size (initial_height);
            }
        }

        double rel_event_x = event_x;
        double rel_event_y = event_y;
        double rel_press_x = initial_drag_press_x;
        double rel_press_y = initial_drag_press_y;

        var canvas = (Lib.Canvas) item.canvas;
        // Convert the coordinates from the canvas to the item so we know the real
        // values even if the item is rotated.
        canvas.convert_to_item_space (item, ref rel_event_x, ref rel_event_y);
        canvas.convert_to_item_space (item, ref rel_press_x, ref rel_press_y);

        // Calculate the change based on the event.
        var delta_x = rel_event_x - rel_press_x;
        var delta_y = rel_event_y - rel_press_y;

        bool ratio_locked = canvas.ctrl_is_pressed || item.size.locked;

        // These values will be populated.
        double inc_width = 0;
        double inc_height = 0;
        double inc_x = 0;
        double inc_y = 0;

        Utils.AffineTransform.calculate_size_adjustments (
            selected_nob,
            initial_width,
            initial_height,
            delta_x,
            delta_y,
            initial_width / initial_height,
            ratio_locked,
            canvas.shift_is_pressed,
            initial_item_transform,
            ref inc_x,
            ref inc_y,
            ref inc_width,
            ref inc_height
        );

        var reset_width = item.size.width - initial_width;
        var reset_height = item.size.height - initial_height;

        Cairo.Matrix new_matrix;
        item.get_transform (out new_matrix);
        new_matrix.x0 = initial_item_transform.x0 + inc_x + scale_item_x_adj;
        new_matrix.y0 = initial_item_transform.y0 + inc_y + scale_item_y_adj;
        item.set_transform (new_matrix);

        Utils.AffineTransform.adjust_size (item, inc_width - reset_width, inc_height - reset_height);
    }
}
