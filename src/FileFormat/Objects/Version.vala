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

 /**
  * Contains the last version of Akira that opened the file.
  *
  * In the future, we may want to prevent the app from opening a file
  * version bigger than the app version. It can also help us debug
  * when users post the terminal output.
  */
public class Akira.FileFormat.Version : FileFormat.JsonObject {
    public string file_version { get; set; default = "0.0.0"; }

    public Version (Json.Object object) {
        Object (object: object);
        connect_signals ();
    }
}
