/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Layouts.MainCanvas : Gtk.Grid {
	public Gtk.ScrolledWindow main_scroll;
	public Akira.Lib.Canvas canvas;
	public Gtk.Allocation main_window_size;

	public MainCanvas () {
		Object (orientation: Gtk.Orientation.VERTICAL);
	}

	construct {
		get_allocation (out main_window_size);
		main_scroll = new Gtk.ScrolledWindow (null, null);
		main_scroll.expand = true;

		canvas = new Akira.Lib.Canvas ();
		canvas.set_size_request (main_window_size.width, main_window_size.height);
		canvas.set_bounds (0, 0, 10000, 10000);
		canvas.set_scale (1.0);

		main_scroll.add (canvas);

		attach (main_scroll, 0, 0, 1, 1);
	}

	public Goo.CanvasRect add_rect () {
		var root = canvas.get_root_item ();
		var rect = new Goo.CanvasRect (null, 100.0, 100.0, 400.0, 400.0,
									"line-width", 5.0,
									"radius-x", 100.0,
									"radius-y", 100.0,
									"stroke-color", "#f37329",
									"fill-color", "#ffa154", null);
		rect.set ("parent", root);
		return  rect;
	}

	public Goo.CanvasEllipse add_ellipse () {
		var root = canvas.get_root_item ();
		var ellipse = new Goo.CanvasEllipse (null, 0, 0, 64, 64,
			"line-width", 5.0,
			"stroke-color", "#9bdb4d",
			"fill-color", "#68b723");

		ellipse.set ("parent", root);
		return ellipse;
	}

	public Goo.CanvasText add_text () {
		var root = canvas.get_root_item ();
		var text = new Goo.CanvasText (null, "Add text here", 20, 20, 200, Goo.CanvasAnchorType.NW, "font", "Open Sans 18");
		text.set ("parent", root);
		return text;
	}
}
