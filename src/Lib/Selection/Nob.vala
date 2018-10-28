/*
* Copyright (c) 2018 Alessandro Castellani (https://github.com/Alecaddd)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Alessandro Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Selection.Nob : Goo.CanvasItemSimple, Goo.CanvasItem {
    public double height { get; set; default = 10; }
    public double radius_x { get; set; }
    public double radius_y { get; set; }
    public double width { get; set; default = 10; }
    public double x { get; set; }
    public double y { get; set; }

    public string f_color { get; set; default = "#fff"; }
    public string s_color { get; set; default = "#41c9fd"; }
    public double s { get; set; default = 1.0; }

    public double scale { get; set; default = 1.0; }

    public Nob (Goo.CanvasItem? root) {
        set_rectangle (root, 0, 0);
    }

    public Nob.with_values (Goo.CanvasItem? root, double x, double y, double canvas_scale) {
        Object (parent: root);
        scale = canvas_scale;
        set_rectangle (root, x, y);
    }

    construct {
        can_focus = false;
    }

    public void set_rectangle (Goo.CanvasItem? root, double _x, double _y) {
        parent = root;
        height = height / scale;
        width = width / scale;
        x = _x - (width / 2);
        y = _y - (height / 2);
        line_width = s / scale;
        fill_color = "#fff";
        stroke_color = "#41c9fd";
    }
}