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
public interface Akira.LayerEntry : Granite.Widgets.SourceList.Item {
}

public class Akira.Layouts.Partials.Layer : Granite.Widgets.SourceList.ExpandableItem, LayerEntry, Granite.Widgets.SourceListSortable, Granite.Widgets.SourceListDragDest {
	public weak Akira.Window window { get; construct; }
	// public Akira.Shape shape { get; construct; }

	enum Type {
		DEFAULT,
		GROUP,
		COMPOUND,
		ARTBOARD,
		MASK
	}

	// const Gtk.TargetEntry[] target_list = {
	// 	{ "INTEGER",    0, Target.INT32 },
	// 	{ "STRING",     0, Target.STRING },
	// 	{ "text/plain", 0, Target.STRING },
	// 	{ "application/x-rootwindow-drop", 0, Target.ROOTWIN }
	// };

	public Layer (Akira.Window main_window, string layer_name, string icon_name) {
		Object (window: main_window);
		name = layer_name;

		if (icon_name.contains ("/")) {
			try {
				icon = new Gdk.Pixbuf.from_resource (icon_name);
			} catch (Error e) {
				warning (e.message);
			}
		} else {
			icon = new GLib.ThemedIcon (icon_name);
		}
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
		// if (a is Akira.Layouts.Partials.Layer && b is Akira.Layouts.Partials.Layer) {
		// 	return (a as Akira.Layouts.Partials.Layer).name.collate ((b as Akira.Layouts.Partials.Layer).name);
		// }
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

	// , Granite.Widgets.SourceListDragSource
	// public bool draggable () {
	// 	return true;
	// }

	// public void prepare_selection_data (Gtk.SelectionData data) {}
}