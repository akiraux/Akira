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
 *
 * Parts of this code are taken from GooCanvas
 */

/*
 * Drawable for rects.
 */
public class Akira.Drawables.DrawableText : Drawable {

    public DrawableText (double tl_x, double tl_y, double width, double height, string text) {
       this.center_x = tl_x + width / 2.0;
       this.center_y = tl_y + height / 2.0;
       this.width = width;
       this.height = height;
       this.label = text;
    }

    public override void simple_create_path (Cairo.Context context) {
        var w = width;
        var h = height;
        var x = center_x - w / 2.0;
        var y = center_y - h / 2.0;


        context.rectangle (x, y, w, h);
    }

    public override void paint (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        // Simple bounds check
        if (bounds.left > target_bounds.right || bounds.right < target_bounds.left
            || bounds.top > target_bounds.bottom || bounds.bottom < target_bounds.top) {
            return;
        }

        context.save ();
        context.transform (transform);
        context.set_source_rgba (0.0, 0.0, 0.0, 1.0);
        draw_text (context, scale);
        context.restore ();

        context.new_path ();

        is_drawn = true;
    }

    private void draw_text (Cairo.Context context, double scale) {
        var m = 0;//label_margin (scale);

        var w = bounds.width - m * 2;
        var h = bounds.height - m * 2;
        var x = center_x - w / 2.0;
        var y = center_y - h / 2.0;

        if (w <= 0 || h <= 0) {
            return;
        }

        Cairo.Matrix global_transform = context.get_matrix ();
        var tr = transform;
        context.set_matrix (tr);

        var layout = create_pango_layout (context, label, w, scale, null);
        context.set_matrix (global_transform);
        context.rectangle(x, y, w, h);
        context.clip();
        context.move_to (x, y);
        Pango.cairo_show_layout (context, layout);
    }

    private static Pango.Layout create_pango_layout (
        Cairo.Context context,
        string text,
        double layout_width,
        double scale,
        double* extent_width
    ) {
        var layout = Pango.cairo_create_layout (context);
        var pango_context = layout.get_context ();

        if (layout_width > 0) {
            layout.set_width ( (int)(layout_width * Pango.SCALE));
        }

        layout.set_text (text, -1);

        // Load font description
        var desc = new Pango.FontDescription ();
        desc.set_family ("Open Sans");
        desc.set_size ((int) (10 * Pango.SCALE));
        layout.set_font_description (desc);

        // Load hint metrics

        var font_options = new Cairo.FontOptions ();
        font_options.set_hint_metrics (Cairo.HintMetrics.DEFAULT);
        Pango.cairo_context_set_font_options (pango_context, font_options);

        //layout.set_alignment (Pango.Alignment.LEFT);
        //layout.set_ellipsize (Pango.EllipsizeMode.END);
        layout.set_wrap (Pango.WrapMode.WORD);
        return layout;
    }

}
