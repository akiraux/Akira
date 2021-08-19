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

    // To be removed.
    public Layouts.MainCanvas main_canvas;
    public Layouts.MainViewCanvas main_view_canvas;
    public Layouts.LeftSideBar left_sidebar;
    // public Layouts.RightSideBar right_sidebar;
    // end.

    private Layouts.Sidebars.LayersSidebar layers_sidebar;

    public Gtk.Paned pane;
    public Gtk.Paned pane2;

    public MainWindow (Akira.Window window) {
        Object (window: window);
    }

    construct {
        main_view_canvas = new Layouts.MainViewCanvas (window);
        layers_sidebar = new Layouts.Sidebars.LayersSidebar (main_view_canvas.canvas);

        pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane2 = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        pane.pack2 (pane2, true, false);
        pane2.pack1 (main_view_canvas, true, true);

        if (!settings.get_boolean ("invert-sidebar")) {
            // pane.pack1 (left_sidebar, false, false);
            pane2.pack2 (layers_sidebar, false, false);
        } else {
            pane.pack1 (layers_sidebar, false, false);
            // pane2.pack2 (left_sidebar, false, false);
        }

        attach (pane, 0, 0, 1, 1);

        // left_sidebar = new Akira.Layouts.LeftSideBar (window);
        // right_sidebar = new Akira.Layouts.RightSideBar (window);
        // main_canvas = new Akira.Layouts.MainCanvas (window);

        // pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        // pane2 = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        // pane.pack2 (pane2, true, false);
        // pane2.pack1 (main_canvas, true, true);

        // if (!settings.get_boolean ("invert-sidebar")) {
        //     pane.pack1 (left_sidebar, false, false);
        //     pane2.pack2 (right_sidebar, false, false);
        // } else {
        //     pane.pack1 (right_sidebar, false, false);
        //     pane2.pack2 (left_sidebar, false, false);
        // }

        // attach (pane, 0, 0, 1, 1);
    }

    public void focus_canvas () {
        main_view_canvas.canvas.focus_canvas ();
    }

    /*
     * Force the layers panel to show all its newly added children, only after
     * all items have actually been created.
     */
    public void show_added_layers () {
        layers_sidebar.layers_panel.refresh_lists ();
    }

    public void remove_layers (GLib.Array<int> ids) {
        layers_sidebar.layers_panel.delete_selected_layers (ids);
    }
}
