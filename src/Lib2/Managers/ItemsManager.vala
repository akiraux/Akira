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
    public unowned Lib2.ViewCanvas view_canvas {set; get;}

    public Gee.ArrayList<Lib2.Items.ModelItem> items;

    public ItemsManager (Lib2.ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    construct {
        items = new Gee.ArrayList<Lib2.Items.ModelItem> ();
    }

    public void add_item_to_canvas (Lib2.Items.ModelItem item) {
        if (item == null) {
            return;
        }

        items.add(item);
        item.compile_components(false);
        item.add_to_canvas (view_canvas);
        item.notify_view_of_changes ();
    }

    public Lib2.Items.ModelItem add_debug_rect (double x, double y) {
        var new_rect = new Lib2.Items.ModelRect (
            new Lib2.Components.Coordinates (x, y),
            new Lib2.Components.Size (50.0, 50.0, false),
            Lib2.Components.Borders.single_color (Lib2.Components.Color (1.0, 1.0), 2),
            Lib2.Components.Fills.single_color (Lib2.Components.Color (1.0))
        );

        add_item_to_canvas(new_rect);
        return new_rect;
    }

    public void move_item_to (Lib2.Items.ModelItem item, double new_x, double new_y) {
        item.components.coordinates = new Lib2.Components.Coordinates (new_x, new_y);
        item.components.compiled_geometry = null;
        item.compile_components (true);
    }

    private void compile_items() {
        foreach (var item in items) {
            item.compile_components (false);
        }
    }


}
