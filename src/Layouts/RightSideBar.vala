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

public class Akira.Layouts.RightSideBar : Gtk.Grid {
	public weak Akira.Window window { get; construct; }

	public Gtk.Overlay layers_overlay;
	public Gtk.Grid indicator;
	public Akira.Layouts.Partials.LayersPanel layers_panel;
	public Akira.Layouts.Partials.PagesPanel pages_panel;
	public Gtk.ScrolledWindow layers_scroll;
	public Gtk.ScrolledWindow pages_scroll;

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
		var layers_grid = new Gtk.Grid ();
		layers_grid.vexpand = true;
		layers_grid.add (layers_panel);

		layers_scroll = new Gtk.ScrolledWindow (null, null);
		layers_scroll.expand = true;
		layers_scroll.add (layers_grid);

		var scrolled_child = layers_scroll.get_child ();
		if (scrolled_child is Gtk.Container) {
			((Gtk.Container) scrolled_child).set_focus_vadjustment (new Gtk.Adjustment (0, 0, 0, 0, 0, 0));
		}

		layers_overlay = new Gtk.Overlay ();
		layers_overlay.add (layers_scroll);

		indicator = new Gtk.Grid ();
		indicator.expand = false;
		indicator.valign = Gtk.Align.START;
		indicator.width_request = get_allocated_width ();
		indicator.margin_start = 20;
		indicator.margin_end = 5;
		indicator.height_request = 1;

		var circle = new Gtk.Grid ();
		circle.get_style_context ().add_class ("indicator-circle");
		circle.width_request = 6;
		circle.height_request = 6;
		circle.valign = Gtk.Align.CENTER;
		var line = new Gtk.Grid ();
		line.get_style_context ().add_class ("indicator");
		line.expand = true;
		line.height_request = 2;
		line.valign = Gtk.Align.CENTER;

		indicator.attach (circle, 0, 0, 1, 1);
		indicator.attach (line, 1, 0, 1, 1);
		layers_overlay.add_overlay (indicator);
		layers_overlay.set_overlay_pass_through (indicator, true);

		indicator.visible = false;
		indicator.no_show_all = true;

		var top_panel = new Gtk.Grid ();
		top_panel.attach (build_search_bar (), 0, 0, 1, 1);
		top_panel.attach (layers_overlay, 0, 1, 1, 1);

		pane.pack1 (top_panel, false, false);

		pages_panel = new Akira.Layouts.Partials.PagesPanel (window);
		pages_scroll = new Gtk.ScrolledWindow (null, null);
		pages_scroll.expand = true;
		pages_scroll.add (pages_panel);

		attach (pane, 0 , 0 , 1, 1);
	}

	private Gtk.Grid build_search_bar () {
		var search = new Gtk.SearchEntry ();
		search.hexpand = true;
		search.margin = 5;
		search.placeholder_text = _("Search Layer");

		search.activate.connect (() => {
			warning ("search");
		});

		var search_grid = new Gtk.Grid ();
		search_grid.get_style_context ().add_class ("border-bottom");
		search_grid.add (search);

		return search_grid;
	}

	public void toggle () {
		toggled = !toggled;
	}
}