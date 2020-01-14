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
    public const double NOB_SIZE = 10;
    public const double LINE_WIDTH = 1;

    public Managers.NobManager.Nob handle_id;

    public double scale { get; set; default = 1.0; }

    private double nob_size;
    private double radius;

    public Nob (
        Goo.CanvasItem? root,
        Managers.NobManager.Nob _handle_id,
        double current_scale
    ) {
        Object (
            parent: root
        );

        handle_id = _handle_id;
        scale = current_scale;

        set_rectangle ();

        (root.get_canvas () as Akira.Lib.Canvas).window.event_bus.zoom.connect (on_zoom);
    }

    construct {
        can_focus = false;
    }

    private void update_size () {
        line_width = LINE_WIDTH / scale;
        nob_size = NOB_SIZE / scale;

        set ("line-width", line_width);
        set ("height", nob_size);
        set ("width", nob_size);
    }

    private void on_zoom (double current_scale) {
        scale = current_scale;

        update_size ();
    }

    public void set_rectangle () {
        x = 0;
        y = 0;

        update_size ();

        radius = handle_id == 8 ? nob_size : 0;

        set ("radius-x", radius);
        set ("radius-y", radius);
        set ("fill-color", "#fff");
        set ("stroke-color", "#41c9fd");
    }
}
