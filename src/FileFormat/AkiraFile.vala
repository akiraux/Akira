/*
 *  Copyright (C) 2019 Felipe Escoto <felescoto95@hotmail.com>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

public class Akira.FileFormat.AkiraFile : Akira.FileFormat.ZipArchiveHandler {

    public File pictures_folder { get; private set; }
    public File thumbnails_folder { get; private set; }
    public File objects_folder { get; private set; }
    public File artbords_folder { get; private set; }

    public FileFormat.Version version_data { get; private set; }

    private File content_file { get; private set; }
    private File version_file { get; private set; }

    public AkiraFile (File _gzipped_file) {
        Object (opened_file: _gzipped_file.dup ());
    }

    public void load_file () {
        try {
            open_archive ();

            var version_json = get_content_as_json (version_file);
            version_data = new FileFormat.Version (version_json != null ? version_json : new Json.Object ());

            debug ("Version from file: %s\n", version_data.file_version);
        } catch (Error e) {
            error ("Could not load file: %s\n", e.message);
        }
    }

    public void save_file () {
        try {
            version_data.file_version = Constants.VERSION;

            write_content_to_file (version_file, version_data.to_string (false));
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
        objects_folder = File.new_for_path (Path.build_filename (base_path, "Objects"));
        artbords_folder = File.new_for_path (Path.build_filename (base_path, "Artboards"));

        make_dir (pictures_folder);
        make_dir (thumbnails_folder);
        make_dir (objects_folder);
        make_dir (artbords_folder);

        content_file = File.new_for_path (Path.build_filename (base_path, "content.json"));
        version_file = File.new_for_path (Path.build_filename (base_path, "version.json"));

        make_file (content_file);
        make_file (version_file);
    }
}