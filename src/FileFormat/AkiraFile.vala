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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.FileFormat.AkiraFile : Akira.FileFormat.ZipArchiveHandler {
    public weak Akira.Window window { get; construct; }

    public File pictures_folder { get; private set; }
    public File thumbnails_folder { get; private set; }

    private File content_file { get; set; }
    public string path {
        owned get {
            return opened_file.get_parent ().get_path () + "/" + opened_file.get_basename ();
        }
    }

    public AkiraFile (File _gzipped_file, Akira.Window window) {
        Object (opened_file: _gzipped_file.dup (), window: window);
    }

    public void load_file () {
        try {
            open_archive ();

            var content_json = get_content_as_json (content_file);
            new FileFormat.JsonLoader (window, content_json);

            update_recent_list.begin ();
            debug ("Version from file: %s", content_json.get_string_member ("version"));
        } catch (Error e) {
            error ("Could not load file: %s", e.message);
        }
    }

    public void save_file () {
        try {
            var content = new FileFormat.JsonContent (window);

            content.save_content ();
            var json = content.finalize_content ();
            write_content_to_file (content_file, json);

            write_to_archive ();
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    public void close () {
        try {
            clean ();
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    public override void prepare () {
        base.prepare ();

        var base_path = unarchived_location.get_path ();
        pictures_folder = File.new_for_path (Path.build_filename (base_path, "Pictures"));
        thumbnails_folder = File.new_for_path (Path.build_filename (base_path, "Thumbnails"));

        make_dir (pictures_folder);
        make_dir (thumbnails_folder);

        content_file = File.new_for_path (Path.build_filename (base_path, "content.json"));

        make_file (content_file);
    }

    /**
     * Update the GSettings array of recently opened files.
     */
    private async void update_recent_list () {
        string[] array = {};
        // Add the last opened file always on top.
        array += path;

        for (var i = 0; i <= settings.recently_opened.length; i++) {
            // Skip if the record is empty.
            if (settings.recently_opened[i] == null) {
                continue;
            }

            // If the file doesn't exist anymore, remove it from the list.
            var file = File.new_for_path (settings.recently_opened[i]);
            if (!file.query_exists ()) {
                continue;
            }

            // Don't store more than 10 files.
            if (i >= 9) {
                break;
            }

            // If the same file was already in the list, don't save it again.
            if (path == settings.recently_opened[i]) {
                continue;
            }

            array += settings.recently_opened[i];
        }

        settings.set_strv ("recently-opened", array);
    }
}
