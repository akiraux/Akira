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

public class Akira.Lib2.Items.ModelTypeArtboard : Object, ModelType<ModelTypeArtboard> {
    //Goo.CanvasItem background;

    public static ModelInstance default_artboard (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size
    ) {
        var new_item = new ModelInstance (-1, new ModelTypeArtboard ());
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.transform = Lib2.Components.Components.default_transform ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        new_item.components.fills = Lib2.Components.Fills.single_color (Lib2.Components.Color (1.0, 1.0, 1.0, 1.0));

        var layout_data = Components.Layout.LayoutData () {
            can_rotate = true,
            dilated_resize = false,
            clips_children = true
        };
        new_item.components.layout = new Components.Layout (layout_data);
        return new_item;
    }

    public ModelType copy () {
        return new ModelTypeArtboard ();
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
        instance.drawable = new Drawables.DrawableArtboard (
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
                instance.drawable.line_width = 0;
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
                instance.drawable.center_x = - (w / 2.0);
                instance.drawable.center_y = - (h / 2.0);
                instance.drawable.set_transform (instance.compiled_geometry.transformation_matrix);
                break;
        }
    }

    public bool is_group () { return true; }
}
