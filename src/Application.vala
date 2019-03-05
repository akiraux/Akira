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

namespace Akira {
	public Akira.Services.Settings settings;
}

public class Akira.Application : Granite.Application {
	private Gee.HashMap<string, Akira.Window> opened_files;
	public GLib.List <Window> windows;

	construct {
		flags |= ApplicationFlags.HANDLES_OPEN;
		build_data_dir = Constants.DATADIR;
		build_pkg_data_dir = Constants.PKGDATADIR;
		build_release_name = Constants.RELEASE_NAME;
		build_version = Constants.VERSION;
		build_version_info = Constants.VERSION_INFO;

		settings = new Akira.Services.Settings ();
		windows = new GLib.List <Window> ();
		opened_files = new Gee.HashMap<string, Akira.Window>();

		program_name = "Akira";
		exec_name = "com.github.akiraux.akira";
		app_launcher = "com.github.akiraux.akira.desktop";
		application_id = "com.github.akiraux.akira";

	}

	public override void open (File[] files, string hint) {

        foreach (var file in files) {
            if (is_file_opened (file)) {
                // Preset active window with file
                var window = get_window_from_file (file);
                window.show_app ();
            } else {
                // Open New window
                var window = new Akira.Window (this);
                this.add_window (window);

                window.open_file (file);
                window.show_app ();
            }
        }
	}

	public void register_file_to_window (File file, Akira.Window window) {
        if (!is_file_opened (file)) {
            opened_files.set (file.get_uri (), window);
        } else {
            warning ("File was opened in two separate windows");
        }
    }

	public Akira.Window get_window_from_file (File file) {
        return opened_files.get (file.get_uri ());
    }

	public bool is_file_opened (File file) {
        return opened_files.has_key (file.get_uri ());
    }

	public void new_window () {
		new Akira.Window (this).present ();
	}

	public override void window_added (Gtk.Window window) {
		windows.append (window as Window);
		base.window_added (window);
	}

	public override void window_removed (Gtk.Window window) {
		windows.remove (window as Window);
		base.window_removed (window);
	}

	protected override void activate () {
		Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");
		Gtk.Settings.get_default().set_property("gtk-theme-name", "elementary");

		weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
		default_theme.add_resource_path ("/com/github/akiraux/akira");

		var window = new Akira.Window (this);
		this.add_window (window);
	}
}
