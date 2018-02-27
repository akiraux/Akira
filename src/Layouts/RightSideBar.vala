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
	public Gtk.ScrolledWindow scroll;

	public bool toggled {
		get {
			return visible;
		} set {
			visible = value;
			no_show_all = !value;
		}
	}

	public RightSideBar () {
		Object (
			orientation: Gtk.Orientation.VERTICAL,
			column_homogeneous: true,
			toggled: true
		);
	}

	construct {
		get_style_context ().add_class ("sidebar-r");
		width_request = 220;
		
		var pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
		pane.expand = true;
		pane.wide_handle = false;
		pane.position = 600;

		pane.pack1 (build_layers_pane (), false, false);
		pane.pack2 (new Gtk.Label ("Bottom"), true, false);

		attach (pane, 0 , 0 , 1, 1);
	}

	private Gtk.Grid build_layers_pane () {
		var grid = new Gtk.Grid ();

		grid.attach (build_search_bar (), 0, 0, 1, 1);
		grid.attach (build_layers (), 0, 1, 1, 1);

		return grid;
	}

	private Gtk.Grid build_search_bar () {
		var search = new Gtk.SearchEntry ();
		search.hexpand = true;
		search.margin = 5;
		search.placeholder_text = _("Search Layer");
		search.get_style_context ().add_class ("search-input");

		search.activate.connect (() => {
			warning ("search");
		});

		var search_grid = new Gtk.Grid ();
		search_grid.get_style_context ().add_class ("border-bottom");
		search_grid.add (search);

		return search_grid;
	}

	private Gtk.ScrolledWindow build_layers () {
		scroll = new Gtk.ScrolledWindow (null, null);
		scroll.expand = true;

		var artboard = new Granite.Widgets.SourceList.ExpandableItem ("Artboard 1");
		artboard.editable = true;
		artboard.expand_all ();

		var rectangle_item = new Granite.Widgets.SourceList.Item ("Rectangle");
		rectangle_item.editable = true;
		rectangle_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/rectangle.svg");

		var circle_item = new Granite.Widgets.SourceList.Item ("Circle");
		circle_item.editable = true;
		circle_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/circle.svg");

		var triangle_item = new Granite.Widgets.SourceList.Item ("Triangle");
		triangle_item.editable = true;
		triangle_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/triangle.svg");
		
		artboard.add (rectangle_item);
		artboard.add (circle_item);
		artboard.add (triangle_item);

		var artboard2 = new Granite.Widgets.SourceList.ExpandableItem ("Artboard 2");
		artboard2.editable = true;
		artboard2.expand_all ();

		var text_item = new Granite.Widgets.SourceList.Item ("Text");
		text_item.editable = true;
		text_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/text.svg");

		artboard2.add (text_item);

		var group_rectangle_item = new Granite.Widgets.SourceList.Item ("Rectangle");
		group_rectangle_item.editable = true;
		group_rectangle_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/rectangle.svg");

		var group_circle_item = new Granite.Widgets.SourceList.Item ("Circle");
		group_circle_item.editable = true;
		group_circle_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/circle.svg");

		var compound_item = new Granite.Widgets.SourceList.ExpandableItem ("Compound Object");
		compound_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/bool-union.svg");
		compound_item.editable = true;
		compound_item.expand_all ();
		compound_item.add (group_rectangle_item);
		compound_item.add (group_circle_item);

		var group_item = new Granite.Widgets.SourceList.ExpandableItem ("Group");
		group_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/group.svg");
		group_item.editable = true;
		group_item.expand_all ();
		group_item.add (compound_item);

		artboard2.add (group_item);

		var artboard3 = new Granite.Widgets.SourceList.ExpandableItem ("Artboard 3");
		artboard3.editable = true;
		artboard3.expand_all ();

		var vector_item = new Granite.Widgets.SourceList.Item ("Vector Path");
		vector_item.editable = true;
		vector_item.icon = new Gdk.Pixbuf.from_resource ("/com/github/alecaddd/akira/tools/pen.svg");

		artboard3.add (vector_item);

		var source_list = new Granite.Widgets.SourceList ();
		source_list.root.add (artboard);
		source_list.root.add (artboard2);
		source_list.root.add (artboard3);

		scroll.add (source_list);

		return scroll;
	}

	public void toggle () {
		toggled = !toggled;
	}
}