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
public class Akira.Lib.Items.Model : Object {
    public const int ORIGIN_ID = 5;
    public const int GROUP_START_ID = 10;
    public const int ITEM_START_ID = 10000000;

    private int last_group_id = GROUP_START_ID;
    private int last_item_id = ITEM_START_ID;

    public Gee.HashMap<int, ModelInstance> group_map;
    public Gee.HashMap<int, ModelInstance> item_map;

    public Gee.HashMap<int, ModelNode> group_nodes;
    public Gee.HashMap<int, ModelNode> item_nodes;

    public Gee.HashSet<int> dirty_items;
    public Gee.HashSet<int> dirty_groups;

    private bool is_live = false;

    private unowned ViewLayers.BaseCanvas? canvas = null;

    public Model.live_model (ViewLayers.BaseCanvas? canvas) {
        is_live = true;
        this.canvas = canvas;
    }

    construct {
        item_map = new Gee.HashMap<int, ModelInstance> ();
        group_map = new Gee.HashMap<int, ModelInstance> ();
        item_nodes = new Gee.HashMap<int, ModelNode> ();
        group_nodes = new Gee.HashMap<int, ModelNode> ();

        dirty_items = new Gee.HashSet<int> ();
        dirty_groups = new Gee.HashSet<int> ();

        var group_instance = new ModelInstance (ORIGIN_ID, new ModelTypeGroup ());
        add_to_maps (new ModelNode (group_instance, 0), false);
    }

    public signal void item_added (int id);
    public signal void item_geometry_changed (int id);

    public void compile_geometries () {
        internal_compile_geometries ();
    }

    public ModelInstance? instance_from_id (int id) {
        if (id >= ITEM_START_ID) {
            return item_map.get (id);
        }

        return group_map.get (id);
    }

    public ModelInstance? child_instance_at (int parent_id, int pos) {
        if (parent_id >= ITEM_START_ID) {
            // items don't have children
            return null;
        }

        var node = node_from_id (parent_id);

        if (node == null || pos >= node.children.length) {
            return null;
        }

        return node.children.index (pos).instance;
    }

    public ModelNode? node_from_id (int id) {
        if (id >= ITEM_START_ID) {
            return item_nodes.get (id);
        }

        return group_nodes.get (id);
    }

    public string path_from_id (int id) {
        return path_from_node (node_from_id (id));
    }

    public string path_from_node (ModelNode node) {
        if (node == null) {
            return "";
        }

        var builder = new GLib.StringBuilder ();
        build_path_recursive (node, ref builder);
        return builder.str;
    }

    public GLib.Array<unowned Lib.Items.ModelNode> children_in_group (int group_id) {
        var group = group_nodes.get (group_id);
        return group == null ? new GLib.Array<unowned Lib.Items.ModelNode> () : group.children;
    }

    public void mark_node_geometry_dirty_by_id (int id) {
        var node = node_from_id (id);
        if (node == null) {
            assert (false);
            return;
        }

        mark_node_geometry_dirty (node);
    }

    public void mark_node_geometry_dirty (Lib.Items.ModelNode node) {
        internal_mark_geometry_dirty (node, false);
    }

    public void mark_node_name_dirty (Lib.Items.ModelNode node) {
        if (dirty_groups.contains (node.id) || dirty_items.contains (node.id)) {
            return;
        }

        node.instance.compiled_components.compiled_name = null;
        on_item_geometry_compilation_requested (node);
    }

    public void recalculate_children_stacking (int parent_id) {
        var group = group_nodes.get (parent_id);
        if (group == null) {
            assert (false);
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
        var parent_node = group_nodes.get (parent_id);

        if (parent_node == null || pos >= parent_node.children.length) {
            return -1;
        }

        unowned var target_node = parent_node.children.index (pos);

        inner_remove (parent_node, target_node, pos);

        if (restack) {
            for (var i = (int)pos; i < parent_node.children.length; ++i) {
                parent_node.children.index (i).pos_in_parent--;
            }
        }
        return 0;
    }

    public int append_new_item (int parent_id, Lib.Items.ModelInstance candidate) {
        var parent_node = group_nodes.get (parent_id);
        if (parent_node == null) {
            return -1;
        }

        var pos = parent_node.children == null ? 0 : parent_node.children.length;
        return inner_splice_new_item (parent_node, pos, candidate);
    }

    public int splice_new_item (int parent_id, uint pos, Lib.Items.ModelInstance candidate) {
        var parent_node = group_nodes.get (parent_id);
        if (parent_node == null) {
            return -1;
        }
        return inner_splice_new_item (parent_node, pos, candidate);
    }

    public int move_items (int parent_id, uint pos, uint newpos, int length, bool restack) {
        if (pos == newpos || length <= 0) {
            return 0;
        }

        var parent_node = group_nodes.get (parent_id);
        if (parent_node == null) {
            return -1;
        }

        if (pos >= parent_node.children.length || pos + length > parent_node.children.length) {
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
                unowned var ch = parent_node.children.index (i);
                ch.pos_in_parent = i;
                mark_node_geometry_dirty (ch);
            }
        }

        return 1;
    }

