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
 */

/*
 * Layout component containing all layers related elements.
 */
public class Akira.Layouts.Sidebars.Partials.LayersPanel : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private Gtk.ListBox items_list;
    // Keep track of each row associated to a node's ID in order to quickly get
    // the layer to remove, move, or select, without doing nested foreach.
    private Gee.HashMap<int, Gtk.ListBoxRow> list_map;

    public LayersPanel (Lib.ViewCanvas canvas) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            view_canvas: canvas
        );
    }

    construct {
        get_style_context ().add_class ("layers-panel");
        expand = true;

        list_map = new Gee.HashMap<int, Gtk.ListBoxRow> ();
        items_list = new Gtk.ListBox ();
        items_list.activate_on_single_click = false;
        items_list.selection_mode = Gtk.SelectionMode.MULTIPLE;

        // Motion revealer for layers drag&drop on the empty area.
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 2;

        var motion_layer_revealer = new Gtk.Revealer ();
        motion_layer_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_layer_revealer.add (motion_grid);

        var empty_area = new Gtk.Grid ();
        empty_area.expand = true;

        attach (items_list, 0, 1);
        attach (motion_layer_revealer, 0, 2);
        attach (empty_area, 0, 5);

        // Connect signals.
        view_canvas.items_manager.item_model.item_added.connect (on_item_added);
        view_canvas.window.event_bus.selection_modified.connect (on_selection_modified);
    }

    /*
     * Add a new layer whenever an item is added to the model.
     */
    private void on_item_added (int id) {
        var node_instance = view_canvas.items_manager.instance_from_id (id);
        // No need to add any layer if we don't have an instance.
        if (node_instance == null) {
            return;
        }

        var layer = new LayerElement (node_instance, view_canvas);
        items_list.prepend (layer);

        // Add the newly created layer to the list map.
        list_map[node_instance.id] = layer;
    }

    public void refresh_lists () {
        items_list.show_all ();
    }

    /*
     * Use the received list of nodes' ids from the signal to loop through the
     * layers list and remove rows. We do this because the on_selection_modified
     * method runs first and all the rows have already been deselected, so we
     * can't loop through them.
     */
    public void delete_selected_layers (GLib.Array<int> ids) {
        foreach (var id in ids.data) {
            var row = list_map.get (id);
            if (row == null) {
                continue;
            }

            row.destroy ();
            list_map.unset (id);
        }
    }

    private void on_selection_modified () {
        var sm = view_canvas.selection_manager;
        if (sm.is_empty ()) {
            items_list.unselect_all ();
            return;
        }

        foreach (var selected in sm.selection.nodes.values) {
            var row = list_map.get (selected.node.id);
            if (row == null) {
                continue;
            }

            items_list.select_row (row);
        }
    }
}
