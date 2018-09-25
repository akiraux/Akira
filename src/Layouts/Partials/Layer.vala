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
	public Akira.Layouts.Partials.Layer? layer_group { construct set; get; }
	public string layer_name { get; construct; }
	public string icon_name { get; construct; }

	private bool scroll_up = false;
	private bool scrolling = false;
	private bool should_scroll = false;
	public Gtk.Adjustment vadjustment;

	private const int SCROLL_STEP_SIZE = 5;
	private const int SCROLL_DISTANCE = 30;
	private const int SCROLL_DELAY = 50;

	private const Gtk.TargetEntry targetEntriesLayer[] = {
		{ "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public Gtk.Image icon;
	public Gtk.Image icon_folder_open;
	public Gtk.Image icon_locked;
	public Gtk.Image icon_unlocked;
	public Gtk.Image icon_hidden;
	public Gtk.Image icon_visible;
	public Gtk.ToggleButton button_locked;
	public Gtk.ToggleButton button_hidden;
	public Gtk.Label label;
	public Gtk.Entry entry;
	public Gtk.EventBox handle;
	private Gtk.Grid label_grid;

	// Group related properties
	public Gtk.ToggleButton button;
	public Gtk.Image button_icon;
	public Gtk.Revealer revealer;
	public Gtk.ListBox container;

	private bool _locked { get; set; default = false; }
	public bool locked {
		get { return _locked; } set { _locked = value; }
	}

	// Keep __hidden with double underscore for FreeBSD compatibility
	private bool __hidden { get; set; default = false; }
	public bool hidden {
		get { return __hidden; } set { __hidden = value; }
	}

	private bool _editing { get; set; default = false; }
	public bool editing {
		get { return _editing; } set { _editing = value; }
	}

	private bool _grouped { get; set; default = false; }
	public bool grouped {
		get { return _grouped; } set construct { _grouped = value; }
	}

	// public Akira.Shape shape { get; construct; }

	public Layer (Akira.Window main_window, Akira.Layouts.Partials.Artboard artboard, string name, string icon, bool group, Akira.Layouts.Partials.Layer? parent = null) {
		Object (
			window: main_window,
			layer_name: name,
			icon_name: icon,
			artboard: artboard,
			grouped: group,
			layer_group: parent
		);
	}

	construct {
		can_focus = true;
		get_style_context ().add_class ("layer");

		label =  new Gtk.Label (layer_name);
		label.halign = Gtk.Align.FILL;
		label.xalign = 0;
		label.expand = true;
		label.set_ellipsize (Pango.EllipsizeMode.END);

		entry = new Gtk.Entry ();
		entry.margin_top = 5;
		entry.margin_bottom = 5;
		entry.expand = true;
		entry.visible = false;
		entry.no_show_all = true;
		entry.set_text (layer_name);

		entry.activate.connect (update_on_enter);
		entry.focus_out_event.connect (update_on_leave);
		entry.key_release_event.connect (update_on_escape);

		if (icon_name.contains ("/")) {
			icon = new Gtk.Image.from_resource (icon_name);
			icon.margin_end = 6;
			icon.margin_start = 16;
		} else {
			icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
			icon.margin_end = 10;
		}
		icon.vexpand = true;

		icon_folder_open = new Gtk.Image.from_icon_name ("folder-open", Gtk.IconSize.MENU);
		icon_folder_open.margin_end = 10;
		icon_folder_open.vexpand = true;
		icon_folder_open.visible = false;
		icon_folder_open.no_show_all = true;

		var icon_layer_grid = new Gtk.Grid ();
		icon_layer_grid.attach (icon, 0, 0, 1, 1);
		icon_layer_grid.attach (icon_folder_open, 1, 0, 1, 1);

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

		var handle_grid = new Gtk.Grid ();
		handle_grid.expand = true;
		handle_grid.attach (icon_layer_grid, 0, 0, 1, 1);
		handle_grid.attach (label, 1, 0, 1, 1);
		handle_grid.attach (entry, 2, 0, 1, 1);

		handle = new Gtk.EventBox ();
		handle.expand = true;
		handle.above_child = false;
		handle.add (handle_grid);

		label_grid = new Gtk.Grid ();
		label_grid.expand = true;
		label_grid.attach (handle, 1, 0, 1, 1);
		label_grid.attach (button_locked, 2, 0, 1, 1);
		label_grid.attach (button_hidden, 3, 0, 1, 1);

		is_group ();
		build_darg_and_drop ();

		handle.event.connect (on_click_event);

		lock_actions ();
		hide_actions ();
		reveal_actions ();
	}

	private void is_group () {
		if (! grouped) {
			add (label_grid);
			return;
		}

		get_style_context ().add_class ("layer-group");

		button = new Gtk.ToggleButton ();
		button.active = true;
		button.get_style_context ().remove_class ("button");
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.get_style_context ().add_class ("revealer-button");
		button_icon = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
		button.add (button_icon);

		label_grid.attach (button, 0, 0, 1, 1);

		revealer = new Gtk.Revealer ();
		revealer.hexpand = true;
		revealer.reveal_child = true;

		container = new Gtk.ListBox ();
		container.get_style_context ().add_class ("group-container");
		container.activate_on_single_click = true;
		container.selection_mode = Gtk.SelectionMode.SINGLE;
		revealer.add (container);

		if (revealer.get_reveal_child ()) {
			icon_folder_open.visible = true;
			icon_folder_open.no_show_all = false;
			icon.visible = false;
			icon.no_show_all = true;
		}

		var group_grid = new Gtk.Grid ();
		group_grid.attach (label_grid, 0, 0, 1, 1);
		group_grid.attach (revealer, 0, 1, 1, 1);

		add (group_grid);
	}

	private void reveal_actions () {
		if (! grouped) {
			return;
		}

		button.toggled.connect (() => {
			revealer.reveal_child = ! revealer.get_reveal_child ();

			if (revealer.get_reveal_child ()) {
				button.get_style_context ().remove_class ("closed");
				
				icon_folder_open.visible = true;
				icon_folder_open.no_show_all = false;
				icon.visible = false;
				icon.no_show_all = true;
			} else {
				button.get_style_context ().add_class ("closed");

				icon_folder_open.visible = false;
				icon_folder_open.no_show_all = true;
				icon.visible = true;
				icon.no_show_all = false;
			}

			window.main_window.right_sidebar.layers_panel.reload_zebra ();
		});
	}

	private void build_darg_and_drop () {
		Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntriesLayer, Gdk.DragAction.MOVE);

		drag_begin.connect (on_drag_begin);
		drag_data_get.connect (on_drag_data_get);

		Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntriesLayer, Gdk.DragAction.MOVE);
		drag_motion.connect (on_drag_motion);
		drag_leave.connect (on_drag_leave);
	}

	private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
		// var row = (Akira.Layouts.Partials.Layer) widget.get_ancestor (typeof (Akira.Layouts.Partials.Layer));
		var row = (widget as Akira.Layouts.Partials.Layer);
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
		var layers_panel = (Akira.Layouts.Partials.LayersPanel) artboard.get_ancestor (typeof (Akira.Layouts.Partials.LayersPanel));
		var row = (Akira.Layouts.Partials.Artboard) layers_panel.get_row_at_index (artboard.get_index ());

		int index = this.get_index ();
		Gtk.Allocation alloc;
		this.get_allocation (out alloc);

		int row_index = row.get_index ();
		Gtk.Allocation row_alloc;
		row.get_allocation (out row_alloc);

		int real_y = (index * alloc.height) + (row_index * alloc.height) - alloc.height + y;

		check_scroll (real_y);
		if (should_scroll && !scrolling) {
			scrolling = true;
			Timeout.add (SCROLL_DELAY, scroll);
		}

		return true;
	}

	public void on_drag_leave (Gdk.DragContext context, uint time) {
		artboard.container.drag_unhighlight_row ();
		should_scroll = false;
	}

	public bool on_click_event (Gdk.Event event) {

		if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
			entry.visible = true;
			entry.no_show_all = false;
			label.visible = false;
			label.no_show_all = true;

			button_locked.visible = false;
			button_locked.no_show_all = true;
			button_hidden.visible = false;
			button_hidden.no_show_all = true;

			editing = true;

			Timeout.add (200, () => {
				entry.grab_focus ();
				return false;
			});

			return false;
		}

		if (event.type == Gdk.EventType.BUTTON_RELEASE) {

			if (entry.visible == true) {
				return false;
			}

			Gdk.ModifierType state;
			event.get_state (out state);

			if (state.to_string () == "GDK_CONTROL_MASK") {
				artboard.container.selection_mode = Gtk.SelectionMode.MULTIPLE;
			} else {
				artboard.container.selection_mode = Gtk.SelectionMode.SINGLE;

				window.main_window.right_sidebar.layers_panel.foreach (child => {
					if (child is Akira.Layouts.Partials.Artboard) {
						Akira.Layouts.Partials.Artboard artboard = (Akira.Layouts.Partials.Artboard) child;

						window.main_window.right_sidebar.layers_panel.unselect_row (artboard);
						artboard.container.unselect_all ();

						unselect_groups (artboard.container);
					}
				});

				if (layer_group != null) {
					artboard.container.selection_mode = Gtk.SelectionMode.NONE;
					artboard.container.unselect_row (layer_group);
				}
			}

			activate ();

			window.main_window.right_sidebar.layers_panel.selection_mode = Gtk.SelectionMode.NONE;
			window.main_window.right_sidebar.layers_panel.unselect_row (artboard);

			return false;
		}

		return false;
	}

	private void unselect_groups (Gtk.ListBox container) {
		container.foreach (child => {
			if (child is Akira.Layouts.Partials.Layer) {
				Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) child;

				if (layer.grouped) {
					layer.container.unselect_all ();
					unselect_groups (layer.container);
				}
			}
		});
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

		button_locked.visible = true;
		button_locked.no_show_all = false;
		button_hidden.visible = true;
		button_hidden.no_show_all = false;

		editing = false;

		activate ();
	}

	private void lock_actions () {
		button_locked.toggled.connect (() => {
			var active = button_locked.get_active ();

			button_locked.tooltip_text = active ? _("Unlock Layer") : _("Lock Layer");

			if (active) {
				button_locked.get_style_context ().add_class ("show");
			} else {
				button_locked.get_style_context ().remove_class ("show");
			}

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

			if (active) {
				button_hidden.get_style_context ().add_class ("show");
			} else {
				button_hidden.get_style_context ().remove_class ("show");
			}

			icon_visible.visible = active;
			icon_visible.no_show_all = ! active;

			icon_hidden.visible = ! active;
			icon_hidden.no_show_all = active;

			hidden = active;
		});
	}

	private void check_scroll (int y) {
		vadjustment = window.main_window.right_sidebar.layers_scroll.vadjustment;

		if (vadjustment == null) {
			return;
		}

		double vadjustment_min = vadjustment.value;
		double vadjustment_max = vadjustment.page_size + vadjustment_min;
		double show_min = double.max (0, y - SCROLL_DISTANCE);
		double show_max = double.min (vadjustment.upper, y + SCROLL_DISTANCE);

		if (vadjustment_min > show_min) {
			should_scroll = true;
			scroll_up = true;
		} else if (vadjustment_max < show_max) {
			should_scroll = true;
			scroll_up = false;
		} else {
			should_scroll = false;
		}
	}

	private bool scroll () {
		if (should_scroll) {
			if (scroll_up) {
				vadjustment.value -= SCROLL_STEP_SIZE;
			} else {
				vadjustment.value += SCROLL_STEP_SIZE;
			}
		} else {
			scrolling = false;
		}

		return should_scroll;
	}
}