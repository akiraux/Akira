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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ExportAreaManager : Object {
    private const string COLOR = "#41c9fd";
    private const double LINE_WIDTH = 2.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }

    private double initial_event_x;
    private double initial_event_y;

    public ExportAreaManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    public Goo.CanvasRect create_area (Gdk.EventButton event) {
        var dash = new Goo.CanvasLineDash (2, 5.0, 5.0);
        var rgba_fill = Gdk.RGBA ();
        rgba_fill.parse (COLOR);
        rgba_fill.alpha = 0.1;
        uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);

        var area = new Goo.CanvasRect (
            null,
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            0.0, 0.0,
            "line-width", LINE_WIDTH,
            "stroke-color", COLOR,
            "line-dash", dash,
            "fill-color-rgba", fill_color_rgba,
            null
        );

        area.set ("parent", canvas.get_root_item ());
        area.can_focus = false;

        return area;
    }
}
