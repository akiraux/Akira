/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
 */

 public class Akira.Utils.Font : Object {
    private const string[] ACCEPTED_TYPES = {
        "font/ttf",
        "font/fot",
        "font/otf",
        "font/woff",
    };

    public static bool is_valid_font (File file) {
        try {
            var file_info = file.query_info ("standard::*", 0);

            // Check for correct file type, don't try to load directories.
            if (file_info.get_file_type () != GLib.FileType.REGULAR) {
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

    public static string[] get_fonts () {
        string[] fonts = {};
        // Directory Paths to search for fonts
        string home_dir = GLib.Environment.get_home_dir ();
        string[] font_paths = {home_dir + "/.local/share/fonts", "/usr/share/fonts"};

        foreach (var font_path in font_paths) {
            fonts = get_font_from_path (font_path, fonts);
        }

        return fonts;
    }

    public static string[] get_font_from_path (string font_path, string[] fonts) {
        string[] fonts_found = fonts;
        var file_name = "";
        try {
            var font_dir = Dir.open (font_path);
            while ((file_name = font_dir.read_name ()) != null) {
                string path = Path.build_filename (font_path, file_name);
                if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                    string name_of_font = file_name.split ("-")[0].split (".")[0];
                    if (!is_string_in_array (name_of_font, fonts_found) && is_valid_font (File.new_for_path (path))) {
                        fonts_found += name_of_font;
                    }
                }
                else if (FileUtils.test (path, FileTest.IS_DIR)) {
                    fonts_found = get_font_from_path (path, fonts_found);
                }
            }
        } catch (FileError err) {
            print (err.message);
        }
        return fonts_found;
    }

    public static bool is_string_in_array (string value, string [] array) {
        foreach (var font_item in array) {
            if (font_item == value) {
                return true;
            }
        }
        return false;
    }
}
