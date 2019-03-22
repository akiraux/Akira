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

public class Akira.Services.ActionManager : Object {
	public weak Akira.Application app { get; construct; }
	public weak Akira.Window window { get; construct; }

	public SimpleActionGroup actions { get; construct; }

	public const string ACTION_PREFIX = "win.";
	public const string ACTION_NEW_WINDOW = "action_new_window";
	public const string ACTION_OPEN = "action_open";
	public const string ACTION_SAVE = "action_save";
	public const string ACTION_SAVE_AS = "action_save_as";
	public const string ACTION_SHOW_PIXEL_GRID = "action-show-pixel-grid";
	public const string ACTION_SHOW_UI_GRID = "action-show-ui-grid";
	public const string ACTION_PRESENTATION = "action_presentation";
	public const string ACTION_PREFERENCES = "action_preferences";
	public const string ACTION_EXPORT = "action_export";
	public const string ACTION_LABELS = "action_labels";
	public const string ACTION_QUIT = "action_quit";
	public const string ACTION_ZOOM_IN = "action_zoom_in";
	public const string ACTION_ZOOM_OUT = "action_zoom_out";
	public const string ACTION_ZOOM_RESET = "action_zoom_reset";
	public const string ACTION_ADD_RECT = "action_add_rect";
	public const string ACTION_ADD_ELLIPSE = "action_add_ellipse";
	public const string ACTION_ADD_TEXT = "action_add_text";

	public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

	private const ActionEntry[] action_entries = {
		{ ACTION_NEW_WINDOW, action_new_window },
		{ ACTION_OPEN, action_open },
		{ ACTION_SAVE, action_save },
		{ ACTION_SAVE_AS, action_save_as },
		{ ACTION_SHOW_PIXEL_GRID, action_show_pixel_grid },
		{ ACTION_SHOW_UI_GRID, action_show_ui_grid },
		{ ACTION_PRESENTATION, action_presentation },
		{ ACTION_PREFERENCES, action_preferences },
		{ ACTION_EXPORT, action_export },
		{ ACTION_LABELS, action_labels },
		{ ACTION_QUIT, action_quit },
		{ ACTION_ZOOM_IN, action_zoom_in },
		{ ACTION_ZOOM_OUT, action_zoom_out },
		{ ACTION_ZOOM_RESET, action_zoom_reset },
		{ ACTION_ADD_RECT, action_add_rect },
		{ ACTION_ADD_ELLIPSE, action_add_ellipse },
		{ ACTION_ADD_TEXT, action_add_text },
	};

	public ActionManager (Akira.Application akira_app, Akira.Window main_window) {
		Object (
			app: akira_app,
			window: main_window
		);
	}

	static construct {
		action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
		action_accelerators.set (ACTION_OPEN, "<Control>o");
		action_accelerators.set (ACTION_SAVE, "<Control>s");
		action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
		action_accelerators.set (ACTION_SHOW_PIXEL_GRID, "<Control><Shift>p");
		action_accelerators.set (ACTION_SHOW_UI_GRID, "<Control><Shift>g");
		action_accelerators.set (ACTION_PRESENTATION, "<Control>period");
		action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
		action_accelerators.set (ACTION_EXPORT, "<Control><Shift>e");
		action_accelerators.set (ACTION_QUIT, "<Control>q");
		action_accelerators.set (ACTION_ZOOM_IN, "<Control>equal");
		action_accelerators.set (ACTION_ZOOM_OUT, "<Control>minus");
		action_accelerators.set (ACTION_ZOOM_RESET, "<Control>0");
	}

	construct {
		actions = new SimpleActionGroup ();
		actions.add_action_entries (action_entries, this);
		window.insert_action_group ("win", actions);

		foreach (var action in action_accelerators.get_keys ()) {
			app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
		}
	}

	private void action_labels () {
		window.headerbar.toggle ();
		window.headerbar.menu.toggle ();
		window.headerbar.toolset.toggle ();
		window.headerbar.zoom.toggle ();
		window.headerbar.preferences.toggle ();
		window.headerbar.export.toggle ();
		window.headerbar.group.toggle ();
		window.headerbar.ungroup.toggle ();
		window.headerbar.move_up.toggle ();
		window.headerbar.move_down.toggle ();
		window.headerbar.move_top.toggle ();
		window.headerbar.move_bottom.toggle ();
		window.headerbar.path_difference.toggle ();
		window.headerbar.path_exclusion.toggle ();
		window.headerbar.path_intersect.toggle ();
		window.headerbar.path_union.toggle ();
		window.headerbar.toggle ();
	}

