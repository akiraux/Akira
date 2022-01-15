/**
 * Copyright (c) 2021-2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 *              Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerMultiSelect : ViewLayer {
    private const double UI_LINE_WIDTH = 1.0;
    private Gdk.RGBA fill { get; default = Gdk.RGBA () { red = 0.25, green = 0.79, blue = 0.98, alpha = 0.4 }; }
    private Gdk.RGBA stroke {
        get {
            var color = fill;
            color.alpha = 1;
            return color;
        }
    }

    private Drawables.Drawable? drawable = null;
    private Drawables.Drawable? old_drawable = null;
    private Geometry.Rectangle last_drawn_bb = Geometry.Rectangle.empty ();
    private Gee.ArrayList<unowned Drawables.Drawable> found_drawables;

    private double initial_press_x;
    private double initial_press_y;

    public ViewLayerMultiSelect () {
        found_drawables = new Gee.ArrayList<unowned Drawables.Drawable> ();
    }

    public void create_region (Gdk.EventButton event) {
        initial_press_x = event.x;
        initial_press_y = event.y;

        drawable = new Drawables.DrawableRect (event.x, event.y, 0, 0);
    }

    public void update_region (double width, double height) {
        var center_x = initial_press_x + width / 2;
        var center_y = initial_press_y + height / 2;

        drawable.center_x = center_x;
        drawable.center_y = center_y;
        drawable.width = width;
        drawable.height = height;

        old_drawable = drawable;

        drawable.bounds = Geometry.Rectangle.with_coordinates (
            initial_press_x,
            initial_press_y,
            initial_press_x + width,
            initial_press_y + height
        );

        update ();
    }

    public void remove_region () {
        update ();
        drawable = null;
    }

    public Geometry.Rectangle? get_region_bounds () {
        return drawable.bounds;
    }

    public void update_found_drawables (Gee.ArrayList<unowned Drawables.Drawable> drawables) {
        found_drawables = drawables;
        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (canvas == null || drawable == null) {
            return;
        }

        drawable.fill_rgba = fill;
        drawable.line_width = UI_LINE_WIDTH / scale;
        drawable.stroke_rgba = stroke;
        drawable.paint (context, target_bounds, scale);

        last_drawn_bb = drawable.bounds;

        foreach (unowned var d in found_drawables) {
            d.paint_hover (context, stroke, UI_LINE_WIDTH, target_bounds, scale);
        }
    }

    public override void update () {
        if (canvas == null) {
            return;
        }

        if (old_drawable != null) {
            canvas.request_redraw (last_drawn_bb);
        }

        if (drawable != null) {
            canvas.request_redraw (drawable.bounds);
        }
    }
}
