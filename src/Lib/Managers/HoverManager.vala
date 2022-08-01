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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.HoverManager : Object {
    // Signal used to notify other parts of the UI that the hover effect on a
    // canvas item has changed. This must be used exclusively from the canvas to
    // other items, and not vice-versa. If a UI element has to trigger the hover
    // state of an item (like the layers), a dedicated method should be created
    // that doesn't trigger this signal.
    public signal void hover_changed (int? id);

    public unowned ViewCanvas view_canvas { get; construct; }

    private int current_hovered_id = -1;
    private ViewLayers.ViewLayerHover hover_layer;

    public HoverManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        hover_layer = new ViewLayers.ViewLayerHover ();
        hover_layer.add_to_canvas (ViewLayers.ViewLayer.HOVER_LAYER_ID, view_canvas);
    }

    public void on_mouse_over (double event_x, double event_y) {
        var target = view_canvas.items_manager.node_at_canvas_position (
            event_x,
            event_y,
            Drawables.Drawable.HitTestType.SELECT
        );

        // Remove the hover effect if no item is hovered.
        // TODO: artboard
        if (target == null) {
            remove_hover_effect ();
            hover_changed (null);
            return;
        }

        if (view_canvas.selection_manager.item_selected (target.id)) {
            return;
        }

        // Account for groups.
        if (!view_canvas.ctrl_is_pressed) {
            var old_target = target;
            target = Utils.ModelUtil.recursive_get_parent_target (target);

            unowned var sm = view_canvas.selection_manager;
            if (
                !sm.is_empty () &&
                (target.has_child (old_target.id, true) || sm.item_is_sibling (old_target.id))
            ) {
                target = old_target;
            }
            old_target = null;
        }

        maybe_create_hover_effect (target);
        return;
    }

    public void remove_hover_effect () {
        hover_layer.add_drawable (null);
        hover_layer.set_visible (false);
        current_hovered_id = -1;
    }

    public void maybe_create_hover_effect_by_id (int id) {
        var node = view_canvas.items_manager.node_from_id (id);
        if (node == null) {
            print ("Failed to create hover effect for %d", id);
            assert (node != null);
            return;
        }

        if (view_canvas.selection_manager.item_selected (id)) {
            return;
        }

        maybe_create_hover_effect (node);
    }

    private void maybe_create_hover_effect (Lib.Items.ModelNode node) {
        if (current_hovered_id == node.id) {
            return;
        }

        remove_hover_effect ();
        hover_layer.add_drawable (node.instance.drawable);
        current_hovered_id = node.id;
        hover_changed (node.instance.id);
    }
}
