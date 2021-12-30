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

public class Akira.Lib.Managers.SelectionManager : Object {
    // Signal triggered every time an item is added or removed from the selection
    // map. Connect this signal when elements of the UI need to be updated based
    // on the selected items.
    public signal void selection_modified ();

    // Signal triggered only when an item is added or removed from the selection
    // map exclusively via click event from the ViewCanvas. This is necessary in
    // order to only update the Layers panel without triggering a selection loop.
    public signal void selection_modified_external ();

    public unowned ViewCanvas view_canvas { get; construct; }

    /*
     * Blocks notifications until class is destructed.
     */
    public class ChangeSignalBlocker {
        private unowned SelectionManager manager;

        public ChangeSignalBlocker (SelectionManager sm) {
            this.manager = sm;
            this.manager.block_change_notifications += 1;
        }

        ~ChangeSignalBlocker () {
            manager.block_change_notifications -= 1;
            manager.on_selection_changed (-1);
        }
    }

    public Lib.Items.NodeSelection selection;
    protected int block_change_notifications = 0;

    public SelectionManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        selection = new Lib.Items.NodeSelection (null);
        view_canvas.window.event_bus.flip_item.connect (on_flip_selected);
        view_canvas.window.event_bus.delete_selected_items.connect (delete_selected);
        view_canvas.window.event_bus.change_z_selected.connect (change_z_order);
    }

    public bool is_empty () {
        return selection.is_empty ();
    }

    public int count () {
        return selection.count ();
    }

    public void reset_selection () {
        if (is_empty ()) {
            return;
        }

        selection = new Lib.Items.NodeSelection (null);
        on_selection_changed (-1);
        selection_modified ();
    }

    public void add_to_selection (int id) {
        var node = view_canvas.items_manager.node_from_id (id);
        if (node == null) {
            return;
        }
        selection.add_node (node);
        on_selection_changed (-1);
        selection_modified ();
    }

    /*
     * Remove a specific node from the current selection, if present.
     */
    public void remove_from_selection (int id) {
        if (!item_selected (id)) {
            return;
        }

        selection.remove_node (id);
        on_selection_changed (-1);
        selection_modified ();
    }

    public bool item_selected (int id) {
        return selection.has_id (id, true);
    }

    /*
     * Called whenever the selection is changed, including adding and removing
     * items, and modifying the selection's geometry.
     */
    public void on_selection_changed (int id) {
        if (block_change_notifications == 0) {
            if (id < 0 || selection.has_id (id, false)) {
                view_canvas.window.event_bus.selection_modified ();
            }
        }
    }

    public void delete_selected () {
        var to_delete = new GLib.Array<int> ();
        foreach (var node_id in selection.nodes.keys) {
            to_delete.append_val (node_id);
        }

        reset_selection ();
        view_canvas.items_manager.remove_items (to_delete);
    }

    public void change_z_order (bool up, bool to_end) {
        var to_shift = new GLib.Array<int> ();
        foreach (var node_id in selection.nodes.keys) {
            to_shift.append_val (node_id);
        }

        int amount = up ? 1 : -1;
        view_canvas.items_manager.shift_items (to_shift, amount, to_end);
    }

    public void on_flip_selected (bool vertical) {
        var to_flip = new GLib.Array<int> ();
        foreach (var node_id in selection.nodes.keys) {
            to_flip.append_val (node_id);
        }

        view_canvas.items_manager.flip_items (to_flip, vertical);
    }
}
