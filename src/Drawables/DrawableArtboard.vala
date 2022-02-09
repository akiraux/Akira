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
 */

/*
 * Drawable for artboards.
 */
public class Akira.Drawables.DrawableArtboard : Drawable {
    private const double LABEL_HEIGHT = 20;
    private const double LABEL_MARGIN = 5;

    public DrawableArtboard (double tl_x, double tl_y, double width, double height) {
       this.center_x = tl_x + width / 2.0;
       this.center_y = tl_y + height / 2.0;
       this.width = width;
       this.height = height;
    }

    public override bool hit_test (
        double x,
        double y,
        Cairo.Context context,
        double scale,
        Drawable.HitTestType hit_test_type
    ) {
        if (hit_test_type == GROUP_REGION) {
            return base.hit_test (x, y, context, scale, Drawable.HitTestType.SELECT);
        }

        var lheight = LABEL_HEIGHT / scale;
        var lbot = bounds.top;
        var ltop = lbot - lheight;

        var m = label_margin (scale);
        var w = bounds.width - m * 2;
        if (w <= 0) {
            return false;
        }

        double extent_width = 0;
        create_pango_layout (context, label, w, scale, &extent_width);
        extent_width /= scale;
        return !(x < bounds.left || x > bounds.left + extent_width + m * 2 || y < ltop || y > lbot);
    }

    public override void simple_create_path (Cairo.Context context) {
        Drawables.DrawableRect.rect_path (context, this);
    }

    public override void paint (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        base.paint (context, target_bounds, scale);

        draw_text (context, scale);
    }

    private void draw_text (Cairo.Context context, double scale) {
        var m = label_margin (scale);
        var w = bounds.width - m * 2;
        if (w <= 0) {
            return;
        }

        context.save ();

        if (settings.follow_system_theme) {
            var granite_settings = Granite.Settings.get_default ();
            if (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                context.set_source_rgba (1, 1, 1, 0.75);
            } else {
                context.set_source_rgba (0, 0, 0, 0.75);
            }
        } else {
            if (settings.dark_theme) {
                context.set_source_rgba (1, 1, 1, 0.75);
            } else {
                context.set_source_rgba (0, 0, 0, 0.75);
            }
        }

        var layout = create_pango_layout (context, label, w, scale, null);
        context.move_to (bounds.left + m, bounds.top - LABEL_HEIGHT / scale);
        context.scale (1 / scale, 1 / scale);
        Pango.cairo_show_layout (context, layout);

        context.restore ();
        context.new_path ();
    }

    private static Pango.Layout create_pango_layout (
        Cairo.Context context,
        string text,
        double layout_width,
        double scale,
        double* extent_width
    ) {
        var p_layout = Pango.cairo_create_layout (context);
        var p_context = p_layout.get_context ();

        if (layout_width > 0) {
            p_layout.set_width ( (int)(layout_width * Pango.SCALE));
        }

        p_layout.set_text (text, -1);

        // Load font description
        var desc = new Pango.FontDescription ();
        desc.set_family ("Open Sans");
        desc.set_size ((int) (10 * Pango.SCALE));
        p_layout.set_font_description (desc);

        // Load hint metrics

        var font_options = new Cairo.FontOptions ();
        font_options.set_hint_metrics (Cairo.HintMetrics.DEFAULT);
        Pango.cairo_context_set_font_options (p_context, font_options);

        p_layout.set_alignment (Pango.Alignment.LEFT);
        p_layout.set_ellipsize (Pango.EllipsizeMode.END);
        p_layout.set_wrap (Pango.WrapMode.WORD);

        if (extent_width != null) {
            Pango.Rectangle ink_rect;
            Pango.Rectangle logical_rect;
            p_layout.get_extents (out ink_rect, out logical_rect);

            var logical_width = (double) logical_rect.width / Pango.SCALE;
            *extent_width = logical_width;
        }

        return p_layout;
    }

    /*
     * Hover paint method for the drawable.
     */
    public override void paint_hover (
        Cairo.Context context,
        Gdk.RGBA color,
        double line_width,
        Geometry.Rectangle target_bounds,
        double scale
    ) {
        base.paint_hover (context, color, line_width, target_bounds, scale);
    }

    public override Geometry.Rectangle generate_bounding_box () {
        var r = base.generate_bounding_box ();
        return r;
    }

    public override void request_redraw (ViewLayers.BaseCanvas canvas, bool recalculate_bounds) {
        if (recalculate_bounds) {
            bounds = generate_bounding_box ();
        }
        else if (!is_drawn) {
            // This request is to clear the old draw, but since it was never drawn, we can ignore.
            return;
        }

        var tb = bounds;
        tb.top -= LABEL_HEIGHT / canvas.scale;
        canvas.request_redraw (tb);
    }

    protected double label_margin (double scale) {
        return LABEL_MARGIN / scale;
    }
}
