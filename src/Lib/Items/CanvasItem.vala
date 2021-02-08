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

    /**
     * Helper method to get and set the item's width. We do it this way because
     * it's faster than type casting each item to get the property from the
     * object class (e.g. CanvasRect, CanvasEllipse, etc.)
     */
    public double width {
        get {
            double item_width = 0.0;
            get ("width", out item_width);

            return item_width;
        }
        set {
            set ("width", value);
        }
    }

    /**
     * Helper method to get and set the item's height. We do it this way because
     * it's faster than type casting each item to get the property from the
     * object class (e.g. CanvasRect, CanvasEllipse, etc.)
     */
    public double height {
        get {
            double item_height = 0.0;
            get ("height", out item_height);

            return item_height;
        }
        set {
            set ("height", value);
        }
    }

    /**
     * Helper method to get and set the opacity of the item, only if the item
     * is using the Opacity component.
     */
    public double opacity {
        get {
            Component? opacity_c = this.get_component (typeof (Components.Opacity));

            if (opacity_c != null) {
                return ((Components.Opacity) opacity_c).opacity;
            }

            // If the item doesn't have an Opacity component (e.g. Artboards)
            // return 0 so the slider in the Transform Panel can be reset.
            return 0.0;
        }
        set {
            Component? opacity_c = this.get_component (typeof (Components.Opacity));

            if (opacity_c != null) {
                ((Components.Opacity) opacity_c).opacity = value;
            }
        }
    }

    /**
     * Helper method to get and set the rotation of the item, only if the item
     * is using the Rotation component.
     */
    public double rotation {
        get {
            Component? rotation_c = this.get_component (typeof (Components.Rotation));

            if (rotation_c != null) {
                return ((Components.Rotation) rotation_c).rotation;
            }

            // If the item doesn't have a Rotation component (e.g. Artboards)
            // return 0 so the slider in the Transform Panel can be reset.
            return 0.0;
        }
        set {
            Component? rotation_c = this.get_component (typeof (Components.Rotation));

            if (rotation_c != null) {
                ((Components.Rotation) rotation_c).rotation = value;
            }
        }
    }
}
