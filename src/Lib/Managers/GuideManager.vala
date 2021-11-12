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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

 public class Akira.Lib.Managers.GuideManager : Object {
    public enum Direction {
        NONE,
        HORIZONTAL,
        VERTICAL
    }

    public unowned Lib.ViewCanvas view_canvas { get; construct; }
    private GuideData guide_data;

    public GuideManager (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas
        );

        guide_data = new GuideData ();
    }

     public bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        if (uppercase_keyval == Gdk.Key.Q) {
            print("press q\n");
            int x_pos = 0, y_pos = 0;
            get_current_pointer_position (out x_pos, out y_pos);

            guide_data.add_h_guide (y_pos);
            view_canvas.guide_layer.update_guide_data (guide_data);

            return true;
        } else if (uppercase_keyval == Gdk.Key.W) {
            print("press w\n");
            int x_pos = 0, y_pos = 0;
            get_current_pointer_position (out x_pos, out y_pos);

            guide_data.add_v_guide (x_pos);
            view_canvas.guide_layer.update_guide_data (guide_data);

            return true;
        }

        return false;
    }

    public bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public bool button_press_event (Gdk.EventButton event) {
        return false;
    }

    public bool button_release_event (Gdk.EventButton event) {
        return false;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        return false;
    }

    private void get_current_pointer_position (out int x_pos, out int y_pos) {
        var display = Gdk.Display.get_default ();
        var seat = display.get_default_seat ();
        var mouse = seat.get_pointer ();

        var window = display.get_default_group ();
        window.get_device_position (mouse, out x_pos, out y_pos, null);
    }
 }

 public class Akira.Lib.Managers.GuideData {
    // Stores the coordinates of horizontal guides.
    // Since a guideline is a straight line (either horizontal or vertical),
    // we only need one coordinate to store a line.
    public int[] h_guides;
    // Stores the coordinates of vertical guides.
    public int[] v_guides;

    public void add_h_guide (int pos) {
        h_guides.resize (h_guides.length + 1);
        h_guides[h_guides.length - 1] = pos;
    }

    public void add_v_guide (int pos) {
        v_guides.resize (v_guides.length + 1);
        v_guides[v_guides.length - 1] = pos;
    }
 }