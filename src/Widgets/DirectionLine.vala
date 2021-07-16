/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/
public class Akira.Widgets.DirectionLine {
    public Lib.Selection.Nob start_nob;
    public Lib.Selection.Nob end_nob;
    private Lib.Selection.Nob selected_nob;

    private Lib.Canvas canvas;
    private Lib.Items.CanvasItem selected_item;
    private GradientEditor gradient_editor;
    private Window window;
    private Akira.Models.ColorModel.Type type;

    // dummy identity matrix
    private Cairo.Matrix identity_mat = Cairo.Matrix.identity ();

    public DirectionLine (Window _window, GradientEditor _gradient_editor, Akira.Models.ColorModel model) {
        type = model.type;

        // since gradients on borders are not yet supported, dont draw direction line
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return;
        }

        window = _window;
        canvas = window.main_window.main_canvas.canvas as Lib.Canvas;
        selected_item = canvas.selected_bound_manager.selected_items.nth_data (0);
        var root = canvas.get_root_item ();
        gradient_editor = _gradient_editor;

        start_nob = new Lib.Selection.Nob (root, Lib.Managers.NobManager.Nob.GRADIENT_START);
        end_nob = new Lib.Selection.Nob (root, Lib.Managers.NobManager.Nob.GRADIENT_END);

        start_nob.set_rectangle ();
        end_nob.set_rectangle ();

        update_visibility (model.color_mode);

        // initial position of direction nobs will be outside the canvas.
        // when CanvasItem gets selected, they will be placed along the diagonal
        start_nob.update_state (identity_mat, -10, -10, false);
        end_nob.update_state (identity_mat, -10, -10, false);

        window.event_bus.color_mode_changed.connect (update_visibility);
        canvas.button_press_event.connect (on_buton_press_event);
        canvas.button_release_event.connect (on_button_release_event);

        window.event_bus.selected_items_list_changed.connect (() => {
            if (type == Akira.Models.ColorModel.Type.BORDER) {
                return;
            }

            if (canvas.selected_bound_manager.selected_items.length () == 0) {
                destroy_direction_line ();
            }

        });

    }

    public void get_direction_coords (out double x0, out double y0, out double x1, out double y1) {
        x0 = start_nob.center_x - selected_item.coordinates.x;
        y0 = start_nob.center_y - selected_item.coordinates.y;
        x1 = end_nob.center_x - selected_item.coordinates.x;
        y1 = end_nob.center_y - selected_item.coordinates.y;
    }

    private bool on_buton_press_event (Gdk.EventButton event) {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return false;
        }

        if (start_nob.hit_test (event.x, event.y, canvas.get_scale ())) {
            selected_nob = start_nob;
            canvas.motion_notify_event.connect (on_motion_event);

            // return true here to prevent the button press event from propogating.
            // this is because in transform_manager, this event causes the canvas item to move
            return true;
        } else if (end_nob.hit_test (event.x, event.y, canvas.get_scale ())) {
            selected_nob = end_nob;
            canvas.motion_notify_event.connect (on_motion_event);

            return true;
        }
        return false;
    }

    private bool on_motion_event (Gdk.EventMotion event) {
        selected_nob.update_state (identity_mat, event.x, event.y, true);
        gradient_editor.create_gradient_pattern ();

        return true;
    }

    private bool on_button_release_event (Gdk.EventButton event) {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return false;
        }

        canvas.motion_notify_event.disconnect (on_motion_event);
        return false;
    }

    private void update_visibility (string color_mode) {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return;
        }

        if (start_nob.center_x == -10 || start_nob.center_y == -10) {
            // if this is the first time the direction line is being displayed,
            // set its default position along diagonal
            double pos_x = selected_item.coordinates.x;
            double pos_y = selected_item.coordinates.y;
            double width = selected_item.size.width;
            double height = selected_item.size.height;
            double offset = Akira.Lib.Selection.Nob.NOB_SIZE;

            start_nob.update_state (identity_mat, pos_x + offset, pos_y + offset, true);
            end_nob.update_state (identity_mat, pos_x + width - offset, pos_y + height - offset, true);
        }

        if (color_mode == "solid") {
            hide_direction_line ();
        } else {
            show_direction_line ();
        }
    }

    private void hide_direction_line () {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return;
        }

        start_nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
        end_nob.set ("visibility", Goo.CanvasItemVisibility.HIDDEN);
    }

    private void show_direction_line () {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return;
        }

        start_nob.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
        end_nob.set ("visibility", Goo.CanvasItemVisibility.VISIBLE);
    }

    private void destroy_direction_line () {
        if (type == Akira.Models.ColorModel.Type.BORDER) {
            return;
        }

        // we need to destroy direction line everytime an item is deselected. This is because
        // when and item is selected, it creates a new instance of DirectionLine. This results in duplicate 
        // start_nob and end_nob
        window.event_bus.color_mode_changed.disconnect (update_visibility);
        canvas.button_press_event.disconnect (on_buton_press_event);
        canvas.button_release_event.disconnect (on_button_release_event);

        hide_direction_line ();
        start_nob.remove ();
        end_nob.remove ();
    }
}
