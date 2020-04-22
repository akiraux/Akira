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
    public weak Akira.Window window { get; construct; }

    const string FILENAME = "/akira-%s-img-%u.%s";
    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public ImageManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    public async Gdk.Pixbuf get_pixbuf (File file, int width = -1, int height = -1) throws Error {
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

    public string get_extension (GLib.File file) {
        var parts = file.get_basename ().split (".");
        if (parts.length > 1) {
            return parts[parts.length - 1];
        } else {
            return "png";
        }
    }

    // public string file_to_base64 (File file) {
    //     uint8[] data;

    //     try {
    //         FileUtils.get_data (file.get_path (), out data);
    //     } catch (Error e) {
    //         warning ("Could not get file data: %s", e.message);
    //     }

    //     return Base64.encode (data);
    // }

    // public void base64_to_file (string filename, string base64_data) {
    //     var data = Base64.decode (base64_data);
    //     try {
    //        FileUtils.set_data (filename, data);
    //     } catch (Error e) {
    //         warning ("Could not save data to file: %s", e.message);
    //     }
    // }
}
