/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Drawable for groups.
 */
public class Akira.Drawables.DrawableGroup : Drawable {

    public DrawableGroup () {}

    public override void simple_create_path (Cairo.Context context) {}

    public override void paint (Cairo.Context context, Geometry.Rectangle target_bounds, double scale, Drawable.DrawType draw_type) {}

    /*
     * Hover paint method for the drawable.
     */
    public override void paint_hover (
        Cairo.Context context,
        Gdk.RGBA color,
        double line_width,
        Geometry.Rectangle target_bounds,
        double scale
    ) {
        context.save ();
        Cairo.Matrix global_transform = context.get_matrix ();

        // We apply the item transform before creating the path.
        Cairo.Matrix tr = transform;
        context.transform (tr);

        context.rectangle (bounds.left, bounds.top, bounds.width, bounds.height);

        context.set_line_width (line_width / scale);
        context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        context.set_matrix (global_transform);
        context.stroke ();

        context.restore ();

        // Very important to initialize new path.
        context.new_path ();
    }
}
