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

    private Models.GuidelineModel guide_data;
    // Stores the id of currently selected artboard.
    private int artboard_id;

    private Geometry.Point current_cursor;
    private int sel_line;
    private Direction sel_direction;

    public GuideManager (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas
        );

        guide_data = new Models.GuidelineModel ();
        artboard_id = -1;

        view_canvas.scroll_event.connect (on_scroll);
        guide_data.changed.connect (on_guide_data_changed);
        view_canvas.items_manager.items_removed.connect (on_item_delete);
    }

     public bool key_press_event (Gdk.EventKey event) {
        if (!is_within_artboard ()) {
            return false;
        }

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
        /*
        if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
            //  The Double Click to Delete Bug/Feature and its patch.

            //  Why double clicking deletes a guideline
            //      When you click on a guideline, it gets deleted from the SortedArray.
            //      Then you can drag you anywhere. As soon as you release the button, it gets added to 
            //      the sorted array at the correct position. 

            //      When you double click, the events occur as follows
            //          1. click -> delete the guideline.
            //          2. release -> add the guideline we deleted.
            //          3. click -> again delete the same guideline.
            //          4. double click -> should delete the guideline, but none exists coz we just deleted it
            //              At this point, we also enter the guide_data.does_exist_at method. Since there is not guide,
            //              we also make the selected guide as none.
            //          5. release -> no action here. Since there was no selected guide.
            
            //  In case you feel like disabling the double click to delete guide feature, just uncomment
            //  this 'if' block.

            return false;
        }
        */

        if (!is_within_artboard ()) {
            return false;
        } else {
            // In case we clicked on a different artboard, we need to update that data.
            view_canvas.guide_layer.update_guide_data (guide_data);
        }

        Geometry.Point point = Geometry.Point (event.x, event.y);

        if (guide_data.does_guide_exist_at (point, out sel_line, out sel_direction)) {
            guide_data.remove_guide (sel_direction, sel_line);
            guide_data.calculate_distance_positions (current_cursor);
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

            guide_data.reset_distances ();
            
            return true;
        }

        guide_data.reset_distances ();
        
        return false;
    }

    public bool motion_notify_event (Gdk.EventMotion event) {
        // Here, we just want to get the cursor position,
        // so we allow the event to propogate further by returning false.
        current_cursor = Geometry.Point (event.x, event.y);

        if (sel_direction != Direction.NONE) {
            // If while moving a guideline, user takes it out of artboard,
            // delete it immediately.
            if (!guide_data.drawable_extents.contains (current_cursor.x, current_cursor.y)) {
                sel_direction = Lib.Managers.GuideManager.Direction.NONE;
                sel_line = -1;

                return true;
            }

            guide_data.move_guide_to_position (sel_line, sel_direction, current_cursor);
            guide_data.calculate_distance_positions (current_cursor);
            return true;
        }

        int highlight_guide;
        Direction highlight_direction;

        if (guide_data.does_guide_exist_at (current_cursor, out highlight_guide, out highlight_direction)) {
            guide_data.set_highlighted_guide (highlight_guide, highlight_direction);
            return true;
        } else {
            guide_data.set_highlighted_guide (-1, Direction.NONE);
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

    private void on_guide_data_changed () {
        if (view_canvas.guide_layer != null) {
            view_canvas.guide_layer.update_guide_data (guide_data);
        }
    }

    private bool is_within_artboard () {
        var groups = view_canvas.items_manager.item_model.group_nodes;

        // Need to optimize this part.
        foreach (var item in groups) {
            if (item.key >= Lib.Items.Model.GROUP_START_ID) {
                var extents = item.value.instance.bounding_box;

                if (extents.contains (current_cursor.x, current_cursor.y)) {
                    guide_data.changed.disconnect (on_guide_data_changed);
                    guide_data = item.value.instance.guide_data;
                    artboard_id = item.value.instance.id;
                    guide_data.set_drawable_extents (item.value.instance.bounding_box);
                    guide_data.changed.connect (on_guide_data_changed);
                    return true;
                }
            }
        }

        return false;
    }

    private void on_item_delete (GLib.Array<int> del_ids) {
        foreach (var del_id in del_ids.data) {
            if (del_id == artboard_id) {
                guide_data.changed.disconnect (on_guide_data_changed);
                guide_data = new Models.GuidelineModel ();
                guide_data.changed.connect (on_guide_data_changed);
                artboard_id = -1;
                guide_data.changed ();
            }
        }
    }
 }
