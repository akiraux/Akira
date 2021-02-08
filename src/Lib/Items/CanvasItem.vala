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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

using Akira.Lib.Components;

/**
 * This is the base interface other items will need to extend in order to be created.
 * This interface shouldn't have any abstract attributes other than the components.
 * We use components instead of inheritance to keep our items modular and avoid useless
 * attributes repetitions.
 */
public interface Akira.Lib.Items.CanvasItem : Goo.CanvasItemSimple, Goo.CanvasItem {
    public abstract Gee.ArrayList<Component> components { get; set; }

    /**
     * Find the component attached to the item by its GLib.Type.
     */
    private Component? get_component (GLib.Type type) {
        foreach (Component comp in components) {
            if (comp.get_type () == type) {
                return comp;
            }
        }

        return null;
    }

    /**
     * Helper method to return the GLib.Type of a specific component,
     * only if the item is actually using that component.
     */
    public GLib.Type? type () {
        Component? type_c = this.get_component (typeof (Components.Type));

        if (type_c != null) {
            return ((Components.Type) type_c).item_type;
        }

        return null;
    }

    /**
     * Helper method to get and set the name of the item, only if the item
     * is using the Name component.
     */
    public string name {
        get {
            Component? name_c = this.get_component (typeof (Components.Name));

            if (name_c != null) {
                return ((Components.Name) name_c).name;
            }

            // Return a generic string to avoid empty names.
            return _("Item");
        }
        set {
            Component? name_c = this.get_component (typeof (Components.Name));

            if (name_c != null) {
                ((Components.Name) name_c).name = value;
            }
        }
    }
}
