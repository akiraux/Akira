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
    public weak Akira.Window window { get; construct; }

    public MainCanvas (Akira.Window window) {
        Object (window: window, orientation: Gtk.Orientation.VERTICAL);
    }

    construct {
        main_scroll = new Gtk.ScrolledWindow (null, null);
        main_scroll.expand = true;

        canvas = new Akira.Lib.Canvas (window);
        canvas.set_bounds (0, 0, 100000, 100000);
        canvas.set_scale (1.0);

        main_scroll.add (canvas);
        attach (main_scroll, 0, 0, 1, 1);

        canvas.update_bounds ();

        // Detect mouse scroll and change adjustment
        canvas.scroll_event.connect (on_scroll);
    }

    public bool on_scroll (Gdk.EventScroll event) {
        switch (event.direction) {
            case Gdk.ScrollDirection.UP:
                // Zoom in
                if (event.state == Gdk.ModifierType.CONTROL_MASK) {
                    window.headerbar.zoom.zoom_in ();
                } else if (event.state == Gdk.ModifierType.SHIFT_MASK) {
                    main_scroll.hadjustment.value += 10;
                } else {
                    main_scroll.vadjustment.value -= 10;
                }
                break;
            case Gdk.ScrollDirection.DOWN:
                // Zoom out
                if (event.state == Gdk.ModifierType.CONTROL_MASK) {
                    window.headerbar.zoom.zoom_out ();
                } else if (event.state == Gdk.ModifierType.SHIFT_MASK) {
                    main_scroll.hadjustment.value -= 10;
                } else {
                    main_scroll.vadjustment.value += 10;
                }
                break;
        }
        return true;
    }
}
