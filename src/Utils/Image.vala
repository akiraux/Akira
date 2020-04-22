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

public class Akira.Utils.Image : Object {
    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    /**
    * Check if the filename has a picture file extension.
    */
    public static bool is_valid_image (GLib.File file) {
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

    /**
     * Return only the file extension, PNG if not extension was found.
     */
    public static string get_extension (GLib.File file) {
        var parts = file.get_basename ().split (".");

        return parts.length > 1 ? parts[parts.length - 1] : "png";
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
