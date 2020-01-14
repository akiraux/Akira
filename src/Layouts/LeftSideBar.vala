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
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.LeftSideBar : Gtk.Grid {
    public weak Akira.Window window { get; construct; }
    public Akira.Layouts.Partials.TransformPanel transform_panel;
    public Akira.Layouts.Partials.FillsPanel fills_panel;
    public Akira.Layouts.Partials.BordersPanel borders_panel;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public LeftSideBar (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL,
            toggled: true
        );
    }

    construct {
        get_style_context ().add_class ("sidebar-l");

        var align_items_panel = new Akira.Layouts.Partials.AlignItemsPanel (window);
        transform_panel = new Akira.Layouts.Partials.TransformPanel (window);
        var border_radius_panel = new Akira.Layouts.Partials.BorderRadiusPanel (window);
        fills_panel = new Akira.Layouts.Partials.FillsPanel (window);
        borders_panel = new Akira.Layouts.Partials.BordersPanel (window);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.expand = true;
        var scrolled_grid = new Gtk.Grid ();
        scrolled_grid.expand = true;
        scrolled_grid.attach (transform_panel, 0, 0, 1, 1);
        scrolled_grid.attach (border_radius_panel, 0, 1, 1, 1);
        scrolled_grid.attach (fills_panel, 0, 2, 1, 1);
        scrolled_grid.attach (borders_panel, 0, 3, 1, 1);
        scrolled_window.add (scrolled_grid);

        attach (align_items_panel, 0, 0, 1, 1);
        attach (scrolled_window, 0, 1, 1, 1);

        show_all ();
    }

    public void toggle () {
        toggled = !toggled;
    }
}
