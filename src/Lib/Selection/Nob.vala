/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Selection.Nob : Goo.CanvasRect {
    public const double NOB_SIZE = 10;
    public const double LINE_WIDTH = 1;

    public Utils.Nobs.Nob handle_id;

    private double nob_size;
    public double center_x;
    public double center_y;

    public Nob (Goo.CanvasItem? root, Utils.Nobs.Nob _handle_id) {
        Object (
            parent: root
        );

        handle_id = _handle_id;
        can_focus = false;

        set_rectangle ();
    }

    /*
     * Returns true if position is within a circular area around center.
     */
    public bool hit_test (double x, double y, double scale) {
        double xd = center_x - x;
        double yd = center_y - y;
        double dist = GLib.Math.sqrt (xd * xd + yd * yd);
        return (dist <= (NOB_SIZE / scale));
    }

    public void update_state (Cairo.Matrix matrix, double new_x, double new_y, bool visible) {
        matrix.x0 = new_x;
        matrix.y0 = new_y;
        set_transform (matrix);
        center_x = new_x;
        center_y = new_y;

        line_width = LINE_WIDTH / canvas.scale;
        nob_size = NOB_SIZE / canvas.scale;

        set ("line-width", line_width);
        set ("x", - nob_size / 2.0);
        set ("y", - nob_size / 2.0);
        set ("height", nob_size);
        set ("width", nob_size);

        this.set (
            "visibility",
            visible ? Goo.CanvasItemVisibility.VISIBLE: Goo.CanvasItemVisibility.HIDDEN
        );
    }

    /*
     * Updates the sate using global coordinates, and a local rotation
     */
    public void update_global_state (double new_x, double new_y, double rotation, bool visible) {
        var tr = Cairo.Matrix.identity ();
        tr.x0 = new_x;
        tr.y0 = new_y;
        tr.rotate (rotation);
        set_transform (tr);

        center_x = new_x;
        center_y = new_y;

        line_width = LINE_WIDTH / canvas.scale;
        nob_size = NOB_SIZE / canvas.scale;

        set ("line-width", line_width);
        set ("x", - nob_size / 2.0);
        set ("y", - nob_size / 2.0);
        set ("height", nob_size);
        set ("width", nob_size);

        this.set (
            "visibility",
            visible ? Goo.CanvasItemVisibility.VISIBLE: Goo.CanvasItemVisibility.HIDDEN
        );
    }

    public void set_rectangle () {
        x = 0;
        y = 0;

        update_state (Cairo.Matrix.identity (), 0, 0, false);

        if (handle_id == Utils.Nobs.Nob.ROTATE) {
            set ("radius-x", nob_size);
            set ("radius-y", nob_size);
        }

        set ("fill-color", "#fff");
        set ("stroke-color", "#41c9fd");
    }
}
