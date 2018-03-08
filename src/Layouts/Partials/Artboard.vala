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

public class Akira.Layouts.Partials.Artboard : Gtk.ListBoxRow {
	public weak Akira.Window window { get; construct; }

	private const Gtk.TargetEntry targetEntries[] = {
		{ "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public Gtk.Expander expander;
	public string layer_name { get; construct; }

	public Artboard (Akira.Window main_window, string name) {
		Object (
			window: main_window, 
			layer_name: name
		);
	}

	construct {
		var label_name =  new Gtk.Label (layer_name);
		label_name.get_style_context ().add_class ("artboard-name");
		label_name.halign = Gtk.Align.FILL;
		label_name.xalign = 0;
		label_name.hexpand = true;

		expander = new Gtk.Expander (layer_name);
		expander.label_fill = true;
		expander.label_widget = label_name;
		expander.expanded = false;

		add (expander);

		get_style_context ().add_class ("artboard");

		build_darg_and_drop ();
	}

	private void build_darg_and_drop () {
		Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);

		drag_begin.connect (on_drag_begin);
		drag_data_get.connect (on_drag_data_get);

		Gtk.drag_dest_set (this.expander, Gtk.DestDefaults.MOTION, targetEntries, Gdk.DragAction.MOVE);
		this.expander.drag_motion.connect (on_drag_motion);
		this.expander.drag_leave.connect (on_drag_leave);
	}

	private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
		var row = (widget as Akira.Layouts.Partials.Artboard);
		Gtk.Allocation alloc;
		row.get_allocation (out alloc);

		var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
		var cr = new Cairo.Context (surface);
		cr.set_source_rgba (0, 0, 0, 0.3);
		cr.set_line_width (1);

		cr.move_to (0, 0);
		cr.line_to (alloc.width, 0);
		cr.line_to (alloc.width, alloc.height);
		cr.line_to (0, alloc.height);
		cr.line_to (0, 0);
		cr.stroke ();

		cr.set_source_rgba (255, 255, 255, 0.5);
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.fill ();

		row.get_style_context ().add_class ("drag-icon");
		row.draw (cr);
		row.get_style_context ().remove_class ("drag-icon");

		Gtk.drag_set_icon_surface (context, surface);
	}

	private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
		uchar[] data = new uchar[(sizeof (Akira.Layouts.Partials.Artboard))];
		((Gtk.Widget[])data)[0] = widget;

		selection_data.set (
			Gdk.Atom.intern_static_string ("ARTBOARD"), 32, data
		);
	}
	
	public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
		get_style_context ().add_class ("hover");
		return true;
	}

	public void on_drag_leave (Gdk.DragContext context, uint time) {
		get_style_context ().remove_class ("hover");
	}
}