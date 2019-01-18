/*
* Copyright (c) 2018 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Services.Settings : Granite.Services.Settings {
    public int pos_x { get; set; }
    public int pos_y { get; set; }
    public int window_width { get; set; default = 1000; }
    public int window_height { get; set; default = 600; }
    public int right_paned { get; set; default = 2000; }
    public int left_paned { get; set; default = 220; }
    public bool dark_theme { get; set; }
    public bool open_quick { get; set; }

    public Settings () {
        base ("com.github.alecaddd.akira");
    }
}
