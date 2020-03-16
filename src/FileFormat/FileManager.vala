/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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

public class Akira.FileFormat.FileManager : Object {
    public weak Akira.Window window { get; construct; }

    public FileManager (Akira.Window window) {
       Object (
          window: window
       );
    }

    // Save file.
    public void save_file () {
        // Check if we already have a file open to save or save a new one.
        if (window.akira_file != null) {
            window.akira_file.save_file ();
            window.event_bus.file_saved (null);
            return;
        }

        save_file_as ();
    }

    //  Save as.
    public void save_file_as () {
        var dialog = new Gtk.FileChooserNative (
            _("Save Akira file"), window,
            Gtk.FileChooserAction.SAVE,
            _("Save"), _("Cancel"));

        dialog.set_do_overwrite_confirmation (true);
        add_filters (dialog);
        dialog.set_modal (true);
        if (window.akira_file != null) {
            var file = window.app.get_file_from_window (window);
            try {
                dialog.set_file (file);
            }
            catch (GLib.Error error) {
                info ("%s\n", error.message);
            }
        }

        dialog.response.connect ((response_id) => save_file_as_response (dialog, response_id));
        dialog.show ();
    }

    private void add_filters (Gtk.FileChooserNative chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.akira");
        filter.set_filter_name (_("Akira files"));
        chooser.add_filter (filter);

        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name (_("All files"));
        chooser.add_filter (filter);
    }

    private void save_file_as_response (Gtk.FileChooserNative dialog, int response_id) {
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                File file;
                var save_file = dialog.get_file ();
                var path = save_file.get_path ();
                if (path.has_suffix (".akira")) {
                   file = save_file;
                } else {
                   file = File.new_for_path (path + ".akira");
                }
                window.save_new_file (file);
                window.event_bus.file_saved (dialog.get_current_name ());
                break;
        }
        dialog.destroy ();
    }

    // Open file.
    public void open_file () {
        var dialog = new Gtk.FileChooserNative (
            _("Open Akira file"), window,
            Gtk.FileChooserAction.OPEN,
            _("Open"), _("Cancel"));

        add_filters (dialog);
        dialog.local_only = true;
        dialog.select_multiple = false;
        dialog.response.connect ((response_id) => open_file_response (dialog, response_id));
        dialog.show ();
    }

    private void open_file_response (Gtk.FileChooserNative dialog, int response_id) {
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
            case Gtk.ResponseType.OK:
                File[] files = {};
                files += dialog.get_file ();
                window.app.open (files, "");
                var file_name = dialog.get_filename ().replace (dialog.get_current_folder () + "/", "");
                window.event_bus.file_saved (file_name);
                info ("opened: %s\n", (dialog.get_filename ()));
                break;

            case Gtk.ResponseType.CANCEL:
                info ("Cancelled: FileChooserAction.OPEN\n");
                break;
        }
        dialog.destroy ();
    }
}
