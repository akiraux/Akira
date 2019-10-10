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
public class Akira.Layouts.MainCanvas : Gtk.Grid {
    public Gtk.ScrolledWindow main_scroll;
    public Akira.Lib.Canvas canvas;
    public Gtk.Allocation main_window_size;
    public weak Akira.Window window { get; construct; }

    public MainCanvas (Akira.Window window) {
        Object (window: window, orientation: Gtk.Orientation.VERTICAL);
    }

    construct {
        get_allocation (out main_window_size);
        main_scroll = new Gtk.ScrolledWindow (null, null);
        main_scroll.expand = true;

        canvas = new Akira.Lib.Canvas (window);
        canvas.set_size_request (main_window_size.width, main_window_size.height);
        var wcenter = (100000 - main_window_size.width) / 2;
        var hcenter = (100000 - main_window_size.height) / 2;
        canvas.set_bounds (0, 0, 100000, 100000);
        canvas.set_scale (1.0);

        main_scroll.add (canvas);

        attach (main_scroll, 0, 0, 1, 1);
    }
}
