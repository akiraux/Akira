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

public class Akira.Lib2.Items.ModelRect : ModelItem {
    public ModelRect (
        Lib2.Components.Coordinates coordinates,
        Lib2.Components.Size size,
        Lib2.Components.Borders? borders,
        Lib2.Components.Fills? fills
    ) {
        components = new Lib2.Components.Components();
        components.coordinates = coordinates;
        components.size = size;
        components.borders = borders;
        components.fills = fills;
        components.rotation = Lib2.Components.Components.default_rotation ();
        components.flipped = Lib2.Components.Components.default_flipped ();
        components.border_radius = Lib2.Components.Components.default_border_radius ();
    }

    public override void add_to_canvas (Goo.Canvas canvas) {
        item = new Goo.CanvasRect (
            canvas.get_root_item (),
            0,
            0,
            components.size.width,
            components.size.height
        );
    }

    public override void component_updated (Lib2.Components.Component.Type type) {
        switch (type) {
            case Lib2.Components.Component.Type.COMPILED_BORDER:
                var rgba = components.compiled_border.color;
                var size = components.compiled_border.size;

                if (size == 0 || rgba.alpha == 0.0) {
                    item.set ("stroke-color-rgba", null);
                }
                else {
                    uint urgba = Utils.Color.rgba_to_uint (rgba);
                    // The "line-width" property expects a DOUBLE type, but we don't support subpixels
                    // so we always handle the border size as INT, therefore we need to type cast it here.
                    item.set ("line-width", (double) size);
                    item.set ("stroke-color-rgba", urgba);
                }
                break;
            case Lib2.Components.Component.Type.COMPILED_FILL:
                var rgba = components.compiled_fill.color;

                if (rgba.alpha == 0.0) {
                    item.set ("fill-color-rgba", null);
                }
                else {
                    uint urgba = Utils.Color.rgba_to_uint (rgba);
                    item.set ("fill-color-rgba", urgba);
                }
                break;
            case Lib2.Components.Component.Type.COMPILED_GEOMETRY:
                item.set_transform (components.compiled_geometry.transform);
                break;
        }
    }

}
