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
		layers_scroll = new Gtk.ScrolledWindow (null, null);
		layers_scroll.expand = true;
		layers_scroll.add (layers_panel);

		var top_panel = new Gtk.Grid ();
		top_panel.attach (build_search_bar (), 0, 0, 1, 1);
		top_panel.attach (layers_scroll, 0, 1, 1, 1);

		pane.pack1 (top_panel, false, false);

		pages_panel = new Akira.Layouts.Partials.PagesPanel (window);
		pages_scroll = new Gtk.ScrolledWindow (null, null);
		pages_scroll.expand = true;
		pages_scroll.add (pages_panel);

		var bottom_panel = new Gtk.Grid ();
		bottom_panel.attach (build_pages_title (), 0, 0, 1, 1);
		bottom_panel.attach (pages_scroll, 0, 1, 1, 1);

		pane.pack2 (bottom_panel, true, false);

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

	private Gtk.Grid build_pages_title () {
		var label = new Gtk.Label (_("Pages"));
		label.halign = Gtk.Align.START;
		label.hexpand = true;
		label.margin = 5;

		var button = new Gtk.Button ();
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.tooltip_text = _("Add Page");
		button.can_focus = false;
		button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));

		var pages_grid = new Gtk.Grid ();
		pages_grid.get_style_context ().add_class ("pages-title");
		pages_grid.attach (label, 0, 0, 1, 1);
		pages_grid.attach (button, 1, 0, 1, 1);

		return pages_grid;
	}

	public void toggle () {
		toggled = !toggled;
	}
}