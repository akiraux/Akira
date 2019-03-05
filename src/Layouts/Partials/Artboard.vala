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

public class Akira.Layouts.Partials.Artboard : Gtk.ListBoxRow {
	public weak Akira.Window window { get; construct; }

	private const Gtk.TargetEntry targetEntries[] = {
		{ "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
	};

	private const Gtk.TargetEntry targetEntriesLayer[] = {
		{ "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public string layer_name { get; construct; }
	public Gtk.Label label;
	public Gtk.Entry entry;
	public Gtk.EventBox handle;
	public Gtk.ToggleButton button;
	public Gtk.Image button_icon;
	public Gtk.Revealer revealer;
	public Gtk.ListBox container;
	public int layers_count { get; set; default = 0; }

	private bool _editing { get; set; default = false; }
	public bool editing {
		get { return _editing; } set { _editing = value; }
	}

	public Artboard (Akira.Window main_window, string name) {
		Object (
			window: main_window, 
			layer_name: name
		);
	}

	construct {
		get_style_context ().add_class ("artboard");

		label =  new Gtk.Label (layer_name);
		label.get_style_context ().add_class ("artboard-name");
		label.halign = Gtk.Align.FILL;
		label.xalign = 0;
		label.hexpand = true;
		label.set_ellipsize (Pango.EllipsizeMode.END);

		entry = new Gtk.Entry ();
		entry.expand = true;
		entry.visible = false;
		entry.no_show_all = true;
		entry.set_text (layer_name);

		entry.activate.connect (update_on_enter);
		entry.focus_out_event.connect (update_on_leave);
		entry.key_release_event.connect (update_on_escape);

		var label_grid = new Gtk.Grid ();
		label_grid.expand = true;
		label_grid.attach (label, 0, 0, 1, 1);
		label_grid.attach (entry, 1, 0, 1, 1);

		revealer = new Gtk.Revealer ();
		revealer.hexpand = true;
		revealer.reveal_child = true;

		container = new Gtk.ListBox ();
		container.get_style_context ().add_class ("artboard-container");
		container.activate_on_single_click = true;
		container.selection_mode = Gtk.SelectionMode.SINGLE;
		Gtk.drag_dest_set (container, Gtk.DestDefaults.ALL, targetEntriesLayer, Gdk.DragAction.MOVE);
		container.drag_data_received.connect (on_drag_data_received);
		revealer.add (container);

		handle = new Gtk.EventBox ();
		handle.hexpand = true;
		handle.add (label_grid);
		handle.event.connect (on_click_event);

		button = new Gtk.ToggleButton ();
		button.active = true;
		button.get_style_context ().remove_class ("button");
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.get_style_context ().add_class ("revealer-button");
		button_icon = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
		button.add (button_icon);

		var grid = new Gtk.Grid ();
		grid.attach (handle, 0, 0, 1, 1);
		grid.attach (button, 1, 0, 1, 1);
		grid.attach (revealer, 0, 1, 2, 1);

		add (grid);

		get_style_context ().add_class ("artboard");

		build_drag_and_drop ();

		button.toggled.connect (() => {
			revealer.reveal_child = ! revealer.get_reveal_child ();

			if (revealer.get_reveal_child ()) {
				button.get_style_context ().remove_class ("closed");
			} else {
				button.get_style_context ().add_class ("closed");
			}
		});

		key_press_event.connect (on_key_pressed);
	}

	private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
		window.main_window.right_sidebar.indicator.visible = false;

		Akira.Layouts.Partials.Layer target;
		Gtk.Widget row;
		Akira.Layouts.Partials.Layer source;
		int newPos;
		var before_group = false;

		target = (Akira.Layouts.Partials.Layer) container.get_row_at_y (y);
		row = ((Gtk.Widget[]) selection_data.get_data ())[0];
		source = (Akira.Layouts.Partials.Layer) row.get_ancestor (typeof (Akira.Layouts.Partials.Layer));
		int index = target.get_index ();
		Gtk.Allocation alloc;

		if (target == null) {
			newPos = -1;
		} else if (target.grouped && source.layer_group == null) {
			source.get_allocation (out alloc);
			y = y - (index * alloc.height);

			var group = (Akira.Layouts.Partials.Layer) target.container.get_row_at_y (y);

			if (group is Akira.Layouts.Partials.Layer) {
				newPos = group.get_index ();
			} else {
				newPos = -1;
			}

			if ((y + alloc.height) < (alloc.height / 2)) {
				newPos = target.get_index () > 1 && source.get_index () > newPos ? target.get_index () - 1 : target.get_index ();
				debug ("Layer dropped ABOVE group: %i", newPos);
				before_group = true;
			} else {
				before_group = false;
				debug ("Layer dropped INSIDE a group from OUTSIDE: %i", newPos);

				if (y > ((newPos * alloc.height) - (alloc.height / 2)) && newPos > 1) {
					debug ("drop below");
					newPos++;
				}
			}
		} else if (target.grouped && source.layer_group != null) {
			source.get_allocation (out alloc);
			y = y - (index * alloc.height);

			var group = (Akira.Layouts.Partials.Layer) target.container.get_row_at_y (y);
			
			if (group is Akira.Layouts.Partials.Layer) {
				newPos = group.get_index ();
			} else {
				newPos = -1;
			}

			if ((y + alloc.height) < (alloc.height / 2)) {
				newPos = target.get_index () > 1 && source.get_index () > newPos ? target.get_index () - 1 : target.get_index ();
				debug ("Layer dropped ABOVE group: %i", newPos);
				before_group = true;
			} else {
				before_group = false;
				debug ("%i", y);
				debug ("%i", newPos);
				debug ("%i", (newPos * alloc.height) - (alloc.height / 2));

				if (y > ((newPos * alloc.height) - (alloc.height / 2)) && source.get_index () > newPos) {
					debug ("dropped below");
					newPos++;
				} else if (y <= ((newPos * alloc.height) - (alloc.height / 2)) && source.get_index () < newPos) {
					debug ("dropped above");
					newPos--;
				}
				debug ("Layer dropped WHITIN group: %i", newPos);
			}
		} else if (!target.grouped && source.layer_group != null) {
			var parent = (Akira.Layouts.Partials.Artboard) target.get_ancestor (typeof (Akira.Layouts.Partials.Artboard));
			var group = parent.container.get_row_at_y (y);
			group.get_allocation (out alloc);

			if (group is Akira.Layouts.Partials.Layer) {
				newPos = group.get_index ();
			} else {
				newPos = -1;
			}

			if (y > ((newPos * alloc.height) - (alloc.height / 2))) {
				debug ("drop below");
				newPos++;
			}

			debug ("Layer dropped OUTSIDE from INSIDE a group: %i", newPos);
		} else {
			target.get_allocation (out alloc);
			newPos = target.get_index ();

			if (y <= ((newPos * alloc.height) - (alloc.height / 2)) && newPos > 1 && source.get_index () < newPos) {
				newPos--;
			}
			debug ("Layer dropped: %i", newPos);
		}

		if (source == target) {
			return;
		}

		if (source.layer_group != null) {
			source.layer_group.container.remove (source);
			source.layer_group = null;
		} else {
			container.remove (source);
		}

		if (before_group) {
			container.insert (source, newPos);
		} else if (target.grouped && source.layer_group == null) {
			source.layer_group = target;
			target.container.insert (source, newPos);
		} else if (target.grouped && source.layer_group != null) {
			source.layer_group = target;
			target.container.insert (source, newPos);
		} else if (!target.grouped && source.layer_group != null) {
			source.layer_group = null;
			container.insert (source, newPos);
		} else {
			container.insert (source, newPos);
		}

		window.main_window.right_sidebar.layers_panel.reload_zebra ();
		show_all ();
	}

	private void build_drag_and_drop () {
		Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);

		drag_begin.connect (on_drag_begin);
		drag_data_get.connect (on_drag_data_get);

		drag_leave.connect (on_drag_leave);
	}

	private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
		var row = (Akira.Layouts.Partials.Artboard) widget.get_ancestor (typeof (Akira.Layouts.Partials.Artboard));
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

		row.draw (cr);

		Gtk.drag_set_icon_surface (context, surface);
	}

