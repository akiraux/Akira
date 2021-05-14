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
 */

/*
 * A selection of items with some useful accessors.
 */
public class Akira.Lib2.Items.ItemSelection : Object {
    public Gee.ArrayList<ModelItem> items;

    public ItemSelection (ModelItem? item) {
        items = new Gee.ArrayList<ModelItem> ();
        if (item != null) {
            items.add(item);
        }
    }

    public void add_item (ModelItem item) {
        foreach (var exitem in items) {
            if (item == exitem) {
                return;
            }
        }

        items.add (item);
    }

    public bool is_empty () { return items.size == 0; }

    public void coordinates (
        ref double tl_x,
        ref double tl_y,
        ref double tr_x,
        ref double tr_y,
        ref double bl_x,
        ref double bl_y,
        ref double br_x,
        ref double br_y
    ) {
        if (items.size == 1) {
            var cg = items[0].compiled_geometry ();
            tl_x = cg.x0 ();
            tl_y = cg.y0 ();
            tr_x = cg.x1 ();
            tr_y = cg.y1 ();
            bl_x = cg.x2 ();
            bl_y = cg.y2 ();
            br_x = cg.x3 ();
            br_y = cg.y3 ();
            return;
        }

        double top = int.MAX;
        double bottom = int.MIN;
        double left = int.MAX;
        double right = int.MIN;

        foreach (var item in items) {
            var cg = item.compiled_geometry ();
            top = double.min(top, cg.bb_top ());
            bottom = double.max(bottom, cg.bb_bottom ());
            left = double.min(left, cg.bb_left ());
            right = double.max(right, cg.bb_right ());
        }

        tl_x = left;
        tl_y = top;
        tr_x = right;
        tr_y = top;
        bl_x = left;
        bl_y = bottom;
        br_x = right;
        br_y = bottom;
    }
}
