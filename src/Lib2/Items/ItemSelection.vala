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
public class Akira.Lib2.Items.NodeSelection : Object {
    public Gee.HashSet<int> groups;
    public Gee.TreeMap<int, ModelNode> nodes;

    public NodeSelection (ModelNode? node) {
        groups = new Gee.HashSet<int> ();
        nodes = new Gee.TreeMap<int, ModelNode> ();

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
        return it.get_value ();
    }

    public void add_node (ModelNode node) {
        if (has_id (node.id, true)) {
            return;
        }

        nodes[node.id] = node;

        if (node.instance.is_group ()) {
            groups.add (node.id);

            var to_del = new GLib.Array<int> ();
            foreach (var test in nodes.keys) {
                if (node.has_child (test)) {
                    to_del.append_val (test);
                }
            }

            foreach (var did in to_del.data) {
                nodes.unset (did);
            }
        }
    }

    public void remove_item (int id) {
        if (nodes.has_key (id)) {
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
            if (nodes[group].has_child (id)) {
                return true;
            }
        }

        return false;
    }

    public bool is_empty () { return nodes.size == 0; }

    public Geometry.RotatedRectangle coordinates () {
        var result = Geometry.RotatedRectangle ();

        if (nodes.size == 0) {
            return result;
        }

        if (nodes.size == 1) {
            unowned var item = first_node ().instance.item;
            unowned var cg = item.compiled_geometry;
            if (cg == null) {
                return result;
            }

            result = cg.area;
            if (item.components != null && item.components.rotation != null) {
                result.rotation = item.components.rotation == null ? 0 : item.components.rotation.in_radians ();
            }
            return result;
        }

        double top = int.MAX;
        double bottom = int.MIN;
        double left = int.MAX;
        double right = int.MIN;

        foreach (var node in nodes) {
            unowned var cg = node.value.instance.item.compiled_geometry;
            if (cg == null) {
                continue;
            }

            top = double.min (top, cg.bb_top);
            bottom = double.max (bottom, cg.bb_bottom);
            left = double.min (left, cg.bb_left);
            right = double.max (right, cg.bb_right);
        }

        result.tl_x = left;
        result.tl_y = top;
        result.tr_x = right;
        result.tr_y = top;
        result.bl_x = left;
        result.bl_y = bottom;
        result.br_x = right;
        result.br_y = bottom;
        result.rotation = 0;
        return result;
    }

    public void nob_coordinates (Utils.Nobs.Nob nob, double scale, ref double x, ref double y) {
        Utils.Nobs.nob_xy_from_coordinates (nob, coordinates (), scale, ref x, ref y);
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
            unowned var cg = node.instance.item.compiled_geometry;
            if (cg == null) {
                continue;
            }
            top = double.min (top, cg.bb_top);
            bottom = double.max (bottom, cg.bb_bottom);
            left = double.min (left, cg.bb_left);
            right = double.max (right, cg.bb_right);
        }

        result.top = top;
        result.bottom = bottom;
        result.left = left;
        result.right = right;
        return result;
    }
}
