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

public class Akira.Lib.Items.ModelTypeGroup : ModelType {
    public static ModelInstance default_group () {
        var new_item = new ModelInstance (-1, new ModelTypeGroup ());
        var layout_data = Components.Layout.LayoutData () {
            can_rotate = true,
            dilated_resize = true,
            clips_children = false
        };
        new_item.components.layout = new Components.Layout (layout_data);
        new_item.components.name = Lib.Components.Components.default_name ();
        new_item.components.layer = Lib.Components.Components.default_layer ();
        return new_item;
    }

    public override string name_id { get { return "group"; } }

    public override Components.CompiledGeometry compile_geometry (
        Components.Components? components,
        Lib.Items.ModelNode? node
    ) {
        return new Components.CompiledGeometry.from_descendants (components, node);
    }

    public override void construct_canvas_item (ModelInstance instance) {
        instance.drawable = new Drawables.DrawableGroup ();
    }

    public override bool is_group () { return true; }
}
