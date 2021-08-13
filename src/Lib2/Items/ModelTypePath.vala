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

public class Akira.Lib2.Items.ModelTypePath : ModelType {
    public static ModelInstance minimal_rect () {
        return default_path (
            new Lib2.Components.Coordinates (0.5, 0.5),
            null,
            null
        );
    }

    public static ModelInstance default_path (
        Lib2.Components.Coordinates center,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        var new_item = new ModelInstance (-1, new ModelTypePath ());
        new_item.components.center = center;
        new_item.components.borders = borders;
        new_item.components.fills = fills;
        new_item.components.transform = Lib2.Components.Components.default_transform ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        new_item.components.path = new Lib2.Components.Path.from_single_point (Akira.Geometry.Point (center.x, center.y), false);
        return new_item;
    }

    public override Components.CompiledGeometry compile_geometry (
        Components.Components? components,
        Lib2.Items.ModelNode? node
    ) {
        return new Components.CompiledGeometry.from_components (components, node, true);
    }


    public override void construct_canvas_item (ModelInstance instance, Goo.Canvas canvas) {
        instance.drawable = new Drawables.DrawablePath (
            canvas.get_root_item (),
            (instance.components.path == null) ? null : instance.components.path.data
        );
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
                instance.drawable.center_x = -instance.compiled_geometry.source_width / 2.0;
                instance.drawable.center_y = -instance.compiled_geometry.source_height / 2.0;
                instance.drawable.set_transform (instance.compiled_geometry.transformation_matrix);
                break;
        }
    }
}
