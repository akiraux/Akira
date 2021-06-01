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

public class Akira.Lib2.Items.ModelInstance {
    public int id;
    public ModelItem item;
    public int[] children;

    private ModelInstance () {}

    public ModelInstance.as_item (int uid, ModelItem item) {
        this.id = uid;
        this.item = item;
        this.item.id = uid;
    }

    public ModelInstance.as_group (int uid, ModelItem? item) {
        this.id = uid;
        this.children = new int[0];
        this.item = item;
        if (item != null) {
            this.item.id = uid;
        }
    }

    public virtual bool has_children () { return false; }

    public virtual GLib.Array<int>? get_children () { return null; }
}

public class Akira.Lib2.Items.ModelNode {
    public int id;
    // This is the position of the node relative to its parent.
    public int pos_in_parent = -1;
    public unowned ModelInstance instance;

    public unowned ModelNode parent = null;
    public GLib.Array<unowned ModelNode> children;

    private ModelNode () {}

    public ModelNode.as_item_node (ModelInstance instance, int pos_in_parent) {
        this.instance = instance;
        this.id = instance.id;
        this.pos_in_parent = pos_in_parent;
    }

    public ModelNode.as_group_node (ModelInstance instance, int pos_in_parent) {
        this.instance = instance;
        this.id = instance.id;
        this.pos_in_parent = pos_in_parent;
    }

    public void swap_children (int pos, int newpos) {
        var tmp = children.data[pos];
        children.data[pos] = children.data[newpos];
        children.data[newpos] = tmp;
    }
}

public class Akira.Lib2.Items.PositionKey
{
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

public class Akira.Lib2.Items.ChildrenSet
{
    public ModelNode parent_node;
    public int first_child;
    public int length;

    // optional array with children nodes
    public GLib.Array<unowned ModelNode> children_in_set;
}

/*
 * Holds maps to instances that define connectivity between items and groups.
 * Holds a dag based on nodes (starting from an origin node with `origin_id`.
 *
 * The dag needs to be rebuilt any time group topologies change. Changes that don't
 * affect groups generally don't need to have the dag rebuilt. Rebuilding a dag
 * repopulates all group nodes, but not item nodes. Item nodes can only have
 * a single parent and no children, and they are populated when an operation chages them.
 *
 * The reason changes to items (add/remove/restack) don't require the dag to be rebuilt
 * is for performance reasons--and the simplicity of their topology (single parent, no children).
 *
 * Group topologies rebuild the dag because in general those topologies will be small, and
 * it ascertains that the dag is true and minimizes boilerplate code that is very tricky to
 * begin with.
 */
public class Akira.Lib2.Items.Model : Object {
    public const int origin_id = 5;
    public const int group_start_id = 10;
    public const int item_start_id = 10000000;

    public int last_group_id = group_start_id;
    public int last_item_id = item_start_id;

    public Gee.HashMap<int, ModelInstance> group_map;
    public Gee.HashMap<int, ModelInstance> item_map;

    public Gee.HashMap<int, ModelNode> group_nodes;
    public Gee.HashMap<int, ModelNode> item_nodes;

    private bool needs_dag_build = true;

    construct {
        item_map = new Gee.HashMap<int, ModelInstance> ();
        group_map = new Gee.HashMap<int, ModelInstance> ();
        item_nodes = new Gee.HashMap<int, ModelNode> ();
        group_nodes = new Gee.HashMap<int, ModelNode> ();

        var group_instance = new ModelInstance.as_group (origin_id, null);
        group_map[origin_id] = group_instance;
        group_nodes[origin_id] = new ModelNode.as_group_node (group_instance, 0);
    }

    public ModelInstance? instance_from_id (int id) {
        if (id >= item_start_id) {
            return item_map.has_key (id) ? item_map[id] : null;
        }

        return group_map.has_key (id) ? group_map[id] : null;
    }

    public ModelInstance? child_instance_at (int parent_id, int pos) {
        if (parent_id >= item_start_id) {
            // items don't have children
            return null;
        }
        
        var node = node_from_id (parent_id);

        if (node == null || pos >= node.children.length) {
            return null;
        }

        return node.children.index(pos).instance;
    }

