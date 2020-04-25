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
    public GLib.File file { get; set; }

    // Save the generated Pixbuf for later reference.
    public Gdk.Pixbuf pixbuf;
    // The unique name of the loaded image, including the current timestamp.
    public string filename;

    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public ImageManager (GLib.File _file, int id) {
        file = _file;

        var timestamp = new GLib.DateTime.now_utc ();
        filename = ("akira-img-%i-%s.%s").printf (
            id,
            timestamp.to_unix ().to_string (),
            Utils.Image.get_extension (file)
        );
    }

    /**
     * Initialize a new ImageManager from a previously saved file.
     * We use this to avoid changing the filename which should be unique.
     *
     * @param {GLib.File} _file - The file loaded from the saved archive.
     * @param {string} _filename - The original filename of the saved file.
     */
    public ImageManager.from_archive (GLib.File _file, string _filename) {
        file = _file;
        filename = _filename;
    }

    /**
     * Generate the Pixbuf from the given file. This method is also called to
     * resample the quality of the pixbuf when the image is resized.
     *
     * @param {int} width - The requested width for the resample.
     * @param {int} height - The requested height for the resample.
     * @return Gdk.Pixbuf
     */
    public async Gdk.Pixbuf get_pixbuf (int width = -1, int height = -1) throws Error {
        FileInputStream stream;

        try {
            stream = yield file.read_async ();
        } catch (Error e) {
            throw e;
        }

        if (width != -1 && height != -1) {
            try {
                pixbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async (stream, width, height, false);
                return pixbuf;
            } catch (Error e) {
                throw e;
            }
        } else {
            try {
                pixbuf = yield new Gdk.Pixbuf.from_stream_async (stream);
                return pixbuf;
            } catch (Error e) {
                throw e;
            }
        }
    }
}
