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
	public Akira.Layouts.Partials.Artboard artboard { construct set; get; }
	public string layer_name { get; construct; }
	public string icon_name { get; construct; }

	private const Gtk.TargetEntry targetEntriesLayer[] = {
		{ "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public Gtk.Image icon;
	public Gtk.Image icon_locked;
	public Gtk.Image icon_unlocked;
	public Gtk.Image icon_hidden;
	public Gtk.Image icon_visible;
	public Gtk.ToggleButton button_locked;
	public Gtk.ToggleButton button_hidden;
	public Gtk.Label label;
	public Gtk.Entry entry;
	public Gtk.EventBox handle;

	private bool _locked { get; set; default = false; }
	public bool locked {
		get { return _locked; } set { _locked = value; }
	}

	private bool _hidden { get; set; default = false; }
	public bool hidden {
		get { return _hidden; } set { _hidden = value; }
	}

	// public Akira.Shape shape { get; construct; }

	public Layer (Akira.Window main_window, Akira.Layouts.Partials.Artboard artboard, string name, string icon) {
		Object (
			window: main_window,
			layer_name: name,
			icon_name: icon,
			artboard: artboard
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

		button_locked = new Gtk.ToggleButton ();
		button_locked.tooltip_text = _("Lock Layer");
		button_locked.get_style_context ().remove_class ("button");
		button_locked.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button_locked.get_style_context ().add_class ("layer-action");
		icon_locked = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.MENU);
		icon_unlocked = new Gtk.Image.from_icon_name ("channel-insecure-symbolic", Gtk.IconSize.MENU);
		icon_unlocked.visible = false;
		icon_unlocked.no_show_all = true;

		var button_locked_grid = new Gtk.Grid ();
		button_locked_grid.attach (icon_locked, 0, 0, 1, 1);
		button_locked_grid.attach (icon_unlocked, 1, 0, 1, 1);
		button_locked.add (button_locked_grid);

		button_hidden = new Gtk.ToggleButton ();
		button_hidden.tooltip_text = _("Hide Layer");
		button_hidden.get_style_context ().remove_class ("button");
		button_hidden.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button_hidden.get_style_context ().add_class ("layer-action");
		icon_hidden = new Gtk.Image.from_resource ("/com/github/alecaddd/akira/tools/eye.svg");
		icon_visible = new Gtk.Image.from_resource ("/com/github/alecaddd/akira/tools/eye-not.svg");
		icon_visible.visible = false;
		icon_visible.no_show_all = true;

		var button_hidden_grid = new Gtk.Grid ();
		button_hidden_grid.attach (icon_hidden, 0, 0, 1, 1);
		button_hidden_grid.attach (icon_visible, 1, 0, 1, 1);
		button_hidden.add (button_hidden_grid);

		var label_grid = new Gtk.Grid ();
		label_grid.margin = 6;
		label_grid.expand = true;
		label_grid.attach (icon, 0, 0, 1, 1);
		label_grid.attach (label, 1, 0, 1, 1);
		label_grid.attach (entry, 2, 0, 1, 1);
		label_grid.attach (button_locked, 3, 0, 1, 1);
		label_grid.attach (button_hidden, 4, 0, 1, 1);

		handle = new Gtk.EventBox ();
		handle.hexpand = true;
		handle.add (label_grid);

		add (handle);

		build_darg_and_drop ();

		handle.enter_notify_event.connect ((event) => {
			button_locked.get_style_context ().add_class ("show");
			button_hidden.get_style_context ().add_class ("show");
			return true;
		});

		handle.leave_notify_event.connect ((event) => {
			if (event.detail != Gdk.NotifyType.INFERIOR) {
				if (! button_locked.get_active ()) {
					button_locked.get_style_context ().remove_class ("show");
				}

				if (! button_hidden.get_active ()) {
					button_hidden.get_style_context ().remove_class ("show");
				}
			}
		});

		handle.event.connect (on_click_event);

		lock_actions ();
		hide_actions ();
	}

	private void build_darg_and_drop () {
		Gtk.drag_source_set (handle, Gdk.ModifierType.BUTTON1_MASK, targetEntriesLayer, Gdk.DragAction.MOVE);

		handle.drag_begin.connect (on_drag_begin);
		handle.drag_data_get.connect (on_drag_data_get);

		Gtk.drag_dest_set (handle, Gtk.DestDefaults.MOTION, targetEntriesLayer, Gdk.DragAction.MOVE);
		handle.drag_motion.connect (on_drag_motion);
		handle.drag_leave.connect (on_drag_leave);
	}

	private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
		var row = (Akira.Layouts.Partials.Layer) widget.get_ancestor (typeof (Akira.Layouts.Partials.Layer));
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
		uchar[] data = new uchar[(sizeof (Akira.Layouts.Partials.Layer))];
		((Gtk.Widget[])data)[0] = widget;

		selection_data.set (
			Gdk.Atom.intern_static_string ("LAYER"), 32, data
		);
	}

	public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
		artboard.container.drag_highlight_row (this);
		// Gtk.Allocation alloc;
		// get_allocation (out alloc);

		// if (y <= (alloc.height / 2)) {
		// 	get_style_context ().add_class ("hover-up");
		// 	get_style_context ().remove_class ("hover-down");
		// } else if (y > (alloc.height / 2)) {
		// 	get_style_context ().add_class ("hover-down");
		// 	get_style_context ().remove_class ("hover-up");
		// }
		return true;
	}

	public void on_drag_leave (Gdk.DragContext context, uint time) {
		artboard.container.drag_unhighlight_row ();
		// get_style_context ().remove_class ("hover-up");
		// get_style_context ().remove_class ("hover-down");
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

	private void lock_actions () {
		button_locked.toggled.connect (() => {
			var active = button_locked.get_active ();

			button_locked.tooltip_text = active ? _("Unlock Layer") : _("Lock Layer");

			icon_unlocked.visible = active;
			icon_unlocked.no_show_all = ! active;

			icon_locked.visible = ! active;
			icon_locked.no_show_all = active;

			locked = active;
		});
	}

	private void hide_actions () {
		button_hidden.toggled.connect (() => {
			var active = button_hidden.get_active ();

			button_hidden.tooltip_text = active ? _("Show Layer") : _("Hide Layer");

			icon_visible.visible = active;
			icon_visible.no_show_all = ! active;

			icon_hidden.visible = ! active;
			icon_hidden.no_show_all = active;

			hidden = active;
		});
	}
}