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

        activate_on_single_click = true;
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
            } else {
                row = new LayerListItem ();
            }

            row.assign ((LayerItemModel)item);
            row.show_all ();

            return row;
        };

        // When an item is selected from a click on the layers list.
        row_selection_changed.connect ((clear) => {
            on_row_selection_changed (clear);
        });

        // Listed to the button release event only for the secondary click in
        // order to trigger the context menu.
        button_release_event.connect ((e) => {
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
    }

    private void on_item_added (int id) {
        var node_instance = view_canvas.items_manager.instance_from_id (id);
        // No need to add any layer if we don't have an instance.
        if (node_instance == null) {
            return;
        }

        var service_uid = node_instance.id;
        var item = new LayerItemModel (node_instance, service_uid);
        layers[service_uid] = item;
        list_store.add (item);
        print ("on_item_added: %i\n", service_uid);
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
     * Triggers the update of the list store and refresh of the UI to show the
     * newly added items that are currently visible.
     */
    public void show_added_layers (int added) {
        list_store.items_changed (0, 0, added);
    }

    /*
     * Remove all the currently selected layers. The list of ids comes from the
     * selected nodes in the view canvas.
     */
    public void remove_items (GLib.Array<int> ids) {
        var removed = 0;
        foreach (var uid in ids.data) {
            var item = layers[uid];
            if (item != null) {
                layers.unset (uid);
                list_store.remove (item);
                removed++;
            }
        }

        list_store.items_changed (0, removed, 0);
    }

    /*
     * Sort function to always add new layers at the top.
     */
    private static int layers_sort_function (LayerItemModel layer1, LayerItemModel layer2) {
        return (int)(layer2.id - layer1.id);
    }

    /*
     * Update the selected items in the canvas when the selection of rows in the
     * listbox changes.
     */
    private void on_row_selection_changed (bool clear) {
        var sm = view_canvas.selection_manager;
        // Always reset the selection.
        sm.reset_selection ();

        // No need to do anything else if all rows were selected.
        if (clear) {
            return;
        }

        // Add all currently selected rows to the selection. This won't trigger
        // a selection changed loop since the selection_modified_external signal
        // is only triggered from a click on the canvas.
        foreach (var model in get_selected_rows ()) {
            sm.add_to_selection (((LayerItemModel) model).node.id);
        }

        // Trigger the transform mode if is not currently active. This might
        // happen when no items is selected and the first selection is triggered
        // from the layers listbox.
        var mm = view_canvas.mode_manager;
        if (mm.active_mode_type != Lib.Modes.AbstractInteractionMode.ModeType.TRANSFORM) {
            var new_mode = new Lib.Modes.TransformMode (view_canvas, Utils.Nobs.Nob.NONE);
            mm.register_mode (new_mode);
            mm.deregister_active_mode ();
        }
    }

    /*
     * When an item in the canvas is selected via click interaction.
     */
    private void on_selection_modified_external () {
        print ("on_selection_modified_external\n");
        // Always reset the selection of the layers.
        unselect_all ();

        var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            return;
        }

        // A bit hacky but I don't know how to fix this. Since we're adding the
        // new layer on top, the index is always 0 for newly generated layers.
        // That means the selection changes happens so fast that it tries to select
        // the row on index 0 while a new row is being added at index 0. Without
        // the timeout, the app crashes.
        Timeout.add (0, () => {
            foreach (var node in sm.selection.nodes.values) {
                select_row_at_index (model.get_index_of (layers[node.node.id]));
            }
            return false;
        });
    }
}
