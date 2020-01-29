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

public struct Point {
    double x;
    double y;
}

public class Akira.Lib.Selection.SelectionRect : Goo.CanvasRect {
    public const double LINE_WIDTH = 1;

    private Goo.CanvasBounds bounds;
    public bool dragging = false;
    private bool has_end_point = false;

    public SelectionRect (Goo.CanvasItem? root) {
        Object (
            parent: root
        );

        set_rectangle ();
        width = 0;
        height = 0;
    }

    public void set_start_point (double sx, double sy) {
        bounds.x1 = sx;
        bounds.y1 = sy;
        dragging = true;
        has_end_point = false;
        update_bounds ();
    }

    public void set_end_point (double sx, double sy) {
        bounds.x2 = sx;
        bounds.y2 = sy;
        has_end_point = true;
        update_bounds ();
    }

    public void hide () {
        dragging = false;
        has_end_point = false;
        update_bounds ();
    }

    private void update_bounds () {
        if (!dragging || !has_end_point) {
            width = height = 0;
            return;
        }

        if (bounds.x1 > bounds.x2) {
            x = bounds.x2;
            width = bounds.x1 - bounds.x2;
        } else {
            x = bounds.x1;
            width = bounds.x2 - bounds.x1;
        }

        if (bounds.y1 > bounds.y2) {
            y = bounds.y2;
            height = bounds.y1 - bounds.y2;
        } else {
            y = bounds.y1;
            height = bounds.y2 - bounds.y1;
        }
    }

    private void update_size () {
        line_width = LINE_WIDTH;
        set ("line-width", line_width);
    }

    public void set_rectangle () {
        x = 50000;
        y = 50000;

        update_size ();

        set ("fill-color", "#00000000");
        set ("stroke-color", "#000000");
    }
}