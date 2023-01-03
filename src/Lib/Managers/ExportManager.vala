/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
    public signal void generating_preview (string message);
    public signal void show_preview (Gee.HashMap<int, Gdk.Pixbuf> pixbufs);
    public signal void preview_finished ();
    public signal void export_finished (string message);

    public enum Type {
        AREA,
        SELECTION,
        ARTBOARD
    }
    private Type export_type;

    public unowned Akira.Lib.ViewCanvas canvas { get; construct; }

    private Cairo.Format format;
    private Cairo.ImageSurface? surface = null;
    private Cairo.Context? context = null;
    private Gdk.PixbufLoader loader;
    private Gee.HashMap<int, Gdk.Pixbuf> pixbufs;

    public ExportManager (Lib.ViewCanvas view_canvas) {
        Object (canvas: view_canvas);
        pixbufs = new Gee.HashMap<int, Gdk.Pixbuf> ();
    }

    public void export_selection () {
        export_type = Type.SELECTION;
        trigger_export_dialog ();
        generate_preview ();
    }

    public void generate_preview () {
        generating_preview (_("Generating preview, please wait…"));
        try {
            init_generate_preview ();
            show_preview (pixbufs);
        } catch (Error e) {
            error ("Could not generate export preview: %s", e.message);
        }
        preview_finished ();
    }

    private void init_generate_preview () throws Error {
        pixbufs.clear ();

        if (settings.export_format == "png") {
            format = Cairo.Format.ARGB32;
        } else if (settings.export_format == "jpg") {
            format = Cairo.Format.RGB24;
        }

        // Loop through all items and clone the model.
        unowned var selection = canvas.selection_manager.selection;
        foreach (var node_id in selection.nodes.keys) {
            var node = canvas.items_manager.node_from_id (node_id);
            // Ignore a node if it doesn't exists, it's not attached to the canvas, or
            // it's part of a group or artbaord. TODO: handle groups and artboards.
            if (node == null || node.parent == null || node.parent.id != Lib.Items.Model.ORIGIN_ID) {
                continue;
            }

            unowned var inst = node.instance;

            // Account for the border size to define the export area.
            double border_size = 0;
            if (inst.components.borders != null) {
                var size = inst.components.borders.get_border_width ();
                // Currently we only support centered border as per SVG specs, but
                // in the future we will support internal and external border types
                // so we will need to account for those.
                border_size = size > 0 ? size / 2 : 0;
            }

            var top = inst.bounding_box.top - border_size;
            var bottom = inst.bounding_box.bottom + border_size;
            var left = inst.bounding_box.left - border_size;
            var right = inst.bounding_box.right + border_size;

            var bounds = Geometry.Rectangle ();
            bounds.top = top;
            bounds.bottom = bottom;
            bounds.left = left;
            bounds.right = right;

            double width = bounds.width;
            double height = bounds.height;
            scale_surface (ref width, ref height);

            // Create the rendered image with Cairo.
            surface = new Cairo.ImageSurface (
                format,
                (int) Math.round (width),
                (int) Math.round (height)
            );
            context = new Cairo.Context (surface);

            // Draw a white background if JPG export.
            if (settings.export_format == "jpg" || !settings.export_alpha) {
                context.set_source_rgba (1, 1, 1, 1);
                context.rectangle (
                    0, 0,
                    (int) Math.round (width),
                    (int) Math.round (height)
                );
                context.fill ();
            }

            scale_context (ref context);

            // Move the context to the right coordinates.
            context.translate (-left, -top);

            // Render what's currently on the canvas inside those coordinates.
            canvas.draw_model (context, bounds);

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
            //  var scaled = rescale_image (loader.get_pixbuf (), bounds);
            var scaled = loader.get_pixbuf ();

            try {
                loader.close ();
            } catch (Error e) {
                throw (e);
            }

            pixbufs.set (node_id, scaled);
        }
    }

    private void scale_surface (ref double width, ref double height) {
        switch (settings.export_scale) {
            case 0:
                width = width / 2;
                height = height / 2;
                break;

            case 2:
                width = width * 2;
                height = height * 2;
                break;

            case 3:
                width = width * 4;
                height = height * 4;
                break;

            default:
                width = width * 1;
                height = height * 1;
                break;
        }
    }

    private void scale_context (ref Cairo.Context context) {
        switch (settings.export_scale) {
            case 0:
                context.scale (0.5, 0.5);
                break;

            case 2:
                context.scale (2, 2);
                break;

            case 3:
                context.scale (4, 4);
                break;

            default:
                context.scale (1, 1);
                break;
        }
    }

    private void trigger_export_dialog () {
        // Disable all those accels interfering with regular typing.
        canvas.window.event_bus.disconnect_typing_accel ();

        var export_dialog = new Akira.Dialogs.ExportDialog (canvas, this);
        export_dialog.show_all ();
        export_dialog.present ();

        // Update the dialog UI based on the stored gsettings options.
        export_dialog.update_format_ui ();

        export_dialog.close.connect (() => {
            // Store the dialog size into gsettings so users don't get upset.
            int width, height;
            export_dialog.get_size (out width, out height);
            settings.export_width = width;
            settings.export_height = height;

            // Enable accels again.
            canvas.window.event_bus.connect_typing_accel ();
            canvas.window.event_bus.set_focus_on_canvas ();

            // Clean up.
            context = null;
            surface.finish ();
            surface = null;
        });
    }

    public async void export_images () {
        /*
        TODO:
         - Implement filenames and don't allow exporting without one.
         - Detect overwriting of existing files.
         - Handle error messages in the dialog.
        */
        generating_preview (_("Exporting images…"));

        SourceFunc callback = export_images.callback;

        new Thread<void*> (null, () => {
            foreach (var entry in pixbufs.entries) {
                var pixbuf = entry.value;
                var node_id = entry.key;

                try {
                    if (settings.export_format == "png") {
                        pixbuf.save (
                            settings.export_folder + "/" + node_id.to_string () + ".png",
                            "png",
                            "compression",
                            settings.export_compression.to_string (),
                            null);
                    }

                    if (settings.export_format == "jpg") {
                        pixbuf.save (
                            settings.export_folder + "/" + node_id.to_string () + ".jpg",
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

        preview_finished ();
        export_finished (_("Export successfully completed!"));
    }
}
