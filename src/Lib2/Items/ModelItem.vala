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
    public ModelType item_type = null;

    public ModelItem.dummy_item () {
        item_type = new DummyItemType ();
    }

    public ModelItem.dummy_group () {
        item_type = new DummyGroupType ();
    }

    public signal void geometry_changed (int id);

    public ModelItem clone () {
        var cln = new ModelItem ();
        if (components != null) {
            cln.components = components.copy ();
        }
        cln.item_type = item_type.copy ();
        return cln;
    }

    public void compile_components (bool notify_view) {
        components.maybe_compile_geometry ();
        components.maybe_compile_fill ();
        components.maybe_compile_border ();

        if (notify_view) {
            notify_view_of_changes ();
        }
    }

    public bool hit_test (double x, double y) {
        components.maybe_compile_geometry ();
        return components.compiled_geometry.contains (x, y);
    }

    public void recompile_geometry (bool notify) {
        components.compiled_geometry = null;
        components.maybe_compile_geometry ();

        if (notify) {
            notify_view_of_changes ();
        }
    }

    public void notify_view_of_changes () {
        if (canvas_item == null && container_item == null) {
            return;
        }

        var dirty_types = components.dirty_components.types;
        for (var i = 0; i < dirty_types.length; ++i) {
            var type = dirty_types[i];
            if (type.dirty) {
                item_type.component_updated (this, type.type);

                if (type.type == Lib2.Components.Component.Type.COMPILED_GEOMETRY) {
                    geometry_changed (id);
                }
            }

            components.dirty_components.mark_dirty (type.type, false);
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

    public unowned Lib2.Components.CompiledGeometry compiled_geometry () {
        components.maybe_compile_geometry ();
        return components.compiled_geometry;
    }
}
