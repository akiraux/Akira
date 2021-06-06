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

public class Akira.Lib2.Managers.CopyManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    public Gee.TreeMap<Lib2.Items.PositionKey, Lib2.Items.ModelItem> candidates;

    public CopyManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        view_canvas.window.event_bus.request_copy.connect(do_copy);
        view_canvas.window.event_bus.request_paste.connect(do_paste);
    }

    public void do_copy () {
        candidates = new Gee.TreeMap<Lib2.Items.PositionKey, Lib2.Items.ModelItem> (Lib2.Items.PositionKey.compare);

        foreach (var to_copy in view_canvas.selection_manager.selection.nodes.values) {

            var original_node = view_canvas.items_manager.item_model.node_from_id (to_copy.id);
            var key = new Lib2.Items.PositionKey ();
            key.parent_path = view_canvas.items_manager.item_model.path_from_node (original_node.parent);
            key.pos_in_parent = original_node.pos_in_parent;

            var cln = to_copy.instance.item.clone ();
            cln.id = -1;
            candidates[key] = cln;
        }
    }

    public void do_paste () {
        if (candidates.size == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        view_canvas.selection_manager.reset_selection ();

        foreach (var cand in candidates) {
            var cln = cand.value.clone ();
            view_canvas.items_manager.add_item_to_origin (cln);
            view_canvas.selection_manager.add_to_selection (cln.id);
        }
    }
}
