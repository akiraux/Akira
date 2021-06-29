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
    private Lib.Selection.Nob start_nob;
    private Lib.Selection.Nob end_nob;

    private string color_mode_type;

    // dummy identity matrix
    private Cairo.Matrix identity_mat = Cairo.Matrix.identity();
    
    public DirectionLine (Window window, GradientEditor gradient_editor) {
        var canvas = window.main_window.main_canvas.canvas as Lib.Canvas;
        var root = canvas.get_root_item();

        start_nob = new Lib.Selection.Nob(root, Lib.Managers.NobManager.Nob.GRADIENT_START);
        end_nob = new Lib.Selection.Nob(root, Lib.Managers.NobManager.Nob.GRADIENT_END);

        start_nob.set_rectangle();
        end_nob.set_rectangle();

        start_nob.update_state(identity_mat, 50, 50, false);
        end_nob.update_state(identity_mat, 150, 150, false);

        set_initial_position(canvas.selected_bound_manager.selected_items);
        update_visibility("solid");

        window.event_bus.color_mode_changed.connect(update_visibility);

        window.event_bus.selected_items_list_changed.connect (() => {
            if(canvas.selected_bound_manager.selected_items.length() == 0) {
                hide_direction_line();
            } else {
                if(color_mode_type != "solid") {
                    show_direction_line();
                }
            }
        });

        start_nob.button_press_event.connect((event) => {return on_button_press(event);});
    }

    private bool on_button_press (Goo.CanvasItem event) {
        print("button pressed\n");

        return false;
    }

    private void update_visibility(string color_mode) {
        color_mode_type = color_mode;

        if(color_mode == "solid") {
            hide_direction_line();
        } else {
            show_direction_line();
        }
    }

    private void hide_direction_line() {
        print("hide selection\n");
        start_nob.set("visibility", Goo.CanvasItemVisibility.HIDDEN);
        end_nob.set("visibility", Goo.CanvasItemVisibility.HIDDEN);
    }

    private void show_direction_line() {
        print("show selection\n");
        start_nob.set("visibility", Goo.CanvasItemVisibility.VISIBLE);
        end_nob.set("visibility", Goo.CanvasItemVisibility.VISIBLE);
    }

    private void set_initial_position (List<Lib.Items.CanvasItem> items) {
        if(items.length() == 1) {
            var item = items.first().data;

            double pos_x = item.coordinates.x;
            double pos_y = item.coordinates.y;
            double width = item.size.width;
            double height = item.size.height;

            // TODO: get the rotation matrix and artboard matrix from item and recalculate position

            start_nob.update_state(identity_mat, pos_x+10, pos_y+10, true);
            end_nob.update_state(identity_mat, pos_x+width-10, pos_y+height-10, true);

        } else {
            // TODO: implement gradients when multiple items are selected
        }
    }
}