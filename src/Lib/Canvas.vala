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

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    private EditMode _edit_mode;
    public EditMode edit_mode {
        get {
            return _edit_mode;
        }
        set {
            if (_edit_mode != value) {
                _edit_mode = value;
                set_cursor_by_edit_mode ();
            }
        }
    }

    public enum EditMode {
        MODE_SELECTION,
        MODE_EXPORT_AREA,
        MODE_INSERT,
        MODE_PAN,
        MODE_PANNING,
    }

    public Managers.ExportManager export_manager;
    public Managers.SelectedBoundManager selected_bound_manager;
    private Managers.NobManager nob_manager;
    private Managers.HoverManager hover_manager;

    public bool ctrl_is_pressed = false;
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

        create_pixel_grid ();

        window.event_bus.toggle_pixel_grid.connect (on_toggle_pixel_grid);
        window.event_bus.update_pixel_grid.connect (on_update_pixel_grid);
        window.event_bus.update_scale.connect (on_update_scale);
        window.event_bus.set_scale.connect (on_set_scale);
        window.event_bus.request_change_cursor.connect (on_request_change_cursor);
        window.event_bus.request_change_mode.connect (on_request_change_mode);
        window.event_bus.set_focus_on_canvas.connect (on_set_focus_on_canvas);
        window.event_bus.request_escape.connect (on_set_focus_on_canvas);
        window.event_bus.insert_item.connect (on_insert_item);
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

    public void set_cursor_by_edit_mode () {
        hover_manager.remove_hover_effect ();
        // debug ("Calling set_cursor_by_edit_mode");
        Gdk.CursorType? new_cursor;

        switch (_edit_mode) {
            case EditMode.MODE_SELECTION:
                new_cursor = Gdk.CursorType.ARROW;
                break;

            case EditMode.MODE_INSERT:
            case EditMode.MODE_EXPORT_AREA:
                new_cursor = Gdk.CursorType.CROSSHAIR;
                break;

            case EditMode.MODE_PAN:
                new_cursor = Gdk.CursorType.HAND2;
                break;

            case EditMode.MODE_PANNING:
                new_cursor = Gdk.CursorType.HAND1;
                break;

            default:
                new_cursor = Gdk.CursorType.ARROW;
                break;
        }

        if (current_cursor != new_cursor) {
            // debug (@"Changing cursor. $new_cursor");
            set_cursor (new_cursor);
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.Escape:
                edit_mode = EditMode.MODE_SELECTION;
                // Clear the selected export area to be sure to not leave anything behind.
                export_manager.clear ();
                // Clear the image manager in case the user was adding an image.
                window.items_manager.image_manager = null;
                break;

            case Gdk.Key.space:
                if (edit_mode != EditMode.MODE_PANNING) {
                    edit_mode = EditMode.MODE_PAN;
                }
                break;

            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = true;
                toggle_item_ghost (false);
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                // Show the ghost item only if the CTRL button is not pressed.
                toggle_item_ghost (!ctrl_is_pressed);
                break;

            case Gdk.Key.Up:
            case Gdk.Key.Down:
            case Gdk.Key.Right:
            case Gdk.Key.Left:
                window.event_bus.move_item_from_canvas (event);
                window.event_bus.detect_artboard_change ();
                break;
        }

        return true;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        switch (uppercase_keyval) {
            case Gdk.Key.space:
                edit_mode = EditMode.MODE_SELECTION;
                break;

            case Gdk.Key.Control_L:
            case Gdk.Key.Control_R:
                ctrl_is_pressed = false;
                break;

            case Gdk.Key.Alt_L:
            case Gdk.Key.Alt_R:
                toggle_item_ghost (false);
                break;
        }

        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        focus_canvas ();

        holding = true;

        event.x = Math.round (event.x / current_scale);
        event.y = Math.round (event.y / current_scale);

        hover_manager.remove_hover_effect ();

        if (event.button == Gdk.BUTTON_MIDDLE) {
            edit_mode = EditMode.MODE_PANNING;
            canvas_scroll_set_origin (event.x, event.y);
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
                selected_bound_manager.reset_selection ();

                var new_item = window.items_manager.insert_item (event.x, event.y);

                selected_bound_manager.add_item_to_selection (new_item);

                selected_bound_manager.set_initial_coordinates (event.x, event.y);

                nob_manager.selected_nob = Managers.NobManager.Nob.BOTTOM_RIGHT;

                // Update the pixel grid if it's visible in order to move it to the foreground.
                if (is_grid_visible) {
                    update_pixel_grid ();
                }
                break;

            case EditMode.MODE_SELECTION:
                var clicked_item = get_item_at (event.x, event.y, true);

                // Check if the user is holding down the shift key.
                bool is_shift = (event.state & Gdk.ModifierType.SHIFT_MASK) > 0;

                // Check if no item was clicked, or a non selected artboard was clicked.
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
                    // Reset the selection if the shift key is not pressed.
                    if (!is_shift) {
                        selected_bound_manager.reset_selection ();
                    }

                    return true;
                }

                var clicked_nob_name = Managers.NobManager.Nob.NONE;

                if (clicked_item is Selection.Nob) {
                    var selected_nob = clicked_item as Selection.Nob;

                    clicked_nob_name = nob_manager.get_grabbed_id (selected_nob);
                }

                nob_manager.selected_nob = clicked_nob_name;

                // If we're clicking on the Artboard's label, change the target to the Artboard.
                if (
                    clicked_item is Goo.CanvasText &&
                    clicked_item.parent is Items.CanvasArtboard &&
                    !(clicked_item is Items.CanvasItem)
                ) {
                    clicked_item = clicked_item.parent as Items.CanvasItem;
                }

                // The clicked item is a valid CanvasItem.
                if (clicked_item is Items.CanvasItem) {
                    Items.CanvasItem item = clicked_item as Items.CanvasItem;

                    // If the item is selected and the shift key is pressed,
                    // remove the item from the selection.
                    if (selected_bound_manager.contains_item (item) && is_shift) {
                        selected_bound_manager.remove_item_from_selection (item);
                        return true;
                    }

                    // Check if the clicked item is currently locked.
                    if (item.layer.locked) {
                        // If the shift key is not pressed, reset the selection.
                        if (!is_shift) {
                            selected_bound_manager.reset_selection ();
                        }

                        return true;
                    }

                    if (!selected_bound_manager.contains_item (item) && !is_shift) {
                        selected_bound_manager.reset_selection ();
                    }

                    // Item has been selected.
                    selected_bound_manager.add_item_to_selection (item);
                }

                selected_bound_manager.set_initial_coordinates (event.x, event.y);
                break;

            case EditMode.MODE_PAN:
                edit_mode = EditMode.MODE_PANNING;
                canvas_scroll_set_origin (event.x, event.y);
                break;

            case EditMode.MODE_EXPORT_AREA:
                selected_bound_manager.reset_selection ();
                export_manager.create_area (event);
                break;
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) {
            return true;
        }

        holding = false;

        // This is a temporary approach to end operations. In the future
        // we may want to have more specific methods.
        selected_bound_manager.alert_held_button_release ();

        if (event.button == Gdk.BUTTON_MIDDLE) {
            edit_mode = EditMode.MODE_SELECTION;
        }

        switch (edit_mode) {
            case EditMode.MODE_PANNING:
                edit_mode = EditMode.MODE_PAN;
                break;

            case EditMode.MODE_EXPORT_AREA:
                export_manager.create_area_snapshot ();
                edit_mode = EditMode.MODE_SELECTION;
                break;

            case EditMode.MODE_SELECTION:
                window.event_bus.detect_artboard_change ();
                window.event_bus.detect_image_size_change ();
                break;

            default:
                edit_mode = EditMode.MODE_SELECTION;
                break;
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        event.x = Math.round (event.x / current_scale);
        event.y = Math.round (event.y / current_scale);

        window.event_bus.coordinate_change (event.x, event.y);

        // Hover effect on items only if we're not holding any button and
        // the user is currently in selection mode.
        if (edit_mode == EditMode.MODE_SELECTION && !holding) {
            hover_manager.add_hover_effect (event.x, event.y);
        }

        if (!holding) {
            // Only motion_hover_effect
            return false;
        }

        switch (edit_mode) {
            case EditMode.MODE_INSERT:
            case EditMode.MODE_SELECTION:
                var selected_nob = nob_manager.selected_nob;
                selected_bound_manager.transform_bound (event.x, event.y, selected_nob);
                break;

            case EditMode.MODE_PANNING:
                canvas_moved (event.x, event.y);
                break;

            case EditMode.MODE_EXPORT_AREA:
                export_manager.resize_area (event.x, event.y);
                break;
        }

        return true;
    }

    public void on_insert_item () {
        edit_mode = EditMode.MODE_INSERT;
    }

    public void on_set_focus_on_canvas () {
        edit_mode = EditMode.MODE_SELECTION;
        ctrl_is_pressed = false;
        focus_canvas ();
        // Clear the selected export area to be sure to not leave anything behind.
        export_manager.clear ();
    }

    public void focus_canvas () {
        grab_focus (get_root_item ());
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

    private void on_request_change_cursor (Gdk.CursorType? cursor_type) {
        // debug ("Setting cursor from on_request_change_cursor");
        if (cursor_type == null) {
            set_cursor_by_edit_mode ();
            return;
        }

        set_cursor (cursor_type);
    }

    private void on_request_change_mode (EditMode mode) {
        edit_mode = mode;
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
                item.transform.x1, item.transform.y1,
                item.transform.x2 - item.transform.x1, item.transform.y2 - item.transform.y1,
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

    /**
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
