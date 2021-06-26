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

public class Akira.Lib2.Managers.HoverManager : Object {
    private const string STROKE_COLOR = "#41c9fd";
    private const double LINE_WIDTH = 2.0;

    public unowned ViewCanvas view_canvas { get; construct; }

    private int current_hovered_id = -1;
    private Goo.CanvasItem hover_effect;

    public HoverManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        view_canvas.window.event_bus.zoom.connect (on_canvas_zoom);
    }

    public void on_mouse_over (double event_x, double event_y) {
        var target = view_canvas.items_manager.hit_test (event_x, event_y, false);

        // Remove the hover effect is no item is hovered
        // TODO: artboard
        if (target == null) {
            remove_hover_effect ();
            return;
        }

        maybe_create_hover_effect (target);
        return;
    }

    public void remove_hover_effect () {
        if (hover_effect == null) {
            return;
        }

        current_hovered_id = -1;
        hover_effect.remove ();
        hover_effect = null;

        //view_canvas.window.event_bus.hover_over_item (null)
    }

    private void maybe_create_hover_effect (Lib2.Items.ModelItem item) {
        if (view_canvas.selection_manager.item_selected (item.id)) {
            return;
        }

        if (current_hovered_id == item.id) {
            return;
        }
        else {
            remove_hover_effect ();
        }

        double item_width = 0;
        double item_height = 0;

        item_width = item.compiled_geometry.area.width;
        item_height = item.compiled_geometry.area.height;

        var scale = view_canvas.current_scale;

        var width = item_width + LINE_WIDTH / 4.0 / scale;
        var height = item_height + LINE_WIDTH / 4.0 / scale;

        hover_effect = new Goo.CanvasRect (
            null,
            - (width / 2.0), - (height / 2.0),
            width, height,
            "line-width", LINE_WIDTH / scale,
            "stroke-color", STROKE_COLOR,
            null
        );

        hover_effect.set_transform (item.compiled_geometry.transform ());

        hover_effect.set ("parent", view_canvas.get_root_item ());
        hover_effect.can_focus = false;
        hover_effect.pointer_events = Goo.CanvasPointerEvents.NONE;

        //view_canvas.window.event_bus.hover_over_item (null)
    }

    private void on_canvas_zoom () {
        // Interrupt if we don't have any hover effect currently visible.
        if (hover_effect == null) {
            return;
        }

        // Update the line width of the hover effect based on the canvas scale.
        hover_effect.set ("line-width", LINE_WIDTH / view_canvas.current_scale);
    }
}
