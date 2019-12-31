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
public class Akira.Lib.Selection.Nob : Goo.CanvasRect {

    public Managers.NobManager.Nob handle_id;

    public double scale { get; set; default = 1.0; }

    public Nob (
        Goo.CanvasItem? root,
        Managers.NobManager.Nob _handle_id,
        double nob_size,
        double radius,
        double canvas_scale
    ) {
        Object (
            parent: root
        );

        handle_id = _handle_id;
        scale = canvas_scale;

        set_rectangle (0, 0, nob_size, radius);
    }

    construct {
        can_focus = false;
    }

    public void set_rectangle (double _x, double _y, double nob_size, double _radius) {
        height = nob_size / scale;
        width = nob_size / scale;
        x = 0;
        y = 0;

        set ("radius-x", _radius);
        set ("radius-y", _radius);
        set ("line-width", 2.0);
        set ("fill-color", "#fff");
        set ("stroke-color", "#41c9fd");
    }
}
