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

public class Akira.Lib2.Items.ArrayOps {
    public static bool remove_at (ref int[] a, int pos, int length) {
        if (pos >= a.length || pos + length > a.length || pos < 0 || length < 0) {
            assert(false);
            return false;
        }

        a.move (pos + length, pos, a.length - pos - length);
        a.resize (a.length - length);
        return true;
    }

    public static bool insert_at (ref int[] a, int pos, int value) {
        if (pos >= a.length || pos < 0) {
            assert(false);
            return false;
        }

        a.resize (a.length + 1);
        a.move (pos, pos + 1, a.length - pos - 1);
        a[pos] = value;
        return true;
    }

    public static bool append (ref int[] a, int value) {
        a.resize (a.length + 1);
        a[a.length - 1] = value;
        return true;
    }

    public static bool swap (ref int[] a, int pos, int newpos) {
        if (pos >= a.length || newpos >= a.length || pos < 0 || newpos < 0) {
            assert(false);
            return false;
        }

        var tmp = a[pos];
        a[pos] = a[newpos];
        a[newpos] = tmp;
        return true;
    }
}


public class Akira.Lib2.Items.Model.ModelInstance {
    public int id;
    public int[] children;

    private ModelInstance () {}

    public ModelInstance.as_item (int uid) {
        this.id = uid;
    }

    public ModelInstance.as_group (int uid) {
        this.id = uid;
        this.children = new int[0];
    }

    public virtual bool has_children () { return false; }

    public virtual GLib.Array<int>? get_children () { return null; }
}

public class Akira.Lib2.Items.Model.ModelNode {
    public int id;
    public unowned ModelInstance instance;
    public GLib.Array<unowned ModelNode> parents;
    public GLib.Array<unowned ModelNode> children;

    private ModelNode () {}

    public ModelNode.as_item_node (ModelInstance instance) {
        this.instance = instance;
        this.id = instance.id;
        this.parents = new GLib.Array<unowned ModelNode> ();
    }

    public ModelNode.as_group_node (ModelInstance instance) {
        this.instance = instance;
        this.id = instance.id;
        this.parents = new GLib.Array<unowned ModelNode> ();
    }

    public void swap_children (int pos, int newpos) {
        var tmp = children.data[pos];
        children.data[pos] = children.data[newpos];
        children.data[newpos] = tmp;
    }
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

        var group_instance = new ModelInstance.as_group (origin_id);
        group_map[origin_id] = group_instance;
        group_nodes[origin_id] = new ModelNode.as_group_node (group_instance);
    }

    public ModelInstance? instance_from_id (int id) {
        if (id >= item_start_id) {
            return item_map.has_key (id) ? item_map[id] : null;
        }

        return group_map.has_key (id) ? group_map[id] : null;
    }

    public int extripate (int parent_id, uint pos) {
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

        ArrayOps.remove_at (ref parent_node.instance.children, (int) pos, 1);
        parent_node.children.remove_index (pos);
        target_node.parents.remove_index (0);
        item_nodes.unset(target_node.id);
        item_map.unset(target_node.id);
        return 0;
    }

    public int splice_item (int parent_id, uint pos, ModelInstance candidate) {
        if (!group_map.has_key (parent_id)) {
            return -1;
        }

        var new_id = ++last_item_id;
        candidate.id = new_id;
        item_map[new_id] = candidate;

        var parent_node = group_nodes[parent_id];
        var new_node = new ModelNode.as_item_node (candidate);
        item_nodes[new_id] = new_node;

        if (parent_node.children == null) {
            parent_node.children = new GLib.Array<unowned ModelNode> ();
        }

        if (pos >= parent_node.children.length) {
            parent_node.children.append_val (new_node);
            ArrayOps.append (ref parent_node.instance.children, new_id);
        } else {
            parent_node.children.insert_val (pos, new_node);
            ArrayOps.insert_at (ref parent_node.instance.children, (int)pos, new_id);
        }

        set_item_parent(new_node, parent_node);
        return 0;
    }

    public int move_item (int parent_id, uint pos, uint newpos) {
        if (pos == newpos) {
            return 0;
        }

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

        ArrayOps.swap (ref parent_node.instance.children, (int)pos, (int)newpos);
        parent_node.swap_children ((int)pos, (int)newpos);

        return 0;
    }

    public void maybe_rebuild_dag () {
        if (needs_dag_build) {
            build_dag (group_map, item_map, ref group_nodes, ref item_nodes);
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

    /*
     * Sets a new parent with `new_parent_id` to an item with `id` at `pos`.
     * This method does not handle an old parent, so be sure to handle that
     * before calling this.
     */
    private void set_item_parent (ModelNode node, ModelNode parent_node)  {
        node.parents.set_size(1);
        node.parents.data[0] = parent_node;
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

        for (var pi = 0; pi < node.parents.length; ++pi) {
            print ("%d ", node.parents.index(pi).id);
        }

        print (")\n");


        if (node.children != null) {
            for (var i = 0; i < node.children.length; ++i) {
                print_dag_recurse (node.children.index(i), level + 1);
            }
        }

    }
}


