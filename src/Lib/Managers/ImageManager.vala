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
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ImageManager : Object {
    public GLib.File file { get; construct; }

    //  const string FILENAME = "/akira-%s-img-%u.%s";

    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public ImageManager (GLib.File file) {
        Object (file: file);
    }

    public async Gdk.Pixbuf get_pixbuf (int width = -1, int height = -1) throws Error {
        FileInputStream stream;

        try {
            stream = yield file.read_async ();
        } catch (Error e) {
            throw e;
        }

        if (width != -1 && height != -1) {
            try {
                return yield new Gdk.Pixbuf.from_stream_at_scale_async (stream, width, height, false);
            } catch (Error e) {
                throw e;
            }
        } else {
            try {
                return yield new Gdk.Pixbuf.from_stream_async (stream);
            } catch (Error e) {
                throw e;
            }
        }
    }

    // private string data_to_file (string data) {
    //     var filename =
    //         Environment.get_tmp_dir () + FILENAME.printf (
    //             Environment.get_user_name (),
    //             file_id, image_extension
    //         );
    //     base64_to_file (filename, data);

    //     return filename;
    // }

    public string file_to_base64 () {
       uint8[] data;

       try {
           FileUtils.get_data (file.get_path (), out data);
       } catch (Error e) {
           warning ("Could not get file data: %s", e.message);
       }

       return Base64.encode (data);
    }

    // public void base64_to_file (string filename, string base64_data) {
    //     var data = Base64.decode (base64_data);
    //     try {
    //        FileUtils.set_data (filename, data);
    //     } catch (Error e) {
    //         warning ("Could not save data to file: %s", e.message);
    //     }
    // }
}
