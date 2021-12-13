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

/*
 * An instance represents a single item. It contains information needed to represent and handle
 * an item in the model. If it is a group, it may have children.
 *
 * Instances can live in a model or be freestanding.
 *   - Freestanding instances are generally clones of other instances used for caching or copying
 *   - Instances in a model are part of the scene and get an associated ModelNode within the Model.
 *     If there are children, then the corresponding ModelNode will have those children as nodes.
 *     There is obviously no trivial way to get a child instance without its parent model.
 *
 * Components are clonable collection of immutable bits of information about an instance, they
 * are used to generate the scene or dictate behavior specific to an instance. In general,
 * components are aspects of an instance that make sense being serialized / deserialized. If this
 * is not the case for a specific bit of information (e.g., a volatile aspect like selection state),
 * then that bit of information should NOT be a component
 * Components should never depend on other nodes in the model.
 *
 * CompiledComponents are generated at model compilation from other components. They are volatile
 * and do NOT get serialized / deserialized. They are always reconstructible from the original
 * Components. For example, the bounding box of a component depends on it size, transformation, etc;
 * so it is a compiled component.
 * Compiled Components can depend on other nodes in the model.
 * Freestanding items generally don't have or need compiled components.
 *
 * Some data is cached in the instance to make some calculations faster. This includes the actual
 * drawable object and the boundingboxes calculated after compilation.
 *
 * Caching an instance is ok. HOWEVER, when modifying an instance, make sure to use the id
 * and query it back from the Model. Instances can get replaced or deleted without warning,
 * so it is vital to make sure that modifications occur directly on the model. This should
 * not be a performance concern in the vast majority of cases.
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
    public Components.CompiledName compiled_name { get { return compiled_components.compiled_name; } }

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
        something_changed = node.instance.type is ModelTypeArtboard && compiled_components.maybe_compile_name (type, components, node) || something_changed;

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
