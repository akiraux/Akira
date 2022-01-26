/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * The scrollable layers panel.
 */
public class Akira.Layouts.LayersList.LayerListBox : VirtualizingListBox {
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.HashMap<int, LayerItemModel> layers;
    private LayerListStore list_store;

    public LayerListBox (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        selection_mode = Gtk.SelectionMode.MULTIPLE;
        activate_on_single_click = true;
        edit_on_double_click = true;
        layers = new Gee.HashMap<int, LayerItemModel> ();
        list_store = new LayerListStore ();
        list_store.set_sort_func (layers_sort_function);

        model = list_store;

        // Factory function to reuse the already generated row UI element when
        // a new layer is created or the layers list scrolls to reveal layers
        // outside of the viewport.
        factory_func = (item, old_widget) => {
            LayerListItem? row = null;
            if (old_widget != null) {
                row = old_widget as LayerListItem;
                if (row.is_editing) {
                    row.edit_end ();
                }
            } else {
                row = new LayerListItem ();
            }

            row.assign ((LayerItemModel) item);
            row.show_all ();

            return row;
        };

        // When an item is selected from a click on the layers list.
        row_selection_changed.connect (on_row_selection_changed);

        // When a row is hovered.
        row_hovered.connect (on_row_hovered);

        // When the name of the layer is being edited.
        row_edited.connect (on_row_edited);

        // Listen to the button release event only for the secondary click in
        // order to trigger the context menu.
        button_release_event.connect (e => {
            if (e.button != Gdk.BUTTON_SECONDARY) {
                return Gdk.EVENT_PROPAGATE;
            }
            var row = get_row_at_y ((int)e.y);
            if (row == null) {
                return Gdk.EVENT_PROPAGATE;
            }

            if (selected_row_widget != row) {
                select_row (row);
            }
            return create_context_menu (e, (LayerListItem)row);
        });

        // Trigger the context menu when the `menu` key is pressed.
        key_release_event.connect ((e) => {
            if (e.keyval != Gdk.Key.Menu) {
                return Gdk.EVENT_PROPAGATE;
            }
            var row = selected_row_widget;
            return create_context_menu (e, (LayerListItem)row);
        });

        view_canvas.items_manager.item_model.item_added.connect (on_item_added);
        view_canvas.selection_manager.selection_modified_external.connect (on_selection_modified_external);
        view_canvas.hover_manager.hover_changed.connect (on_hover_changed);
        view_canvas.window.event_bus.request_escape.connect (on_escape_request);
    }

    /*
     * Add all existing nodes to the layers list when the UI is revealed.
     */
    public void regenerate_list () {
        ulong microseconds;
        double seconds;
        // Create a timer object to track the regeneration of the layers list.
        Timer timer = new Timer ();

        var added = 0;
        unowned var im = view_canvas.items_manager;

        foreach (var key in im.item_model.group_nodes.keys) {
            var node = im.item_model.group_nodes[key];
            if (node.id == Lib.Items.Model.ORIGIN_ID) {
                continue;
            }
            var item = new LayerItemModel (view_canvas, node);
            layers[node.id] = item;
            list_store.add (item);
            added++;
        }

        foreach (var key in im.item_model.item_nodes.keys) {
            var node = im.item_model.item_nodes[key];
            var item = new LayerItemModel (view_canvas, node);
            layers[node.id] = item;
            list_store.add (item);
            added++;
        }

        list_store.items_changed (0, 0, added);

        // Restore the selected items.
        on_selection_modified_external ();

        timer.stop ();
        seconds = timer.elapsed (out microseconds);
        print ("Created %i layers in %s s\n", added, seconds.to_string ());
    }

    /*
     * Clear the layers list when the UI is hidden.
     */
    public void clear_list () {
        // Interrupt if the layers list is empty.
        if (layers.size == 0) {
            return;
        }

        ulong microseconds;
        double seconds;
        // Create a timer object to track the deletion of the layers list.
        Timer timer = new Timer ();

        // Remove all items.
        var removed = layers.size;
        layers.clear ();
        list_store.remove_all ();
        list_store.items_changed (0, removed, 0);

        timer.stop ();
        seconds = timer.elapsed (out microseconds);
        print ("Deleted %i layers in %s s\n", removed, seconds.to_string ());
    }

