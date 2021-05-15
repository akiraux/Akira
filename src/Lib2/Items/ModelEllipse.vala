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

public class Akira.Lib2.Items.ModelEllipse : ModelItem {
    public ModelEllipse (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        components = new Lib2.Components.Components();
        components.center = center;
        components.size = size;
        components.borders = borders;
        components.fills = fills;
        components.rotation = Lib2.Components.Components.default_rotation ();
        components.flipped = Lib2.Components.Components.default_flipped ();
        components.border_radius = Lib2.Components.Components.default_border_radius ();
    }

    public override void construct_canvas_item (Goo.Canvas canvas) {
        var radius_x = components.size.width / 2.0;
        var radius_y = components.size.height / 2.0;

        canvas_item = new Lib2.Items.CanvasEllipse (canvas.get_root_item (), 0, 0, radius_x, radius_y);
    }

    public override void component_updated (Lib2.Components.Component.Type type) {
        switch (type) {
            case Lib2.Components.Component.Type.COMPILED_BORDER:
                var rgba = components.compiled_border.color;
                var size = components.compiled_border.size;

                if (size == 0 || rgba.alpha == 0.0) {
                    canvas_item.set ("stroke-color-rgba", null);
                }
                else {
                    uint urgba = Utils.Color.rgba_to_uint (rgba);
                    // The "line-width" property expects a DOUBLE type, but we don't support subpixels
                    // so we always handle the border size as INT, therefore we need to type cast it here.
                    canvas_item.set ("line-width", (double) size);
                    canvas_item.set ("stroke-color-rgba", urgba);
                }
                break;
            case Lib2.Components.Component.Type.COMPILED_FILL:
                var rgba = components.compiled_fill.color;

                if (rgba.alpha == 0.0) {
                    canvas_item.set ("fill-color-rgba", null);
                }
                else {
                    uint urgba = Utils.Color.rgba_to_uint (rgba);
                    canvas_item.set ("fill-color-rgba", urgba);
                }
                break;
            case Lib2.Components.Component.Type.COMPILED_GEOMETRY:
                canvas_item.set ("radius-x", components.size.width / 2.0);
                canvas_item.set ("radius-y", components.size.height / 2.0);
                canvas_item.set_transform (components.compiled_geometry.transform ());
                break;
        }
    }

}
