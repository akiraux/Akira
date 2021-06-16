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

public class Akira.Lib2.Items.ModelTypeEllipse : Object, ModelType<ModelTypeEllipse> {
    public static ModelItem minimal_ellipse () {
        return default_ellipse (
            new Lib2.Components.Coordinates (0.5, 0.5),
            new Lib2.Components.Size (1, 1, false),
            null,
            null
        );
    }

    public static ModelItem default_ellipse (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        var new_item = new ModelItem ();
        new_item.components = new Lib2.Components.Components ();
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.borders = borders;
        new_item.components.fills = fills;
        new_item.components.rotation = Lib2.Components.Components.default_rotation ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        new_item.item_type = new ModelTypeEllipse ();
        return new_item;
    }

    public ModelType copy () {
        return new ModelTypeEllipse ();
    }

    public void construct_canvas_item (ModelItem item, Goo.Canvas canvas) {
        var radius_x = item.components.size.width / 2.0;
        var radius_y = item.components.size.height / 2.0;

        item.canvas_item = new Lib2.Items.CanvasEllipse (canvas.get_root_item (), 0, 0, radius_x, radius_y);
    }

    public void component_updated (ModelItem item, Lib2.Components.Component.Type type) {
        switch (type) {
            case Lib2.Components.Component.Type.COMPILED_BORDER:
                if (!item.compiled_border.is_visible) {
                    item.canvas_item.set ("line-width", 0);
                    item.canvas_item.set ("stroke-color-rgba", null);
                    break;
                }

                var rgba = item.compiled_border.color;
                uint urgba = Utils.Color.rgba_to_uint (rgba);
                // The "line-width" property expects a DOUBLE type, but we don't support subpixels
                // so we always handle the border size as INT, therefore we need to type cast it here.
                item.canvas_item.set ("line-width", (double) item.compiled_border.size);
                item.canvas_item.set ("stroke-color-rgba", urgba);
                break;
            case Lib2.Components.Component.Type.COMPILED_FILL:
                if (!item.compiled_fill.is_visible) {
                    item.canvas_item.set ("fill-color-rgba", null);
                    break;
                }

                var rgba = item.compiled_fill.color;
                uint urgba = Utils.Color.rgba_to_uint (rgba);
                item.canvas_item.set ("fill-color-rgba", urgba);
                break;
            case Lib2.Components.Component.Type.COMPILED_GEOMETRY:
                item.canvas_item.set ("radius-x", item.components.size.width / 2.0);
                item.canvas_item.set ("radius-y", item.components.size.height / 2.0);
                item.canvas_item.set_transform (item.compiled_geometry.transform ());
                break;
        }
    }

    public bool is_group () { return false; }
}
