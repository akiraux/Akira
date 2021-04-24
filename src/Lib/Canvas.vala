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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alberto Fanjul <albertofanjul@gmail.com>
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Canvas : Goo.Canvas {
    public weak Akira.Window window { get; construct; }

    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const int GRID_THRESHOLD = 3;

    // List of accepted dragged targets.
    private const Gtk.TargetEntry[] TARGETS = {
        {"text/uri-list", 0, 0}
    };

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    public Managers.ExportManager export_manager;
    public Managers.SelectedBoundManager selected_bound_manager;
    public Managers.NobManager nob_manager;
    private Managers.HoverManager hover_manager;
    private Managers.ModeManager mode_manager;

    public bool ctrl_is_pressed = false;
    public bool shift_is_pressed = false;
    public bool holding;
    public double current_scale = 1.0;
    private Gdk.CursorType current_cursor = Gdk.CursorType.ARROW;

    // Used to show the canvas bounds of selected items.
    private Goo.CanvasRect ghost;

    // Used to show a pixel grid on the whole canvas.
    private Goo.CanvasGrid pixel_grid;
    private bool is_grid_visible;

    public Canvas (Akira.Window window) {
        Object (window: window);
    }

    construct {
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        events |= Gdk.EventMask.TOUCHPAD_GESTURE_MASK;
        events |= Gdk.EventMask.TOUCH_MASK;

        export_manager = new Managers.ExportManager (this);
        selected_bound_manager = new Managers.SelectedBoundManager (this);
        nob_manager = new Managers.NobManager (this);

        hover_manager = new Managers.HoverManager (this);
        mode_manager = new Managers.ModeManager (this);

        create_pixel_grid ();

        // Make the canvas a destination for drag actions.
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGETS, Gdk.DragAction.COPY);
        drag_data_received.connect (on_drag_data_received);

        window.event_bus.toggle_pixel_grid.connect (on_toggle_pixel_grid);
        window.event_bus.update_pixel_grid.connect (on_update_pixel_grid);
        window.event_bus.update_scale.connect (on_update_scale);
        window.event_bus.set_scale.connect (on_set_scale);
        window.event_bus.set_focus_on_canvas.connect (on_set_focus_on_canvas);
        window.event_bus.request_escape.connect (on_escape_key);
        window.event_bus.insert_item.connect (on_insert_item);
    }

    /**
     * Handle the data received after a drag and drop action.
     */
    private void on_drag_data_received (
        Gdk.DragContext drag_context,
        int x,
        int y,
        Gtk.SelectionData data,
        uint info,
        uint time
    ) {
        // Loop through the list of the dragged files.
        int index = 0;
        foreach (string link in data.get_uris ()) {
            var file_link = link.replace ("file://", "").replace ("file:/", "");
            file_link = Uri.unescape_string (file_link);
            var image = File.new_for_path (file_link);
            if (!Utils.Image.is_valid_image (image)) {
                continue;
            }
            // Create the image manager.
            var manager = new Lib.Managers.ImageManager (image, index);
            // Let the app know that we're adding image items.
            window.event_bus.insert_item ("image");
            // Create the item.
            var item = window.items_manager.insert_item (x, y, manager);
            // Force the resize of the item to its original size.
            ((Lib.Items.CanvasImage)item).resize_pixbuf (-1, -1, true);
            index++;
        }

        Gtk.drag_finish (drag_context, true, false, time);

        update_canvas ();
        // Reset the edit mode.
        edit_mode = EditMode.MODE_SELECTION;
    }

    private void create_pixel_grid () {
        pixel_grid = new Goo.CanvasGrid (
            null,
            0, 0,
            Layouts.MainCanvas.CANVAS_SIZE,
            Layouts.MainCanvas.CANVAS_SIZE,
            1, 1, 0, 0);

        var grid_rgba = Gdk.RGBA ();
        grid_rgba.parse (settings.grid_color);

        pixel_grid.horz_grid_line_width = pixel_grid.vert_grid_line_width = 0.02;
        pixel_grid.horz_grid_line_color_gdk_rgba = pixel_grid.vert_grid_line_color_gdk_rgba = grid_rgba;
        pixel_grid.visibility = Goo.CanvasItemVisibility.HIDDEN;
        pixel_grid.set ("parent", get_root_item ());
        pixel_grid.can_focus = false;
        pixel_grid.pointer_events = Goo.CanvasPointerEvents.NONE;
        is_grid_visible = false;
    }

    /**
     * Trigger the update of the pixel grid after the settings color have been changed.
     */
    private void on_update_pixel_grid () {
        var grid_rgba = Gdk.RGBA ();
        grid_rgba.parse (settings.grid_color);

        pixel_grid.horz_grid_line_color_gdk_rgba = pixel_grid.vert_grid_line_color_gdk_rgba = grid_rgba;
    }

    public void interaction_mode_changed () {
        set_cursor_by_interaction_mode ();
    }

    public void set_cursor_by_interaction_mode () {
        hover_manager.remove_hover_effect ();
        Gdk.CursorType? new_cursor = mode_manager.active_cursor_type ();

        if (new_cursor == null) {
            var hover_cursor = Akira.Lib.Managers.NobManager.cursor_from_nob (nob_manager.hovered_nob);
            new_cursor = (hover_cursor == null) ? Gdk.CursorType.ARROW : hover_cursor;
        }

        if (current_cursor != new_cursor) {
            // debug (@"Changing cursor. $new_cursor");
            set_cursor (new_cursor);
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = true;
                toggle_item_ghost (false);
                break;

            case Gdk.Key.Shift_L:
            case Gdk.Key.Shift_R:
                shift_is_pressed = true;
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                // Show the ghost item only if the CTRL button is not pressed.
                toggle_item_ghost (!ctrl_is_pressed);
                break;

        }

        if (mode_manager.key_press_event (event)) {
            return true;
        }

        switch (uppercase_keyval) {
            case Gdk.Key.space:
                mode_manager.start_panning_mode ();
                if (mode_manager.key_press_event (event)) {
                    return true;
                }
                break;

            case Gdk.Key.Up:
            case Gdk.Key.Down:
            case Gdk.Key.Right:
            case Gdk.Key.Left:
                window.event_bus.move_item_from_canvas (event);
                window.event_bus.detect_artboard_change ();
                break;
        }

        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = false;
                break;

            case Gdk.Key.Shift_L:
            case Gdk.Key.Shift_R:
                shift_is_pressed = false;
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                toggle_item_ghost (false);
                break;
        }

        if (mode_manager.key_release_event (event)) {
            return true;
        }

        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        focus_canvas ();

        holding = true;

        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        hover_manager.remove_hover_effect ();

        if (mode_manager.button_press_event (event)) {
            return true;
        }

        if (event.button == Gdk.BUTTON_MIDDLE) {
            mode_manager.start_panning_mode ();
            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

        return press_event_on_selection (event);
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (mode_manager.button_release_event (event)) {
            return true;
        }

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        window.event_bus.coordinate_change (event.x, event.y);

        if (mode_manager.motion_notify_event (event)) {
            return true;
        }

        var nob_hovered = nob_manager.hit_test (event.x, event.y);
        if (nob_hovered != nob_manager.hovered_nob) {
            nob_manager.hovered_nob = nob_hovered;
            set_cursor_by_interaction_mode ();
        }

        if (nob_hovered != Akira.Lib.Managers.NobManager.Nob.NONE) {
            hover_manager.remove_hover_effect ();
        }
        else {
            hover_manager.add_hover_effect (event.x, event.y);
        }

        return false;
    }

    public void start_export_area_selection () {
        var new_mode = new Akira.Lib.Modes.ExportMode (this, mode_manager);
        mode_manager.register_mode (new_mode);
    }

    public void on_insert_item () {
        var new_mode = new Akira.Lib.Modes.ItemInsertMode (this, mode_manager);
        mode_manager.register_mode (new_mode);
    }

    /*
     * Perform a series of updates after an item is created.
     */
    public void update_canvas () {
        // Update the pixel grid if it's visible in order to move it to the foreground.
        if (is_grid_visible) {
            update_pixel_grid ();
        }
        // Synchronous update to make sure item is initialized before any other event.
        update ();
    }

    /*
     * Handle escape key.
     */
    public void on_escape_key () {
        mode_manager.deregister_active_mode ();
        // Clear the selected export area to be sure to not leave anything behind.
        export_manager.clear ();
        // Clear the image manager in case the user was adding an image.
        window.items_manager.image_manager = null;

        on_set_focus_on_canvas ();
    }

    public void on_set_focus_on_canvas () {
        ctrl_is_pressed = false;
        focus_canvas ();
        // Clear the selected export area to be sure to not leave anything behind.
        export_manager.clear ();
    }

    public void focus_canvas () {
        grab_focus (get_root_item ());
    }

    private bool press_event_on_selection (Gdk.EventButton event) {

        var nob_clicked = nob_manager.hit_test (event.x, event.y);
        nob_manager.set_selected_by_name (nob_clicked);

        if (nob_clicked == Akira.Lib.Managers.NobManager.Nob.NONE) {
            var clicked_item = get_item_at (event.x, event.y, true);

            // Deselect if no item was clicked, or a non selected artboard was clicked.
            // We do this to allow users to clear the selection when clicking on the
            // empty artboard space, which is a white GooCanvasRect item.
            if (
                clicked_item == null ||
                (
                    clicked_item is Goo.CanvasRect &&
                    !(clicked_item is Items.CanvasItem) &&
                    !(clicked_item is Selection.Nob) &&
                    !((Items.CanvasItem) clicked_item.parent).layer.selected
                )
            ) {
                selected_bound_manager.reset_selection ();
                // TODO: allow for multi select with click & drag on canvas
                // Workaround: when no item is clicked, there's no point in keeping holding active
                holding = false;
                return true;
            }

            // If we're clicking on the Artboard's label, change the target to the Artboard.
            if (
                clicked_item is Goo.CanvasText &&
                clicked_item.parent is Items.CanvasArtboard &&
                !(clicked_item is Items.CanvasItem)
            ) {
                clicked_item = clicked_item.parent as Items.CanvasItem;
            }

            if (clicked_item is Items.CanvasItem) {
                var item = clicked_item as Items.CanvasItem;

                // Item has been selected.
                selected_bound_manager.add_item_to_selection (item);
            }
        }

        selected_bound_manager.set_initial_coordinates (event.x, event.y);

        if (selected_bound_manager.selected_items.length () > 0) {
            var new_mode = new Akira.Lib.Modes.TransformMode (this, mode_manager);
            mode_manager.register_mode (new_mode);

            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }
        else {
            nob_manager.set_selected_by_name (Akira.Lib.Managers.NobManager.Nob.NONE);
        }

        return false;
    }

    private void on_update_scale (double zoom) {
        // Force the zoom value to 8% if we're currently at a 2% scale in order
        // to go back to 10% and increase from there.
        if (current_scale == 0.02 && zoom == 0.1) {
            zoom = 0.08;
        }

        current_scale += zoom;
        // Prevent the canvas from shrinking below 2%;
        if (current_scale < 0.02) {
            current_scale = 0.02;
        }

        // Prevent the canvas from growing above 5000%;
        if (current_scale > 50) {
            current_scale = 50;
        }

        window.event_bus.set_scale (current_scale);
    }

    private void on_set_scale (double scale) {
        current_scale = scale;
        set_scale (scale);
        window.event_bus.zoom ();

        // Check if the user requested the pixel grid and if is not already visible.
        if (!is_grid_visible) {
            return;
        }

        // If the pixel grid is visible, hide it based on the canvas scale
        // in order to avoid a visually jarring canvas.
        if (current_scale < GRID_THRESHOLD) {
            pixel_grid.visibility = Goo.CanvasItemVisibility.HIDDEN;
        } else {
            pixel_grid.visibility = Goo.CanvasItemVisibility.VISIBLE;
            // Always move the grid to the top of the stack.
            var root = get_root_item ();
            root.move_child (root.find_child (pixel_grid), window.items_manager.get_items_count ());
        }
    }

    private void set_cursor (Gdk.CursorType? cursor_type) {
        // debug (@"Setting cursor: $cursor_type");
        current_cursor = cursor_type;

        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().set_cursor (cursor);
    }

    /*
     * Show or hide the ghost bounding box of the selected items.
     */
    public void toggle_item_ghost (bool show) {
        // If no items is selected we can't show anything.
        if (selected_bound_manager.selected_items.length () == 0) {
            return;
        }

        // Temporarily get the first item until multi select is implemented.
        var item = selected_bound_manager.selected_items.nth_data (0);

        if (show) {
            ghost = new Goo.CanvasRect (
                null,
                item.coordinates.x1, item.coordinates.y1,
                item.coordinates.x2 - item.coordinates.x1, item.coordinates.y2 - item.coordinates.y1,
                "line-width", 1.0 / current_scale,
                "stroke-color", "#41c9fd",
                null
            );
            ghost.set ("parent", get_root_item ());
            ghost.can_focus = false;
            ghost.pointer_events = Goo.CanvasPointerEvents.NONE;
            return;
        }

        if (ghost != null) {
            ghost.remove ();
        }
    }

    /*
     * Show or hide the pixel grid based on its state.
     */
    private void on_toggle_pixel_grid () {
        if (!is_grid_visible) {
            update_pixel_grid ();
            is_grid_visible = true;
            return;
        }

        pixel_grid.visibility = Goo.CanvasItemVisibility.HIDDEN;
        is_grid_visible = false;
    }

    /*
     * Updates pixel grid if visible, useful to guarantee z-order in paint composition.
     */
    public void update_pixel_grid_if_visible () {
        if (is_grid_visible) {
            update_pixel_grid ();
        }
    }

    private void update_pixel_grid () {
        // Show the grid only if we're zoomed in enough.
        if (current_scale >= GRID_THRESHOLD) {
            pixel_grid.visibility = Goo.CanvasItemVisibility.VISIBLE;
            // Always move the grid to the top of the stack.
            var root = get_root_item ();
            root.move_child (root.find_child (pixel_grid), window.items_manager.get_items_count ());
        }
    }
}