	private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
		uchar[] data = new uchar[(sizeof (Akira.Layouts.Partials.Artboard))];
		((Gtk.Widget[])data)[0] = widget;

		selection_data.set (
			Gdk.Atom.intern_static_string ("ARTBOARD"), 32, data
		);
	}

	public void on_drag_leave (Gdk.DragContext context, uint time) {
		get_style_context ().remove_class ("highlight");
		window.main_window.right_sidebar.indicator.visible = false;
	}

	public bool on_click_event (Gdk.Event event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS) {
			window.main_window.right_sidebar.layers_panel.selection_mode = Gtk.SelectionMode.SINGLE;

			window.main_window.right_sidebar.layers_panel.foreach ((child) => {
				if (child is Akira.Layouts.Partials.Artboard) {
					Akira.Layouts.Partials.Artboard artboard = (Akira.Layouts.Partials.Artboard) child;

					window.main_window.right_sidebar.layers_panel.unselect_row (artboard);
					artboard.container.unselect_all ();
				}
			});

			activate ();
		}

		if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
			entry.visible = true;
			entry.no_show_all = false;
			label.visible = false;
			label.no_show_all = true;

			editing = true;

			Timeout.add (200, () => {
				entry.grab_focus ();
				return false;
			});
		}

		return false;
	}

	private bool on_key_pressed (Gtk.Widget source, Gdk.EventKey key) {
		switch (key.keyval) {
			case 65535: // Delete Key
			case 65288: // Backspace
				return delete_object ();
		}

		return false;
	}

	private bool delete_object () {
		if (is_selected () && !editing) {
			window.main_window.right_sidebar.layers_panel.remove (this);

			return true;
		}

		var layers = container.get_selected_rows ();

		check_delete_object (layers);

		container.foreach (child => {
			if (child is Akira.Layouts.Partials.Layer) {
				Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) child;
				if (layer.grouped) {
					check_delete_object (layer.container.get_selected_rows ());
				}
			}
		});

		window.main_window.right_sidebar.layers_panel.reload_zebra ();

		return true;
	}

	public void check_delete_object (GLib.List<weak Gtk.ListBoxRow> layers) {
		layers.foreach (row => {
			Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) row;
			do_delete_object (layer);

			if (layer.grouped) {
				check_delete_object (layer.container.get_selected_rows ());
			}
		});
	}

	public void do_delete_object (Akira.Layouts.Partials.Layer layer) {
		if (layer.is_selected () && !layer.editing) {
			if (layer.layer_group != null) {
				layer.layer_group.container.remove (layer);
			} else {
				container.remove (layer);
			}
		}
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
			entry.text = label.label;

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

		editing = false;

		activate ();
	}

	public void count_layers () {
		layers_count = 0;

		container.foreach (child => {
			if (child is Akira.Layouts.Partials.Layer) {
				layers_count++;
			}
		});
	}
}
