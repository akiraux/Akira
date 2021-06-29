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
    }

    private void update_visibility(string color_mode) {
        if(color_mode == "solid") {
            var start_x = start_nob.center_x;
            var start_y = start_nob.center_y;
            var end_x = end_nob.center_x;
            var end_y = end_nob.center_y;

            start_nob.update_state(Cairo.Matrix.identity(), start_x, start_y, false);
            end_nob.update_state(Cairo.Matrix.identity(), end_x, end_y, false);
        } else {
            var start_x = start_nob.center_x;
            var start_y = start_nob.center_y;
            var end_x = end_nob.center_x;
            var end_y = end_nob.center_y;

            start_nob.update_state(Cairo.Matrix.identity(), start_x, start_y, true);
            end_nob.update_state(Cairo.Matrix.identity(), end_x, end_y, true);
        }
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