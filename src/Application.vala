/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

namespace Akira {
    public Akira.Services.Settings settings;
}

public class Akira.Application : Gtk.Application {
    public GLib.List<Window> windows;

    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;

        settings = new Akira.Services.Settings ();
        windows = new GLib.List<Window> ();

        application_id = Constants.APP_ID;
    }

    public override void open (File[] files, string hint) {
        foreach (var file in files) {
            if (is_file_opened (file)) {
                // Present active window with currently opened file.
                // We don't allow opening the same file on multiple windows.
                var window = get_window_from_file (file);
                window.show_app ();
            } else {
                // Open a new window.
                var window = new Akira.Window (this);
                this.add_window (window);

                window.open_file (file);
                window.show_app ();
            }
        }
    }

    public Akira.Window? get_window_from_file (File file) {
        foreach (Akira.Window window in windows) {
            if (window.akira_file != null && window.akira_file.opened_file == file) {
                return window;
            }
        }

        return null;
    }

    public bool is_file_opened (File file) {
        foreach (Akira.Window window in windows) {
            if (window.akira_file != null && window.akira_file.opened_file == file) {
                return true;
            }
        }

        return false;
    }

    public void new_window () {
        new Akira.Window (this).present ();
    }

    public override void window_added (Gtk.Window window) {
        windows.append (window as Akira.Window);
        base.window_added (window);
    }

    public override void window_removed (Gtk.Window window) {
        windows.remove (window as Akira.Window);
        base.window_removed (window);
    }

    protected override void activate () {
        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "elementary");

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/akiraux/akira");

        var window = new Akira.Window (this);
        this.add_window (window);
    }
}
