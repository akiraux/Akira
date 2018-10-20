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
	public Gtk.Allocation main_window_size;

	public MainCanvas () {
		Object (orientation: Gtk.Orientation.VERTICAL);
	}

	construct {
		get_allocation (out main_window_size);
		main_scroll = new Gtk.ScrolledWindow (null, null);
		main_scroll.expand = true;

		var canvas = new Goo.Canvas ();
        canvas.set_size_request (main_window_size.width, main_window_size.height);
        canvas.set_bounds (0, 0, 10000, 10000);

        var root = canvas.get_root_item ();
		var text = Goo.CanvasText.create (root, "Add text here", 20, 20, 200, Goo.CanvasAnchorType.NW, "font", "Open Sans 18");

        var rect_item = Goo.CanvasRect.create (root, 100, 100, 400, 400,
                                   "line-width", 5.0,
                                   "radius-x", 100.0,
                                   "radius-y", 100.0,
                                   "stroke-color", "yellow",
                                   "fill-color", "#a8eb12"
								   );
								   
		main_scroll.add (canvas);

		attach (main_scroll, 0, 0, 1, 1);
	}
}