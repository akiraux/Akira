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

    public weak Goo.Canvas canvas { get; construct; }

    private double initial_event_x;
    private double initial_event_y;
    private double initial_width;
    private double initial_height;
    private Goo.CanvasItem hover_effect;

    public HoverManager (Goo.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
    }

    public void set_initial_coordinates (double event_x, double event_y) {
        initial_event_x = event_x;
        initial_event_y = event_y;
    }

    public void add_hover_effect (double event_x, double event_y) {
        remove_hover_effect ();

        var target = canvas.get_item_at (event_x, event_y, true);

        if (target == null) {
            return;
        }

        if (target is Models.CanvasItem) {
            var target_model = target as Models.CanvasItem;

            Goo.CanvasBounds item_bounds;
            target_model.get_bounds (out item_bounds);

            double x = item_bounds.x1;
            double y = item_bounds.y1;
            double width = item_bounds.x2 - item_bounds.x1;
            double height = item_bounds.y2 - item_bounds.y1;

            //debug (@"x: $(x) y: $(y) width: $(width) height: $(height)");

            if (!target_model.selected) {
                hover_effect = new Goo.CanvasRect (
                    null,
                    x, y,
                    width, height,
                    "line-width", 2.0,
                    "stroke-color", "#41c9fd",
                    null
                );

                var transform = Cairo.Matrix.identity ();
                target_model.get_transform (out transform);
                hover_effect.set_transform (transform);

                hover_effect.set ("parent", canvas.get_root_item ());
                hover_effect.can_focus = false;
            }
        }

        return;
    }

    public void remove_hover_effect () {
        if (hover_effect != null) {
            hover_effect.remove ();
            hover_effect = null;
        }
    }
}
