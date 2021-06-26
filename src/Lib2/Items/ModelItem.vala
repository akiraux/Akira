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

public interface Akira.Lib2.Items.ModelType<T> : Object {
    public abstract ModelType copy ();

    public abstract void construct_canvas_item (ModelItem item, Goo.Canvas canvas);

    public abstract void component_updated (ModelItem item, Lib2.Components.Component.Type type);

    public abstract bool is_group ();
}

public class Akira.Lib2.Items.DummyItemType : Object, ModelType<DummyItemType> {
    public ModelType copy () { return new DummyItemType (); }
    public void construct_canvas_item (ModelItem item, Goo.Canvas canvas) {}
    public void component_updated (ModelItem item, Lib2.Components.Component.Type type) {}
    public bool is_group () { return false; }
}

public class Akira.Lib2.Items.DummyGroupType : Object, ModelType<DummyGroupType> {
    public ModelType copy () { return new DummyGroupType (); }
    public void construct_canvas_item (ModelItem item, Goo.Canvas canvas) {}
    public void component_updated (ModelItem item, Lib2.Components.Component.Type type) {}
    public bool is_group () { return true; }
}

public class Akira.Lib2.Items.ModelItem : Object {
    public int id = -1;
    public Lib2.Items.CanvasItem canvas_item = null;
    // Only non-null if it is a group with an associated canvas (e.g., artboard)
    public Goo.CanvasGroup container_item = null;
    public Lib2.Components.Components components = null;
    public Lib2.Components.CompiledComponents compiled_components = null;
    public ModelType item_type = null;

    public Components.CompiledGeometry compiled_geometry { get { return compiled_components.compiled_geometry; }}
    public Components.CompiledFill  compiled_fill { get { return compiled_components.compiled_fill; }}
    public Components.CompiledBorder  compiled_border { get { return compiled_components.compiled_border; }}

    public ModelItem () {
        prep ();
    }

    public ModelItem.dummy_item () {
        item_type = new DummyItemType ();
        prep ();
    }

    public ModelItem.dummy_group () {
        item_type = new DummyGroupType ();
        prep ();
    }

    private void prep () {
        compiled_components = new Lib2.Components.CompiledComponents ();
    }

    public signal void geometry_changed (int id);

    /*
     * When an item is a part of the model, this signal will be used to let the model know
     * that this item needs to have its geometry compiled.
     */
    public signal void geometry_compilation_requested (int id);

    public ModelItem clone () {
        var cln = new ModelItem ();
        if (components != null) {
            cln.components = components.copy ();
        }
        cln.item_type = item_type.copy ();
        return cln;
    }

    /*
     * Invalidates compiled geometry and requests a listener (the model) to eventually
     * update this geometry. At the end of a scope that called this method, the model
     * should be told to recompile all dirty items.
     */
    public void mark_geometry_dirty (bool notify_listeners = true) {
        compiled_components.compiled_geometry = null;

        if (notify_listeners) {
            geometry_compilation_requested (id);
        }
    }

    public void mark_cosmetics_dirty () {
        compiled_components.compiled_fill = null;
        compiled_components.compiled_border = null;
    }

    /*
     * Compiles the component for this item. If a corresponding node is passed, that node
     * is used in the compilation process.
     * This should almost always be called by the model--unless you really know what you are doing.
     * If in doubt, you don't.
     */
    public void compile_components (bool notify_view, ModelNode? node) {
        compiled_components.maybe_compile_geometry (components, node);
        compiled_components.maybe_compile_fill (components, node);
        compiled_components.maybe_compile_border (components, node);

        if (notify_view) {
            notify_view_of_changes ();
        }
    }

    public void notify_view_of_changes () {
        if (compiled_components == null) {
            return;
        }

        if (canvas_item == null && container_item == null) {
            return;
        }

        var dirty_types = compiled_components.dirty_components.types;
        for (var i = 0; i < dirty_types.length; ++i) {
            var type = dirty_types[i];
            if (type.dirty) {
                item_type.component_updated (this, type.type);

                if (type.type == Lib2.Components.Component.Type.COMPILED_GEOMETRY) {
                    geometry_changed (id);
                }
            }

            compiled_components.dirty_components.mark_dirty (type.type, false);
        }
   }

    public void add_to_canvas (Goo.Canvas canvas) {
        item_type.construct_canvas_item (this, canvas);

        if (canvas_item != null) {
            canvas_item.parent_id = id;
        }
    }

    public void remove_from_canvas () {
        if (canvas_item != null) {
            canvas_item.remove ();
        }
        canvas_item = null;
    }

    public bool is_stackable () { return canvas_item != null; }
}
