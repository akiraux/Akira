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
     * The X & Y initial coordinates of an item need to be set to 0 and then
     * the item needs to be translated to the proper position in order to ensure
     * the generation of the item's Cairo.Matrix which is used across the app.
     */
    public void init_position (Items.CanvasItem item, double x, double y) {
        if (item.artboard != null) {
            item.canvas.convert_to_item_space (item.artboard, ref x, ref y);
        }

        item.translate (x, y);
    }

    /**
     * Check if the item belongs to an artboard, and if so add it to the
     * list of items inside the artboard. We do this separately after all
     * the components have been initialized to avoid issues in retrieving
     * attributes not yet defined when the list model is updated.
     */
    public void check_add_to_artboard (Items.CanvasItem item) {
        if (item.artboard != null) {
            item.artboard.items.add_item.begin (item);
        }
    }

    public Components.Name? name {
        get {
            Component? component = this.get_component (typeof (Components.Name));
            return (Components.Name) component;
        }
    }

    public Components.Coordinates? coordinates {
        get {
            Component? component = this.get_component (typeof (Components.Coordinates));
            return (Components.Coordinates) component;
        }
    }

    public Components.Opacity? opacity {
        get {
            Component? component = this.get_component (typeof (Components.Opacity));
            return (Components.Opacity) component;
        }
    }

    public Components.Rotation? rotation {
        get {
            Component? component = this.get_component (typeof (Components.Rotation));
            return (Components.Rotation) component;
        }
    }

    public Components.Fills? fills {
        get {
            Component? component = this.get_component (typeof (Components.Fills));
            return (Components.Fills) component;
        }
    }

    public Components.Borders? borders {
        get {
            Component? component = this.get_component (typeof (Components.Borders));
            return (Components.Borders) component;
        }
    }

    public Components.Size? size {
        get {
            Component? component = this.get_component (typeof (Components.Size));
            return (Components.Size) component;
        }
    }

    public Components.Flipped? flipped {
        get {
            Component? component = this.get_component (typeof (Components.Flipped));
            return (Components.Flipped) component;
        }
    }

    public Components.BorderRadius? border_radius {
        get {
            Component? component = this.get_component (typeof (Components.BorderRadius));
            return (Components.BorderRadius) component;
        }
    }

    public Components.Font? text_font {
        get {
            Component? component = this.get_component (typeof (Components.Font));
            return (Components.Font) component;
        }
    }

    public Components.Layer? layer {
        get {
            Component? component = this.get_component (typeof (Components.Layer));
            return (Components.Layer) component;
        }
    }

    public void delete () {
        // If we're deleting an Artboard, deal with it inside its class.
        if (this is CanvasArtboard) {
            ((CanvasArtboard) this).delete ();
        }

        // Remove the item from the artboard before deleting it
        // if it belongs to one.
        if (artboard != null) {
            artboard.remove_item (this);
        }

        remove ();
    }
}
