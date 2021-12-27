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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerAnchor : ViewLayer {
    public const double UI_LINE_WIDTH = 4.0;

    private Drawables.Drawable? drawable = null;
    private Drawables.Drawable? old_drawable = null;
    private Geometry.Rectangle last_drawn_bb = Geometry.Rectangle.empty ();

    public ViewLayerAnchor () {}

    public void add_drawable (Drawables.Drawable? new_drawable) {
        if (new_drawable == drawable) {
            return;
        }

        old_drawable = drawable;
        drawable = new_drawable;
        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (canvas == null || drawable == null) {
            return;
        }
        var color = Gdk.RGBA () { red = 0.25, green = 0.79, blue = 0.98, alpha = 1.0 };
        drawable.paint_hover (context, color, UI_LINE_WIDTH, target_bounds, scale);
        last_drawn_bb = drawable.bounds;
    }

    public override void update () {
        if (canvas == null) {
            return;
        }

        if (old_drawable != null) {
            canvas.request_redraw (last_drawn_bb);
            old_drawable = null;
        }

        if (drawable != null) {
            canvas.request_redraw (drawable.bounds);
        }
    }
}
