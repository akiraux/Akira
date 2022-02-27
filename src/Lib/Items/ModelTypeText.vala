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

public class Akira.Lib.Items.ModelTypeText : ModelType {
    public static ModelInstance minimal_text () {
        return default_text (
            new Lib.Components.Coordinates (0.5, 0.5),
            new Lib.Components.Size (1, 1, false),
            new Lib.Components.Text ("Akira")
        );
    }

    public static ModelInstance default_text (
        Lib.Components.Coordinates center,
        Lib.Components.Size size,
        Lib.Components.Text text
    ) {
        var new_item = new ModelInstance (-1, new ModelTypeText ());
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.text = text;
        new_item.components.transform = Lib.Components.Components.default_transform ();
        new_item.components.flipped = Lib.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib.Components.Components.default_border_radius ();
        new_item.components.name = Lib.Components.Components.default_name ();
        new_item.components.layer = Lib.Components.Components.default_layer ();
        return new_item;
    }

    public override string name_id { get { return "text"; } }

    public override void construct_canvas_item (ModelInstance instance) {
        var w = instance.components.size.width;
        var h = instance.components.size.height;
        string text = (instance.components.text == null) ? "" : instance.components.text.text;
        instance.drawable = new Drawables.DrawableText (
            - (w / 2.0),
            - (h / 2.0),
            w,
            h,
            text
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
                instance.drawable.width = instance.components.size.width;
                instance.drawable.height = instance.components.size.height;
                instance.drawable.transform = instance.compiled_geometry.transformation_matrix;
                break;
            default:
                break;
        }
    }
}
