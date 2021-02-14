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

    // Keep track of the parent artboard if the item belongs to one.
    public abstract Items.CanvasArtboard? artboard { get; set; }

    // Check if an item was created or it was loaded for ordering purpose.
    public abstract bool is_loaded { get; set; }

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
     * Helper method to get the item's icon based on the type.
     */
    public string? icon {
        get {
            Component? type_c = this.get_component (typeof (Components.Type));
            return ((Components.Type) type_c).icon;
        }
    }

    /**
     * Helper method to get and set the item's id.
     */
    public string id {
        get {
            Component? name_c = this.get_component (typeof (Components.Name));
            return ((Components.Name) name_c).id;
        }
        set {
            Component? name_c = this.get_component (typeof (Components.Name));
            ((Components.Name) name_c).id = value;
        }
    }

    public unowned Components.Name? name {
        get {
            Component? component = this.get_component (typeof (Components.Name));
            return (Components.Name) component;
        }
    }

    public double item_x {
        get {
            Component? transform = this.get_component (typeof (Components.Transform));
            return ((Components.Transform) transform).x;
        }
        set {
            Component? transform = this.get_component (typeof (Components.Transform));
            ((Components.Transform) transform).x = value;
        }
    }

    public double item_y {
        get {
            Component? transform = this.get_component (typeof (Components.Transform));
            return ((Components.Transform) transform).y;
        }
        set {
            Component? transform = this.get_component (typeof (Components.Transform));
            ((Components.Transform) transform).y = value;
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
    public double? opacity {
        get {
            Component? opacity_c = this.get_component (typeof (Components.Opacity));

            if (opacity_c != null) {
                return ((Components.Opacity) opacity_c).opacity;
            }

            return null;
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
    public double? rotation {
        get {
            Component? rotation_c = this.get_component (typeof (Components.Rotation));

            if (rotation_c != null) {
                return ((Components.Rotation) rotation_c).rotation;
            }

            return null;
        }
        set {
            Component? rotation_c = this.get_component (typeof (Components.Rotation));

            if (rotation_c != null) {
                ((Components.Rotation) rotation_c).rotation = value;
            }
        }
    }

    /**
     * Helper method to know if the item implements fillings or not.
     * Primarily used to disable the Fills area in the Transform Panel.
     */
    public bool has_fills {
        get {
            return this.get_component (typeof (Components.Fills)) != null;
        }
    }

    /**
     * Helper method to get the number of Fills the item is using.
     */
     public int fills_count {
        get {
            Component? fills_c = this.get_component (typeof (Components.Fills));

            if (fills_c != null) {
                return ((Components.Fills) fills_c).count ();
            }

            return 0;
        }
    }

    /**
     * Helper method to recalculate the colors of all the applied Fills.
     */
    public void reload_fills () {
        Component? fills_c = this.get_component (typeof (Components.Fills));

        if (fills_c != null) {
            ((Components.Fills) fills_c).reload ();
        }
    }

    /**
     * Helper method to know if the item implements borders or not.
     * Primarily used to disable the Borders area in the Transform Panel.
     */
    public bool has_borders {
        get {
            return this.get_component (typeof (Components.Borders)) != null;
        }
    }

    /**
     * Helper method to get the number of Borders the item is using.
     */
    public int borders_count {
        get {
            Component? borders_c = this.get_component (typeof (Components.Borders));

            if (borders_c != null) {
                return ((Components.Borders) borders_c).count ();
            }

            return 0;
        }
    }

    /**
     * Helper method to recalculate the colors of all the applied Borders.
     */
    public void reload_borders () {
        Component? borders_c = this.get_component (typeof (Components.Borders));

        if (borders_c != null) {
            ((Components.Borders) borders_c).reload ();
        }
    }

    /**
     * Helper method to get and set the locked size of the item, only if the item
     * is using the Size component.
     */
    public bool? size_locked {
        get {
            Component? size = this.get_component (typeof (Components.Size));

            if (size != null) {
                return ((Components.Size) size).locked;
            }

            return null;
        }
        set {
            Component? size = this.get_component (typeof (Components.Size));

            if (size != null) {
                ((Components.Size) size).locked = value;
            }
        }
    }

    /**
     * Helper method to get and set the size ratio of the item, only if the item
     * is using the Size component.
     */
    public double? size_ratio {
        get {
            Component? size = this.get_component (typeof (Components.Size));

            if (size != null) {
                return ((Components.Size) size).ratio;
            }

            return null;
        }
        set {
            Component? size = this.get_component (typeof (Components.Size));

            if (size != null) {
                ((Components.Size) size).ratio = value;
            }
        }
    }

    /**
     * Helper method to update the size ratio of an item.
     */
    public void update_ratio () {
        Component? size = this.get_component (typeof (Components.Size));

        if (size != null) {
            ((Components.Size) size).ratio = width / height;
        }
    }

    /**
     * Helper method to get and set the horizontal mirroring of the item, only if the item
     * is using the Flipped component.
     */
    public bool? flipped_h {
        get {
            Component? flipped = this.get_component (typeof (Components.Flipped));

            if (flipped != null) {
                return ((Components.Flipped) flipped).horizontal;
            }

            return null;
        }
        set {
            Component? flipped = this.get_component (typeof (Components.Flipped));

            if (flipped != null) {
                ((Components.Flipped) flipped).horizontal = value;
            }
        }
    }

    /**
     * Helper method to get and set the vertical mirroring of the item, only if the item
     * is using the Flipped component.
     */
    public bool? flipped_v {
        get {
            Component? flipped = this.get_component (typeof (Components.Flipped));

            if (flipped != null) {
                return ((Components.Flipped) flipped).vertical;
            }

            return null;
        }
        set {
            Component? flipped = this.get_component (typeof (Components.Flipped));

            if (flipped != null) {
                ((Components.Flipped) flipped).vertical = value;
            }
        }
    }

    /**
     * Helper method to know if the item implements the border radius or not.
     * Primarily used to disable the Border Radius area in the Transform Panel.
     */
     public bool has_border_radius {
        get {
            return this.get_component (typeof (Components.BorderRadius)) != null;
        }
    }

    /**
     * Set and get the boolean attribute to control the uniformity of the border radius.
     * E.g.: if both the X & Y radii should be identical.
     */
    public bool border_radius_uniform {
        get {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            return ((Components.BorderRadius) border_radius).uniform;
        }
        set {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            ((Components.BorderRadius) border_radius).uniform = value;
        }
    }

    /**
     * Set and get the boolean attribute to control the autoscaling of the border radius.
     * E.g.: if the X & Y radii should increase when the item is enlarged.
     */
    public bool border_radius_autoscale {
        get {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            return ((Components.BorderRadius) border_radius).autoscale;
        }
        set {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            ((Components.BorderRadius) border_radius).autoscale = value;
        }
    }

    public double border_radius_x {
        get {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            return ((Components.BorderRadius) border_radius).x;
        }
        set {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            ((Components.BorderRadius) border_radius).x = value;
        }
    }

    public double border_radius_y {
        get {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            return ((Components.BorderRadius) border_radius).y;
        }
        set {
            Component? border_radius = this.get_component (typeof (Components.BorderRadius));
            ((Components.BorderRadius) border_radius).y = value;
        }
    }

    public Components.Layer? layer {
        get {
            Component? component = this.get_component (typeof (Components.Layer));
            return (Components.Layer) component;
        }
    }

    public void delete () {
        remove ();
    }
}
