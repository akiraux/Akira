/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.MainWindow : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Akira.Layouts.MainViewCanvas main_view_canvas;

    private Layouts.Sidebars.LayersSidebar layers_sidebar;
    private Layouts.Sidebars.OptionsSidebar options_sidebar;

    public Gtk.Paned pane;
    public Gtk.Paned pane2;

    public MainWindow (Akira.Window window) {
        Object (window: window);
    }

    construct {
        main_view_canvas = new Layouts.MainViewCanvas (window);
        layers_sidebar = new Layouts.Sidebars.LayersSidebar (main_view_canvas.canvas);
        options_sidebar = new Layouts.Sidebars.OptionsSidebar (main_view_canvas.canvas);

        pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane2 = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.pack2 (pane2, true, false);
        pane2.pack1 (main_view_canvas, true, true);

        if (!settings.get_boolean ("invert-sidebar")) {
            pane.pack1 (options_sidebar, false, false);
            pane2.pack2 (layers_sidebar, false, false);
        } else {
            pane.pack1 (layers_sidebar, false, false);
            pane2.pack2 (options_sidebar, false, false);
        }

        attach (pane, 0, 0, 1, 1);
    }

    public void focus_canvas () {
        main_view_canvas.canvas.focus_canvas ();
    }

    /*
     * Force the layers panel to show all its newly added children, only after
     * all items have actually been created.
     */
    public void show_added_layers (int added) {
        layers_sidebar.layers_listbox.show_added_layers (added);
    }

    /*
     * Pass the list of nodes ids to be removed from the layers list.
     */
    public void remove_layers (GLib.Array<int> ids) {
        layers_sidebar.layers_listbox.remove_items (ids);
    }

    /*
     * Pass the list of nodes ids to be added to the layers list.
     */
    public void add_layers (GLib.Array<int> ids) {
        layers_sidebar.layers_listbox.add_items (ids);
    }

    public void set_children_locked (int[] nodes, bool is_locked) {
        layers_sidebar.layers_listbox.set_children_locked (nodes, is_locked);
    }

    /*
     * Regenerate the entire layers list. This is used during history navigation.
     */
    public void regenerate_list (bool go_to_layer = false) {
        layers_sidebar.layers_listbox.clear_list ();
        layers_sidebar.layers_listbox.regenerate_list (go_to_layer);
    }

    public void refresh_fills () {
        options_sidebar.fills_panel.fills_listbox.refresh_list ();
    }

    public void refresh_borders () {
        options_sidebar.borders_panel.borders_listbox.refresh_list ();
    }
}
