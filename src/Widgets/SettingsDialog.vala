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

public class Akira.Widgets.SettingsDialog : Gtk.Dialog {
	public weak Akira.Window window { get; construct; }

	private Gtk.Stack main_stack;
	private Gtk.Switch dark_theme_switch;
	private Gtk.Switch label_switch;
	private Gee.HashMap<int, string> icon_types;
	private Gtk.ComboBox icon_combo_box;

	enum Column {
		ICONTYPE
	}

	public SettingsDialog (Akira.Window parent) {
		Object (
			border_width: 5,
			deletable: false,
			resizable: false,
			title: _("Preferences"),
			transient_for: parent,
			window: parent
		);
	}

	construct {
		main_stack = new Gtk.Stack ();
		main_stack.margin = 6;
		main_stack.margin_bottom = 15;
		main_stack.margin_top = 15;
		main_stack.add_titled (get_general_box (), "general", _("General"));
		main_stack.add_titled (get_interface_box (), "interface", _("Interface"));

		var main_stackswitcher = new Gtk.StackSwitcher ();
		main_stackswitcher.set_stack (main_stack);
		main_stackswitcher.halign = Gtk.Align.CENTER;

		var main_grid = new Gtk.Grid ();
		main_grid.halign = Gtk.Align.CENTER;
		main_grid.attach (main_stackswitcher, 1, 1, 1, 1);
		main_grid.attach (main_stack, 1, 2, 1, 1);

		get_content_area ().add (main_grid);

		var close_button = new SettingsButton (_("Close"));

		close_button.clicked.connect (() => {
			destroy ();
		});

		add_action_widget (close_button, 0);
	}

	private Gtk.Widget get_general_box () {
		var general_grid = new Gtk.Grid ();
		general_grid.row_spacing = 6;
		general_grid.column_spacing = 12;
		general_grid.column_homogeneous = true;

		general_grid.attach (new SettingsHeader (_("General")), 0, 0, 2, 1);
		general_grid.attach (new SettingsLabel (_("Auto Reopen Latest File:")), 0, 1, 1, 1);
		general_grid.attach (new SettingsSwitch ("open-quick"), 1, 1, 1, 1);

		return general_grid;
	}

	private Gtk.Widget get_interface_box () {
		var content_grid = new Gtk.Grid ();
		content_grid.row_spacing = 6;
		content_grid.column_spacing = 12;
		content_grid.column_homogeneous = true;

		content_grid.attach (new SettingsHeader (_("Interface")), 0, 0, 2, 1);

		content_grid.attach (new SettingsLabel (_("Use Dark Theme:")), 0, 1, 1, 1);
		dark_theme_switch = new SettingsSwitch ("dark-theme");
		content_grid.attach (dark_theme_switch, 1, 1, 1, 1);

		dark_theme_switch.notify["active"].connect (() => {
			Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;
		});

		content_grid.attach (new SettingsHeader (_("ToolBar Style")), 0, 2, 2, 1);

		content_grid.attach (new SettingsLabel (_("Show Button Labels:")), 0, 3, 1, 1);
		label_switch = new SettingsSwitch ("show-label");
		content_grid.attach (label_switch, 1, 3, 1, 1);

		label_switch.notify["active"].connect (() => {
			if (!settings.show_label) {
				window.action_manager.hide_labels ();
			} else if (settings.show_label) {
				window.action_manager.show_labels ();
			}
		});

		content_grid.attach (new SettingsLabel (_("Select Icon Style:")), 0, 4, 1, 1);

		icon_types = new Gee.HashMap<int, string> ();
		icon_types.set (0, "filled");
		icon_types.set (1, "lineart");
		icon_types.set (2, "symbolic");

		var list_store = new Gtk.ListStore (1, typeof (string));

		for (int i = 0; i < icon_types.size; i++){
			Gtk.TreeIter iter;
			list_store.append (out iter);
			list_store.set (iter, Column.ICONTYPE, icon_types[i]);
		}

		icon_combo_box = new Gtk.ComboBox.with_model (list_store);
		var cell = new Gtk.CellRendererText ();
		icon_combo_box.pack_start (cell, false);

		icon_combo_box.set_attributes (cell, "text", Column.ICONTYPE);
		icon_combo_box.set_active (0);

		foreach (var entry in icon_types.entries) {
			if (entry.value == settings.icon_style) {
				icon_combo_box.set_active (entry.key);
			}
		}

		//  icons_combo_box = new Gtk.ComboBoxText ();
		//  icons_combo_box.append_text ("filled");
		//  icons_combo_box.append_text ("lineart");
		//  icons_combo_box.append_text ("symbolic");
		//  icons_combo_box.active_id = settings.icon_style;
		content_grid.attach (icon_combo_box, 1, 4, 1, 1);

		icon_combo_box.changed.connect (() => {
			settings.icon_style = icon_types[icon_combo_box.get_active ()];
			window.action_manager.update_icons_style ();
      event_bus.emit("update_icons_style");
		});

		return content_grid;
	}

	private class SettingsHeader : Gtk.Label {
		public SettingsHeader (string text) {
			label = text;
			get_style_context ().add_class ("h4");
			halign = Gtk.Align.START;
		}
	}

	private class SettingsLabel : Gtk.Label {
		public SettingsLabel (string text) {
			label = text;
			halign = Gtk.Align.START;
			margin_end = 10;
		}
	}

	private class SettingsSwitch : Gtk.Switch {
		public SettingsSwitch (string setting) {
			halign = Gtk.Align.END;
			settings.schema.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
		}
	}

	private class SettingsButton : Gtk.Button {
		public SettingsButton (string text) {
			label = text;
			valign = Gtk.Align.END;
			get_style_context ().add_class ("suggested-action");
		}
	}
}
