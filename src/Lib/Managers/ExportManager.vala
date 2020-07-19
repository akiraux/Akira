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

public class Akira.Lib.Managers.ExportManager : Object {
    private const string COLOR = "#41c9fd";
    private const double LINE_WIDTH = 2.0;
    private const double MIN_SIZE = 1.0;

    public enum Type {
        AREA,
        SELECTION,
        ARTBOARD
    }

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
    public Gee.HashMap<string, Gdk.Pixbuf> pixbufs { get; set construct; }

    public ExportManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
        pixbufs = new Gee.HashMap<string, Gdk.Pixbuf> ();
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
            2.0, 2.0,
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

        Utils.AffineTransform.set_size (area, new_width, new_height);
    }

    public void clear () {
        if (area == null) {
            return;
        }

        area.remove ();
    }

    /**
     * Trigger the creation of the pixbuf for the export_area action.
     */
    public void create_area_snapshot () {
        // Hide the area before rendering.
        area.visibility = Goo.CanvasItemVisibility.INVISIBLE;
        // Open Export Dialog before we have the preview.
        trigger_export_dialog (Type.AREA);
        // Generate the image to export.
        init_generate_area_pixbuf.begin ();
    }

    /**
     * Trigger the creation of the pixbuf for the export_selection action.
     */
    public void create_selection_snapshot () {
        canvas.window.event_bus.hide_select_effect ();
        // Open Export Dialog before we have the preview.
        trigger_export_dialog (Type.SELECTION);
        // Generate the image to export.
        init_generate_selection_pixbuf.begin ();
    }

    public void regenerate_pixbuf (Type type) {
        switch (type) {
            case AREA:
                init_generate_area_pixbuf.begin ();
                break;
            case SELECTION:
                canvas.window.event_bus.hide_select_effect ();
                init_generate_selection_pixbuf.begin ();
                break;
        }
    }

    /**
     * Use multithreading to handle async pixbuf loading without freezing the UI.
     */
    public async void init_generate_area_pixbuf () throws ThreadError {
        if (Thread.supported () == false) {
            error ("Threads are not supported!");
        }

        canvas.window.event_bus.export_preview (_("Generating preview, please wait…"));
        SourceFunc callback = init_generate_area_pixbuf.callback;

        new Thread<void*> (null, () => {
            try {
                generate_area_pixbuf ();
            } catch (Error e) {
                error ("Could not generate export preview: %s", e.message);
            }

            Idle.add ((owned) callback);
            Thread.exit (null);

            return null;
        });

        yield;

        yield export_dialog.generate_export_preview ();
        canvas.window.event_bus.preview_completed ();
    }

    public async void init_generate_selection_pixbuf () throws ThreadError {
        if (Thread.supported () == false) {
            error ("Threads are not supported!");
        }

        canvas.window.event_bus.export_preview (_("Generating preview, please wait…"));
        SourceFunc callback = init_generate_selection_pixbuf.callback;

        new Thread<void*> (null, () => {
            try {
                generate_selection_pixbuf ();
            } catch (Error e) {
                error ("Could not generate export preview: %s", e.message);
            }

            Idle.add ((owned) callback);
            Thread.exit (null);

            return null;
        });

        yield;

        yield export_dialog.generate_export_preview ();
        canvas.window.event_bus.preview_completed ();
        canvas.window.event_bus.show_select_effect ();
    }

    public void generate_area_pixbuf () throws Error {
        // Clear pixbuf array from previously stored values.
        pixbufs.clear ();

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

        pixbufs.set (_("Untitled"), scaled);
    }

    public void generate_selection_pixbuf () throws Error {
        // Clear pixbuf array from previously stored values.
        pixbufs.clear ();

        if (settings.export_format == "png") {
            format = Cairo.Format.ARGB32;
        } else if (settings.export_format == "jpg") {
            format = Cairo.Format.RGB24;
        }

        // Loop through all the currently selected elements.
        for (var i = 0; i < canvas.selected_bound_manager.selected_items.length (); i++) {
            var label_height = 0.0;
            var item = canvas.selected_bound_manager.selected_items.nth_data (i);
            var name = _("Untitled %i").printf (i);

            // Weird goocanvas issue which sets the border to 0.**** instead of 0
            // which causes a half pixel white border on export.
            if (item.line_width < 1) {
                var fill_color = item.fill_color_rgba;
                item.set ("stroke-color-rgba", fill_color);
                item.set ("line-width", 0.0);
            }

            // If the item is an artboard, account for the label's height.
            if (item is Akira.Lib.Models.CanvasArtboard) {
                var artboard = item as Akira.Lib.Models.CanvasArtboard;
                label_height = artboard.get_label_height ();
                name = artboard.name != null ? artboard.name : name;
            }

            // Account for items inside or outside artboards.
            double x1 = item.get_global_coord ("x");
            double x2 = x1 + item.get_coords ("width");
            double y1 = item.get_global_coord ("y");
            double y2 = y1 + item.get_coords ("height");

            // Create the rendered image with Cairo.
            surface = new Cairo.ImageSurface (
                format,
                (int) Math.round (x2 - x1),
                (int) Math.round (y2 - y1 - label_height)
            );
            context = new Cairo.Context (surface);

            // Draw a white background if JPG export.
            if (settings.export_format == "jpg" || !settings.export_alpha) {
                context.set_source_rgba (1, 1, 1, 1);
                context.rectangle (
                    0, 0,
                    (int) Math.round (x2 - x1),
                    (int) Math.round (y2 - y1 - label_height));
                context.fill ();
            }

            // Move to the currently selected item.
            context.translate (-x1, -y1 - label_height);

            // Render the selected item.
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
            var scaled = rescale_image (loader.get_pixbuf (), item);

            try {
                loader.close ();
            } catch (Error e) {
                throw (e);
            }

            pixbufs.set (name, scaled);
        }
    }

    public Gdk.Pixbuf rescale_image (Gdk.Pixbuf pixbuf, Lib.Models.CanvasItem? item = null) {
        Gdk.Pixbuf scaled_image;
        var label_height = 0.0;

        // If the item is an artboard, account for the label's height.
        if (item != null && item is Akira.Lib.Models.CanvasArtboard) {
            var artboard = item as Akira.Lib.Models.CanvasArtboard;
            label_height = artboard.get_label_height ();
        }

        // Account for items inside or outside artboards.
        double x1 = item.get_global_coord ("x");
        double x2 = x1 + item.get_coords ("width");
        double y1 = item.get_global_coord ("y");
        double y2 = y1 + item.get_coords ("height");

        var width = item != null ? x2 - x1 : area.width;
        var height = item != null ? y2 - y1 - label_height : area.height;

        switch (settings.export_scale) {
            case 0:
                scaled_image = pixbuf.scale_simple (
                    (int) width / 2,
                    (int) height / 2,
                    Gdk.InterpType.BILINEAR
                );
                break;

            case 2:
                scaled_image = pixbuf.scale_simple (
                    (int) width * 2,
                    (int) height * 2,
                    Gdk.InterpType.BILINEAR
                );
                break;

            case 3:
                scaled_image = pixbuf.scale_simple (
                    (int) width * 4,
                    (int) height * 4,
                    Gdk.InterpType.BILINEAR
                );
                break;

            default:
                scaled_image = pixbuf.scale_simple (
                    (int) width * 1,
                    (int) height * 1,
                    Gdk.InterpType.BILINEAR
                );
                break;
        }

        return scaled_image;
    }

    public void trigger_export_dialog (Type type) {
        // Disable all those accels interfering with regular typing.
        canvas.window.event_bus.disconnect_typing_accel ();

        export_dialog = new Akira.Dialogs.ExportDialog (canvas.window, this, type);
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

    public async void export_images () {
        canvas.window.event_bus.exporting (_("Exporting images…"));

        SourceFunc callback = export_images.callback;

        new Thread<void*> (null, () => {
            for (int i = 0; i < export_dialog.list_store.get_n_items (); i++) {
                var model = (Akira.Models.ExportModel) export_dialog.list_store.get_object (i);

                try {
                    if (settings.export_format == "png") {
                        model.pixbuf.save (
                            settings.export_folder + "/" + model.filename + ".png",
                            "png",
                            "compression",
                            settings.export_compression.to_string (),
                            null);
                    } else if (settings.export_format == "jpg") {
                        model.pixbuf.save (
                            settings.export_folder + "/" + model.filename + ".jpg",
                            "jpeg",
                            "quality",
                            settings.export_quality.to_string (),
                            null);
                    }
                } catch (Error e) {
                    error ("Unable to export images: %s", e.message);
                }
            }

            Idle.add ((owned) callback);
            Thread.exit (null);

            return null;
        });

        yield;

        canvas.window.event_bus.export_completed ();
    }
}
