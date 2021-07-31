/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Managers.HoverManager : Object {
    private const string STROKE_COLOR = "#41c9fd";
    private const double LINE_WIDTH = 2.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }

    private Goo.CanvasItem hover_effect;
    private Lib.Items.CanvasItem current_hover_item;

    public HoverManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        canvas.window.event_bus.zoom.connect (on_canvas_zoom);
        canvas.window.event_bus.hover_over_layer.connect (on_layer_hovered);
    }

    public void on_mouse_over (double event_x, double event_y, Utils.Nobs.Nob nob) {
        if (nob != Utils.Nobs.Nob.NONE) {
            current_hover_item = null;
            remove_hover_effect ();
            return;
        }

        var target = canvas.get_item_at (event_x, event_y, true);

        // Remove the hover effect is no item is hovered, or the item is the
        // white background of the CanvasArtboard, which is a GooCanvasRect item.
        if (target == null || (target is Goo.CanvasRect && !(target is Items.CanvasItem))) {
            current_hover_item = null;
            remove_hover_effect ();
            return;
        }

        // If we're hovering over the Artboard's label, change the target to the Artboard.
        if (
            target is Goo.CanvasText &&
            target.parent is Items.CanvasArtboard &&
            !(target is Items.CanvasItem)
        ) {
            target = target.parent as Items.CanvasItem;
        }

        if (!(target is Items.CanvasItem)) {
            return;
        }

        var item = target as Items.CanvasItem;

        if (current_hover_item != null && item.name.id == current_hover_item.name.id) {
            // We already have the hover effect rendered correctly.
            return;
        }

        // We need to recreate it.
        remove_hover_effect ();
        current_hover_item = item;

        create_hover_effect (item);

        if (!item.layer.selected) {
            canvas.window.event_bus.hover_over_item (item);
        }

        return;
    }

    private void on_layer_hovered (Items.CanvasItem? item) {
        if (item == null) {
            remove_hover_effect ();
            return;
        }

        remove_hover_effect ();
        create_hover_effect (item);
    }

    private void create_hover_effect (Items.CanvasItem item) {
        if (item.layer.selected) {
            return;
        }

        hover_effect = new Goo.CanvasRect (
            null,
            0, 0,
            item.size.width, item.size.height,
            "line-width", LINE_WIDTH / canvas.current_scale,
            "stroke-color", STROKE_COLOR,
            null
        );

        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        // If the item is inside an artboard, we need to convert
        // its coordinates from the artboard space.
        if (item.artboard != null) {
            item.canvas.convert_from_item_space (item.artboard, ref matrix.x0, ref matrix.y0);
        }

        hover_effect.set_transform (matrix);

        hover_effect.set ("parent", canvas.get_root_item ());
        hover_effect.can_focus = false;
        hover_effect.pointer_events = Goo.CanvasPointerEvents.NONE;
    }

    public void remove_hover_effect () {
        if (hover_effect == null) {
            return;
        }

        hover_effect.remove ();
        hover_effect = null;

        canvas.window.event_bus.hover_over_item (null);
    }

    private void on_canvas_zoom () {
        // Interrupt if we don't have any hover effect currently visible.
        if (hover_effect == null) {
            return;
        }

        // Update the line width of the hover effect based on the canvas scale.
        hover_effect.set ("line-width", LINE_WIDTH / canvas.current_scale);
    }
}
