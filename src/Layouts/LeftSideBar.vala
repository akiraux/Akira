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
	public weak Akira.Window window { get; construct; }

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
		width_request = 220;

		var align_items_panel = new Akira.Layouts.Partials.AlignItemsPanel (window);
		var fill_box_panel = new Akira.Layouts.Partials.FillsBoxPanel (window);
		var transorm_panel = new Akira.Layouts.Partials.TransformPanel ();

		attach (align_items_panel, 0, 0, 1, 1);
		attach (transorm_panel, 0, 1, 1, 1);
		attach (fill_box_panel, 0, 2, 1, 1);

		show_all ();
	}

	public void toggle () {
		toggled = !toggled;
	}
}
