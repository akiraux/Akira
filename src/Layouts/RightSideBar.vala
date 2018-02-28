/*
* Copyright (c) 2018 Alecaddd (http://alecaddd.com)
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
public class Akira.Layouts.RightSideBar : Gtk.Grid {
	public weak Akira.Window window { get; construct; }

	public Akira.Layouts.Partials.LayersPanel layers_panel;

	public bool toggled {
		get {
			return visible;
		} set {
			visible = value;
			no_show_all = !value;
		}
	}

	public RightSideBar (Akira.Window main_window) {
		Object (
			orientation: Gtk.Orientation.VERTICAL,
			column_homogeneous: true,
			toggled: true,
			window: main_window
		);
	}

	construct {
		get_style_context ().add_class ("sidebar-r");
		width_request = 220;
		
		var pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
		pane.expand = true;
		pane.wide_handle = false;
		pane.position = 600;

		layers_panel = new Akira.Layouts.Partials.LayersPanel (window);

		pane.pack1 (layers_panel, false, false);
		pane.pack2 (new Gtk.Label ("Bottom"), true, false);

		attach (pane, 0 , 0 , 1, 1);
	}

	public void toggle () {
		toggled = !toggled;
	}
}