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
 * ModelNode is a DAG representation of the model. It populates the information of an ModelInstance
 * that lives within a Model. This information includes its parent's ModelNode, its children
 * ModelNodes (may be empty) and the original instance.
 *
 * The main purpose of a ModelNode is to ease traversal of the Model without n lookups. It should
 * NOT be cached. There are few exceptions for performance, and when done, it is very important
 * that the lifetime of the container of that cache gets notified whenever a node is destructed.
 * This should very rarely be needed.
 *
 * It is recomended that nodes should be queried on demand from a model whenever needed.
 */
public class Akira.Lib.Items.ModelNode {
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

    /*
     * Return an array of int containing all IDs of the children of this ndoe.
     */
    public int[] get_children_ids () {
        Array<int> children_ids = new Array<int> ();

        if (children == null) {
            return children_ids.data;
        }

        foreach (var child in children.data) {
            children_ids.append_val (child.id);
            get_children_ids_recursive (child, ref children_ids);
        }

        return children_ids.data;
    }

    private void get_children_ids_recursive (ModelNode node, ref Array<int> children_ids) {
        if (node.children == null) {
            return;
        }

        foreach (var child in node.children.data) {
            children_ids.append_val (child.id);
            get_children_ids_recursive (child, ref children_ids);
        }
    }

    public bool has_ancestor (int id, bool recurse = true) {
        var p = parent;

        while (p != null) {
            if (p.id == id) {
                return true;
            }
            p = p.parent;
        }

        return false;
    }

    /*
     * Get the number of ancestors the current model belongs to.
     */
    public int get_ancestors_size () {
        // Start with a negative value since all items have a parent, which is
        // the main canvas, and we want to ignore that.
        int n = -1;
        var p = parent;

        while (p != null) {
            n++;
            p = p.parent;
        }

        return n;
    }

    public void items_in_canvas (
        double x,
        double y,
        Cairo.Context cr,
        double scale,
        Drawables.Drawable.HitTestType hit_test_type,
        ref Gee.ArrayList<unowned ModelNode> nodes
    ) {
        unowned var dr = instance.drawable;
        if (dr == null) {
            if (!instance.bounding_box.contains (x, y)) {
                return;
            }
        }
        else {
            if (dr.hit_test (x, y, cr, scale, hit_test_type)) {
                nodes.add (this);
            }
        }

        if (children != null) {
            foreach (unowned var child in children.data) {
                child.items_in_canvas (x, y, cr, scale, hit_test_type, ref nodes);
            }
        }
    }
}

public class Akira.Lib.Items.PositionKey {
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

public class Akira.Lib.Items.ChildrenSet {
    public ModelNode parent_node;
    public int first_child;
    public int length;

    // optional array with children nodes
    public GLib.Array<unowned ModelNode> children_in_set;
}
