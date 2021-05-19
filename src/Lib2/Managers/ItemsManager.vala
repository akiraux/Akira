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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib2.Managers.ItemsManager : Object {
    public unowned Lib2.ViewCanvas view_canvas { get; construct; }

    private int last_id = 100;
    public Gee.LinkedList<Lib2.Items.ModelItem> items;
    public Gee.HashMap<int, Lib2.Items.ModelItem> items_by_id;

    public ItemsManager (Lib2.ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    construct {
        items = new Gee.LinkedList<Lib2.Items.ModelItem> ();
        items_by_id = new Gee.HashMap<int, Lib2.Items.ModelItem> ();
    }

    public void add_item_to_canvas (Lib2.Items.ModelItem item) {
        if (item == null) {
            return;
        }

        item.id = ++last_id;
        items.add (item);
        items_by_id[item.id] = item;

        item.geometry_changed.connect(on_item_geometry_changed);

        item.compile_components (false);
        item.add_to_canvas (view_canvas);
        item.notify_view_of_changes ();

    }

    public Lib2.Items.ModelItem? hit_test (double x, double y) {
        Lib2.Items.ModelItem? result = null;

        var target = view_canvas.get_item_at (x, y, true);

        if (target == null || !(target is Lib2.Items.CanvasItem)) {
            return result;
        }

        var c_item = target as Lib2.Items.CanvasItem;
        if (items_by_id.has_key (c_item.parent_id)) {
            result = items_by_id[c_item.parent_id];
        }

        return result;
    }

    public void move_item_to (Lib2.Items.ModelItem item, double new_x, double new_y) {
        item.components.center = new Lib2.Components.Coordinates (new_x, new_y);
        item.components.compiled_geometry = null;
        item.compile_components (true);
    }

    private void compile_items() {
        foreach (var item in items) {
            item.compile_components (false);
        }
    }

    public Lib2.Items.ModelItem add_debug_rect (double x, double y) {
        var new_rect = new Lib2.Items.ModelRect (
            new Lib2.Components.Coordinates (x, y),
            new Lib2.Components.Size (50.0, 50.0, false),
            Lib2.Components.Borders.single_color (Lib2.Components.Color (0.3, 0.3, 0.3, 1.0), 2),
            Lib2.Components.Fills.single_color (Lib2.Components.Color (0.0, 0.0, 0.0, 1.0))
        );

        add_item_to_canvas(new_rect);
        return new_rect;
    }

    public void debug_add_rectangles (uint num_of, bool debug_timer = false) {
    	ulong microseconds;
        double seconds;

        // create a timer object:
        Timer timer = new Timer ();

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        for (var i = 0; i < num_of; ++i) {
            var x = GLib.Random.double_range(0, (GLib.Math.log(num_of + GLib.Math.E) - 1) * 1000);
            var y = GLib.Random.double_range(0, (GLib.Math.log(num_of + GLib.Math.E) - 1) * 1000);
            var new_item = add_debug_rect(x, y);
            view_canvas.selection_manager.add_to_selection (new_item);
        }

        if (debug_timer) {
            timer.stop ();
         	seconds = timer.elapsed (out microseconds);
            print ("Created %u items in %s s\n", num_of, seconds.to_string ());
        }
    }

    public void on_item_geometry_changed (int id) {
        if (view_canvas.selection_manager.selection.has_item_id (id)) {
            view_canvas.selection_manager.on_selection_changed ();
        }
    }
}
