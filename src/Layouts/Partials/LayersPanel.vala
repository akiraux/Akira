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
public class Akira.Layouts.Partials.LayersPanel : Gtk.Grid {
	public weak Akira.Window window { get; construct; }

	// public Granite.Widgets.SourceList layers;
	public Akira.Layouts.Partials.LayersList layers_list;

	public LayersPanel (Akira.Window main_window) {
		Object (window: main_window);
	}

	construct {
		layers_list = new Akira.Layouts.Partials.LayersList (window);

		attach (build_search_bar (), 0, 0, 1, 1);
		attach (layers_list, 0, 1, 1, 1);
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

	// private Granite.Widgets.SourceList build_layers () {
	// 	layers = new Granite.Widgets.SourceList ();
	// 	layers.get_style_context ().add_class ("layers-panel");

	// 	Gtk.TargetEntry uri_list_entry = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
	// 	layers.enable_drag_dest ({ uri_list_entry }, Gdk.DragAction.COPY);

	// 	layers.events |= Gdk.EventMask.KEY_RELEASE_MASK;
	// 	layers.key_release_event.connect ((key) => {
	// 		if (key.keyval == Gdk.Key.Delete && (layers.selected is Akira.Layouts.Partials.Layer)) {
	// 			(layers.selected as Akira.Layouts.Partials.Layer).delete ();
	// 		}
	// 		return true;
	// 	});

	// 	var artboard = new Akira.Layouts.Partials.Artboard (window, "Artboard 1");

	// 	var rectangle_item = new Akira.Layouts.Partials.Layer (window, "Rectangle", "/com/github/alecaddd/akira/tools/rectangle.svg");
	// 	var circle_item = new Akira.Layouts.Partials.Layer (window, "Circle", "/com/github/alecaddd/akira/tools/circle.svg");
	// 	var triangle_item = new Akira.Layouts.Partials.Layer (window, "Triangle", "/com/github/alecaddd/akira/tools/triangle.svg");
		
	// 	artboard.add (rectangle_item);
	// 	artboard.add (circle_item);
	// 	artboard.add (triangle_item);

	// 	var artboard2 = new Akira.Layouts.Partials.Artboard (window, "Artboard 2");

	// 	var text_item = new Akira.Layouts.Partials.Layer (window, "Text", "/com/github/alecaddd/akira/tools/text.svg");

	// 	artboard2.add (text_item);

	// 	var group_rectangle_item = new Akira.Layouts.Partials.Layer (window, "Rectangle", "/com/github/alecaddd/akira/tools/rectangle.svg");
	// 	var group_circle_item = new Akira.Layouts.Partials.Layer (window, "Circle", "/com/github/alecaddd/akira/tools/circle.svg");

	// 	var compound_item = new Akira.Layouts.Partials.Layer (window, "Compound Object", "/com/github/alecaddd/akira/tools/bool-union.svg");
	// 	compound_item.add (group_rectangle_item);
	// 	compound_item.add (group_circle_item);

	// 	var group_item = new Akira.Layouts.Partials.Layer (window, "Group", "folder-symbolic");
	// 	group_item.add (compound_item);

	// 	artboard2.add (group_item);

	// 	var artboard3 = new Akira.Layouts.Partials.Artboard (window, "Artboard 3");

	// 	var vector_item = new Akira.Layouts.Partials.Layer (window, "Vector Path", "/com/github/alecaddd/akira/tools/pen.svg");

	// 	artboard3.add (vector_item);

	// 	var layers_root = new Akira.Layouts.Partials.Artboard (window, "Layers");
	// 	layers_root.expand_all ();

	// 	layers.root.add (layers_root);

	// 	layers_root.add (artboard);
	// 	layers_root.add (artboard2);
	// 	layers_root.add (artboard3);

	// 	return layers;
	// }
}