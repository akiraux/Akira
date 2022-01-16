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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerNobs : ViewLayer {
    public const double UI_NOB_SIZE = 5;
    public const double UI_LINE_WIDTH = 1.01;
    public const double UI_ANCHOR_LINE_WIDTH = 2.0;

    private Utils.Nobs.NobSet? nobs = null;
    private Utils.Nobs.NobSet? old_nobs = null;

    private Drawables.Drawable? sub_selection_drawable = null;
    private Drawables.Drawable? old_sub_selection_drawable = null;
    private Geometry.Rectangle sub_selection_last_bb_drawn = Geometry.Rectangle.empty ();
    // private bool redraw_only_sub_selection = false;

    public void update_nob_data (Utils.Nobs.NobSet? new_nobs) {
        if (nobs != null) {
            old_nobs = new Utils.Nobs.NobSet.clone (nobs);
        }

        nobs = (new_nobs == null) ? null : new Utils.Nobs.NobSet.clone (new_nobs);
        update ();
    }

    public void add_sub_selection (Drawables.Drawable? new_sub_selection_drawable) {
        if (new_sub_selection_drawable == sub_selection_drawable) {
            return;
        }

        old_sub_selection_drawable = sub_selection_drawable;
        sub_selection_drawable = new_sub_selection_drawable;

        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (is_visible == false) {
            return;
        }

        if (canvas == null || nobs == null || !nobs.any_active ()) {
            return;
        }

        var extents = nobs.extents (canvas.scale, false);
        if (extents == null) {
            return;
        }

        if (extents.left > target_bounds.right || extents.right < target_bounds.left
            || extents.top > target_bounds.bottom || extents.bottom < target_bounds.top) {
            return;
        }

        draw_rect (context, nobs, canvas.scale);
        draw_nobs (context, nobs, canvas.scale);

        if (sub_selection_drawable != null) {
            var color = Gdk.RGBA () { red = 0.25, green = 0.79, blue = 0.98, alpha = 1.0 };
            sub_selection_drawable.paint_anchor (context, color, UI_ANCHOR_LINE_WIDTH, scale);
            sub_selection_last_bb_drawn = sub_selection_drawable.bounds;
        }

        context.new_path ();
    }

    public void draw_nobs (Cairo.Context context, Utils.Nobs.NobSet nobs, double scale) {
        double radius = UI_NOB_SIZE / canvas.scale;
        double line_width = UI_LINE_WIDTH / canvas.scale;

        foreach (var nob in nobs.data) {
            if (!nob.active) {
                continue;
            }
            context.save ();

            context.new_path ();
            context.set_source_rgba (1, 1, 1, 1);
            context.set_line_width (line_width);

            //apply nob transform here

            // Then translate it
            context.translate (nob.center_x, nob.center_y);

            if (nob.handle_id == Utils.Nobs.Nob.ROTATE) {
                context.arc (0, 0, radius, 0, 2.0 * GLib.Math.PI);
            }
            else {
                double x = -radius;
                double w = radius * 2;
                double y = -radius;
                double h = radius * 2;
                context.rectangle (x, y, w, h);
            }

            context.fill_preserve ();
            context.set_source_rgba (0.25, 0.79, 0.98, 1);
            context.stroke ();

            context.restore ();
        }
    }

    public void draw_rect (Cairo.Context context, Utils.Nobs.NobSet nobs, double scale) {
        double line_width = UI_LINE_WIDTH / canvas.scale;
        context.save ();

        context.new_path ();
        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (line_width);

        var tl = nobs.data[Utils.Nobs.Nob.TOP_LEFT];
        var tr = nobs.data[Utils.Nobs.Nob.TOP_RIGHT];
        var bl = nobs.data[Utils.Nobs.Nob.BOTTOM_LEFT];
        var br = nobs.data[Utils.Nobs.Nob.BOTTOM_RIGHT];

        context.move_to (tl.center_x, tl.center_y);
        context.line_to (tr.center_x, tr.center_y);
        context.line_to (br.center_x, br.center_y);
        context.line_to (bl.center_x, bl.center_y);
        context.close_path ();
        context.stroke ();

        var rr = nobs.data[Utils.Nobs.Nob.ROTATE];
        if (rr.active) {
            var tc = nobs.data[Utils.Nobs.Nob.TOP_CENTER];
            context.new_path ();
            context.move_to (rr.center_x, rr.center_y);
            context.line_to (tc.center_x, tc.center_y);
            context.stroke ();
        }

        context.new_path ();

        context.restore ();
    }

    public override void update () {
        if (canvas == null) {
            return;
        }
        update_nobs (old_nobs);
        update_nobs (nobs);
        update_sub_selection ();

        old_nobs = null;
    }

    private void update_sub_selection () {
        if (canvas == null) {
            return;
        }

        if (old_sub_selection_drawable != null) {
            canvas.request_redraw (sub_selection_last_bb_drawn);
            old_sub_selection_drawable = null;
        }

        if (sub_selection_drawable != null) {
            canvas.request_redraw (sub_selection_drawable.bounds);
        }
    }

    private void update_nobs (Utils.Nobs.NobSet? nobs) {
        if (canvas == null || nobs == null) {
            return;
        }

        var extents = nobs.extents (canvas.scale, true);
        if (extents == null) {
            return;
        }

        canvas.request_redraw (extents);
    }

}
