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

public class Akira.Lib.Items.ModelInstance {
    public int id;
    public int[] children;

    public ModelType type = null;

    public Lib.Components.Components components;
    public Lib.Components.CompiledComponents compiled_components;

    public Drawables.Drawable drawable = null;
    public Geometry.Rectangle bounding_box;
    public Geometry.Rectangle drawable_bounding_box;

    public Components.CompiledGeometry compiled_geometry { get { return compiled_components.compiled_geometry; } }
    public Components.CompiledFill compiled_fill { get { return compiled_components.compiled_fill; } }
    public Components.CompiledBorder compiled_border { get { return compiled_components.compiled_border; } }

    public bool is_group { get { return type.is_group (); } }
    public bool is_stackable { get { return drawable != null; } }

    public ModelInstance (int uid, ModelType type) {
        this.type = type;
        components = Lib.Components.Components ();
        compiled_components = Lib.Components.CompiledComponents ();
        bounding_box = Geometry.Rectangle ();
        drawable_bounding_box = Geometry.Rectangle ();

        if (is_group) {
            this.children = new int[0];
        }

        this.id = uid;
    }

    public ModelInstance clone () {
        var cln = new ModelInstance (-1, type);
        cln.components = components;
        return cln;
    }

    /*
     * Compiles the component for this item. If a corresponding node is passed, that node
     * is used in the compilation process.
     * This should almost always be called by the model--unless you really know what you are doing.
     * If in doubt, you don't.
     */
    public bool compile_components (ModelNode node, ViewLayers.BaseCanvas? canvas) {
        bool something_changed = false;
        something_changed = compiled_components.maybe_compile_geometry (type, components, node) || something_changed;
        something_changed = compiled_components.maybe_compile_fill (type, components, node) || something_changed;
        something_changed = compiled_components.maybe_compile_border (type, components, node) || something_changed;

        notify_view_of_changes ();

        if (something_changed) {
            update_drawable_bounds (canvas);
        }

        return something_changed;
    }

    public void notify_view_of_changes () {
        if (compiled_components.is_empty) {
            return;
        }

        if (drawable == null) {
            return;
        }

        var dirty_types = compiled_components.dirty_components.types;
        for (var i = 0; i < dirty_types.length; ++i) {
            var dirty_type = dirty_types[i];
            if (dirty_type.dirty) {
                type.component_updated (this, dirty_type.type);
            }

            compiled_components.dirty_components.mark_dirty (dirty_type.type, false);
        }
   }

    public void add_to_canvas () {
        type.construct_canvas_item (this);
    }

    public void remove_from_canvas (ViewLayers.BaseCanvas? canvas) {
        if (canvas != null) {
            drawable.request_redraw (canvas, false);
        }
        drawable = null;
    }

    private void update_drawable_bounds (ViewLayers.BaseCanvas? canvas) {
        bounding_box = compiled_geometry.area_bb;
        if (drawable != null) {
            if (canvas != null) {
                drawable.request_redraw (canvas, false);
                drawable.request_redraw (canvas, true);
            }
            drawable_bounding_box = drawable.bounds;
        } else {
            drawable_bounding_box = bounding_box;
        }
    }
}
