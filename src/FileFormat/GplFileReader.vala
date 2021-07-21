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
 * Authored by: Abdallah "Abdallah-Moh" Mohammad <abdallah.mam29@gmail.com>
*/

public class Akira.FileFormat.GplFileReader {
    public static GplObject read_file (string file_path) {
        var gpl_colors = new GplObject ();

        try {
            string file_content = "";
            GLib.FileUtils.get_contents (file_path, out file_content);

            var lines = file_content.split ("\n");

            if (!lines[0].contains ("GIMP Palette")) {
                print ("File is Corrupted");
            }

            else {
                gpl_colors.name = lines[1].replace ("Name:", "").replace (" ", "");

                // We used the index 3 because that is where the colors start from
                for (int i = 3; i < lines.length; i++) {
                    string line = lines[i];
                    var parsed_line = /\s\s+/.split (line);
                    var rgba = Gdk.RGBA ();
                    rgba.parse ("rgb(" + parsed_line[0] + "," + parsed_line[1] + "," + parsed_line[2] + ")");
                    gpl_colors.colors.add (rgba);
                }

            }
        } catch (Error e) {
            error (e.message);
        }
        return gpl_colors;
    }
}