	public void show_labels () {
		window.headerbar.toggle ();
		window.headerbar.menu.show_labels ();
		window.headerbar.toolset.show_labels ();
		window.headerbar.zoom.show_labels ();
		window.headerbar.preferences.show_labels ();
		window.headerbar.export.show_labels ();
		window.headerbar.group.show_labels ();
		window.headerbar.ungroup.show_labels ();
		window.headerbar.move_up.show_labels ();
		window.headerbar.move_down.show_labels ();
		window.headerbar.move_top.show_labels ();
		window.headerbar.move_bottom.show_labels ();
		window.headerbar.path_difference.show_labels ();
		window.headerbar.path_exclusion.show_labels ();
		window.headerbar.path_intersect.show_labels ();
		window.headerbar.path_union.show_labels ();
		window.headerbar.toggle ();
	}

	public void hide_labels () {
		window.headerbar.toggle ();
		window.headerbar.menu.hide_labels ();
		window.headerbar.toolset.hide_labels ();
		window.headerbar.zoom.hide_labels ();
		window.headerbar.preferences.hide_labels ();
		window.headerbar.export.hide_labels ();
		window.headerbar.group.hide_labels ();
		window.headerbar.ungroup.hide_labels ();
		window.headerbar.move_up.hide_labels ();
		window.headerbar.move_down.hide_labels ();
		window.headerbar.move_top.hide_labels ();
		window.headerbar.move_bottom.hide_labels ();
		window.headerbar.path_difference.hide_labels ();
		window.headerbar.path_exclusion.hide_labels ();
		window.headerbar.path_intersect.hide_labels ();
		window.headerbar.path_union.hide_labels ();
		window.headerbar.toggle ();
	}

	public void update_icons_style () {
		window.headerbar.toggle ();
		window.headerbar.update_icons_style ();
		window.headerbar.toggle ();
	}

	private void action_quit () {
		window.before_destroy ();
	}

	private void action_presentation () {
		window.headerbar.toggle ();
		window.main_window.statusbar.toggle ();
		window.main_window.left_sidebar.toggle ();
		window.main_window.right_sidebar.toggle ();
	}

	private void action_new_window () {
		app.new_window ();
	}

	private void action_open () {
		warning ("open");
	}

	private void action_save () {
		warning ("save");
	}

	private void action_save_as () {
		warning ("save_as");
	}

	private void action_show_pixel_grid () {
		warning ("show pixel grid");
	}

	private void action_show_ui_grid () {
		warning ("show UI grid");
	}
	
	private void action_preferences () {
		if (window.settings_dialog == null) {
			window.settings_dialog = new Akira.Widgets.SettingsDialog (window);
			window.settings_dialog.show_all ();
			
			window.settings_dialog.destroy.connect (() => {
				window.settings_dialog = null;
			});
		}
		
		window.settings_dialog.present ();
	}
	
	private void action_export () {
		warning ("export");
	}

	private void action_zoom_in () {
		window.headerbar.zoom.zoom_in ();
	}

	private void action_zoom_out () {
		window.headerbar.zoom.zoom_out ();
	}

	private void action_zoom_reset () {
		window.headerbar.zoom.zoom_reset ();
	}

	private void action_add_rect () {
		var rect = window.main_window.main_canvas.add_rect ();
		var artboard = window.main_window.right_sidebar.layers_panel.artboard;
		artboard.container.add (new Akira.Layouts.Partials.Layer (window, artboard, rect, "Rectangle", "shape-rectangle-symbolic", false));
		artboard.show_all ();
	}

	private void action_add_ellipse () {
		var ellipse = window.main_window.main_canvas.add_ellipse ();
		var artboard = window.main_window.right_sidebar.layers_panel.artboard;
		artboard.container.add (new Akira.Layouts.Partials.Layer (window, artboard, ellipse, "Circle", "shape-circle-symbolic", false));
		artboard.show_all ();
	}

	private void action_add_text () {
		var text = window.main_window.main_canvas.add_text ();
		var artboard = window.main_window.right_sidebar.layers_panel.artboard;
		artboard.container.add (new Akira.Layouts.Partials.Layer (window, artboard, text, "Text", "shape-text-symbolic", false));
		artboard.show_all ();
	}

	public static void action_from_group (string action_name, ActionGroup? action_group) {
		action_group.activate_action (action_name, null);
	}
}
