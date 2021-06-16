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

    public static ModelItem default_artboard (
        Lib2.Components.Coordinates center,
        Lib2.Components.Size size
    ) {
        var new_item = new ModelItem ();
        new_item.components = new Lib2.Components.Components ();
        new_item.components.center = center;
        new_item.components.size = size;
        new_item.components.rotation = Lib2.Components.Components.default_rotation ();
        new_item.components.flipped = Lib2.Components.Components.default_flipped ();
        new_item.components.border_radius = Lib2.Components.Components.default_border_radius ();
        new_item.components.fills = Lib2.Components.Fills.single_color (Lib2.Components.Color (1.0, 1.0, 1.0, 1.0));
        new_item.item_type = new ModelTypeArtboard ();
        return new_item;
    }

    public ModelType copy () {
        return new ModelTypeArtboard ();
    }

    public void construct_canvas_item (ModelItem item, Goo.Canvas canvas) {
        var mid_x = item.components.size.width / 2.0;
        var mid_y = item.components.size.height / 2.0;

        var artboard = new Lib2.Items.CanvasRect (
            canvas.get_root_item (),
            -mid_x,
            -mid_y,
            item.components.size.width,
            item.components.size.height
        );
        //var artboard = new Goo.CanvasRect (canvas.get_root_item(), null);
        //artboard.x = -mid_x;
        //artboard.y = -mid_y;
        //artboard.width = item.components.size.width;
        //artboard.height = item.components.size.height;

        //background = new Goo.CanvasRect (artboard, 0, 0, 1, 1, "line-width", 0.0, null);
        //background.translate (0, 0);
        //background.can_focus = false;

        item.canvas_item = artboard;

        var fill_color = Gdk.RGBA ();
        fill_color.parse ("#fff");
        //item.canvas_item.set ("fill-color-rgba", fill_color);
    }

    public void component_updated (ModelItem item, Lib2.Components.Component.Type type) {
        switch (type) {
            case Lib2.Components.Component.Type.COMPILED_BORDER:
                break;
            case Lib2.Components.Component.Type.COMPILED_FILL:
                if (!item.compiled_fill.is_visible) {
                    item.canvas_item.set ("fill-color-rgba", null);
                    break;
                }

                var rgba = item.compiled_fill.color;
                uint urgba = Utils.Color.rgba_to_uint (rgba);
                print ("here\n");
                item.canvas_item.set ("fill-color-rgba", urgba);
                break;
            case Lib2.Components.Component.Type.COMPILED_GEOMETRY:
                item.canvas_item.set ("x", -item.components.size.width / 2.0);
                item.canvas_item.set ("y", -item.components.size.height / 2.0);
                item.canvas_item.set ("width", item.components.size.width);
                item.canvas_item.set ("height", item.components.size.height);
                item.canvas_item.set_transform (item.compiled_geometry.transform ());
                print ("%s", item.canvas_item.is_visible ().to_string ());
                break;
        }
    }

    public bool is_group () { return true; }
}
