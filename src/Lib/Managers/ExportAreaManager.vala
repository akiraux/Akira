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
    public Akira.Dialogs.ExportDialog export_dialog;

    private double initial_x;
    private double initial_y;
    private double initial_width;
    private double initial_height;

    public Goo.CanvasRect area;
    public Cairo.Format format;
    public Cairo.Surface surface;
    public Cairo.Context context;
    public Gdk.PixbufLoader loader;
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
            "line-width", LINE_WIDTH / canvas.current_scale,
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
        // Hide the area before rendering.
        area.visibility = Goo.CanvasItemVisibility.INVISIBLE;
        // Open Export Dialog before we have the preview.
        trigger_export_dialog ();
        // Generate the image to export.
        init_generate_pixbuf.begin ();
    }

    /**
     * Use multithreading to handle async pixbuf loading without freezing the UI.
     */
    public async void init_generate_pixbuf () throws ThreadError {
        if (Thread.supported () == false) {
            error ("Threads are not supported!");
        }

        canvas.window.event_bus.generating_preview ();
        SourceFunc callback = init_generate_pixbuf.callback;

        new Thread<void*> (null, () => {
            try {
                generate_pixbuf ();
            } catch (Error e) {
                error ("Could not generate export preview: %s", e.message);
            }

            Idle.add ((owned) callback);
            export_dialog.generate_export_preview.begin ();
            canvas.window.event_bus.preview_completed ();
            Thread.exit (null);
            return null;
        });

        yield;
    }

    public void generate_pixbuf () throws Error {
        if (settings.export_format == "png") {
            format = Cairo.Format.ARGB32;
        } else if (settings.export_format == "jpg") {
            format = Cairo.Format.RGB24;
        }

        // Create the rendered image with Cairo.
        surface = new Cairo.ImageSurface (
            format,
            (int) Math.round (area.width),
            (int) Math.round (area.height)
        );
        context = new Cairo.Context (surface);

        // Draw a white background if JPG export.
        if (settings.export_format == "jpg" || !settings.export_alpha) {
            context.set_source_rgba (1, 1, 1, 1);
            context.rectangle (0, 0, (int) Math.round (area.width), (int) Math.round (area.height));
            context.fill ();
        }

        // Move to the currently selected area.
        context.translate (-area.bounds.x1, -area.bounds.y1);

        // Render the selected area.
        canvas.render (context, null, canvas.current_scale);

        // Create pixbuf from stream.
        try {
            loader = new Gdk.PixbufLoader.with_mime_type ("image/png");
        } catch (Error e) {
            throw (e);
        }

        surface.write_to_png_stream ((data) => {
            try {
                loader.write ((uint8 []) data);
            } catch (Error e) {
                return Cairo.Status.DEVICE_ERROR;
            }
            return Cairo.Status.SUCCESS;
        });
        var scaled = rescale_image (loader.get_pixbuf ());

        try {
            loader.close ();
        } catch (Error e) {
            throw (e);
        }
        pixbuf = scaled;
    }

    public Gdk.Pixbuf rescale_image (Gdk.Pixbuf pixbuf) {
        Gdk.Pixbuf scaled_image;

        switch (settings.export_scale) {
            case 0:
                scaled_image = pixbuf.scale_simple (
                    (int) area.width / 2,
                    (int) area.height / 2,
                    Gdk.InterpType.BILINEAR
                );
                break;

            case 2:
                scaled_image = pixbuf.scale_simple (
                    (int) area.width * 2,
                    (int) area.height * 2,
                    Gdk.InterpType.BILINEAR
                );
                break;

            case 3:
                scaled_image = pixbuf.scale_simple (
                    (int) area.width * 4,
                    (int) area.height * 4,
                    Gdk.InterpType.BILINEAR
                );
                break;

            default:
                scaled_image = pixbuf.scale_simple (
                    (int) area.width * 1,
                    (int) area.height * 1,
                    Gdk.InterpType.BILINEAR
                );
                break;
        }

        return scaled_image;
    }

    public void trigger_export_dialog () {
        // Disable all those accels interfering with regular typing.
        canvas.window.event_bus.disconnect_typing_accel ();

        export_dialog = new Akira.Dialogs.ExportDialog (canvas.window, this);
        export_dialog.show_all ();
        export_dialog.present ();

        // Update the dialog UI based on the stored gsettings options.
        export_dialog.update_format_ui ();

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

    public void export_images () {
        pixbuf = rescale_image (pixbuf);
        try {
            if (settings.export_format == "png") {
                pixbuf.save (
                    settings.export_folder + "/test.png",
                    "png",
                    "compression",
                    settings.export_compression.to_string (),
                    null);
            } else if (settings.export_format == "jpg") {
                pixbuf.save (
                    settings.export_folder + "/test.jpg",
                    "jpeg",
                    "quality",
                    settings.export_quality.to_string (),
                    null);
            }
        } catch (Error e) {
            error ("Unable to export images: %s", e.message);
        }
    }
}
