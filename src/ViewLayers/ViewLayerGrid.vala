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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerGrid : ViewLayer {
    private const double UI_LINE_WIDTH = 1.0;

    private Geometry.Rectangle bounds;
    private Gdk.RGBA p_color { get; set; default = Gdk.RGBA () { alpha = 1.0 }; }
    private double p_spacing { get; set; default = 1.0; }

    public double spacing {
        get { return p_spacing; }
        set { inner_set_spacing (value); }
    }

    public Gdk.RGBA color {
        get { return p_color; }
        set { inner_set_color (value); }
    }


    public ViewLayerGrid (double x, double y, double width, double height) {
        bounds = Geometry.Rectangle.with_coordinates (x, y, x + width, y + height);
        var rgba = Gdk.RGBA ();
        rgba.parse (settings.grid_color);
        inner_set_color (rgba);
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (canvas == null || scale < 5) {
            return;
        }

        context.save ();

        var viewport_bounds = canvas.viewport_bounds_in_user ();

        paint_horizontal_lines (context, target_bounds, viewport_bounds, scale);
        paint_vertical_lines (context, target_bounds, viewport_bounds, scale);

        context.restore ();
        context.new_path ();
    }

    private void paint_horizontal_lines (
        Cairo.Context context,
        Geometry.Rectangle target_bounds,
        Geometry.Rectangle viewport_bounds,
        double scale
    ) {
        if (spacing <= 0) {
            return;
        }

        context.save ();
        context.set_line_width (UI_LINE_WIDTH / scale);
        context.set_line_cap (Cairo.LineCap.BUTT);
        context.set_source_rgba (color.red, color.green, color.blue, 0.2);

        var y = viewport_bounds.top;

        if (target_bounds.top - spacing > viewport_bounds.top) {
            y += GLib.Math.floor ((target_bounds.top - viewport_bounds.top) / spacing) * spacing;
        }

        y += spacing * 0.00001;

        var max_y = double.min (target_bounds.bottom + spacing, viewport_bounds.bottom);

        while (y <= max_y) {
            context.move_to (viewport_bounds.left, y);
            context.line_to (viewport_bounds.right, y);
            context.stroke ();
            y += spacing;
        }

        context.restore ();
    }

    private void paint_vertical_lines (
        Cairo.Context context,
        Geometry.Rectangle target_bounds,
        Geometry.Rectangle viewport_bounds,
        double scale
    ) {
        if (spacing <= 0) {
            return;
        }

        context.save ();
        context.set_line_width (UI_LINE_WIDTH / scale);
        context.set_line_cap (Cairo.LineCap.BUTT);
        context.set_source_rgba (color.red, color.green, color.blue, 0.2);

        var x = viewport_bounds.left * 0.00001;

        if (target_bounds.left - spacing > viewport_bounds.left) {
            x += GLib.Math.floor ((target_bounds.left - viewport_bounds.left) / spacing) * spacing;
        }

        x += spacing * 0.00001;

        var max_x = double.min (target_bounds.right + spacing, viewport_bounds.right);

        while (x <= max_x) {
            context.move_to (x, viewport_bounds.top);
            context.line_to (x, viewport_bounds.bottom);
            context.stroke ();
            x += spacing;
        }

        context.restore ();
    }

    public override void update () {
        if (canvas == null) {
            return;
        }

        canvas.request_redraw (bounds);
    }

    private void inner_set_spacing (double new_spacing) {
        p_spacing = new_spacing;
        update ();
    }

    private void inner_set_color (Gdk.RGBA new_color) {
        p_color = new_color;
        update ();
    }

}
