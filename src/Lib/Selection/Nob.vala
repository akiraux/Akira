/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
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
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
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