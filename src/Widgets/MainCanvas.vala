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
public class Akira.Widgets.MainCanvas : Gtk.Box {
    public Gtk.Paned pane;
    public Gtk.Paned pane2;

    public MainCanvas () {
        Object (orientation: Gtk.Orientation.VERTICAL);
    }

    construct {
        var label = new Gtk.Label ("Main Canvas");
        label.halign = Gtk.Align.CENTER;
        label.expand = true;
        label.margin = 10;

        add (label);
    }
}