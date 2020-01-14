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

    private double initial_event_x;
    private double initial_event_y;
    private Goo.CanvasItem hover_effect;
    private Lib.Managers.NobManager.Nob current_hovering_nob;

    public HoverManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    public void set_initial_coordinates (double event_x, double event_y) {
        initial_event_x = event_x;
        initial_event_y = event_y;
    }

    public void add_hover_effect (double event_x, double event_y) {
        remove_hover_effect ();

        var target = canvas.get_item_at (event_x, event_y, true);

        if (target == null) {
            set_cursor_for_nob (Managers.NobManager.Nob.NONE);
            return;
        }

        if (target is Models.CanvasItem) {
            var item = target as Models.CanvasItem;

            double line_width = 0.0;
            item.get ("line-width", out line_width);

            // Each item is always at 0,0 relative to its
            // coordinate system
            double x = 0 - line_width / 2;
            double y = 0 - line_width / 2;

            double width = item.get_coords ("width");
            double height = item.get_coords ("height");

            x -= line_width / 2;
            y -= line_width / 2;
            width += line_width * 2;
            height += line_width * 2;

            if (!item.selected) {
                hover_effect = new Goo.CanvasRect (
                    null,
                    x, y,
                    width, height,
                    "line-width", LINE_WIDTH,
                    "stroke-color", STROKE_COLOR,
                    null
                );

                var transform = Cairo.Matrix.identity ();
                item.get_transform (out transform);
                hover_effect.set_transform (transform);

                hover_effect.set ("parent", canvas.get_root_item ());
                hover_effect.can_focus = false;
            }

            set_cursor_for_nob (Managers.NobManager.Nob.NONE);
        }

        if (target is Selection.Nob) {
            var nob = target as Selection.Nob;
            set_cursor_for_nob (nob.handle_id);
        }

        return;
    }

    public void remove_hover_effect () {
        if (hover_effect != null) {
            hover_effect.remove ();
            hover_effect = null;
        }
    }

    private void set_cursor_for_nob (Lib.Managers.NobManager.Nob grabbed_id) {
        Gdk.CursorType? selected_cursor = null;

        switch (grabbed_id) {
            case Managers.NobManager.Nob.NONE:
                selected_cursor = null;
                break;
            case Managers.NobManager.Nob.TOP_LEFT:
                selected_cursor = Gdk.CursorType.TOP_LEFT_CORNER;
                break;
            case Managers.NobManager.Nob.TOP_CENTER:
                selected_cursor = Gdk.CursorType.TOP_SIDE;
                break;
            case Managers.NobManager.Nob.TOP_RIGHT:
                selected_cursor = Gdk.CursorType.TOP_RIGHT_CORNER;
                break;
            case Managers.NobManager.Nob.RIGHT_CENTER:
                selected_cursor = Gdk.CursorType.RIGHT_SIDE;
                break;
            case Managers.NobManager.Nob.BOTTOM_RIGHT:
                selected_cursor = Gdk.CursorType.BOTTOM_RIGHT_CORNER;
                break;
            case Managers.NobManager.Nob.BOTTOM_CENTER:
                selected_cursor = Gdk.CursorType.BOTTOM_SIDE;
                break;
            case Managers.NobManager.Nob.BOTTOM_LEFT:
                selected_cursor = Gdk.CursorType.BOTTOM_LEFT_CORNER;
                break;
            case Managers.NobManager.Nob.LEFT_CENTER:
                selected_cursor = Gdk.CursorType.LEFT_SIDE;
                break;
            case Managers.NobManager.Nob.ROTATE:
                selected_cursor = Gdk.CursorType.ICON;
                break;
        }

        if (grabbed_id != current_hovering_nob) {
            canvas.window.event_bus.request_change_cursor (selected_cursor);
            current_hovering_nob = grabbed_id;
        }
    }
}
