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
public class Akira.Layouts.MainCanvas : Gtk.Grid {
	public Gtk.ScrolledWindow main_scroll;
	public Gtk.DrawingArea canvas;

	public MainCanvas () {
		Object (orientation: Gtk.Orientation.VERTICAL);
	}

	construct {
		main_scroll = new Gtk.ScrolledWindow (null, null);
		main_scroll.expand = true;

		canvas = new Gtk.DrawingArea ();
		canvas.set_size_request(10000, 10000);
		main_scroll.add_with_viewport (canvas);

		canvas.draw.connect ((context) => {
			weak Gtk.StyleContext style_context = canvas.get_style_context ();
			int height = 100;
			int width = 100;
			Gdk.RGBA color = style_context.get_color (0);

			double xc = main_scroll.get_allocated_width () / 2;
			double yc = main_scroll.get_allocated_height () / 2;
			double radius = int.min (width, height) / 2.0;
			double angle1 = 0;
			double angle2 = 2*Math.PI;

			context.arc (xc, yc, radius, angle1, angle2);
			Gdk.cairo_set_source_rgba (context, color);
			context.fill ();
			return true;
		});

		attach (main_scroll, 0, 0, 1, 1);
	}
}