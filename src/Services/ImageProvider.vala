/*
* Copyright (c) 2020 Adam Bieńkowski
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Adam Bieńkowski <donadigos159@gmail.com>
*/

public interface Akira.Services.ImageProvider : Object {
    public abstract async Gdk.Pixbuf get_pixbuf (int width = -1, int height = -1) throws Error;
}

public class Akira.Services.FileImageProvider : ImageProvider, Object {
    public File file { get; construct; }

    public FileImageProvider (File file) {
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
}