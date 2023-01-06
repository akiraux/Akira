/**
 * Copyright (c) 2022-2023 Alecaddd (https://alecaddd.com)
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
    public signal void busy (string message);
    public signal void show_preview (Gee.HashMap<int, Gdk.Pixbuf> pixbufs);
    public signal void free ();
    public signal void export_finished (string message);

    public enum Type {
        AREA,
        SELECTION,
        ARTBOARD
    }
    private Type export_type;
    private Akira.Geometry.Rectangle area;

    public unowned Akira.Lib.ViewCanvas canvas { get; construct; }

    private Cairo.Format format;
    private Cairo.ImageSurface? surface = null;
    private Cairo.Context? context = null;
    private Gdk.PixbufLoader loader;
    private Gee.HashMap<int, Gdk.Pixbuf> pixbufs;

    private GLib.Cancellable? preview_cancellable;

    public ExportManager (Lib.ViewCanvas view_canvas) {
        Object (canvas: view_canvas);
        pixbufs = new Gee.HashMap<int, Gdk.Pixbuf> ();
    }

    public async void export_selection () {
        export_type = Type.SELECTION;
        trigger_export_dialog ();
        if (preview_cancellable != null) {
            preview_cancellable.cancel ();
        }

        preview_cancellable = new GLib.Cancellable ();
        yield generate_preview (preview_cancellable);
    }

    public async void export_area (Geometry.Rectangle bounds) {
        export_type = Type.AREA;
        area = bounds;
        trigger_export_dialog ();
        if (preview_cancellable != null) {
            preview_cancellable.cancel ();
        }

        preview_cancellable = new GLib.Cancellable ();
        yield generate_preview (preview_cancellable);
    }

    public async void generate_preview (GLib.Cancellable cancellable) {
        busy (_("Generating preview, please wait…"));

        yield init_generate_preview (cancellable);
        show_preview (pixbufs);

        free ();
    }

    private async void init_generate_preview (GLib.Cancellable cancellable) {
        pixbufs.clear ();

        if (settings.export_format == "png") {
            format = Cairo.Format.ARGB32;
        } else if (settings.export_format == "jpg") {
            format = Cairo.Format.RGB24;
        }

        switch (export_type) {
            case Type.SELECTION:
                yield generate_selection_pixbufs (cancellable);
                break;
            case Type.AREA:
                yield generate_area_pixbuf (cancellable);
                break;
        }
    }

    private async void generate_area_pixbuf (GLib.Cancellable cancellable) {
        yield generate_image_surface (area);
        var pixbuf = yield generate_pixbuf (surface);

        pixbufs.set (9999, pixbuf);
    }

    private async void generate_selection_pixbufs (GLib.Cancellable cancellable) {
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

            yield generate_image_surface (bounds);
            var pixbuf = yield generate_pixbuf (surface);

            pixbufs.set (node_id, pixbuf);
        }
    }

    private async void generate_image_surface (Geometry.Rectangle bounds) {
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
        context.translate (-bounds.left, -bounds.top);
        // Render what's currently on the canvas inside those coordinates.
        canvas.draw_model (context, bounds);
    }

    /*
     * Scale the cairo surface to match the scaled canvas based on the chosen
     * resolution from the user. This is to guarantee a sharp preview.
     */
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

    /*
     * Scale the canvas context to match the user's export resolution.
     */
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

    /*
     * Generate the pixbufs images on a separate async thread in order to now
     * freeze the UI.
     */
    private async Gdk.Pixbuf generate_pixbuf (Cairo.Surface surface) {
        SourceFunc callback = generate_pixbuf.callback;

        var thread = new Thread<Gdk.Pixbuf> (null, () => {
            // Create pixbuf from stream.
            try {
                loader = new Gdk.PixbufLoader.with_mime_type ("image/png");
            } catch (Error e) {
                error ("Could not create pixbuf loader: %s", e.message);
            }

            surface.write_to_png_stream ((data) => {
                try {
                    loader.write ((uint8 []) data);
                } catch (Error e) {
                    return Cairo.Status.DEVICE_ERROR;
                }
                return Cairo.Status.SUCCESS;
            });
            var pixbuf = loader.get_pixbuf ();

            try {
                loader.close ();
            } catch (Error e) {
                error ("Could not close loader: %s", e.message);
            }

            Idle.add ((owned) callback);
            return pixbuf;
        });

        yield;

        return thread.join ();
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
            if (preview_cancellable != null) {
                preview_cancellable.cancel ();
            }

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
            surface = null;
        });
    }

    public async void export_images () {
        /*
        TODO:
         - Implement filenames and don't allow exporting without one.
        */
        busy (_("Exporting images…"));

        bool overwrite_all = false;
        bool skip_all = false;

        // Loop through all generated pixbufs and handle the save to a file.
        foreach (var entry in pixbufs.entries) {
            var pixbuf = entry.value;
            var node_id = entry.key;
            var file_name = ("%s/%i.%s").printf (settings.export_folder, node_id, settings.export_format);

            // Check for existing files to avoid overwriting them.
            var image_file = File.new_for_path (file_name);
            if (image_file.query_exists ()) {
                // Overwrite them all if the user specified it in the dialog
                // during the first loop.
                if (overwrite_all) {
                    yield do_export (pixbuf, file_name);
                    continue;
                }

                // Skip them all if the user specified it in the dialog
                // during the first loop.
                if (skip_all) {
                    free ();
                    continue;
                }

                // Ask the user what to do.
                var results = confirm_overwrite (file_name);
                switch (results[0]) {
                    // Overwrite.
                    case 3:
                        overwrite_all = results[1] == 1;
                        yield do_export (pixbuf, file_name);
                        break;
                    // Skip.
                    case 2:
                        skip_all = results[1] == 1;
                        free ();
                        continue;
                    // Cancel.
                    case 1:
                    default:
                        free ();
                        return;
                }
                continue;
            }

            // This file doesn't exist, just export it.
            yield do_export (pixbuf, file_name);
        }

        free ();
        export_finished (_("Export completed!"));
    }

    /*
     * Trigger a dialog asking the user how to handle an existing file with
     * the same filename.
     */
    private int[] confirm_overwrite (string file_name) {
        int dont_ask = 0;
        int clicked = 0;
        var dialog = canvas.window.dialogs.message_dialog (
            _("File already exists!"),
            _("The file at this location already exists: %s.").printf (file_name),
            "dialog-question",
            _("Overwrite file"),
            _("Skip file")
        );

        // If we're currently exporting more than one image, offer the option
        // to use the chosen action as default in the current export loop.
        if (pixbufs.size > 1) {
            var checkbox = new Gtk.CheckButton.with_label (_("Apply the same action for all other files"));
            dialog.custom_bin.add (checkbox);
            checkbox.toggled.connect (() => {
                dont_ask = checkbox.active ? 1 : 0;
            });
        }

        dialog.show_all ();

        dialog.response.connect ((id) => {
            switch (id) {
                case Gtk.ResponseType.ACCEPT:
                    clicked = 3;
                    dialog.destroy ();
                    break;
                case 2:
                    clicked = 2;
                    dialog.destroy ();
                    break;
                default:
                    clicked = 1;
                    dialog.destroy ();
                    break;
            }
        });

        // Use run() to make the UI busy and freeze the loop until we get a response.
        dialog.run ();

        return new int[] {clicked, dont_ask};
    }

    /*
     * Handle the actual export inside another async thread to avoid freezing
     * the UI while exporting large images.
     */
    private async void do_export (Gdk.Pixbuf pixbuf, string file_name) {
        SourceFunc callback = do_export.callback;

        new Thread<void*> (null, () => {
            try {
                if (settings.export_format == "png") {
                    pixbuf.save (
                        file_name,
                        "png",
                        "compression",
                        settings.export_compression.to_string (),
                        null);
                }

                if (settings.export_format == "jpg") {
                    pixbuf.save (
                        file_name,
                        "jpeg",
                        "quality",
                        settings.export_quality.to_string (),
                        null);
                }
            } catch (Error e) {
                error ("Unable to export images: %s", e.message);
            }

            Idle.add ((owned) callback);
            Thread.exit (null);

            return null;
        });

        yield;
    }
}
