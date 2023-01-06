/**
 * Copyright (c) 2023 Alecaddd (https://alecaddd.com)
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

public class Akira.Lib.Modes.ExportMode : AbstractInteractionMode {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

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
    private ViewLayers.ViewLayerExportArea export_area_layer;

    public ExportMode (Akira.Lib.ViewCanvas canvas) {
        Object (view_canvas: canvas);

        initial_drag_state = new InitialDragState ();
    }

    construct {
        export_area_layer = new ViewLayers.ViewLayerExportArea ();
    }

    public override void mode_begin () {
        export_area_layer.add_to_canvas (ViewLayers.ViewLayer.EXPORT_AREA_LAYER_ID, view_canvas);
    }

    public override void mode_end () {
        export_area_layer.remove_region ();
    }

    public override AbstractInteractionMode.ModeType mode_type () {
        return AbstractInteractionMode.ModeType.EXPORT;
    }

    public override Gdk.CursorType? cursor_type () {
        return Gdk.CursorType.CROSSHAIR;
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

        export_area_layer.create_region (event);

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        var area = export_area_layer.get_region_bounds ();
        view_canvas.export_area.begin (area);

        export_area_layer.remove_region ();

        request_deregistration (mode_type ());
        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        var width = event.x - initial_drag_state.press_x;
        var height = event.y - initial_drag_state.press_y;

        export_area_layer.update_region (width, height);

        return true;
    }

    public override Object? extra_context () {
        return null;
    }
}
