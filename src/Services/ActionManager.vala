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

public class Akira.Services.ActionManager : Object {
	public weak Akira.Application app { get; construct; }
	public weak Akira.Window window { get; construct; }

	public SimpleActionGroup actions { get; construct; }

	public const string ACTION_PREFIX = "win.";
	public const string ACTION_NEW_WINDOW = "action_new_window";
	public const string ACTION_OPEN = "action_open";
	public const string ACTION_SAVE = "action_save";
	public const string ACTION_SAVE_AS = "action_save_as";
	public const string ACTION_PRESENTATION = "action_presentation";
	public const string ACTION_PREFERENCES = "action_preferences";
	public const string ACTION_LABELS = "action_labels";
	public const string ACTION_QUIT = "action_quit";

	// Canvas related actions
	// public const string ACTION_DELETE_LAYER = "action_delete_layer";
	// public const string ACTION_DELETE_LAYER_BK = "action_delete_layer";

	public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

	private const ActionEntry[] action_entries = {
		{ ACTION_NEW_WINDOW, action_new_window },
		{ ACTION_OPEN, action_open },
		{ ACTION_SAVE, action_save },
		{ ACTION_SAVE_AS, action_save_as },
		{ ACTION_PRESENTATION, action_presentation },
		{ ACTION_PREFERENCES, action_preferences },
		{ ACTION_LABELS, action_labels },
		{ ACTION_QUIT, action_quit },
		// { ACTION_DELETE_LAYER, action_delete_layer },
		// { ACTION_DELETE_LAYER_BK, action_delete_layer }
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
		action_accelerators.set (ACTION_PRESENTATION, "<Control>period");
		action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
		action_accelerators.set (ACTION_QUIT, "<Control>q");
		// action_accelerators.set (ACTION_DELETE_LAYER, "<Control>Delete");
		// action_accelerators.set (ACTION_DELETE_LAYER_BK, "<Control>BackSpace");
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
		window.headerbar.layout.toggle ();
		window.headerbar.ruler.toggle ();
		window.headerbar.toolset.toggle ();
		window.headerbar.preferences.toggle ();
		window.headerbar.toggle ();
	}

	public void show_labels () {
		window.headerbar.toggle ();
		window.headerbar.menu.show_labels ();
		window.headerbar.layout.show_labels ();
		window.headerbar.ruler.show_labels ();
		window.headerbar.toolset.show_labels ();
		window.headerbar.preferences.show_labels ();
		window.headerbar.toggle ();
	}

	public void hide_labels () {
		window.headerbar.toggle ();
		window.headerbar.menu.hide_labels ();
		window.headerbar.layout.hide_labels ();
		window.headerbar.ruler.hide_labels ();
		window.headerbar.toolset.hide_labels ();
		window.headerbar.preferences.hide_labels ();
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

	// private void action_delete_layer () {
	// 	window.main_window.right_sidebar.layers_panel.selected_foreach ((box, row) => {
	// 		window.main_window.right_sidebar.layers_panel.remove ((Akira.Layouts.Partials.Artboard) row);
	// 	});

	// 	window.main_window.right_sidebar.layers_panel.@foreach ((child) => {
	// 		if (child is Akira.Layouts.Partials.Artboard) {
	// 			Akira.Layouts.Partials.Artboard artboard = (Akira.Layouts.Partials.Artboard) child;

	// 			var layers = artboard.container.get_selected_rows ();
	// 			layers.@foreach ((row) => {
	// 				Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) row;
	// 				if (layer.is_selected () && !layer.editing) {
	// 					artboard.container.remove (layer);
	// 				}
	// 			});
	// 		}
	// 	});
	// }

	public static void action_from_group (string action_name, ActionGroup? action_group) {
		action_group.activate_action (action_name, null);
	}
}