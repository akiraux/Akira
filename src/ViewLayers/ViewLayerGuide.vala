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
    private Lib.Managers.GuideData guide_data;

    public void update_guide_data (Lib.Managers.GuideData data) {
        guide_data = data;
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

        if (guide_data.extents.left > target_bounds.right || guide_data.extents.right < target_bounds.left
            || guide_data.extents.top > target_bounds.bottom || guide_data.extents.bottom < target_bounds.top) {
            return;
        }

        draw_lines (context);
    }

    public override void update () {
        if (canvas == null || guide_data == null) {
            return;
        } else if (guide_data != null) {
            if (guide_data.h_guides == null && guide_data.v_guides == null) {
                return;
            }
        }

        // Optimize this part. Update extents for each line individually.
        //  canvas.request_redraw (old_live_extents);
        canvas.request_redraw (guide_data.extents);
    }

    private void draw_lines (Cairo.Context context) {

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.5, 0.5, 0.5, 1);
        context.set_line_width (1.0 / canvas.scale);
        
        if (guide_data.h_guides != null) {
            foreach (var line in guide_data.h_guides) {
                context.move_to (0, line);
                context.line_to (10000, line);
            }
        }

        if (guide_data.v_guides != null) {
            foreach (var line in guide_data.v_guides) {
                context.move_to (line, 0);
                context.line_to (line, 10000);
            }
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }
 }