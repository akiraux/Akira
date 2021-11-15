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
    private Lib.Managers.GuideData? guide_data;
    private Lib.Managers.GuideData? old_data;

    public ViewLayerGuide () {
    }
    public void update_guide_data (Lib.Managers.GuideData data) {
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

        foreach (var line in guide_data.h_guides) {
            var extents = Geometry.Rectangle.empty ();
            extents.left = 0;
            extents.right = 10000;
            extents.top = line - 1;
            extents.bottom = line + 1;

            if (extents.left > target_bounds.right || extents.right < target_bounds.left
                || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
                continue;
            }

            draw_line (context, line, Lib.Managers.GuideManager.Direction.HORIZONTAL);
        }

        foreach (var line in guide_data.v_guides) {
            var extents = Geometry.Rectangle.empty ();
            extents.left = line - 1;
            extents.right = line + 1;
            extents.top = 0;
            extents.bottom = 10000;

            if (extents.left > target_bounds.right || extents.right < target_bounds.left
                || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
                continue;
            }

            draw_line (context, line, Lib.Managers.GuideManager.Direction.VERTICAL);
        }

        draw_highlighted_guide (context);
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

    private void perform_redraw (Lib.Managers.GuideData data) {
        foreach (var line in data.v_guides) {
            var extents = Geometry.Rectangle.empty ();
            extents.left = line - 1;
            extents.right = line + 1;
            extents.top = 0;
            extents.bottom = 10000;

            canvas.request_redraw (extents);
        }

        foreach (var line in data.h_guides) {
            var extents = Geometry.Rectangle.empty ();
            extents.top = line - 1;
            extents.bottom = line + 1;
            extents.left = 0;
            extents.right = 10000;

            canvas.request_redraw (extents);
        }
    }

    private void draw_line (Cairo.Context context, double pos, Lib.Managers.GuideManager.Direction dir) {

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.6235, 0.1686, 0.4078, 1);
        context.set_line_width (1.0 / canvas.scale);

        if (dir == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            context.move_to (0, pos);
            context.line_to (10000, pos);
        } else {
            context.move_to (pos, 0);
            context.line_to (pos, 10000);
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

        if (guide_data.highlight_direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            var guide = guide_data.h_guides[guide_data.highlight_guide];
            context.move_to (0, guide);
            context.line_to (10000, guide);
        } else if (guide_data.highlight_direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            var guide = guide_data.v_guides[guide_data.highlight_guide];
            context.move_to (guide, 0);
            context.line_to (guide, 10000);
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }
 }
