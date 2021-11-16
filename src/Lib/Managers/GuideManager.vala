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
    private int sel_line;
    private Direction sel_direction;

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
        Geometry.Point point = Geometry.Point (event.x, event.y);

        if (guide_data.does_guide_exist_at (point, out sel_line, out sel_direction)) {
            guide_data.remove_guide (sel_direction, sel_line);
            return true;
        }

        return false;
    }

    public bool button_release_event (Gdk.EventButton event) {
        if (sel_direction != Direction.NONE) {
            if (sel_direction == Direction.HORIZONTAL) {
                guide_data.add_h_guide (guide_data.highlight_position);
            } else if (sel_direction == VERTICAL) {
                guide_data.add_v_guide (guide_data.highlight_position);
            }

            sel_direction = Direction.NONE;
            sel_line = -1;

            print("horizontal are\n");
            foreach (var it in guide_data.h_guides.elements) {
                print("%f ", it);
            }
            print("\nvertical are\n");
            foreach (var it in guide_data.v_guides.elements) {
                print("%f ", it);
            }
            print("\n\n");

            return true;
        }

        return false;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        // Here, we just want to get the cursor position,
        // so we allow the event to propogate further by returning false.
        current_cursor = Geometry.Point (event.x, event.y);

        if (sel_direction != Direction.NONE) {
            guide_data.move_guide_to_position (sel_line, sel_direction, current_cursor);
            view_canvas.guide_layer.update_guide_data (guide_data);
            return true;
        }

        int highlight_guide;
        Direction highlight_direction;

        if (guide_data.does_guide_exist_at (current_cursor, out highlight_guide, out highlight_direction)) {
            guide_data.set_highlighted_guide (highlight_guide, highlight_direction);
            view_canvas.guide_layer.update_guide_data (guide_data);
            return true;
        } else {
            guide_data.set_highlighted_guide (-1, Direction.NONE);
            view_canvas.guide_layer.update_guide_data (guide_data);
            return false;
        }
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
    public Utils.SortedArray h_guides;
    // Stores the coordinates of vertical guides.
    public Utils.SortedArray v_guides;

    public int highlight_guide;
    public GuideManager.Direction highlight_direction;
    public double highlight_position;

    public GuideData () {
        h_guides = new Utils.SortedArray ();
        v_guides = new Utils.SortedArray ();
    }

    public GuideData copy () {
        var clone = new GuideData ();
        
        clone.h_guides = h_guides.clone ();
        clone.v_guides = v_guides.clone ();

        clone.highlight_guide = highlight_guide;
        clone.highlight_direction = highlight_direction;
        clone.highlight_position = highlight_position;

        return clone;
    }

    public void add_h_guide (double pos) {
        h_guides.insert (pos);
    }

    public void add_v_guide (double pos) {
        v_guides.insert (pos);
    }

    public void set_highlighted_guide (int guide, GuideManager.Direction direction) {
        highlight_guide = guide;
        highlight_direction = direction;
        
        if (direction == GuideManager.Direction.HORIZONTAL) {
            highlight_position = h_guides.elements[guide];
        } else if (direction == GuideManager.Direction.VERTICAL) {
            highlight_position = v_guides.elements[guide];
        }
    }

    public bool does_guide_exist_at (Geometry.Point point, out int sel_line, out GuideManager.Direction sel_direction) {
        double thresh = 1;

        for (int i = 0; i < h_guides.length; ++i) {
            if ((h_guides.elements[i] - point.y).abs () < thresh) {
                sel_line = i;
                sel_direction = GuideManager.Direction.HORIZONTAL;
                return true;
            }
        }

        for (int i = 0; i < v_guides.length; ++i) {
            if ((v_guides.elements[i] - point.x).abs () < thresh) {
                sel_line = i;
                sel_direction = GuideManager.Direction.VERTICAL;
                return true;
            }
        }

        sel_line = -1;
        sel_direction = GuideManager.Direction.NONE;
        
        return false;
    }

    public void move_guide_to_position (int position, GuideManager.Direction direction, Geometry.Point new_pos) {
        if (direction == GuideManager.Direction.HORIZONTAL) {
            highlight_position = new_pos.y;
            highlight_direction = direction;
            highlight_guide = position;
        } else if (direction == GuideManager.Direction.VERTICAL) {
            highlight_position = new_pos.x;
            highlight_direction = direction;
            highlight_guide = position;
        }
    }

    public void remove_guide (GuideManager.Direction dir, int pos) {
        if (dir == GuideManager.Direction.HORIZONTAL) {
            h_guides.remove_at (pos);
        } else if (dir == GuideManager.Direction.VERTICAL) {
            v_guides.remove_at (pos);
        }
    }
 }
