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

public class Akira.Layouts.Partials.PagesPanel : Gtk.ListBox {
	public weak Akira.Window window { get; construct; }

	// private bool scroll_up = false;
	// private bool scrolling = false;
	// private bool should_scroll = false;
	// public Gtk.Adjustment vadjustment;

	// private const int SCROLL_STEP_SIZE = 5;
	// private const int SCROLL_DISTANCE = 30;
	// private const int SCROLL_DELAY = 50;

	private const Gtk.TargetEntry targetEntries[] = {
		{ "PAGES", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public PagesPanel (Akira.Window main_window) {
		Object (
			window: main_window,
			activate_on_single_click: false,
			selection_mode: Gtk.SelectionMode.SINGLE
		);
	}

	construct {
		expand = true;
	}
}