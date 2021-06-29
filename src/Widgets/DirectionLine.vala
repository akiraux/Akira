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
    
    public DirectionLine (Window window, GradientEditor gradient_editor) {
        var root = window.main_window.main_canvas.canvas.get_root_item();
        start_nob = new Lib.Selection.Nob(root, Lib.Managers.NobManager.Nob.GRADIENT_START);
        end_nob = new Lib.Selection.Nob(root, Lib.Managers.NobManager.Nob.GRADIENT_END);

        start_nob.set_rectangle();
        end_nob.set_rectangle();

        start_nob.update_state(Cairo.Matrix.identity(), 50, 50, false);
        end_nob.update_state(Cairo.Matrix.identity(), 150, 150, false);

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
}