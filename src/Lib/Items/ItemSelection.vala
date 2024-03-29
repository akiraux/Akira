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
public class Akira.Lib.Items.NodeSelection : Object {
    private class ParentInfo {
        public uint children_selected_ct = 1;
    }

    // Used to determine first and last added nodes
    private uint last_added_sid = 0;

    public class SelectedNode {
        public ModelNode node;
        public int parent_id;
        public uint sid;

        public SelectedNode (ModelNode node, uint sid) {
            this.node = node;
            this.parent_id = node.parent.id;
            this.sid = sid;
        }
    }

    public Gee.HashSet<int> groups;
    public Gee.TreeMap<int, SelectedNode> nodes;

    private Gee.HashMap<int, ParentInfo> parent_data;

    public NodeSelection (ModelNode? node) {
        groups = new Gee.HashSet<int> ();
        nodes = new Gee.TreeMap<int, SelectedNode> ();
        parent_data = new Gee.HashMap<int, ParentInfo> ();

        if (node != null) {
            add_node (node);
        }
    }

    public ModelNode? first_node () {
        if (nodes.size == 0) {
            return null;
        }

        var it = nodes.map_iterator ();
        it.next ();
        return it.get_value ().node;
    }

    /*
     * Returns true if the selection only spans a single group. Meaning all selected items reside in a single group.
     * If true, the group id will be populated. Otherwise -1 is populated.
     */
    public bool spans_one_group (out int group_id) {
        group_id = -1;

        if (parent_data.size == 1) {
            foreach (var k in parent_data.keys) {
                group_id = k;
                return true;
            }
        }
        return false;
    }

    public void add_node (ModelNode to_add) {
        assert (to_add.parent != null);
        if (has_id (to_add.id, false)) {
            return;
        }

        // If any ancestor is selected
        if (ancestor_selected (to_add)) {
            return;
        }

        var cand = new SelectedNode (to_add, ++last_added_sid);
        nodes[to_add.id] = cand;
        register_parent (cand.parent_id);

        if (to_add.instance.is_group) {
            groups.add (to_add.id);

            var to_del = new GLib.Array<int> ();
            foreach (var test in nodes.keys) {
                if (to_add.has_child (test)) {
                    to_del.append_val (test);
                }
            }

            foreach (var did in to_del.data) {
                nodes.unset (did);
            }
        }
    }

    public void remove_node (int id) {
        if (nodes.has_key (id)) {
            deregister_parent (nodes[id].parent_id);
            nodes.unset (id);
        }

        if (groups.contains (id)) {
            groups.remove (id);
        }
    }

    public bool has_id (int id, bool nested) {
        if (nodes.has_key (id)) {
            return true;
        }

        if (groups.contains (id)) {
            return true;
        }

        if (!nested) {
            return false;
        }

        foreach (var group in groups) {
            if (nodes[group].node.has_child (id)) {
                return true;
            }
        }

        return false;
    }

    public bool is_empty () {
        return nodes.size == 0;
    }

    public int count () {
        return nodes.size;
    }

    public Geometry.TransformedRectangle area () {

        if (nodes.size == 0) {
            return Geometry.TransformedRectangle.empty ();
        }

        if (nodes.size == 1) {
            unowned var geom = first_node ().instance.compiled_geometry;
            return Geometry.TransformedRectangle () {
                matrix = geom.transformation_matrix,
                rect = geom.local_bb
            };
        }

        double top = int.MAX;
        double bottom = int.MIN;
        double left = int.MAX;
        double right = int.MIN;

        foreach (var node in nodes.values) {
            unowned var inst = node.node.instance;
            top = double.min (top, inst.bounding_box.top);
            bottom = double.max (bottom, inst.bounding_box.bottom);
            left = double.min (left, inst.bounding_box.left);
            right = double.max (right, inst.bounding_box.right);
        }

        return Geometry.TransformedRectangle () {
            matrix = Cairo.Matrix.identity (),
            rect = Geometry.Rectangle () {
                top = top,
                right = right,
                left = left,
                bottom = bottom,
            }
        };
    }

    public void nob_coordinates (Utils.Nobs.Nob nob, double scale, ref double x, ref double y) {
        Utils.Nobs.nob_xy_from_coordinates (nob, area ().quad (), scale, ref x, ref y);
    }

    public Geometry.Rectangle bounding_box () {
        var result = Geometry.Rectangle ();
        if (nodes.size == 0) {
            return result;
        }

        var top = double.MAX;
        var bottom = double.MIN;
        var left = double.MAX;
        var right = double.MIN;

        foreach (var node in nodes.values) {
            unowned var inst = node.node.instance;
            top = double.min (top, inst.bounding_box.top);
            bottom = double.max (bottom, inst.bounding_box.bottom);
            left = double.min (left, inst.bounding_box.left);
            right = double.max (right, inst.bounding_box.right);
        }

        result.top = top;
        result.bottom = bottom;
        result.left = left;
        result.right = right;
        return result;
    }

    private bool ancestor_selected (ModelNode target) {
        var parent = target.parent;
        while (parent.id != Model.ORIGIN_ID) {
            if (groups.contains (parent.id)) {
                return true;
            }
            parent = parent.parent;
        }

        return false;
    }

    private void register_parent (int parent_id) {
        if (parent_data.has_key (parent_id)) {
            parent_data[parent_id].children_selected_ct++;
            return;
        }
        parent_data[parent_id] = new ParentInfo ();
    }

    private void deregister_parent (int parent_id) {
        if (parent_data.has_key (parent_id)) {
            parent_data[parent_id].children_selected_ct--;

            if (parent_data[parent_id].children_selected_ct == 0) {
                parent_data.unset (parent_id);
            }
            return;
        }

        assert (false);
    }
}
