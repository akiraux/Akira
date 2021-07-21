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

public class Akira.FileFormat.GplObject {
    public string name { get; set;}
    public Gee.ArrayList<Gdk.RGBA?> colors { get; set; }

    public GplObject (string? name = "") {
        this.name = _name;
        this.colors = new Gee.ArrayList<Gdk.RGBA?> ();
    }
}
