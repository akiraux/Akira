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

public class Akira.Lib.Managers.CopyManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    private Lib.Items.Model copy_model;

    public CopyManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        view_canvas.window.event_bus.request_copy.connect (do_copy);
        view_canvas.window.event_bus.request_paste.connect (do_paste);
        view_canvas.window.event_bus.request_duplicate.connect (do_duplicate);
    }

    /*
     * Return a tree map of the currently selected items, with their sorted position.
     */
    private Gee.TreeMap<Lib.Items.PositionKey, int> collect_sorted_candidates () {
        var candidates = new Gee.TreeMap<Lib.Items.PositionKey, int> (Lib.Items.PositionKey.compare);
        foreach (var to_copy in view_canvas.selection_manager.selection.nodes.values) {
            var key = new Lib.Items.PositionKey ();
            key.parent_path = view_canvas.items_manager.item_model.path_from_node (to_copy.node.parent);
            key.pos_in_parent = to_copy.node.pos_in_parent;
            candidates[key] = to_copy.node.id;
        }

        return candidates;
    }

    /*
     * Copy the currently selected nodes.
     */
    public void do_copy () {
        var sorted_candidates = collect_sorted_candidates ();
        // Don't do anything if we don't have selected nodes.
        if (sorted_candidates.size == 0) {
            return;
        }

        // Create a new Model to hold all the cloned nodes in memory.
        copy_model = new Lib.Items.Model ();

        // Populate the model with all the currently selected nodes.
        int res = 0;
        foreach (var sorted_id in sorted_candidates.values) {
            res += Utils.ModelUtil.clone_from_model (
                view_canvas.items_manager.item_model,
                sorted_id,
                copy_model,
                Lib.Items.Model.ORIGIN_ID
            );
        }

        assert (res == 0);
    }

    /*
     * Paste a copied node into the item_model.
     * TODO:
     * - If the `in_place` is true, the cloned node should be spliced at the same position of the
     * currently selected node, ignoring the source node position (eg. paste into group, paste into
     * another artboard, etc.), and the X & Y coordinates of the cloned node should match the
     * coordiante sof the currently selected node.
     * - If the `in_place` is false, we should paste the node at the center of the viewport, at the
     * top most position.
     */
    public void do_paste (bool in_place = false) {
        if (copy_model == null) {
            return;
        }

        var children = copy_model.node_from_id (Lib.Items.Model.ORIGIN_ID).children;
        if (children == null || children.length == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        view_canvas.selection_manager.reset_selection ();
        view_canvas.window.event_bus.create_model_snapshot (
            in_place ? "paste selection in place" : "paste selection");

        int res = 0;
        foreach (var child in children.data) {
            res += Utils.ModelUtil.clone_from_model (
                copy_model,
                child.id,
                view_canvas.items_manager.item_model,
                Lib.Items.Model.ORIGIN_ID,
                on_subtree_cloned,
                in_place ? Utils.ModelUtil.State.PASTE_IN_PLACE : Utils.ModelUtil.State.PASTE
            );
        }
        assert (res == 0);
        on_after_paste ();
    }

    private void do_duplicate () {
        var sorted_candidates = collect_sorted_candidates ();
        // Don't do anything if we don't have selected nodes.
        if (sorted_candidates.size == 0) {
            return;
        }

        // Populate the model with all the currently selected nodes. Use a locally
        // scoped variable to not override the copy_model in order to maintain any
        // existing copied model.
        var duplicate_model = new Lib.Items.Model ();
        int res = 0;
        foreach (var sorted_id in sorted_candidates.values) {
            res += Utils.ModelUtil.clone_from_model (
                view_canvas.items_manager.item_model,
                sorted_id,
                duplicate_model,
                Lib.Items.Model.ORIGIN_ID
            );
        }
        assert (res == 0);

        if (duplicate_model == null) {
            return;
        }

        var children = duplicate_model.node_from_id (Lib.Items.Model.ORIGIN_ID).children;
        if (children == null || children.length == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        view_canvas.selection_manager.reset_selection ();
        view_canvas.window.event_bus.create_model_snapshot ("duplicate selection");

        res = 0;
        foreach (var child in children.data) {
            res += Utils.ModelUtil.clone_from_model (
                duplicate_model,
                child.id,
                view_canvas.items_manager.item_model,
                Lib.Items.Model.ORIGIN_ID,
                on_subtree_cloned,
                Utils.ModelUtil.State.DUPLICATE
            );
        }
        assert (res == 0);
        on_after_paste ();
    }

    private void on_after_paste () {
        view_canvas.items_manager.compile_model ();
        // Regenerate the layers list.
        view_canvas.window.main_window.regenerate_list (true);
    }

    private void on_subtree_cloned (int id) {
        view_canvas.selection_manager.add_to_selection (id);
    }
}
