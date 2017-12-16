/*
* Copyright (c) 2011-2017 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.MainWindow : Gtk.Box {
    public Gtk.Box box;
    public Gtk.Paned pane;
    public Gtk.Paned pane2;

    public MainWindow () {
        Object (orientation: Gtk.Orientation.VERTICAL);
    }

    construct {
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane2 = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.set_position (220);
        pane2.set_position (2000);
        box.pack_start (pane2, true, true, 0);

        pane.pack1 (left_sidebar, true, false);
        pane.pack2 (box, true, false);

        pane2.pack1 (main_canvas, true, false);
        pane2.pack2 (right_sidebar, true, false);

        pack_start (pane, true, true, 0);
        pack_end (statusbar, false, false, 0);
    }
}