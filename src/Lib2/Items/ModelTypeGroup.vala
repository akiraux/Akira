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

public class Akira.Lib2.Items.ModelTypeGroup : Object, ModelType<ModelTypeGroup> {
    public static ModelItem default_group () {
        var new_item = new ModelItem ();
        new_item.components = new Lib2.Components.Components ();
        var layout_data = Components.Layout.LayoutData () {
            can_rotate = true,
            dilated_resize = true
        };
        new_item.components.layout = new Components.Layout (layout_data);

        new_item.item_type = new ModelTypeGroup ();
        return new_item;
    }

    public ModelType copy () {
        return new ModelTypeGroup ();
    }

    public Components.CompiledFill compile_fill (Components.Components? components, Lib2.Items.ModelNode? node) {
        return Components.CompiledFill.compile (components, node);
    }

    public Components.CompiledBorder compile_border (Components.Components? components, Lib2.Items.ModelNode? node) {
        return Components.CompiledBorder.compile (components, node);
    }

    public Components.CompiledGeometry compile_geometry (Components.Components? components, Lib2.Items.ModelNode? node) {
        return new Components.CompiledGeometry.from_descendants (components, node);
    }

    public void construct_canvas_item (ModelItem item, Goo.Canvas canvas) {}

    public void component_updated (ModelItem item, Lib2.Components.Component.Type type) {}

    public bool is_group () { return true; }
}