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

public class Akira.Layouts.Partials.Layer : Gtk.ListBoxRow {
	public weak Akira.Window window { get; construct; }
	public string layer_name { get; construct; }
	public string icon_name { get; construct; }

	public Gtk.Image icon;
	public Gtk.Image icon_locked;
	public Gtk.Image icon_hidden;
	public Gtk.Label label;
	public Gtk.Entry entry;
	public Gtk.EventBox handle;

	private bool _locked { get; set; default = false; }
	public bool locked {
		get { return _locked; } set { _locked = value; }
	}

	private bool _hidden { get; set; default = false; }
	public bool hidden {
		get { return _hidden; } set { _locked = value; }
	}

	// public Akira.Shape shape { get; construct; }

	public Layer (Akira.Window main_window, string name, string icon) {
		Object (
			window: main_window,
			layer_name: name,
			icon_name: icon
		);
	}

	construct {
		get_style_context ().add_class ("layer");

		label =  new Gtk.Label (layer_name);
		label.halign = Gtk.Align.FILL;
		label.xalign = 0;
		label.hexpand = true;
		label.set_ellipsize (Pango.EllipsizeMode.END);

		entry = new Gtk.Entry ();
		entry.expand = true;
		entry.get_style_context ().remove_class ("entry");
		entry.visible = false;
		entry.no_show_all = true;
		entry.set_text (layer_name);

		entry.activate.connect (update_on_enter);
		entry.focus_out_event.connect (update_on_leave);
		entry.key_release_event.connect (update_on_escape);

		if (icon_name.contains ("/")) {
			icon = new Gtk.Image.from_resource (icon_name);
		} else {
			icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
		}

		icon_locked = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.MENU);
		icon_hidden = new Gtk.Image.from_resource ("/com/github/alecaddd/akira/tools/eye.svg");

		var label_grid = new Gtk.Grid ();
		label_grid.margin = 6;
		label_grid.expand = true;
		label_grid.attach (icon, 0, 0, 1, 1);
		label_grid.attach (label, 1, 0, 1, 1);
		label_grid.attach (entry, 2, 0, 1, 1);
		label_grid.attach (icon_locked, 3, 0, 1, 1);
		label_grid.attach (icon_hidden, 4, 0, 1, 1);

		handle = new Gtk.EventBox ();
		handle.hexpand = true;
		handle.add (label_grid);

		add (handle);

		handle.enter_notify_event.connect ((event) => {
			set_state_flags (Gtk.StateFlags.PRELIGHT, true);
			return false;
		});

		handle.leave_notify_event.connect ((event) => {
			set_state_flags (Gtk.StateFlags.NORMAL, true);
			return false;
		});

		handle.event.connect (on_click_event);
	}

	public bool on_click_event (Gdk.Event event) {
		if (event.type == Gdk.EventType.@BUTTON_PRESS) {
			activate ();
		}

		if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
			entry.visible = true;
			entry.no_show_all = false;
			entry.select_region (0, -1);
			label.visible = false;
			label.no_show_all = true;
		}

		return false;
	}

	public void update_on_enter () {
		update_label ();
	}

	public bool update_on_leave () {
		update_label ();
		return false;
	}

	public bool update_on_escape (Gdk.EventKey key) {
		if (key.keyval == 65307) {
			update_label ();
		}
		return false;
	}

	private void update_label () {
		var new_label = entry.get_text ();
		label.label = new_label;

		entry.visible = false;
		entry.no_show_all = true;
		label.visible = true;
		label.no_show_all = false;
	}
}