    public ModelNode? node_from_id (int id) {
        if (id >= item_start_id) {
            return item_nodes.has_key (id) ? item_nodes[id] : null;
        }

        return group_nodes.has_key (id) ? group_nodes[id] : null;
    }

    public string path_from_id (int id) {
        var node = node_from_id (id);
        return path_from_node (node);
    }

    public string path_from_node (ModelNode node) {
        var builder = new GLib.StringBuilder ();
        if (node == null) {
            return builder.str;
        }

        build_path_recursive (node, ref builder);
        return builder.str;
    }

    public GLib.Array<unowned Lib2.Items.ModelNode> children_in_group (int group_id) {
        if (!group_nodes.has_key (group_id)) {
            return new GLib.Array<unowned Lib2.Items.ModelNode> ();
        }

        return group_nodes[group_id].children;
    }

    public void recalculate_children_stacking (int parent_id) {
        var group = group_nodes.has_key (parent_id) ? group_nodes[parent_id] : null;
        if (group == null) {
            return;
        }

        inner_recalculate_children_stacking (group);
    }

    public int remove (int id, bool restack) {
        if (id <= item_start_id) {
            return -1;
        }

        var node = node_from_id (id);
        
        if (node == null) {
            return -1;
        }

        return extripate (node.parent.id, node.pos_in_parent, restack);
    }

    public int extripate (int parent_id, uint pos, bool restack) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var parent_node = group_nodes[parent_id];

        if (pos >= parent_node.children.length) {
            return -1;
        }

        var target_node = parent_node.children.index (pos);

        if (target_node.id < item_start_id) {
            needs_dag_build = true;
            // TODO -- handle group deletion
            return 0;
        }

        // delete leaf

        Utils.Array.remove_from_iarray (ref parent_node.instance.children, (int) pos, 1);
        parent_node.children.remove_index (pos);
        target_node.parent = null;
        item_nodes.unset(target_node.id);
        item_map.unset(target_node.id);

        if (restack) {
            for (var i = (int)pos; i < parent_node.children.length; ++i) {
                parent_node.children.index(i).pos_in_parent--;
            }
        }
        return 0;
    }

