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
        // Loop through all selected files.
        foreach (var file in files) {
            if (is_file_opened (file)) {
                // Present active window with currently opened file.
                // We don't allow opening the same file on multiple windows.
                var window = get_window_from_file (file);
                window.show_app ();
                continue;
            }

            // If the current window is empty, load the file in this one.
            var current_window = active_window as Akira.Window;
            if (current_window != null && current_window.akira_file == null && !current_window.edited) {
                current_window.open_file (file);
                current_window.event_bus.file_saved (file.get_basename ());
                continue;
            }

            // The application was requested to open some files. Be sure to
            // initialize the theme in case it wasn't already running.
            init_theme ();

            // Open a new window.
            var window = new Akira.Window (this);
            this.add_window (window);

            window.open_file (file);
            window.show_app ();
            window.event_bus.file_saved (file.get_basename ());
        }
    }

    public Akira.Window? get_window_from_file (File file) {
        foreach (Akira.Window window in windows) {
            if (window.akira_file != null && window.akira_file.opened_file.get_path () == file.get_path ()) {
                return window;
            }
        }

        return null;
    }

    public bool is_file_opened (File file) {
        foreach (Akira.Window window in windows) {
            if (window.akira_file != null && window.akira_file.opened_file.get_path () == file.get_path ()) {
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

    /**
     * Update the list of recently opened files in all the currently opened Windows.
     */
    public void update_recent_files_list () {
        foreach (Akira.Window window in windows) {
            window.event_bus.update_recent_files_list ();
        }
    }

    protected override void activate () {
        init_theme ();

        var window = new Akira.Window (this);
        this.add_window (window);

        if (settings.version != Constants.VERSION) {
            var dialog = new Akira.Dialogs.ReleaseDialog (window);
            dialog.show_all ();
            dialog.present ();

            // Update the settings so we don't show the same dialog again.
            settings.version = Constants.VERSION;
        }

        // Load the most recently opened/saved file.
        if (settings.open_quick) {
            window.action_manager.action_load_first ();
        }
    }

    private void init_theme () {
        // Interrupt if we have at least one existing window, meaning the theme
        // was previously initialized.
        if (windows.length () > 0) {
            return;
        }

        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "io.elementary.stylesheet.blueberry");

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/akiraux/akira");
    }
}
