/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Managers.SelectedBoundManager : Object {

    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const int BOUNDS_H = 10000;
    private const int BOUNDS_W = 10000;

    public weak Goo.Canvas canvas { get; construct; }
    public unowned List<Models.CanvasItem> selected_items {
        get {
            return _selected_items;
        }
        set {
            _selected_items = value;

            update_bounding_box ();
        }
    }

    private unowned List<Models.CanvasItem> _selected_items;
    private Goo.CanvasBounds select_bb;
    private double initial_event_x;
    private double initial_event_y;
    private double initial_width;
    private double initial_height;

    public SelectedBoundManager (Goo.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        reset_selection ();
    }

    public void set_initial_coordinates (double event_x, double event_y) {
        if (selected_items.length () == 1) {
            var selected_item = selected_items.nth_data (0);

            initial_event_x = event_x;
            initial_event_y = event_y;

            canvas.convert_to_item_space (selected_item, ref initial_event_x, ref initial_event_y);

            initial_width = selected_item.get_coords ("width");
            initial_height = selected_item.get_coords ("height");
        } else {
            initial_event_x = event_x;
            initial_event_y = event_y;

            initial_width = select_bb.x2 - select_bb.x1;
            initial_height = select_bb.y2 - select_bb.y1;
        }
    }

    public void transform_bound (double event_x, double event_y, Managers.NobManager.Nob selected_nob) {
        switch (selected_nob) {
            case Managers.NobManager.Nob.NONE:
                move (event_x, event_y);
                break;

            case Managers.NobManager.Nob.ROTATE:
                debug ("Rotate");
                break;

            default:
                scale (event_x, event_y, selected_nob);
                break;
        }

        update_bounding_box ();
    }

    private void scale (double x, double y, Managers.NobManager.Nob selected_nob) {
        Models.CanvasItem selected_item;
        selected_item = selected_items.nth_data (0);

        canvas.convert_to_item_space (selected_item, ref x, ref y);

        double delta_x = x - initial_event_x;
        double delta_y = y - initial_event_y;

        double item_width = selected_item.get_coords ("width");
        double item_height = selected_item.get_coords ("height");

        double item_x = selected_item.get_coords ("x");
        double item_y = selected_item.get_coords ("y");

        double new_width = item_width;
        double new_height = item_height;

        double origin_move_delta_x = 0.0;
        double origin_move_delta_y = 0.0;

        switch (selected_nob) {
            case Managers.NobManager.Nob.TOP_LEFT:
                new_height = initial_height - delta_y;
                new_width = initial_width - delta_x;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case Managers.NobManager.Nob.TOP_CENTER:
                new_height = initial_height - delta_y;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case Managers.NobManager.Nob.TOP_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height - delta_y;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case Managers.NobManager.Nob.RIGHT_CENTER:
                new_width = initial_width + delta_x;
                break;

            case Managers.NobManager.Nob.BOTTOM_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height + delta_y;
                break;

            case Managers.NobManager.Nob.BOTTOM_CENTER:
                new_height = initial_height + delta_y;
                break;

            case Managers.NobManager.Nob.BOTTOM_LEFT:
                new_height = initial_height + delta_y;
                new_width = initial_width - delta_x;

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case Managers.NobManager.Nob.LEFT_CENTER:
                new_width = initial_width - delta_x;

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;
        }

        origin_move_delta_x = Math.round (origin_move_delta_x);
        origin_move_delta_y = Math.round (origin_move_delta_y);

        new_width = fix_size (new_width);
        new_height = fix_size (new_height);

        if (new_width == MIN_SIZE) {
            origin_move_delta_x = 0.0;
        }

        if (new_height == MIN_SIZE) {
            origin_move_delta_y = 0.0;
        }

        // Before translating, recover the original "canvas" position of
        // initial_event, in order to convert it to the "new" translated
        // item space after the transformation has been applied.
        canvas.convert_from_item_space (selected_item, ref initial_event_x, ref initial_event_y);
        selected_item.translate (origin_move_delta_x, origin_move_delta_y);
        canvas.convert_to_item_space (selected_item, ref initial_event_x, ref initial_event_y);

        selected_item.set ("width", new_width, "height", new_height);
    }

    private void move (double x, double y) {
        Models.CanvasItem selected_item = selected_items.nth_data (0);

        canvas.convert_to_item_space (selected_item, ref x, ref y);

        double delta_x = Math.round (x - initial_event_x);
        double delta_y = Math.round (y - initial_event_y);

        selected_item.translate (delta_x, delta_y);
    }

    public void add_item_to_selection (Models.CanvasItem item) {
        item.selected = true;

        selected_items.append (item);
    }

    public void delete_selection () {
        debug ("Delete selection");
        /*
        if (selected_item != null) {
            selected_item.remove ();

            var artboard = window.main_window.right_sidebar.layers_panel.artboard;
            Akira.Layouts.Partials.Layer layer = selected_item.get_data<Akira.Layouts.Partials.Layer?> ("layer");
            if (layer != null) {
                artboard.container.remove (layer);
            }
            remove_select_effect ();
            remove_hover_effect ();
        }
        */
    }

    public void reset_selection () {
        foreach (var item in selected_items) {
            item.selected = false;
        }

        selected_items = new List<Models.CanvasItem> ();
    }

    private void update_bounding_box () {
        if (selected_items.length () == 0) {
            event_bus.selected_items_bb_changed (null);
            return;
        }

        // Bounding box edges
        double bb_left = 1e6, bb_top = 1e6, bb_right = 0, bb_bottom = 0;

        foreach (var item in selected_items) {
            Goo.CanvasBounds item_bounds;
            item.get_bounds (out item_bounds);

            bb_left = double.min (bb_left, item_bounds.x1);
            bb_top = double.min (bb_top, item_bounds.y1);
            bb_right = double.max (bb_right, item_bounds.x2);
            bb_bottom = double.max (bb_bottom, item_bounds.y2);
        }

        select_bb = Goo.CanvasBounds () {
            x1 = bb_left,
            y1 = bb_top,
            x2 = bb_right,
            y2 = bb_bottom
        };

        event_bus.selected_items_bb_changed (select_bb);
    }

    private double fix_x_position (double x, double width, double delta_x) {
        var min_delta = Math.round (MIN_POS - width);
        var max_delta = Math.round (BOUNDS_H - MIN_POS);

        var new_x = Math.round (x + delta_x);

        if (new_x < min_delta) {
            return 0;
        } else if (new_x > max_delta) {
            return 0;
        } else {
            return delta_x;
        }
    }

    private double fix_y_position (double y, double height, double delta_y) {
        var min_delta = Math.round (MIN_POS - height);
        var max_delta = Math.round (BOUNDS_H - MIN_POS);

        var new_y = Math.round (y + delta_y);

        if (new_y < min_delta) {
            return 0;
        } else if (new_y > max_delta) {
            return 0;
        } else {
            return delta_y;
        }
    }

    private double fix_size (double size) {
        var new_size = Math.round (size);
        return new_size > MIN_SIZE ? new_size : MIN_SIZE;
    }
}
