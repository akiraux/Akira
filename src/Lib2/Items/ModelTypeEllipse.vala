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

public class Akira.Lib2.Items.ModelTypeEllipse : ModelType {
    public static ModelInstance minimal_ellipse () {
        return default_ellipse (
            new Lib2.Components.Coordinates (0.5, 0.5),
            new Lib2.Components.Size (1, 1, false),
            null,
            null
        );
    }

    public static ModelInstance default_ellipse (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        var new_item = new ModelInstance (-1, new ModelTypeEllipse ());
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.borders = borders;
        new_item.components.fills = fills;
        new_item.components.transform = Lib2.Components.Components.default_transform ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        return new_item;
    }

    public override string name_id { get { return "ellipse"; } }

    public override void construct_canvas_item (ModelInstance instance, Goo.Canvas canvas) {
        var radius_x = instance.components.size.width / 2.0;
        var radius_y = instance.components.size.height / 2.0;
        instance.drawable = new Drawables.DrawableEllipse (canvas.get_root_item (), 0, 0, radius_x, radius_y);
    }

    public override void component_updated (ModelInstance instance, Lib2.Components.Component.Type type) {
        switch (type) {
            case Lib2.Components.Component.Type.COMPILED_BORDER:
                if (!instance.compiled_border.is_visible) {
                    instance.drawable.line_width = 0;
                    instance.drawable.stroke_color_rgba = 0;
                    break;
                }

                // The "line-width" property expects a DOUBLE type, but we don't support subpixels
                // so we always handle the border size as INT, therefore we need to type cast it here.
                instance.drawable.line_width = (double) instance.compiled_border.size;
                instance.drawable.stroke_color_gdk_rgba = instance.compiled_border.color;
                break;
            case Lib2.Components.Component.Type.COMPILED_FILL:
                if (!instance.compiled_fill.is_visible) {
                    instance.drawable.fill_color_rgba = 0;
                    break;
                }

                instance.drawable.fill_color_gdk_rgba = instance.compiled_fill.color;
                break;
            case Lib2.Components.Component.Type.COMPILED_GEOMETRY:
                instance.drawable.set ("radius-x", instance.components.size.width / 2.0);
                instance.drawable.set ("radius-y", instance.components.size.height / 2.0);
                instance.drawable.set_transform (instance.compiled_geometry.transformation_matrix);
                break;
        }
    }
}
