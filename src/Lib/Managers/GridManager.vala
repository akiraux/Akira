/*
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
 * Manages the Canvas Pixel grid. This class take case of generating and updating
 * the global pixel grid whenever the user requires it. It also listens to the scale
 * variation of the main Canvas in order to return a properly usable grid with decently
 * spaced columns and rows, and a decently rendered grid thickness.
 */
 public class Akira.Lib.Managers.GridManager : Object {
    public weak Lib.Canvas canvas { get; set construct; }

    private Goo.CanvasGrid pixel_grid;
    private bool is_grid_visible;

    public GridManager (Lib.Canvas canvas) {
        this.canvas = canvas;

        create_pixel_grid ();

        canvas.window.event_bus.toggle_pixel_grid.connect (on_toggle_pixel_grid);
        canvas.window.event_bus.update_pixel_grid.connect (on_update_pixel_grid);
        canvas.window.event_bus.set_scale.connect (on_set_scale);
    }

    /*
     * Generate the default pixel grid.
     */
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
        pixel_grid.set ("parent", canvas.get_root_item ());
        pixel_grid.can_focus = false;
        pixel_grid.pointer_events = Goo.CanvasPointerEvents.NONE;
        is_grid_visible = false;
    }

    /*
     * Trigger the update of the pixel grid after the settings color have been changed.
     */
    private void on_update_pixel_grid () {
        var grid_rgba = Gdk.RGBA ();
        grid_rgba.parse (settings.grid_color);

        pixel_grid.horz_grid_line_color_gdk_rgba = pixel_grid.vert_grid_line_color_gdk_rgba = grid_rgba;
    }

    /*
     * Show or hide the pixel grid based on its state.
     */
    private void on_toggle_pixel_grid () {
        if (!is_grid_visible) {
            is_grid_visible = true;
            raise ();
            recalculate ();
            return;
        }

        pixel_grid.visibility = Goo.CanvasItemVisibility.HIDDEN;
        is_grid_visible = false;
    }

    private void on_set_scale (double scale) {
        // Check if the user requested the pixel grid and if is not already visible.
        if (!is_grid_visible) {
            return;
        }

        recalculate ();
    }

    /*
     * Update the pixel grid to always show the most optimal line thickness,
     * as well as number of columns and rows based on the canvas current scale.
     */
    private void recalculate () {
        double thickness = 1;
        double steps = 1;
        var scale = canvas.current_scale;

        // -20%
        if (scale < 0.2) {
            pixel_grid.visibility = Goo.CanvasItemVisibility.HIDDEN;
            return;
        }

        pixel_grid.visibility = Goo.CanvasItemVisibility.VISIBLE;

        // 20% - 50%
        if (scale >= 0.2 && scale < 0.5) {
            thickness = 1;
            steps = 40;
        }

        // 50% - 150%
        if (scale >= 0.5 && scale < 1.5) {
            thickness = 0.5;
            steps = 20;
        }

        // 150% - 200%
        if (scale >= 1.4 && scale < 2) {
            thickness = 0.2;
            steps = 10;
        }

        // 200% - 250%
        if (scale >= 2 && scale < 2.5) {
            thickness = 0.15;
            steps = 9;
        }

        // 250% - 300%
        if (scale >= 2.5 && scale < 3) {
            thickness = 0.1;
            steps = 8;
        }

        // 300% - 350%
        if (scale >= 3 && scale < 3.5) {
            thickness = 0.09;
            steps = 7;
        }

        // 350% - 400%
        if (scale >= 3.5 && scale < 4) {
            thickness = 0.08;
            steps = 7;
        }

        // 400% - 450%
        if (scale >= 4 && scale < 4.5) {
            thickness = 0.08;
            steps = 7;
        }

        // 450% - 500%
        if (scale >= 4.5 && scale < 5) {
            thickness = 0.08;
            steps = 6;
        }

        // 500% - 550%
        if (scale >= 5 && scale < 5.5) {
            thickness = 0.07;
            steps = 5;
        }

        // 550% - 600%
        if (scale >= 5.5 && scale < 6) {
            thickness = 0.07;
            steps = 4;
        }

        // 600% - 650%
        if (scale >= 6 && scale < 6.5) {
            thickness = 0.05;
            steps = 3;
        }

        // 650% - 700%
        if (scale >= 6.5 && scale < 7) {
            thickness = 0.05;
            steps = 2;
        }

        // 700%+
        if (scale >= 7) {
            thickness = 0.02;
            steps = 1;
        }

        // Update line thickness.
        pixel_grid.horz_grid_line_width = pixel_grid.vert_grid_line_width = thickness;

        // Update the steps between columns and rows.
        pixel_grid.x_step = pixel_grid.y_step = steps;
    }

    /*
     * Called when the canvas is updated after the creation of a new item.
     */
    public void on_canvas_update () {
        if (is_grid_visible) {
            raise ();
        }
    }

    /*
     * Move the pixel grid to the top of the stack.
     */
    private void raise () {
        // Update the pixel grid if it's visible in order to move it to the foreground.
        var root = canvas.get_root_item ();
        var current_position = root.find_child (pixel_grid);
        var top_position = root.get_n_children ();

        // The grid should always be below the select effect and nobs,
        // so we decrease the count to account for that, otherwise we
        // decrease by 1 to ignore the grid current position.
        top_position -= canvas.selected_bound_manager.selected_items.length () > 0 ? 11 : 1;

        // Always move the grid to the top of the stack if necessary.
        if (current_position < top_position) {
            root.move_child (current_position, top_position);
        }
    }
}
