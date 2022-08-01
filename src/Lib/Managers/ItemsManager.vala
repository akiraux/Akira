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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ItemsManager : Object, Items.ModelListener {
    private const bool CUSTOM_HITTEST = true;
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private Lib.Items.Model p_item_model;

    public unowned Lib.Items.Model item_model { get { return p_item_model; } }

    public ItemsManager (Lib.ViewCanvas canvas) {
        Object (view_canvas: canvas);
    }

    construct {
        p_item_model = new Lib.Items.Model.live_model (this, view_canvas);

        view_canvas.window.event_bus.selection_align.connect (selection_align);
    }

    public void replace_model (Lib.Items.Model replacement) {
        p_item_model = replacement;
        p_item_model.wake (this, true);
        view_canvas.set_model_to_render (p_item_model);
        compile_model ();
    }

    public signal void item_added (int id);
    public signal void items_removed (GLib.Array<int> ids);
    public signal void item_transferred (int id);

    public void on_item_added (int id) {
        item_added (id);
    }

    public void on_item_geometry_changed (int id) {
        view_canvas.selection_manager.on_selection_changed (id);
    }

    public void on_items_deleted (GLib.Array<int> ids) {
        items_removed (ids);
    }

    public void on_item_transferred (int id) {
        item_transferred (id);
    }

    public Lib.Items.ModelInstance? instance_from_id (int id) {
        return item_model.instance_from_id (id);
    }

    public Lib.Items.ModelNode? node_from_id (int id) {
        return item_model.node_from_id (id);
    }

    public int add_item_to_origin (Lib.Items.ModelInstance instance) {
        return add_item_to_group (Lib.Items.Model.ORIGIN_ID, instance);
    }

    public int add_item_to_group (int group_id, Lib.Items.ModelInstance instance, bool pause_compile = false) {
        if (instance == null) {
            return -1;
        }

        if (item_model.append_new_item (group_id, instance) <= 0) {
            return -1;
        }

        if (!pause_compile) {
            compile_model ();
        }

        return instance.id;
    }

    public int remove_items (GLib.Array<int> to_remove, bool pause_compile = false) {
        ulong microseconds;
        double seconds;

        // create a timer object:
        Timer timer = new Timer ();

        var to_delete = new Gee.TreeMap<Lib.Items.PositionKey, Lib.Items.ModelInstance> (
            Lib.Items.PositionKey.compare,
            null
        );

        var modified_groups = new GLib.Array<int> ();

        foreach (var id in to_remove.data) {
            var node = item_model.node_from_id (id);

            if (node == null) {
                continue;
            }

            var key = new Lib.Items.PositionKey ();
            key.parent_path = node.parent == null ? "" : item_model.path_from_node (node.parent);
            key.pos_in_parent = node.pos_in_parent;

            to_delete[key] = node.instance;

            if (modified_groups.length == 0) {
                modified_groups.append_val (node.parent.id);
                continue;
            }

            foreach (var gid in modified_groups.data) {
                if (gid != node.parent.id) {
                    modified_groups.append_val (node.parent.id);
                    break;
                }
            }
        }

        // Collect the nodes' ids to be removed in order to let the layers UI
        // be aware of what to remove without needing to access selection manager
        // which immediately loses the list of selected nodes.
        var ids_array = new GLib.Array<int> ();

        var it = to_delete.bidir_map_iterator ();
        for (var has_next = it.last (); has_next; has_next = it.previous ()) {
            var inst = it.get_value ();
            ids_array.append_val (inst.id);

            if (0 != item_model.remove (inst.id, false)) {
                assert (false);
                continue;
            }
        }

        foreach (var gid in modified_groups.data) {
            item_model.recalculate_children_stacking (gid);
        }

        // TODO: move this to the model, have it collect deleted ids and alert this
        items_removed (ids_array);

        if (!pause_compile) {
            compile_model ();
        }

        timer.stop ();
        seconds = timer.elapsed (out microseconds);
        print ("Deleted %u items in %s s\n", to_remove.length, seconds.to_string ());
        return 0;
    }

    /*
     * Alerts the model to recompile all dirty geometries.
    */
    public void compile_model () {
        item_model.compile_geometries ();
    }

    /*
     * Shift items by an amount up or down.
     * If to_end is true, amount is only used for direction (down/up)
     */
    public int shift_items (GLib.Array<int> ids, int amount, bool to_end) {
        if (amount == 0) {
            return 0;
        }

        var sorted_tree = new Gee.TreeMap<Lib.Items.PositionKey, Lib.Items.ModelNode> (
            Lib.Items.PositionKey.compare,
            null
        );

        var shift_groups = new Gee.ArrayList<Lib.Items.ChildrenSet> ();

        foreach (var id in ids.data) {
            var node = item_model.node_from_id (id);
            if (node == null) {
                continue;
            }

            var key = new Lib.Items.PositionKey ();
            key.parent_path = node.parent == null ? "" : item_model.path_from_node (node.parent);
            key.pos_in_parent = node.pos_in_parent;

            sorted_tree[key] = node;
        }

        Lib.Items.ChildrenSet current_set = null;
        int last_group_id = -1;
        int last_pos = -1;
        foreach (var mapit in sorted_tree) {
            var snode = mapit.value;
            bool is_next = last_group_id == snode.parent.id && snode.pos_in_parent == last_pos + 1;

            if (!is_next) {
                last_group_id = snode.parent.id;
                last_pos = snode.pos_in_parent;

                current_set = new Lib.Items.ChildrenSet ();
                current_set.parent_node = snode.parent;
                current_set.first_child = last_pos;
                current_set.children_in_set = new GLib.Array<unowned Lib.Items.ModelNode> ();
                current_set.children_in_set.append_val (snode);
                current_set.length = 1;

                shift_groups.add (current_set);
                continue;
            }

            last_pos = snode.pos_in_parent;
            current_set.children_in_set.append_val (snode);
            current_set.length++;
        }

        bool no_operation_yet = true;
        Utils.TrivialDelegate prep = () => {
            view_canvas.window.event_bus.create_model_snapshot ("shift items' z-order");
            // run only once
            no_operation_yet = false;
        };

        foreach (var cs in shift_groups) {
            var pos = cs.first_child;

            var newpos = pos + amount;

            if (to_end) {
                newpos = (amount > 0) ? (int)(cs.parent_node.children.length - cs.length) : 0;
            }

            if (newpos < 0) {
                newpos = 0;
            }

            if (newpos + cs.length > cs.parent_node.children.length) {
                newpos = (int)(cs.parent_node.children.length - cs.length);
            }

            if (newpos < 0 || newpos + cs.length > cs.parent_node.children.length) {
                cs = null;
                // at edges, nothing to do
                continue;
            }

            if (0 >= item_model.move_items (cs.parent_node.id, pos, newpos, cs.length, true, prep)) {
                // no items were shifted
                cs = null;
                continue;
            }
        }

        compile_model ();

        return 0;
    }

    public void flip_items (GLib.Array<int> ids, bool vertical) {
        /*
        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        foreach (var target_id in ids.data) {
            var target = item_model.instance_from_id (target_id);
            if (target.item != null) {
                unowned var old_flipped = target.item.components.flipped;
                bool new_h = false;
                bool new_v = false;

                if (old_flipped != null) {
                    new_h = old_flipped.horizontal;
                    new_v = old_flipped.vertical;
                }

                new_h = vertical ? new_h : !new_h;
                new_v = vertical ? !new_v : new_h;

                if (target.item.components.rotation != null) {
                    var tr = target.item.compiled_geometry.transform;
                    tr.x0 = 0;
                    tr.y0 = 0;

                    double offset = vertical ? 0 : 90;
                    double start_x = vertical ? 0 : -1;
                    double start_y = vertical ? -1 : 0;
                    tr.transform_point (ref start_x, ref start_y);
                    double flipped_x = start_x;
                    double flipped_y = start_y;

                    var radians = GLib.Math.atan2 (
                        flipped_x,
                        flipped_y
                    );

                    var rotation = GLib.Math.fmod (radians * 180 / GLib.Math.PI + offset, 360);
                    target.item.components.rotation = new Lib.Components.Rotation (rotation);
                }


                target.item.components.flipped = new Lib.Components.Flipped (new_h, new_v);
                target.item.mark_geometry_dirty ();
            }
        }

        compile_model ();
        */
    }

    public GLib.Array<unowned Lib.Items.ModelNode> children_in_group (int group_id) {
        return item_model.children_in_group (group_id);
    }

    public Lib.Items.ModelNode? node_at_canvas_position (
        double x,
        double y,
        Drawables.Drawable.HitTestType hit_test_type
    ) {
        var found_items = nodes_at_canvas_position (x, y, hit_test_type);
        if (found_items.size == 0) {
            return null;
        }

        return found_items.last ();
    }

    public Gee.ArrayList<unowned Lib.Items.ModelNode> nodes_in_bounded_region (
        Geometry.Rectangle bound
    ) {
        var found_items = new Gee.ArrayList<unowned Lib.Items.ModelNode> ();

        var origin = item_model.node_from_id (Lib.Items.Model.ORIGIN_ID);

        if (origin.children == null) {
            return found_items;
        }

        foreach (unowned var node in origin.children.data) {
            var node_type = node.instance.type.name_id;

            if (node_type == "artboard" && node.children != null) {
                foreach (unowned var child_node in node.children.data) {
                    // Only add items that are not currently selected.
                    if (
                        !view_canvas.selection_manager.item_selected (child_node.id) &&
                        bound.contains_bound (child_node.instance.bounding_box)
                    ) {
                        found_items.add (child_node);
                    }
                }
                continue;
            }

            // Only add items that are not currently selected.
            if (
                !view_canvas.selection_manager.item_selected (node.id) &&
                bound.contains_bound (node.instance.bounding_box)
            ) {
                found_items.add (node);
            }
        }

        return found_items;
    }

    /*
     * Returns the top-most group at position. Origin if no other group found.
     */
    public Lib.Items.ModelNode first_group_at (double x, double y) {
        var found_items = nodes_at_canvas_position (x, y, Drawables.Drawable.HitTestType.GROUP_REGION);

        var it = found_items.bidir_list_iterator ();
        for (var has_next = it.last (); has_next; has_next = it.previous ()) {
            unowned var cand = it.get ();
            if (cand.instance.is_group) {
                return cand;
            }
        }

        return item_model.node_from_id (Lib.Items.Model.ORIGIN_ID);
    }

    public Gee.ArrayList<unowned Lib.Items.ModelNode> nodes_at_canvas_position (
        double x,
        double y,
        Drawables.Drawable.HitTestType hit_test_type
    ) {
        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        Cairo.Context context = new Cairo.Context (surface);
        context.set_antialias (Cairo.Antialias.GRAY);
        context.set_line_width (2.0);

        var found_items = new Gee.ArrayList<unowned Lib.Items.ModelNode> ();

        var origin = item_model.node_from_id (Lib.Items.Model.ORIGIN_ID);
        if (origin.children == null) {
            return found_items;
        }

        foreach (unowned var root in origin.children.data) {
            root.items_in_canvas (x, y, context, view_canvas.scale, hit_test_type, ref found_items);
        }
        return found_items;
    }

    /*
    private void view_restack (Lib.Items.ChildrenSet children_set, bool up, Lib.Items.ModelNode reference) {
            if (reference == null) {
                assert (reference != null);
                return;
            }
            if (children_set.children_in_set.length == 0) {
                return;
            }

            if (up) {
                restack_up (children_set, reference);
                return;
            }

            restack_down (children_set, reference);
    }

    private bool restack_up (Lib.Items.ChildrenSet children_set, Lib.Items.ModelNode reference) {
        var sibling_under = Lib.Items.Model.previous_sibling (reference, true);

        if (sibling_under == null) {
            return false;
        }


        for (var i = (int) children_set.children_in_set.length - 1; i >= 0; --i) {
            unowned var model_item = children_set.children_in_set.index (i).instance.item;
            if (model_item.is_stackable ()) {
                model_item.canvas_item.raise (sibling_under.instance.item.canvas_item);
            }
        }
        return true;
    }

    private bool restack_down (Lib.Items.ChildrenSet children_set, Lib.Items.ModelNode reference) {
        var sibling_over = Lib.Items.Model.next_sibling (reference, true);

        if (sibling_over == null) {
            return false;
        }

        foreach (var to_restack in children_set.children_in_set.data) {
            unowned var model_item = to_restack.instance.item;
            if (model_item.is_stackable ()) {
                model_item.canvas_item.lower (sibling_over.instance.item.canvas_item);
            }
        }
        return true;
    }
    */

    public Lib.Items.ModelInstance add_debug_rect (double x, double y) {
        var new_rect = Lib.Items.ModelTypeEllipse.default_ellipse (
            //new Lib.Components.Coordinates (x + i * 60, y),
            new Lib.Components.Coordinates (x, y),
            new Lib.Components.Size (50.0, 50.0, false),
            new Lib.Components.Borders.single_color (Lib.Components.Color (0.3, 0.3, 0.3, 1.0), 2),
            new Lib.Components.Fills.with_color (Lib.Components.Color (0.0, 0.0, 0.0, 1.0))
        );

        add_item_to_origin (new_rect);

        return new_rect;
    }

    public Lib.Items.ModelInstance add_debug_group (double x, double y, bool debug_timer = false) {
        ulong microseconds;
        double seconds;

        // create a timer object:
        Timer timer = new Timer ();

        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);
        view_canvas.pause_redraw = true;

        var group = Lib.Items.ModelTypeArtboard.default_artboard (
            new Lib.Components.Coordinates (520, 520),
            new Lib.Components.Size (1000, 1000, false)
        );
        add_item_to_origin (group);

        var num_of = 1000;

        for (var i = 0; i < num_of; ++i) {
            x = GLib.Random.double_range (0, 1000);
            y = GLib.Random.double_range (0, 1000);

            var new_rect = Lib.Items.ModelTypeEllipse.default_ellipse (
                //new Lib.Components.Coordinates (x + i * 60, y),
                new Lib.Components.Coordinates (x, y),
                new Lib.Components.Size (50.0, 50.0, false),
                new Lib.Components.Borders.single_color (Lib.Components.Color (0.3, 0.3, 0.3, 1.0), 2),
                new Lib.Components.Fills.with_color (Lib.Components.Color (0.0, 0.0, 0.0, 1.0))
            );

            add_item_to_group (group.id, new_rect, true);
        }

        compile_model ();
        view_canvas.pause_redraw = false;
        view_canvas.request_redraw (view_canvas.get_bounds ());

        // Regenerate the layers list.
        view_canvas.window.main_window.regenerate_list ();

        if (debug_timer) {
            timer.stop ();
            seconds = timer.elapsed (out microseconds);
            print ("Created %u items in %s s\n", num_of, seconds.to_string ());
        }

        return group;
    }

    public void debug_add_rectangles (uint num_of, bool debug_timer = false) {
        // Always reset the selection before adding a chunk of items.
        view_canvas.selection_manager.reset_selection ();

        ulong microseconds;
        double seconds;

        // create a timer object:
        Timer timer = new Timer ();

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);
        view_canvas.pause_redraw = true;

        for (var i = 0; i < num_of; ++i) {
            var x = GLib.Random.double_range (0, (GLib.Math.log (num_of + GLib.Math.E) - 1) * 1000);
            var y = GLib.Random.double_range (0, (GLib.Math.log (num_of + GLib.Math.E) - 1) * 1000) + 500;
            var new_item = add_debug_rect (x, y);
            view_canvas.selection_manager.add_to_selection (new_item.id);
        }

        view_canvas.pause_redraw = false;
        view_canvas.request_redraw (view_canvas.get_bounds ());

        // Regenerate the layers list.
        view_canvas.window.main_window.regenerate_list ();

        if (debug_timer) {
            timer.stop ();
            seconds = timer.elapsed (out microseconds);
            print ("Created %u items in %s s\n", num_of, seconds.to_string ());
        }
    }

    public void create_group_from_selection () {
        // Don't create a group if we don't have any node selected.
        unowned var selection = view_canvas.selection_manager.selection;
        if (selection.count () == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);
        view_canvas.pause_redraw = true;

        var sorted_tree = new Gee.TreeMap<Lib.Items.PositionKey, Lib.Items.ModelNode> (
            Lib.Items.PositionKey.compare,
            null
        );

        var shift_groups = new Gee.ArrayList<Lib.Items.ChildrenSet> ();

        foreach (var node_id in selection.nodes.keys) {
            var node = item_model.node_from_id (node_id);
            if (node == null) {
                continue;
            }

            var key = new Lib.Items.PositionKey ();
            key.parent_path = node.parent == null ? "" : item_model.path_from_node (node.parent);
            key.pos_in_parent = node.pos_in_parent;

            sorted_tree[key] = node;
        }

        Lib.Items.ChildrenSet current_set = null;
        int target_group_id = -1;
        int target_group_pos = -1;
        int last_pos = -1;
        foreach (var mapit in sorted_tree) {
            var snode = mapit.value;
            bool is_next = target_group_id == snode.parent.id && snode.pos_in_parent == last_pos + 1;

            if (!is_next) {
                target_group_id = snode.parent.id;
                last_pos = snode.pos_in_parent;
                target_group_pos = last_pos;

                current_set = new Lib.Items.ChildrenSet ();
                current_set.parent_node = snode.parent;
                current_set.first_child = last_pos;
                current_set.children_in_set = new GLib.Array<unowned Lib.Items.ModelNode> ();
                current_set.children_in_set.append_val (snode);
                current_set.length = 1;

                shift_groups.add (current_set);
                continue;
            }

            last_pos = snode.pos_in_parent;
            current_set.children_in_set.append_val (snode);
            current_set.length++;
        }

        if (target_group_id < Lib.Items.Model.ORIGIN_ID) {
            assert (false);
            return;
        }


        // Clear the current selection so we don't stumble upon weird states.
        view_canvas.selection_manager.reset_selection ();

        view_canvas.window.event_bus.create_model_snapshot ("create group from selection");

        unowned var model = view_canvas.items_manager.item_model;
        // Create a new empty group and add it to the main canvas.
        var group = Lib.Items.ModelTypeGroup.default_group ();

        var result_id = model.splice_new_item (target_group_id, int.MAX, group);
        assert (result_id > Lib.Items.Model.ORIGIN_ID);

        var it = shift_groups.bidir_list_iterator ();
        for (var has_next = it.last (); has_next; has_next = it.previous ()) {
            var sg = it.get ();

            if (0 != model.transfer (
                sg.parent_node.id,
                sg.first_child,
                sg.length,
                result_id,
                int.MAX,
                true,
                null
            )) {
                assert (false);
                return;
            }
        }


        var container = model.node_from_id (target_group_id);

        var new_group = model.node_from_id (result_id);
        if (model.move_items (container.id, new_group.pos_in_parent, target_group_pos, 1, true, null) < 0) {
            assert (false);
        }

        compile_model ();
        view_canvas.pause_redraw = false;
        view_canvas.request_redraw (view_canvas.get_bounds ());

        // Regenerate the layers list.
        view_canvas.window.main_window.regenerate_list ();
        // Select the newly created group.
        view_canvas.selection_manager.add_to_selection (group.id);
    }

    public void selection_align (Utils.ItemAlignment.AlignmentDirection direction) {
        unowned var selection = view_canvas.selection_manager.selection;
        if (selection.count () <= 1) {
            return;
        }

        unowned int? anchor_point_node_id = view_canvas.nob_manager.anchor_point_node_id;

        var type = Utils.ItemAlignment.AlignmentType.AUTO;
        Lib.Items.ModelNode? anchor = null;

        if (anchor_point_node_id != null) {
            anchor = node_from_id (anchor_point_node_id);
            type = Utils.ItemAlignment.AlignmentType.ANCHOR;
        }

        Utils.TrivialDelegate prep = () => {
            view_canvas.window.event_bus.create_model_snapshot ("autoalign items");
        };

        Utils.ItemAlignment.align_selection (selection, direction, type, anchor, view_canvas, prep);
    }

}
