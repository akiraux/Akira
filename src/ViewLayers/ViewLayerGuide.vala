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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

 public class Akira.ViewLayers.ViewLayerGuide : ViewLayer {
    private Models.GuidelineModel? guide_data;
    private Models.GuidelineModel? old_data;

    public ViewLayerGuide () {
    }
    public void update_guide_data (Models.GuidelineModel data) {
        old_data = (guide_data == null) ? null : guide_data.copy ();
        guide_data = data.copy ();

        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (!is_visible || canvas == null) {
            return;
        }

        if (guide_data == null) {
            return;
        } else {
            // If neither kind of guides are present, only then exit.
            if (guide_data.h_guides == null && guide_data.v_guides == null) {
                return;
            }
        }

        var artboard_extents = guide_data.drawable_extents;

        foreach (var line in guide_data.h_guides.elements) {
            var extents = Geometry.Rectangle.empty ();

            extents.left = artboard_extents.left;
            extents.right = artboard_extents.right;
            extents.top = line - 1;
            extents.bottom = line + 1;

            if (extents.left > target_bounds.right || extents.right < target_bounds.left
                || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
                continue;
            }

            draw_line (context, line, Lib.Managers.GuideManager.Direction.HORIZONTAL);
        }

        foreach (var line in guide_data.v_guides.elements) {
            var extents = Geometry.Rectangle.empty ();

            extents.left = line - 1;
            extents.right = line + 1;
            extents.top = artboard_extents.top;
            extents.bottom = artboard_extents.bottom;

            if (extents.left > target_bounds.right || extents.right < target_bounds.left
                || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
                continue;
            }

            draw_line (context, line, Lib.Managers.GuideManager.Direction.VERTICAL);
        }

        draw_highlighted_guide (context);

        draw_distances (context);
    }

    public override void update () {
        if (canvas == null || guide_data == null) {
            return;
        } else if (guide_data != null) {
            if (guide_data.h_guides == null && guide_data.v_guides == null) {
                return;
            }
        }

        if (old_data != null) {
            perform_redraw (old_data);
            old_data = null;
        }

        if (guide_data != null) {
            perform_redraw (guide_data);
        }
    }

    private void perform_redraw (Models.GuidelineModel data) {
        var artboard_extents = data.drawable_extents;

        // Draw all vertical guidelines.
        foreach (var line in data.v_guides.elements) {
            var extents = Geometry.Rectangle.empty ();

            extents.left = line - 1;
            extents.right = line + 1;
            extents.top = artboard_extents.top;
            extents.bottom = artboard_extents.bottom;

            canvas.request_redraw (extents);
        }

        // Draw all horizontal guidelines.
        foreach (var line in data.h_guides.elements) {
            var extents = Geometry.Rectangle.empty ();

            extents.top = line - 1;
            extents.bottom = line + 1;
            extents.left = artboard_extents.left;
            extents.right = artboard_extents.right;

            canvas.request_redraw (extents);
        }

        // Draw the highlighted guideline.
        var highlight_extents = Geometry.Rectangle.empty ();

        if (data.highlight_direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            highlight_extents.top = data.highlight_position - 1;
            highlight_extents.bottom = data.highlight_position + 1;
            highlight_extents.left = artboard_extents.left;
            highlight_extents.right = artboard_extents.right;
        } else if (data.highlight_direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            highlight_extents.left = data.highlight_position - 1;
            highlight_extents.right = data.highlight_position + 1;
            highlight_extents.top = artboard_extents.top;
            highlight_extents.bottom = artboard_extents.bottom;
        }

        canvas.request_redraw (highlight_extents);

        // Draw the distance text.
        var distance_extents = Geometry.Rectangle.empty ();

        distance_extents.left = data.cursor_position.x - 90;
        distance_extents.right = data.cursor_position.x + 90;
        distance_extents.top = data.cursor_position.y - 14;
        distance_extents.bottom = data.cursor_position.y + 14;

        canvas.request_redraw (distance_extents);
    }

    private void draw_line (Cairo.Context context, double pos, Lib.Managers.GuideManager.Direction dir) {

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.6235, 0.1686, 0.4078, 1);
        context.set_line_width (1.0 / canvas.scale);

        var artboard_extents = guide_data.drawable_extents;

        if (dir == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            context.move_to (artboard_extents.left, pos);
            context.line_to (artboard_extents.right, pos);
        } else {
            context.move_to (pos, artboard_extents.top);
            context.line_to (pos, artboard_extents.bottom);
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }

    private void draw_highlighted_guide (Cairo.Context context) {
        context.save ();

        context.new_path ();
        context.set_source_rgba (0.8705, 0.1921, 0.3882, 1);
        context.set_line_width (2.0 / canvas.scale);

        var artboard_extents = guide_data.drawable_extents;

        if (guide_data.highlight_direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            context.move_to (artboard_extents.left, guide_data.highlight_position);
            context.line_to (artboard_extents.right, guide_data.highlight_position);
        } else if (guide_data.highlight_direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            context.move_to (guide_data.highlight_position, artboard_extents.top);
            context.line_to (guide_data.highlight_position, artboard_extents.bottom);
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }

    private void draw_distances (Cairo.Context context) {
        context.set_source_rgba (0.8705, 0.1921, 0.3882, 1);
        context.select_font_face ("monospace", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        context.set_font_size (14);

        double x = guide_data.cursor_position.x - 50;
        double y = guide_data.cursor_position.y - 5;

        context.move_to (x, y);
        context.show_text (guide_data.distances);
    }
 }