    public int append_item (int parent_id, ModelInstance candidate) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var parent_node = group_nodes[parent_id];
        var pos = parent_node.children == null ? 0 : parent_node.children.length;
        return inner_splice_item (parent_node, pos, candidate);
    }

    public int splice_item (int parent_id, uint pos, ModelInstance candidate) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        return inner_splice_item (group_nodes[parent_id], pos, candidate);
    }

    public int move_items (int parent_id, uint pos, uint newpos, int length, bool restack) {
        if (pos == newpos || length <= 0) {
            return 0;
        }

        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var parent_node = group_nodes[parent_id];

        if (pos >= parent_node.children.length) {
            return -1;
        }

        if (newpos + length > parent_node.children.length) {
            return 0;
        }

        var target_node = parent_node.children.index (pos);

        if (target_node.id < item_start_id) {
            needs_dag_build = true;
            // TODO -- handle group deletion
            return 0;
        }

        // convert to rotation parameters
        var f = (int) (uint.min (pos, newpos));
        var m = (int) (newpos > pos ? pos + length : pos);
        var e = (int) (uint.max (pos + length, newpos + length));

        Utils.Array.rotate_iarray (ref parent_node.instance.children, f, m, e);
        Utils.Array.rotate_weak_garray (ref parent_node.children, f, m, e);

        if (restack) {
            var start = int.min ((int)pos, (int)newpos);
            for (var i = start; i < parent_node.children.length; ++i) {
                parent_node.children.index(i).pos_in_parent = i;
            }
        }

        return (int) (newpos - pos);
    }

    public ModelNode? next_sibling (ModelNode node, bool only_stackable) {
        if (node == null || node.parent == null) {
            return null;
        }

        var sibling_pos = node.pos_in_parent + 1;
        unowned ModelNode sibling = null;
        while (sibling_pos < node.parent.children.length) {
            sibling = node.parent.children.index(sibling_pos);
            if (!only_stackable || sibling.instance.item.is_stackable ()) {
                return sibling;
            }
            sibling_pos++;
        }

        return null;
    }

    public ModelNode? previous_sibling (ModelNode node, bool only_stackable) {
        if (node == null || node.parent == null) {
            return null;
        }

        var sibling_pos = node.pos_in_parent - 1;
        unowned ModelNode sibling = null;
        while (sibling_pos >= 0) {
            sibling = node.parent.children.index(sibling_pos);
            if (!only_stackable || sibling.instance.item.is_stackable ()) {
                return sibling;
            }
            sibling_pos--;
        }

        return null;
    }

    public void maybe_rebuild_dag () {
        if (needs_dag_build) {
            build_dag (group_map, item_map, ref group_nodes, ref item_nodes);
        }
    }

    private int inner_splice_item (ModelNode parent_node, uint pos, ModelInstance candidate) {
        var new_id = ++last_item_id;
        candidate.id = new_id;
        if (candidate.item != null) {
            candidate.item.id = new_id;
        }

        item_map[new_id] = candidate;

        var new_node = new ModelNode.as_item_node (candidate, (int) pos);
        item_nodes[new_id] = new_node;

        if (parent_node.children == null) {
            parent_node.children = new GLib.Array<unowned ModelNode> ();
        }

        bool update_sibling_locations = false;
        if (pos >= parent_node.children.length) {
            parent_node.children.append_val (new_node);
            Utils.Array.append_to_iarray (ref parent_node.instance.children, new_id);
        } else {
            parent_node.children.insert_val (pos, new_node);
            Utils.Array.insert_at_iarray (ref parent_node.instance.children, (int)pos, new_id);
            update_sibling_locations = true;
        }

        if (update_sibling_locations) {
            var ipos = (int) pos;
            for (var i = ipos; i < parent_node.children.length; ++i) {
                parent_node.children.index(ipos).pos_in_parent = ipos++;
            }
        }

        new_node.parent = parent_node;
        return new_id;
    }

    private static void build_dag (
        Gee.HashMap<int, ModelInstance> group_map,
        Gee.HashMap<int, ModelInstance> item_map,
        ref Gee.HashMap<int, ModelNode> group_nodes,
        ref Gee.HashMap<int, ModelNode>? item_nodes
    ) {
    }

    private static void build_dag_recursive (
        ModelNode node,
        Gee.HashMap<int, ModelInstance> group_map,
        Gee.HashMap<int, ModelInstance> item_map,
        ref Gee.HashMap<int, ModelNode> group_nodes,
        ref Gee.HashMap<int, ModelNode>? item_nodes
    ) {
    }

    private void build_path_recursive (ModelNode node, ref StringBuilder builder) {
        if (node.parent != null) {
            build_path_recursive (node.parent, ref builder);
        }

        if (builder.len > 0) {
            builder.append ("_");
        }

        builder.append (node.pos_in_parent.to_string ());
    }

    public void print_instances () {
        print ("Groups: \n");
        foreach (var inst in group_map) {
            print ("  >%d -- ", inst.value.id);

            if (inst.value.has_children ()) {
                foreach (var id in inst.value.children) {
                    print ("%d ", id);
                }
            }
            print ("\n");
        }

        print ("Instances: \n");
        foreach (var inst in item_map) {
            print ("  >%d -- \n", inst.value.id);
        }
    }

    public void print_dag () {
        print ("DAG: \n");
        print_dag_recurse (group_nodes[origin_id], 1);
    }

    public void print_dag_recurse (ModelNode node, int level) {
        for(var d = 0; d < level; ++d) {
            print ("  ");
        }

        print (">%d -- (", node.id);

        if (node.parent != null) {
            print ("%d", node.parent.id);
        }

        print (")\n");


        if (node.children != null) {
            for (var i = 0; i < node.children.length; ++i) {
                print_dag_recurse (node.children.index(i), level + 1);
            }
        }

    }

    private void inner_recalculate_children_stacking (ModelNode parent_node) {
        int ct = 0;
        foreach (unowned var child in parent_node.children.data) {
            child.pos_in_parent = ct++;
        }
    }
}


