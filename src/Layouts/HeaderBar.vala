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

public class Akira.Layouts.HeaderBar : Gtk.HeaderBar {
	public weak Akira.Window window { get; construct; }

	public Akira.Partials.HeaderBarButton new_document;
	public Akira.Partials.HeaderBarButton save_file;
	public Akira.Partials.HeaderBarButton save_file_as;

	public Akira.Partials.MenuButton menu;
	public Akira.Partials.MenuButton toolset;
	public Akira.Partials.HeaderBarButton preferences;
	public Akira.Partials.HeaderBarButton export;
	public Akira.Partials.HeaderBarButton layout;

	public bool toggled {
		get {
			return visible;
		} set {
			visible = value;
			no_show_all = !value;
		}
	}

	public HeaderBar (Akira.Window main_window) {
		Object (
			toggled: true,
			window: main_window
		);
	}

	construct {
		set_title (APP_NAME);
		set_show_close_button (true);
		get_style_context ().add_class ("default-decoration");

		var menu_items = new Gtk.Menu ();

		var new_window = new Gtk.MenuItem.with_label (_("New Window"));
		new_window.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_NEW_WINDOW;
		menu_items.add (new_window);
		menu_items.add (new Gtk.SeparatorMenuItem ());

		var open = new Gtk.MenuItem.with_label (_("Open"));
		open.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_OPEN;
		menu_items.add (open);

		var save = new Gtk.MenuItem.with_label (_("Save"));
		save.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_SAVE;
		menu_items.add (save);

		var save_as = new Gtk.MenuItem.with_label (_("Save As"));
		save_as.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_SAVE_AS;
		menu_items.add (save_as);

		menu_items.add (new Gtk.SeparatorMenuItem ());

		var quit = new Gtk.MenuItem.with_label(_("Quit"));
		quit.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_QUIT;
		menu_items.add (quit);

		menu_items.show_all ();

		menu = new Akira.Partials.MenuButton ("document-open", _("Menu"), null);
		menu.button.popup = menu_items;

		var tools = new Gtk.Menu ();
		tools.add (new Gtk.MenuItem.with_label(_("Artboard")));
		tools.add (new Gtk.SeparatorMenuItem ());
		tools.add (new Gtk.MenuItem.with_label(_("Vector")));
		tools.add (new Gtk.MenuItem.with_label(_("Pencil")));
		tools.add (new Gtk.MenuItem.with_label(_("Shapes")));
		tools.add (new Gtk.SeparatorMenuItem ());
		tools.add (new Gtk.MenuItem.with_label(_("Text")));
		tools.add (new Gtk.MenuItem.with_label(_("Image")));
		tools.show_all ();

		toolset = new Akira.Partials.MenuButton ("insert-object", _("Insert"), null);
		toolset.button.popup = tools;

		preferences = new Akira.Partials.HeaderBarButton ("open-menu", _("Settings"), {"<Ctrl>comma"});
		preferences.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_PREFERENCES;

		export = new Akira.Partials.HeaderBarButton ("document-export", _("Export"), {"<Ctrl><Shift>E"});
		export.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_EXPORT;

		add (menu);
		add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
		add (toolset);
		add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
		pack_end (preferences);
		pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
		pack_end (export);

		build_signals ();
	}

	private void build_signals () {
		// deal with signals not part of accelerators
	}

	public void button_sensitivity () {
		// dinamically toggle button sensitivity based on document status or actor selected.
	}

	public void update_icons_style () {
		menu.update_image ();
		toolset.update_image ();
		export.update_image ();
		preferences.update_image ();
	}

	public void toggle () {
		toggled = !toggled;
	}
}