    public static ModelNode? root (ModelNode node) {
        if (node.parent == null) {
            assert (node.id == ORIGIN_ID);
            return node;
        }

        if (node.parent.id == ORIGIN_ID) {
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
            sibling = node.parent.children.index (sibling_pos);
            if (!only_stackable || sibling.instance.is_stackable) {
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
            sibling = node.parent.children.index (sibling_pos);
            if (!only_stackable || sibling.instance.is_stackable) {
                return sibling;
            }
            sibling_pos--;
        }

        return null;
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
        print_dag_recurse (group_nodes[ORIGIN_ID], 1);
    }

    public void print_dag_recurse (ModelNode node, int level) {
        for (var d = 0; d < level; ++d) {
            print ("  ");
        }

        print (">%d -- (", node.id);

        if (node.parent != null) {
            print ("%d", node.parent.id);
        }

        print (")\n");

        if (node.children != null) {
            for (var i = 0; i < node.children.length; ++i) {
                print_dag_recurse (node.children.index (i), level + 1);
            }
        }
    }

    private int inner_splice_new_item (ModelNode parent_node, uint pos, ModelInstance candidate) {
        var new_id = candidate.is_group ? ++last_group_id : ++last_item_id;
        candidate.id = new_id;
        // Generate the initial name for the item composed by the type name and
        // the id. We subtract the starter IDs from what we show the user just
        // to make it look prettier. The ID saved in the Name component is never
        // used, maybe we could remove it.
        var new_name_id = candidate.is_group ? new_id - GROUP_START_ID : new_id - ITEM_START_ID;
        candidate.components.name = new Lib.Components.Name (
            "%s %i".printf (candidate.type.name_id, new_name_id),
            new_id.to_string ()
        );
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
                parent_node.children.index (ipos).pos_in_parent = ipos++;
            }
        }

        new_node.parent = parent_node;

        internal_mark_geometry_dirty (new_node, false);

        return new_id;
    }

    private int inner_remove (ModelNode parent_node, ModelNode to_delete, uint pos_in_parent) {
        if (to_delete.children != null) {
            for (var ci = (int) to_delete.children.length - 1; ci >= 0; --ci) {
                unowned var child_node = to_delete.children.index (ci);
                if (child_node.children != null && child_node.children.length > 0) {
                    inner_remove (to_delete, child_node, ci);
                    continue;
                }

                child_node.instance.remove_from_canvas (canvas);
                child_node.parent = null;
                remove_from_maps (child_node.id);
            }
        }

        to_delete.instance.remove_from_canvas (canvas);
        to_delete.parent = null;

        Utils.Array.remove_from_iarray (ref parent_node.instance.children, (int)pos_in_parent, 1);
        parent_node.children.remove_index (pos_in_parent);

        if (parent_node.id != ORIGIN_ID) {
            internal_mark_geometry_dirty (parent_node, false);
        }

        remove_from_maps (to_delete.id);
        return 0;
    }

    private void add_to_maps (ModelNode node, bool listen) {
        // TODO create drawable in a nicer way.
        node.instance.add_to_canvas ();

        if (node.instance.is_group) {
            group_map[node.id] = node.instance;
            group_nodes[node.id] = node;
        } else {
            item_map[node.id] = node.instance;
            item_nodes[node.id] = node;
        }

        if (is_live && listen) {
            item_added (node.id);
        }
    }

    private void remove_from_maps (int id) {
        var target = instance_from_id (id);
        if (target == null) {
            return;
        }

        if (id < ITEM_START_ID) {
            group_nodes.unset (id);
            group_map.unset (id);
        } else {
            item_nodes.unset (id);
            item_map.unset (id);
        }
    }

    private void build_path_recursive (ModelNode node, ref StringBuilder builder) {
        if (node.parent != null) {
            build_path_recursive (node.parent, ref builder);
        }

        if (builder.len > 0) {
            builder.append ("_");
        }

        builder.append ((node.id == ORIGIN_ID) ? node.id.to_string () : node.pos_in_parent.to_string ());
    }

    /*
     * Internal operation to mark an instance as dirty. If 'simple' is true,
     * only the instance's geometry is nullified, otherwise a recursive dirtying
     * of items occurs.
     */
    private void internal_mark_geometry_dirty (Lib.Items.ModelNode node, bool simple) {
        if (dirty_groups.contains (node.id) || dirty_items.contains (node.id)) {
            return;
        }

        node.instance.compiled_components.compiled_geometry = null;
        if (!simple) {
            on_item_geometry_compilation_requested (node);
        }
    }

    private void on_item_geometry_compilation_requested (Lib.Items.ModelNode node) {
        if (!is_live) {
            return;
        }
        mark_dirty (node);

        unowned var parent = node.parent;
        while (parent.id != ORIGIN_ID) {
            internal_mark_geometry_dirty (parent, true);
            on_item_geometry_compilation_requested (parent);
            parent = parent.parent;
        }
    }

    private void mark_dirty (ModelNode node) {
        if (node.instance.is_group) {
            dirty_groups.add (node.id);
        } else {
            dirty_items.add (node.id);
        }
    }

    private void internal_recalculate_children_stacking (ModelNode parent_node) {
        int ct = 0;
        foreach (unowned var child in parent_node.children.data) {
            child.pos_in_parent = ct++;
        }
    }

    private void internal_compile_geometries () {
        if (!is_live) {
            return;
        }

        if (dirty_items.size == 0 && dirty_groups.size == 0) {
            return;
        }

        foreach (var leaf in dirty_items) {
            var node = node_from_id (leaf);
            if (node.instance.compile_components (node, canvas)) {
                item_geometry_changed (node.id);
            }
        }

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
            if (node.instance.compile_components (node, canvas)) {
                item_geometry_changed (node.id);
            }

            // #TODO improve this
            if (node.instance.components.layout.clips_children) {
                if (node.children == null) {
                    continue;
                }

                unowned var clip = node.instance.compiled_geometry.area;
                foreach (unowned var child in node.children.data) {
                    unowned var dr = child.instance.drawable;
                    if (dr != null) {
                        dr.clipping_path = clip;
                    }
                }
            }
        }

        dirty_groups.clear ();
    }
}
