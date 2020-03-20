/*
 * Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
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
