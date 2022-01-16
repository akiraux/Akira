/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 *              Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Modes.MultiSelectMode : AbstractInteractionMode {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.ArrayList<unowned Lib.Items.ModelNode> found_items;

    public class DragItemData : Object {
        public Lib.Components.CompiledGeometry item_geometry;
    }

    public class InitialDragState : Object {
        public double press_x;
        public double press_y;

        // initial_selection_data
        public Geometry.Quad area;

        public Gee.HashMap<int, DragItemData> item_data_map;

        construct {
            item_data_map = new Gee.HashMap<int, DragItemData> ();
        }
    }

    private InitialDragState initial_drag_state;
    private ViewLayers.ViewLayerMultiSelect multi_select_layer;

    public MultiSelectMode (Akira.Lib.ViewCanvas canvas) {
        Object (view_canvas: canvas);

        initial_drag_state = new InitialDragState ();
    }

    construct {
        multi_select_layer = new ViewLayers.ViewLayerMultiSelect ();
        found_items = new Gee.ArrayList<unowned Lib.Items.ModelNode> ();
    }

    public override void mode_begin () {
        multi_select_layer.add_to_canvas (ViewLayers.ViewLayer.MULTI_SELECT_LAYER_ID, view_canvas);
    }

    public override void mode_end () {}

    public override AbstractInteractionMode.ModeType mode_type () {
        return AbstractInteractionMode.ModeType.MULTI_SELECT;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        return true;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        initial_drag_state.press_x = event.x;
        initial_drag_state.press_y = event.y;

        multi_select_layer.create_region (event);

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        select_items_inside_region ();
        multi_select_layer.remove_region ();

        request_deregistration (mode_type ());
        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        var width = event.x - initial_drag_state.press_x;
        var height = event.y - initial_drag_state.press_y;

        multi_select_layer.update_region (width, height);

        found_items = view_canvas.items_manager.nodes_in_bounded_region (
            multi_select_layer.get_region_bounds ()
        );

        if (found_items.size == 0) {
            return true;
        }

        var drawables = new Gee.ArrayList<unowned Drawables.Drawable> ();
        foreach (unowned var item in found_items) {
            drawables.add (item.instance.drawable);
        }
        multi_select_layer.update_found_drawables (drawables);

        return true;
    }

    public override Object? extra_context () {
        return null;
    }

    private void select_items_inside_region () {
        // Block selection manager while selecting potentially many items
        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        // Get rid of unused var warning
        (blocker);

        foreach (unowned var item in found_items) {
            view_canvas.selection_manager.add_to_selection (item.instance.id);
        }

        view_canvas.selection_manager.selection_modified_external (true);
    }
}
