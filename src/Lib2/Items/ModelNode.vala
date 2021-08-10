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

public class Akira.Lib2.Items.ModelNode {
    public int id;
    // This is the position of the node relative to its parent.
    public int pos_in_parent = -1;
    public unowned ModelInstance instance;

    public unowned ModelNode parent = null;
    public GLib.Array<unowned ModelNode> children;

    public ModelNode (ModelInstance instance, int pos_in_parent) {
        this.instance = instance;
        this.id = instance.id;
        this.pos_in_parent = pos_in_parent;
    }

    public void swap_children (int pos, int newpos) {
        var tmp = children.data[pos];
        children.data[pos] = children.data[newpos];
        children.data[newpos] = tmp;
    }

    public bool has_child (int id, bool recurse = true) {
        if (children == null) {
            return false;
        }

        foreach (var child in children.data) {
            if (child.id == id) {
                return true;
            }

            if (recurse && child.instance.is_group) {
                if (child.has_child (id)) {
                    return true;
                }
            }
        }

        return false;
    }

    public void items_in_canvas (double x, double y, Cairo.Context cr, ref Gee.ArrayList<unowned ModelNode> nodes) {
        if (instance.drawable_bounding_box.left > x || instance.drawable_bounding_box.right < x
            || instance.drawable_bounding_box.top > y || instance.drawable_bounding_box.bottom < y) {
            return;
        }

        unowned var dr = instance.drawable;
        if (dr.new_hit_test (x, y, cr, true, true)) {
          nodes.add (this);
        }

        if (children != null) {
            foreach (unowned var child in children.data) {
                child.items_in_canvas (x, y, cr, ref nodes);
            }
        }
    }
}

public class Akira.Lib2.Items.PositionKey {
    public string parent_path;
    public int pos_in_parent;

    public static int compare (PositionKey a, PositionKey b) {
        if (a.parent_path == b.parent_path) {
            if (a.pos_in_parent == b.pos_in_parent) {
                return 0;
            }

            return a.pos_in_parent < b.pos_in_parent ? -1 : 1;

        }

        return a.parent_path < b.parent_path ? -1 : 1;
    }
}

public class Akira.Lib2.Items.ChildrenSet {
    public ModelNode parent_node;
    public int first_child;
    public int length;

    // optional array with children nodes
    public GLib.Array<unowned ModelNode> children_in_set;
}
