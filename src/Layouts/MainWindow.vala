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

public class Akira.Layouts.MainWindow : Gtk.Grid {
	public weak Akira.Window window { get; construct; }

	public Akira.Layouts.MainCanvas main_canvas;
	public Akira.Layouts.LeftSideBar left_sidebar;
	public Akira.Layouts.RightSideBar right_sidebar;
	public Akira.Layouts.StatusBar statusbar;

	public Gtk.Grid grid;
	public Gtk.Paned pane;
	public Gtk.Paned pane2;

	public MainWindow (Akira.Window main_window) {
		Object (window: main_window);
	}

	construct {
		left_sidebar = new Akira.Layouts.LeftSideBar ();
		right_sidebar = new Akira.Layouts.RightSideBar (window);
		statusbar = new Akira.Layouts.StatusBar ();
		main_canvas = new Akira.Layouts.MainCanvas ();

		grid = new Gtk.Grid ();
		pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		pane2 = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		pane.position = settings.left_paned;
		pane2.position = settings.right_paned;
		grid.attach (pane2, 0, 0, 1, 1);

		pane.pack1 (left_sidebar, false, false);
		pane.pack2 (grid, true, false);

		pane2.pack1 (main_canvas, true, false);
		pane2.pack2 (right_sidebar, false, false);

		attach (pane, 0, 0, 1, 1);
		attach (statusbar, 0, 1, 1, 1);
	}
}