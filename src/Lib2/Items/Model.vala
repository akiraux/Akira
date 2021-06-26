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

    public ModelInstance (int uid, ModelItem? item) {
        if (item == null || item.item_type.is_group ()) {
            this.children = new int[0];
        }
        this.id = uid;
        this.item = item;
        if (item != null) {
            this.item.id = uid;
        }
    }

    public bool is_group () { return item == null || item.item_type.is_group (); }
}

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

            if (recurse && child.instance.is_group ()) {
                if (child.has_child (id)) {
                    return true;
                }
            }
        }

        return false;
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

    public Gee.HashSet<int> dirty_items;
    public Gee.HashSet<int> dirty_groups;

    private bool needs_dag_build = true;

    construct {
        item_map = new Gee.HashMap<int, ModelInstance> ();
        group_map = new Gee.HashMap<int, ModelInstance> ();
        item_nodes = new Gee.HashMap<int, ModelNode> ();
        group_nodes = new Gee.HashMap<int, ModelNode> ();

        dirty_items = new Gee.HashSet<int> ();
        dirty_groups = new Gee.HashSet<int> ();

        var group_instance = new ModelInstance (origin_id, null);
        add_to_maps (new ModelNode (group_instance, 0), false);
    }

    public void compile_geometries () {
        internal_compile_geometries ();
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

        internal_recalculate_children_stacking (group);
    }

    public int remove (int id, bool restack) {
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

        inner_remove (parent_node, target_node, pos);

        if (restack) {
            for (var i = (int)pos; i < parent_node.children.length; ++i) {
                parent_node.children.index(i).pos_in_parent--;
            }
        }
        return 0;
    }

    public int append_new_item (int parent_id, Lib2.Items.ModelItem candidate) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var parent_node = group_nodes[parent_id];
        var pos = parent_node.children == null ? 0 : parent_node.children.length;

        return inner_splice_new_item (parent_node, pos, new ModelInstance (-1, candidate));
    }

    public int splice_new_item (int parent_id, uint pos, Lib2.Items.ModelItem candidate) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        return inner_splice_new_item (group_nodes[parent_id], pos, new ModelInstance (-1, candidate));
    }

    public int move_items (int parent_id, uint pos, uint newpos, int length, bool restack) {
        if (pos == newpos || length <= 0) {
            return 0;
        }

        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var parent_node = group_nodes[parent_id];

        if (pos >= parent_node.children.length || pos + length >= parent_node.children.length) {
            return -1;
        }

        if (newpos + length > parent_node.children.length) {
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

        return 1;
    }

    public static ModelNode? root (ModelNode node) {
        if (node.parent == null) {
            return node;
        }

        if (node.parent.id == origin_id) {
            return node;
        }

        return root (node.parent);
    }

    public static ModelNode? next_sibling (ModelNode node, bool only_stackable) {
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

    public static ModelNode? previous_sibling (ModelNode node, bool only_stackable) {
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

    public void print_instances () {
        print ("Groups: \n");
        foreach (var inst in group_map) {
            print ("  >%d -- ", inst.value.id);

            if (inst.value.children != null) {
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

    private int inner_splice_new_item (ModelNode parent_node, uint pos, ModelInstance candidate) {
        var new_id = candidate.is_group () ? ++last_group_id : ++last_item_id;
        candidate.id = new_id;
        if (candidate.item != null) {
            candidate.item.id = new_id;
        }


        var new_node = new ModelNode (candidate, (int) pos);

        add_to_maps (new_node, true);

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

    private int inner_remove (ModelNode parent_node, ModelNode to_delete, uint pos_in_parent) {
        if (to_delete.children != null) {
            for (var ci = (int) to_delete.children.length - 1; ci >= 0; --ci) {
                var child_node = to_delete.children.index(ci);
                if (child_node.children != null && child_node.children.length > 0) {
                    inner_remove (to_delete, child_node, ci);
                    continue;
                }

                child_node.instance.item.remove_from_canvas ();
                child_node.parent = null;
                remove_from_maps (child_node.id);
            }
        }

        to_delete.instance.item.remove_from_canvas ();
        to_delete.parent = null;

        Utils.Array.remove_from_iarray (ref parent_node.instance.children, (int)pos_in_parent, 1);
        parent_node.children.remove_index (pos_in_parent);

        remove_from_maps (to_delete.id);
        return 0;
    }

    private void add_to_maps (ModelNode node, bool listen) {
        if (node.instance.is_group ()) {
            group_map[node.id] = node.instance;
            group_nodes[node.id] = node;
        } else {
            item_map[node.id] = node.instance;
            item_nodes[node.id] = node;
        }

        if (listen) {
            node.instance.item.geometry_compilation_requested.connect (on_item_geometry_changed);
        }
    }


    private void remove_from_maps (int id) {
        var target = instance_from_id (id);
        if (target == null) {
            return;
        }

        target.item.geometry_compilation_requested.disconnect (on_item_geometry_changed);

        if (id < item_start_id) {
            group_nodes.unset(id);
            group_map.unset(id);
        } else {
            item_nodes.unset(id);
            item_map.unset(id);
        }
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

        builder.append ((node.id == origin_id) ? node.id.to_string () : node.pos_in_parent.to_string ());
    }

    private void on_item_geometry_changed (int id) {
        var target = node_from_id (id);

        if (target.instance.is_group ()) {
            dirty_groups.add (id);
        }
        else {
            dirty_items.add (id);
        }

        var parent = target.parent;
        while (parent.id != origin_id) {
            parent.instance.item.mark_geometry_dirty (false);
            on_item_geometry_changed (parent.id);
            parent = parent.parent;
        }
    }

    private void internal_recalculate_children_stacking (ModelNode parent_node) {
        int ct = 0;
        foreach (unowned var child in parent_node.children.data) {
            child.pos_in_parent = ct++;
        }
    }
    

    private void internal_compile_geometries () {

        // create a timer object:
        ulong microseconds;
        double seconds;
        Timer timer = new Timer ();
        timer.start ();

        if (dirty_items.size == 0 && dirty_groups.size == 0) {
            return;
        }

        foreach (var leaf in dirty_items) {
            var node = node_from_id (leaf);
            node.instance.item.compile_components (true, node);
        }

        timer.stop ();
        seconds = timer.elapsed (out microseconds);

        dirty_items.clear ();

        if (dirty_groups.size == 0) {
            return;
        }

        var sorted = new Gee.TreeMap<string, ModelNode> ();
        foreach (var group_id in dirty_groups) {
            var group_node = node_from_id (group_id);
            sorted[path_from_node (group_node)] = group_node;
        }

        var it = sorted.bidir_map_iterator ();
        for (var has_next = it.last (); has_next; has_next = it.previous ()) {
            var node = it.get_value ();
            node.instance.item.compile_components (true, node);
        }

        dirty_groups.clear ();
    }
}


