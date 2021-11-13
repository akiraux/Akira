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

    private Geometry.Point current_cursor;

    public GuideManager (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas
        );

        guide_data = new GuideData ();

        view_canvas.scroll_event.connect (on_scroll);
    }

     public bool key_press_event (Gdk.EventKey event) {
        uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);

        if (uppercase_keyval == Gdk.Key.Q) {
            guide_data.add_h_guide (current_cursor.y);
            view_canvas.guide_layer.update_guide_data (guide_data);

            return true;
        } else if (uppercase_keyval == Gdk.Key.W) {
            guide_data.add_v_guide (current_cursor.x);
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
        // Here, we just want to get the cursor position,
        // so we allow the event to propogate further by returning true.
        current_cursor = Geometry.Point (event.x, event.y);
        return false;
    }

    private bool on_scroll (Gdk.EventScroll event) {
        double delta_x, delta_y;
        event.get_scroll_deltas (out delta_x, out delta_y);

        current_cursor.x += delta_x * 10;
        current_cursor.y += delta_y * 10;

        return false;
    }
 }

 public class Akira.Lib.Managers.GuideData {
    // Stores the coordinates of horizontal guides.
    // Since a guideline is a straight line (either horizontal or vertical),
    // we only need one coordinate to store a line.
    public double[] h_guides;
    // Stores the coordinates of vertical guides.
    public double[] v_guides;

    // Stores the extents of guidelines.that were updated.
    // Can't save the extents of all guidelines as they may be spread over a large area.
    public Geometry.Rectangle extents;

    public GuideData () {
        h_guides = new double[0];
        v_guides = new double[0];

        extents = Geometry.Rectangle.empty ();
    }

    public void add_h_guide (double pos) {
        h_guides.resize (h_guides.length + 1);
        h_guides[h_guides.length - 1] = pos;
        update_extents ();
    }

    public void add_v_guide (double pos) {
        v_guides.resize (v_guides.length + 1);
        v_guides[v_guides.length - 1] = pos;
        update_extents ();
    }

    private void update_extents () {
        // TODO: Optimize extents here.
        extents.left = extents.top = 0;
        extents.right = extents.bottom = 10000;
    }
 }