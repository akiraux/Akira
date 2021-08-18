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
    public unowned Lib2.ViewCanvas view_canvas { get; construct; }

    private Gtk.ListBox items_list;

    public LayersPanel (Lib2.ViewCanvas canvas) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            view_canvas: canvas
        );
    }

    construct {
        get_style_context ().add_class ("layers-panel");
        expand = true;

        items_list = new Gtk.ListBox ();
        items_list.activate_on_single_click = false;
        items_list.selection_mode = Gtk.SelectionMode.SINGLE;

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

        items_list.prepend (new LayerElement (node_instance, view_canvas));
    }

    public void refresh_lists () {
        items_list.show_all ();
    }

    public void clear_list () {
        foreach (var row in items_list.get_selected_rows ()) {
            row.destroy ();
        }
    }
}
