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

    public weak Goo.Canvas canvas { get; construct; }
    public unowned List<Goo.CanvasItem> selected_items {
        get {
            return _selected_items;
        }
        set {
            _selected_items = value;

            update_bounding_box ();
        }
    }

    private Goo.CanvasBounds select_bb;
    private unowned List<Goo.CanvasItem> _selected_items;

    public SelectedBoundManager (Goo.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        reset_selection ();
    }

    public void add_item_to_selection (Goo.CanvasItem item) {
        selected_items.append (item);
    }

    public void delete_selection () {
        debug ("Delete selection");
    }

    public void reset_selection () {
        selected_items = new List<Goo.CanvasItem> ();
    }

    private void update_bounding_box  () {
        if (selected_items.length () == 0) {
            event_bus.selected_items_bb_changed (null);
            return;
        }

        // Bounding box edges
        double bb_left = 1e6, bb_top = 1e6, bb_right = 0, bb_bottom = 0;

        foreach (var item in selected_items) {
            Goo.CanvasBounds item_bounds;
            item.get_bounds (out item_bounds);

            bb_left = double.min(bb_left, item_bounds.x1);
            bb_top = double.min(bb_top, item_bounds.y1);
            bb_right = double.max(bb_right, item_bounds.x2);
            bb_bottom = double.max(bb_bottom, item_bounds.y2);
        }

        select_bb = Goo.CanvasBounds () {
            x1 = bb_left,
            y1 = bb_top,
            x2 = bb_right,
            y2 = bb_bottom
        };

        event_bus.selected_items_bb_changed (select_bb);
    }
}
