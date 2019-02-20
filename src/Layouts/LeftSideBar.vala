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

public class Akira.Layouts.LeftSideBar : Gtk.Grid {
	public bool toggled {
		get {
			return visible;
		} set {
			visible = value;
			no_show_all = !value;
		}
	}

	public LeftSideBar () {
		Object (
			orientation: Gtk.Orientation.HORIZONTAL, 
			toggled: true
		);
	}

	construct {
		get_style_context ().add_class ("sidebar-l");
		width_request = 220;
		
		var label = new Gtk.Label ("Sidebar L");
		label.halign = Gtk.Align.CENTER;
		label.expand = true;
		label.margin = 10;
		label.expand = true;

		attach (label, 0, 0, 1, 1);
	}

	public void toggle () {
		toggled = !toggled;
	}
}