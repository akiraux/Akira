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
public interface Akira.ArtboardEntry : Granite.Widgets.SourceList.Item {
}

public class Akira.Layouts.Partials.Artboard : Granite.Widgets.SourceList.ExpandableItem, ArtboardEntry, Granite.Widgets.SourceListSortable, Granite.Widgets.SourceListDragDest {
	public weak Akira.Window window { get; construct; }

	public Artboard (Akira.Window main_window, string layer_name) {
		Object (window: main_window);
		name = layer_name;
	}

	construct {
		selectable = true;
		editable = true;

		edited.connect (rename);
		expand_all ();
	}

	protected void rename (string new_name) {
		warning (new_name);
	}

	public bool allow_dnd_sorting () {
		return true;
	}

	public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
		return 0;
	}

	private bool data_drop_possible (Gdk.DragContext context, Gtk.SelectionData data) {
		// var targets = window.main_window.right_sidebar.layers_panel.layers.root.children;
		// foreach (var target in targets) {
		// 	warning (target.name);
		// 	if (target == this) {
		// 		return true;
		// 	}
		// }
		// return false;
		return true;
	}

	private Gdk.DragAction data_received (Gdk.DragContext context, Gtk.SelectionData data) {
		return Gdk.DragAction.COPY;
	}

	public void delete () {
		this.parent.remove (this);
	}
}