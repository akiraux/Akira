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

public class Akira.Lib2.Items.ModelTypeRect : Object, ModelType<ModelTypeRect> {
    public static ModelInstance minimal_rect () {
        return default_rect (
            new Lib2.Components.Coordinates (0.5, 0.5),
            new Lib2.Components.Size (1, 1, false),
            null,
            null
        );
    }

    public static ModelInstance default_rect (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        var new_item = new ModelInstance (-1, new ModelTypeRect ());
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.borders = borders;
        new_item.components.fills = fills;
        new_item.components.transform = Lib2.Components.Components.default_transform ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        return new_item;
    }

    public ModelType copy () {
        return new ModelTypeRect ();
    }

    public Components.CompiledFill compile_fill (Components.Components? components, Lib2.Items.ModelNode? node) {
        return Components.CompiledFill.compile (components, node);
    }

    public Components.CompiledBorder compile_border (Components.Components? components, Lib2.Items.ModelNode? node) {
        return Components.CompiledBorder.compile (components, node);
    }

    public Components.CompiledGeometry compile_geometry (
        Components.Components? components,
        Lib2.Items.ModelNode? node
    ) {
        return new Components.CompiledGeometry.from_components (components, node);
    }

    public void construct_canvas_item (ModelInstance instance, Goo.Canvas canvas) {
        var w = instance.components.size.width;
        var h = instance.components.size.height;
        instance.drawable = new Drawables.DrawableRect (
            canvas.get_root_item (),
            - (w / 2.0),
            - (h / 2.0),
            w,
            h
        );
    }

    public void component_updated (ModelInstance instance, Lib2.Components.Component.Type type) {
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
                var w = instance.components.size.width;
                var h = instance.components.size.height;
                instance.drawable.set ("width", w);
                instance.drawable.set ("height", h);
                instance.drawable.set_transform (instance.compiled_geometry.transformation_matrix);
                break;
        }
    }

    public bool is_group () { return false; }
}
