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

public class Akira.Lib2.Items.ModelItem : Object {
    public int id = -1;
    public Goo.CanvasItem item = null;
    public Lib2.Components.Components components = null;

    public void compile_components (bool notify_view) {
        components.maybe_compile_geometry ();
        components.maybe_compile_fill ();
        components.maybe_compile_border ();

        if (notify_view) {
            notify_view_of_changes ();
        }
    }

    public void notify_view_of_changes() {
        if (item == null) {
            return;
        }

        foreach (var dirty in components.dirty_components) {
            component_updated (dirty);
        }

        components.dirty_components.clear ();
    }

    public virtual void add_to_canvas (Goo.Canvas canvas) {}

    public virtual void component_updated (Lib2.Components.Component.Type type) {}
}
