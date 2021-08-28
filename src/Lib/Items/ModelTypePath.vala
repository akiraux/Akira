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

public class Akira.Lib.Items.ModelTypePath : ModelType {
    public static ModelInstance minimal_rect () {
        return default_path (
            new Lib.Components.Coordinates (0.5, 0.5),
            null,
            null
        );
    }

    public static ModelInstance default_path (
        Lib.Components.Coordinates center,
        Lib.Components.Borders? borders,
        Lib.Components.Fills? fills
    ) {
        var new_item = new ModelInstance (-1, new ModelTypePath ());
        new_item.components.center = center;
        new_item.components.borders = borders;
        new_item.components.fills = fills;
        new_item.components.transform = Lib.Components.Components.default_transform ();
        new_item.components.flipped = Lib.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib.Components.Components.default_border_radius ();
        new_item.components.path = new Lib.Components.Path.from_single_point (
            Akira.Geometry.Point (center.x, center.y),
            false
        );
        new_item.components.size = new Lib.Components.Size (1, 1, false);
        return new_item;
    }

    public override string name_id { get { return "path"; } }

    public override Components.CompiledGeometry compile_geometry (
        Components.Components? components,
        Lib.Items.ModelNode? node
    ) {
        return new Components.CompiledGeometry.from_components (components, node, true);
    }

    public override void construct_canvas_item (ModelInstance instance) {
        instance.drawable = new Drawables.DrawablePath (
            (instance.components.path == null) ? null : instance.components.path.data
        );
    }

    public override void component_updated (ModelInstance instance, Lib.Components.Component.Type type) {
        switch (type) {
            case Lib.Components.Component.Type.COMPILED_BORDER:
                if (!instance.compiled_border.is_visible) {
                    instance.drawable.line_width = 0;
                    instance.drawable.stroke_rgba = Gdk.RGBA () { alpha = 0 };
                    break;
                }

                // The "line-width" property expects a DOUBLE type, but we don't support subpixels
                // so we always handle the border size as INT, therefore we need to type cast it here.
                instance.drawable.line_width = (double) instance.compiled_border.size;
                instance.drawable.stroke_rgba = instance.compiled_border.color;
                break;
            case Lib.Components.Component.Type.COMPILED_FILL:
                if (!instance.compiled_fill.is_visible) {
                    instance.drawable.fill_rgba = Gdk.RGBA () { alpha = 0 };
                    break;
                }

                instance.drawable.fill_rgba = instance.compiled_fill.color;
                break;
            case Lib.Components.Component.Type.COMPILED_GEOMETRY:
                instance.drawable.center_x = -instance.compiled_geometry.source_width / 2.0;
                instance.drawable.center_y = -instance.compiled_geometry.source_height / 2.0;
                instance.drawable.transform = instance.compiled_geometry.transformation_matrix;
                break;
        }
    }
}
