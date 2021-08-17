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

    private Gtk.ListBox artboards_list;
    private Gtk.ListBox free_items_list;

    public LayersPanel (Lib2.ViewCanvas canvas) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            view_canvas: canvas
        );
    }

    construct {
        get_style_context ().add_class ("layers-panel");
        expand = true;

        // We need to keep free items (layers which parent is the canvas), and
        // artboards in different listboxes to properly handle drag&drop and hierarchy.
        free_items_list = new Gtk.ListBox ();
        free_items_list.activate_on_single_click = false;
        free_items_list.selection_mode = Gtk.SelectionMode.SINGLE;

        artboards_list = new Gtk.ListBox ();
        artboards_list.activate_on_single_click = false;
        artboards_list.selection_mode = Gtk.SelectionMode.SINGLE;

        // Motion revealer for layers drag&drop on the empty area.
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 2;

        var motion_layer_revealer = new Gtk.Revealer ();
        motion_layer_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_layer_revealer.add (motion_grid);

        // Motion revealer for artboards drag&drop reordering.
        var motion_artboard_grid = new Gtk.Grid ();
        motion_artboard_grid.get_style_context ().add_class ("grid-motion");
        motion_artboard_grid.height_request = 2;

        var motion_artboard_revealer = new Gtk.Revealer ();
        motion_artboard_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_artboard_revealer.add (motion_artboard_grid);

        var empty_area = new Gtk.Grid ();
        empty_area.expand = true;

        // Free items are always listed above any other element.
        attach (free_items_list, 0, 1);
        attach (motion_layer_revealer, 0, 2);
        attach (artboards_list, 0, 3);
        attach (motion_artboard_revealer, 0, 4);
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

        var new_layer = new LayerElement (node_instance, view_canvas);

        // Create a new layer and add it to a specific listbox based on the
        // node's type.
        if (node_instance.type is Lib2.Items.ModelTypeArtboard) {
            artboards_list.add (new_layer);
            return;
        }

        free_items_list.add (new_layer);
    }
}
