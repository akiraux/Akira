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

public class Akira.Layouts.Partials.Artboard : Gtk.Expander {
	public weak Akira.Window window { get; construct; }

	const int BYTE_BITS = 8;
	const int WORD_BITS = 16;
	const int DWORD_BITS = 32;

	enum Target {
		INT32,
		STRING,
		ROOTWIN
	}

	/* datatype (string), restrictions on DnD (Gtk.TargetFlags), datatype (int) */
	const Gtk.TargetEntry[] target_list = {
		{ "INTEGER",    0, Target.INT32 },
		{ "STRING",     0, Target.STRING },
		{ "text/plain", 0, Target.STRING },
		{ "application/x-rootwindow-drop", 0, Target.ROOTWIN }
	};

	public Artboard (Akira.Window main_window, string name) {
		Object (window: main_window);
		
		var label_name =  new Gtk.Label (name);
		label_name.get_style_context ().add_class ("artboard-name");
		label_name.halign = Gtk.Align.START;
		label_name.hexpand = true;

		label_widget = label_name;
	}

	construct {
		expanded = false;
		hexpand = true;
		label_fill = true;

		get_style_context ().add_class ("artboard");

		build_darg_and_drop ();
	}

	private void build_darg_and_drop () {
		Gtk.drag_source_set (
				this,                      // widget will be drag-able
				Gdk.ModifierType.BUTTON1_MASK, // modifier that will start a drag
				target_list,               // lists of target to support
				Gdk.DragAction.MOVE            // what to do with data after dropped
			);

		// All possible source signals
		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_data_delete.connect(on_drag_data_delete);
		drag_end.connect(on_drag_end);
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

		row.get_style_context().add_class("drag-icon");
		row.draw(cr);
		row.get_style_context().remove_class("drag-icon");

		int x, y;
		widget.translate_coordinates (row, 0, 0, out x, out y);
		surface.set_device_offset (-x, -y);

		Gtk.drag_set_icon_surface (context, surface);
	}

	private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
								   Gtk.SelectionData selection_data,
								   uint target_type, uint time) {
		string string_data = "This is data from the source.";
		long integer_data = 42;

		print ("%s: on_drag_data_get\n", widget.name);

		print (" Sending ");
		switch (target_type) {
			// case Target.SOME_OBJECT:
			// Serialize the object and send as a string of bytes.
			// Pixbufs, (UTF-8) text, and URIs have their own convenience
			// setter functions
		case Target.INT32:
			print ("integer: %ld", integer_data);
			uchar [] buf;
			convert_long_to_bytes(integer_data, out buf);
			selection_data.set (
					selection_data.get_target(),      // target type
					BYTE_BITS,                 // number of bits per 'unit'
					buf // pointer to data to be sent
				);
			break;
		case Target.STRING:
			print ("string: %s", string_data);
			selection_data.set (
					selection_data.get_target(),
					BYTE_BITS,
					(uchar [])string_data.to_utf8()
				);
			break;
		case Target.ROOTWIN:
			print ("Dropped on the root window!\n");
			break;
		default:
			// Default to some a safe target instead of fail.
			assert_not_reached ();
		}

		print (".\n");
	}

	private void on_drag_data_delete (Gtk.Widget widget, Gdk.DragContext context) {}

	private void on_drag_end (Gtk.Widget widget, Gdk.DragContext context) {}

	private void convert_long_to_bytes(long number, out uchar [] buffer) {
		buffer = new uchar[sizeof(long)];
		for (int i=0; i<sizeof(long); i++) {
			buffer[i] = (uchar) (number & 0xFF);
			number = number >> 8;
		}
	}

}