    private void on_item_added (int id) {
        if (view_canvas.block_ui) {
            return;
        }

        var node = view_canvas.items_manager.node_from_id (id);
        // No need to add any layer if we don't have an instance.
        if (node == null) {
            return;
        }

        var node_id = node.id;
        var item = new LayerItemModel (view_canvas, node);
        layers[node_id] = item;
        list_store.add (item);

        // Check if the newly created layer is inside an artboard or a group and
        // show all its child layers if they were removed.
        recursive_show_child_layers (node_id);
    }

    private void recursive_show_child_layers (int node_id) {
        var item = layers[node_id];
        if (item == null) {
            return;
        }

        var parent = layers[item.parent_uid];
        if (parent == null) {
            return;
        }

        parent.children_visible = true;
        recursive_show_child_layers (parent.parent_uid);
    }

    private bool create_context_menu (Gdk.Event e, LayerListItem row) {
        var menu = new Gtk.Menu ();
        menu.show_all ();

        if (e.type == Gdk.EventType.BUTTON_RELEASE) {
            menu.popup_at_pointer (e);
            return Gdk.EVENT_STOP;
        } else if (e.type == Gdk.EventType.KEY_RELEASE) {
            menu.popup_at_widget (row, Gdk.Gravity.EAST, Gdk.Gravity.CENTER, e);
            return Gdk.EVENT_STOP;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    /*
     * Visually create layers from a list of items ids. This method is used to
     * show layers that have been removed when a parent (artboard or group)
     * collapses its children.
     */
    public void add_items (GLib.Array<int> ids) {
        if (view_canvas.block_ui) {
            return;
        }

        var added = 0;
        foreach (var uid in ids.data) {
            // Don't create a layer if it already exists. This might happen when
            // revealing the children of a collapsed artboard during the
            // creation of a new child item.
            if (layers[uid] == null) {
                on_item_added (uid);
            }
            // Check if the layer was actually created.
            if (layers[uid] != null) {
                added++;
            }
        }
        // Refresh the layers list UI.
        show_added_layers (added);
    }

    /*
     * Triggers the update of the list store and refresh of the UI to show the
     * newly added items that are currently visible.
     */
    public void show_added_layers (int added) {
        if (view_canvas.block_ui) {
            return;
        }

        list_store.items_changed (0, 0, added);
        // Restore selected items.
        on_selection_modified_external ();
    }

    /*
     * Remove all the currently selected layers. The list of ids comes from the
     * selected nodes in the view canvas.
     */
    public void remove_items (GLib.Array<int> ids) {
        if (view_canvas.block_ui) {
            return;
        }

        var removed = 0;
        foreach (var uid in ids.data) {
            var item = layers[uid];
            if (item != null) {
                removed += inner_remove_items (item);
                layers.unset (uid);
                list_store.remove (item);
                removed++;
            }
        }

        list_store.items_changed (0, removed, 0);
    }

    /*
     * Check if an item has children and recursively loop through them to
     * remove all the matching layers.
     */
    private int inner_remove_items (LayerItemModel item) {
        var removed = 0;
        foreach (var uid in item.get_children ()) {
            if (uid == 0) {
                continue;
            }

            var child = layers[uid];
            if (child != null) {
                removed += inner_remove_items (child);
                layers.unset (uid);
                list_store.remove (child);
                removed++;
            }
        }

        return removed;
    }

    /*
     * Sort function to always add new layers at the top unless they belong to a
     * group or an artboard.
     */
    private int layers_sort_function (LayerItemModel layer1, LayerItemModel layer2) {
        var im = view_canvas.items_manager.item_model;
        var node1 = im.node_from_id (layer1.id);
        var node2 = im.node_from_id (layer2.id);

        var node1_is_group = node1.instance.is_group;
        var node2_is_group = node2.instance.is_group;

        if (node1_is_group != node2_is_group) {
            unowned var group_node = node1_is_group ? node1 : node2;
            unowned var child_node = node1_is_group ? node2 : node1;
            if (child_node.has_ancestor (group_node.id)) {
                return node1_is_group ? -1 : 1;
            }
        }

        var path1 = im.array_path_from_node (node1);
        var path2 = im.array_path_from_node (node2);

        return Utils.Array.compare_arrays (path2, path1);
    }

    /*
     * Update the selected items in the canvas when the selection of rows in the
     * listbox changes.
     */
    private void on_row_selection_changed (bool clear) {
        unowned var sm = view_canvas.selection_manager;
        // Always reset the selection.
        sm.reset_selection ();

        // No need to do anything else if all rows were deselected.
        if (clear) {
            reset_edited_row ();
            return;
        }

        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        // Add all currently selected rows to the selection. This won't trigger
        // a selection changed loop since the selection_modified_external signal
        // is only triggered from a click on the canvas.
        foreach (var model in get_selected_rows ()) {
            sm.add_to_selection (((LayerItemModel) model).id);
        }

        // Trigger the transform mode if is not currently active. This might
        // happen when no items is selected and the first selection is triggered
        // from the layers listbox.
        unowned var mm = view_canvas.mode_manager;
        if (mm.active_mode_type != Lib.Modes.AbstractInteractionMode.ModeType.TRANSFORM) {
            var new_mode = new Lib.Modes.TransformMode (view_canvas, Utils.Nobs.Nob.NONE, true);
            mm.register_mode (new_mode);
            mm.deregister_active_mode ();
        }
    }

    /*
     * When an item in the canvas is selected via click interaction.
     */
    private void on_selection_modified_external (bool go_to_layer = false) {
        reset_edited_row ();

        // Always reset the selection of the layers.
        unselect_all ();

        unowned var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            return;
        }

        var it = sm.selection.nodes.map_iterator ();

        // If the selection was modified from a click on the canvas, we need to
        // move the first selected layer into the viewport of the layers list.
        if (go_to_layer) {
            it.next ();
            var first_node = it.get_value ().node;
            if (layers[first_node.id] != null) {
                select_row_at_index (model.get_index_of (layers[first_node.id]));
            }
        }

        // For all other scenarios where a selection is restored dynamically or
        // multiple items are selected, we don't generate the layer row widgets
        // but we only update the selection state of the model.
        while (it.next ()) {
            var node = it.get_value ().node;
            if (layers[node.id] != null) {
                list_store.set_item_selected (layers[node.id], true);
            }
        }

        if (sm.selection.count () > 1) {
            // Trigger a visual refresh of the visible layers without changing
            // anything in the list store in order to show the newly selected layers.
            list_store.items_changed (0, 0, 0);
        }
    }

    /*
     * Show the hover effect on a canvas item if available.
     */
    private void on_row_hovered (GLib.Object? item) {
        unowned var hm = view_canvas.hover_manager;
        if (item == null) {
            hm.remove_hover_effect ();
            return;
        }

        hm.maybe_create_hover_effect_by_id (((LayerItemModel) item).id);
    }

    /*
     * Show the hover effect on a layer row when an item from the canvas is
     * hovered. Clear the hover effect if no canvas item was hovered.
     */
    private void on_hover_changed (int? id) {
        on_mouse_leave_internal ();

        if (id != null && layers[id] != null) {
            set_hover_on_row_from_model (layers[id]);
        }
    }

    /*
     * Toggle the edit state of rows and handle typing accelerators accordingly.
     */
    private void on_row_edited (VirtualizingListBoxRow? item) {
        reset_edited_row ();

        if (item == null) {
            return;
        }

        edited_row = item;
        var layer = (LayerListItem) edited_row;
        layer.edit ();
        layer.entry.activate.connect (on_activate_entry);
        view_canvas.window.event_bus.disconnect_typing_accel ();
    }

    /*
     * Handle the `activate` signal triggered by the edited label entry of a
     * layer row.
     */
    private void on_activate_entry () {
        ((LayerListItem) edited_row).update_label ();
        on_row_edited (null);
    }

    /*
     * If a layer row is currently being edited, reset it to the default state.
     */
    private void reset_edited_row () {
        if (edited_row != null) {
            var layer = (LayerListItem) edited_row;
            layer.edit_end ();
            layer.entry.activate.disconnect (on_activate_entry);

            edited_row = null;
            view_canvas.window.event_bus.connect_typing_accel ();
        }
    }

    /*
     * Be sure to reset any potential leftover edited layer row when the user
     * presses the `esc` button.
     */
    private void on_escape_request () {
        on_row_edited (null);
    }

    /*
     * Loop through the passed nodes and update the locked state.
     */
    public void set_children_locked (int[] nodes, bool is_locked) {
        foreach (var uid in nodes) {
            if (layers[uid] != null) {
                layers[uid].locked = is_locked;
            }
        }
        // Trigger a visual refresh of the visible layers without changing
        // anything in the list store.
        list_store.items_changed (0, 0, 0);
    }
}
