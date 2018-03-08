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

public class Akira.Layouts.Partials.Layer : Gtk.ListBoxRow {
	public weak Akira.Window window { get; construct; }
	public string layer_name { get; construct; }
	public string icon_name { get; construct; }

	public Gtk.Image icon;

	// public Akira.Shape shape { get; construct; }

	public Layer (Akira.Window main_window, string name, string icon) {
		Object (
			window: main_window,
			layer_name: name,
			icon_name: icon
		);
	}

	construct {
		get_style_context ().add_class ("layer");

		var name = new Gtk.Label (layer_name);

		if (icon_name.contains ("/")) {
			icon = new Gtk.Image.from_resource (icon_name);
		} else {
			icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
		}

		var grid = new Gtk.Grid ();
		grid.hexpand = true;
		grid.attach (icon, 0, 0, 1, 1);
		grid.attach (name, 1, 0, 1, 1);

		add (grid);
	}
}