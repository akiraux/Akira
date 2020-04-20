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

public class Akira.Lib.Managers.ImageManager : Object {
    const string FILENAME = "/akira-%s-img-%u.%s";

    private uint file_id;

    public bool valid = false;
    private string? base64_image = null;
    public string image_extension { get; private set; }

    private string _url = "";
    public string url {
        get {
            return _url;
        } set {
            _url = value;
            var file = File.new_for_path (value);
            valid = (file.query_exists () && is_valid_image (file));
        }
    }

    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public ImageManager.from_data (string _extension, string _base64_data) {
        file_id += 1;
        image_extension = _extension != "" ? _extension : "png";
        base64_image = _base64_data;
        url = data_to_file (_base64_data);
    }

    public ImageManager.from_file (File file) {
        file_id += 1;
        replace (file);
    }

    public void replace (File file) {
        image_extension = get_extension (file.get_basename ());
        base64_image = file_to_base64 (file);
        url = data_to_file (base64_image);
    }

    public string serialize () {
        return """"image":"%s", "image-data":"%s" """.printf (image_extension, base64_image);
    }

    private string get_extension (string filename) {
        var parts = filename.split (".");
        if (parts.length > 1) {
            return parts[parts.length - 1];
        } else {
            return "png";
        }
    }

    private string data_to_file (string data) {
        var filename =
            Environment.get_tmp_dir () + FILENAME.printf (
                Environment.get_user_name (),
                file_id, image_extension
            );
        base64_to_file (filename, data);

        return filename;
    }

    /**
     * Check if the filename has a picture file extension.
     */
    public bool is_valid_image (GLib.File file) {
        try {
            var file_info = file.query_info ("standard::*", 0);

            // Check for correct file type, don't try to load directories.
            if (file_info.get_file_type () != GLib.FileType.REGULAR) {
                return false;
            }
            try {
                var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());
                var width = pixbuf.get_width ();
                var height = pixbuf.get_height ();

                if (width < 1 || height < 1) return false;
            } catch (Error e) {
                warning ("Invalid image loaded: %s", e.message);
                return false;
            }

            foreach (var type in ACCEPTED_TYPES) {
                if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                    return true;
                }
            }
        } catch (Error e) {
            warning ("Could not get file info: %s", e.message);
        }

        return false;
    }

    public string file_to_base64 (File file) {
        uint8[] data;

        try {
            FileUtils.get_data (file.get_path (), out data);
        } catch (Error e) {
            warning ("Could not get file data: %s", e.message);
        }

        return Base64.encode (data);
    }

    public void base64_to_file (string filename, string base64_data) {
        var data = Base64.decode (base64_data);
        try {
           FileUtils.set_data (filename, data);
        } catch (Error e) {
            warning ("Could not save data to file: %s", e.message);
        }
    }
}
