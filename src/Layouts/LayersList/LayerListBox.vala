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
    public signal void layer_selected (Lib.Items.ModelInstance? node);
    public signal void layer_focused (Lib.Items.ModelInstance? node);

    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private string? current_search_query = null;
    private Gee.HashMap<string, LayerItemModel> layers;
    private LayerListStore list_store;

    public LayerListBox (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        activate_on_single_click = true;
        layers = new Gee.HashMap<string, LayerItemModel> ();
        list_store = new LayerListStore ();

        model = list_store;

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

        row_activated.connect ((row) => {
            if (row == null) {
                layer_focused (null);
                return;
            }
            layer_focused (((LayerItemModel) row).node);
        });

        row_selected.connect ((row) => {
            if (row == null) {
                layer_selected (null);
                return;
            }

            layer_selected (((LayerItemModel) row).node);
        });

        button_release_event.connect ((e) => {
            if (e.button != Gdk.BUTTON_SECONDARY) {
                return Gdk.EVENT_PROPAGATE;
            }
            var row = get_row_at_y ((int)e.y);
            if (selected_row_widget != row) {
                select_row (row);
            }
            return create_context_menu (e, (LayerListItem)row);
        });

        key_release_event.connect ((e) => {
            if (e.keyval != Gdk.Key.Menu) {
                return Gdk.EVENT_PROPAGATE;
            }
            var row = selected_row_widget;
            return create_context_menu (e, (LayerListItem)row);
        });

        view_canvas.items_manager.item_model.item_added.connect (on_item_added);
    }

    private void add_layer_item (Lib.Items.ModelInstance node, string service_uid) {
        var item = new LayerItemModel (node, service_uid);
        layers[node.id.to_string()] = item;
        list_store.add (item);
    }

    private void on_item_added (int id) {
        var node_instance = view_canvas.items_manager.instance_from_id (id);
        // No need to add any layer if we don't have an instance.
        if (node_instance == null) {
            return;
        }

        add_layer_item (node_instance, "test");
    }

    private bool create_context_menu (Gdk.Event e, LayerListItem row) {
        var item = (LayerItemModel)row.model_item;

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
}
