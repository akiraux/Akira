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
		var search = new Gtk.Entry ();
		search.hexpand = true;
		search.margin = 5;
		search.get_style_context ().add_class ("search-input");
		search.placeholder_text = _("Search layer");

		search.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "system-search-symbolic");
		search.icon_press.connect ((pos, event) => {
			if (pos == Gtk.EntryIconPosition.SECONDARY) {
				warning ("search");
			}
		});

		var search_grid = new Gtk.Grid ();
		search_grid.get_style_context ().add_class ("border-bottom");
		search_grid.add (search);

		return search_grid;
	}

	private Gtk.ScrolledWindow build_layers () {
		scroll = new Gtk.ScrolledWindow (null, null);
		scroll.expand = true;

		var music_item = new Granite.Widgets.SourceList.Item ("Music");
		music_item.editable = true;
		music_item.activatable = new GLib.ThemedIcon ("view-more-symbolic");
		music_item.badge = "1";
		music_item.icon = new GLib.ThemedIcon ("library-music");

		var library_category = new Granite.Widgets.SourceList.ExpandableItem ("Libraries");
		library_category.editable = true;
		library_category.expand_all ();
		library_category.add (music_item);

		var my_store_podcast_item = new Granite.Widgets.SourceList.Item ("Podcasts");
		my_store_podcast_item.icon = new GLib.ThemedIcon ("library-podcast");

		var my_store_music_item = new Granite.Widgets.SourceList.Item ("Music");
		my_store_music_item.icon = new GLib.ThemedIcon ("library-music");

		var my_store_item = new Granite.Widgets.SourceList.ExpandableItem ("My Store");
		my_store_item.icon = new GLib.ThemedIcon ("system-software-install");
		my_store_item.editable = true;
		my_store_item.add (my_store_music_item);
		my_store_item.add (my_store_podcast_item);

		var store_category = new Granite.Widgets.SourceList.ExpandableItem ("Stores");
		store_category.expand_all ();
		store_category.add (my_store_item);

		var player1_item = new Granite.Widgets.SourceList.Item ("Player 1");
		player1_item.icon = new GLib.ThemedIcon ("multimedia-player");

		var player2_item = new Granite.Widgets.SourceList.Item ("Player 2");
		player2_item.badge = "3";
		player2_item.icon = new GLib.ThemedIcon ("phone");

		var device_category = new Granite.Widgets.SourceList.ExpandableItem ("Devices");
		device_category.expand_all ();
		device_category.add (player1_item);
		device_category.add (player2_item);

		var source_list = new Granite.Widgets.SourceList ();
		source_list.root.add (library_category);
		source_list.root.add (store_category);
		source_list.root.add (device_category);

		scroll.add (source_list);

		return scroll;
	}

	public void toggle () {
		toggled = !toggled;
	}
}