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

    public bool has_item (ModelItem item) {
        return items.contains (item);
    }

    public bool is_empty () { return items.size == 0; }

    public void coordinates (
        out double tl_x,
        out double tl_y,
        out double tr_x,
        out double tr_y,
        out double bl_x,
        out double bl_y,
        out double br_x,
        out double br_y,
        out double rotation
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
            rotation = items[0].components.rotation.in_radians ();
            return;
        }

        if (items.size == 0) {
            tl_x = 0.0;
            tl_y = 0.0;
            tr_x = 0.0;
            tr_y = 0.0;
            bl_x = 0.0;
            bl_y = 0.0;
            br_x = 0.0;
            br_y = 0.0;
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
        rotation = 0;
    }

    public void nob_coordinates (Utils.Nobs.Nob nob, double scale, ref double x, ref double y) {
        double tl_x;
        double tl_y;
        double tr_x;
        double tr_y;
        double bl_x;
        double bl_y;
        double br_x;
        double br_y;
        double rot;

        coordinates(out tl_x, out tl_y, out tr_x, out tr_y, out bl_x, out bl_y, out br_x, out br_y, out rot);

        Utils.Nobs.nob_xy_from_coordinates (nob, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y, scale, ref x, ref y);
    }

    public void bounding_box (
        ref double top,
        ref double left,
        ref double bottom,
        ref double right
    ) {
        if (items.size == 0) {
            top = 0.0;
            left = 0.0;
            bottom = 0.0;
            right = 0.0;
            return;
        }

        top = int.MAX;
        bottom = int.MIN;
        left = int.MAX;
        right = int.MIN;

        foreach (var item in items) {
            var cg = item.compiled_geometry ();
            top = double.min(top, cg.bb_top ());
            bottom = double.max(bottom, cg.bb_bottom ());
            left = double.min(left, cg.bb_left ());
            right = double.max(right, cg.bb_right ());
        }
    }
}
