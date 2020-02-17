/*
 * Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Managers.ExportAreaManager : Object {
    private const string COLOR = "#41c9fd";
    private const double LINE_WIDTH = 2.0;
    private const double MIN_SIZE = 1.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }

    private double initial_x;
    private double initial_y;
    private double initial_width;
    private double initial_height;

    public Goo.CanvasRect area;
    public Cairo.Surface surface;
    public Cairo.Context context;
    public Gdk.Pixbuf pixbuf;

    public ExportAreaManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    public Goo.CanvasRect create_area (Gdk.EventButton event) {
        var dash = new Goo.CanvasLineDash (2, 5.0, 5.0);
        var rgba_fill = Gdk.RGBA ();
        rgba_fill.parse (COLOR);
        rgba_fill.alpha = 0.1;
        uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);

        area = new Goo.CanvasRect (
            null,
            Utils.AffineTransform.fix_size (event.x),
            Utils.AffineTransform.fix_size (event.y),
            1.0, 1.0,
            "line-width", LINE_WIDTH,
            "stroke-color", COLOR,
            "line-dash", dash,
            "fill-color-rgba", fill_color_rgba,
            null
        );

        initial_x = event.x;
        initial_y = event.y;
        initial_width = 1.0;
        initial_height = 1.0;

        area.set ("parent", canvas.get_root_item ());
        area.can_focus = false;

        return area;
    }

    public void resize_area (double x, double y) {
        canvas.convert_to_item_space (area, ref x, ref y);

        double delta_x = x - initial_x;
        double delta_y = y - initial_y;

        double item_width = area.width;
        double item_height = area.height;

        double new_width = item_width;
        double new_height = item_height;

        double origin_move_delta_x = 0.0;
        double origin_move_delta_y = 0.0;

        new_width = initial_width + delta_x;
        new_height = initial_height + delta_y;
        if (canvas.ctrl_is_pressed && new_height > MIN_SIZE) {
            new_height = new_width;
        }

        if (new_width < initial_width) {
            new_width = initial_width - delta_x;
            origin_move_delta_x = item_width - new_width;
        }

        if (new_height < MIN_SIZE) {
            new_height = initial_height - delta_y;
            origin_move_delta_y = item_height - new_height;
        }

        new_width = Utils.AffineTransform.fix_size (new_width);
        new_height = Utils.AffineTransform.fix_size (new_height);
        origin_move_delta_x = Utils.AffineTransform.fix_size (origin_move_delta_x);
        origin_move_delta_y = Utils.AffineTransform.fix_size (origin_move_delta_y);

        canvas.convert_from_item_space (area, ref initial_x, ref initial_y);
        area.translate (origin_move_delta_x, origin_move_delta_y);
        canvas.convert_to_item_space (area, ref initial_x, ref initial_y);

        Utils.AffineTransform.set_size (new_width, new_height, area);
    }

    public void clear () {
        if (area == null) {
            return;
        }

        area.remove ();
    }

    public void create_export_snapshot () {
        // Create the rendered image with Cairo.
        surface = new Cairo.ImageSurface (
            Cairo.Format.ARGB32,
            (int) Math.round (area.width),
            (int) Math.round (area.height)
        );
        context = new Cairo.Context (surface);
        context.translate (-area.bounds.x1, -area.bounds.y1);

        // Hide the area before rendering.
        area.visibility = Goo.CanvasItemVisibility.INVISIBLE;

        // Render the selected area.
        canvas.render (context, null, settings.export_scale);

        // Create pixbuf from stream.
        var loader = new Gdk.PixbufLoader.with_mime_type("image/png");
        surface.write_to_png_stream ((data) => {
            try {
                loader.write ((uint8 []) data);
            } catch (Error e) {
                return Cairo.Status.DEVICE_ERROR;
            }
            return Cairo.Status.SUCCESS;
        });
        pixbuf = loader.get_pixbuf ();
        loader.close ();

        //  pixbuf.save ("test.jpg", "jpeg", "quality", "100", null);
        //  pixbuf.save ("test.png", "png", "compression", "0", null);

        // Open Export Dialog with the preview.
        trigger_export_dialog ();
    }

    public void trigger_export_dialog () {
        // Disable all those accels interfering with regular typing.
        canvas.window.event_bus.disconnect_typing_accel ();

        var export_dialog = new Akira.Dialogs.ExportDialog (canvas.window, this);
        export_dialog.show_all ();
        export_dialog.present ();

        // Update the dialog UI based on the stored gsettings options.
        export_dialog.update_format_ui ();
        export_dialog.generate_export_preview ();

        // Store the dialog size into gsettings users don't get upset.
        export_dialog.close.connect (() => {
            int width, height;

            export_dialog.get_size (out width, out height);
            settings.export_width = width;
            settings.export_height = height;

            canvas.window.event_bus.connect_typing_accel ();
            canvas.window.event_bus.set_focus_on_canvas ();

            // Clean up the Manager.
            context = null;
            surface = null;
            clear ();
        });
    }
}
