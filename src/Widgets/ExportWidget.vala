/*
 * Copyright (c) 2020-2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Widgets.ExportWidget : Gtk.Grid {
    private const int MB = 1024 * 1024;
    private const int KB = 1024;

    public Akira.Models.ExportModel model { get; set construct; }

    private Gtk.Label info;
    private Gtk.Grid image_container;
    private Gtk.Image image;
    private uint8[]? imagedata;

    public ExportWidget (Akira.Models.ExportModel model) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            model: model
        );
    }

    construct {
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        column_spacing = 6;
        expand = true;

        // Label for image size info. We need to create this before calling get_image ().
        info = new Gtk.Label ("");
        info.get_style_context ().add_class ("export-info");
        info.hexpand = false;
        info.halign = Gtk.Align.END;

        // Image preview container with checker.
        image_container = new Gtk.Grid ();
        image_container.halign = Gtk.Align.CENTER;
        image_container.get_style_context ().add_class (Granite.STYLE_CLASS_CHECKERBOARD);
        image_container.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);

        image = new Gtk.Image ();
        image_container.add (image);
        get_image.begin ();

        model.notify["pixbuf"].connect (() => {
            image.clear ();
            get_image.begin ();
        });

        // Filename with editable entry.
        var input = new Gtk.Entry ();
        input.get_style_context ().add_class ("export-filename");
        input.width_chars = 10;
        input.hexpand = true;
        model.bind_property ("filename", input, "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

        attach (input, 0, 0);
        attach (info, 1, 0);
        attach (image_container, 0, 1, 2);

        show_all ();

        settings.changed["export-quality"].connect (() => {
            update_file_size.begin ();
        });
        settings.changed["export-compression"].connect (() => {
            update_file_size.begin ();
        });
    }

    /**
     * Generate the image from the pixbuf model and resize it if bigger than
     * half of the width of the export dialog.
     */
    public async void get_image () {
        var resized_image = model.pixbuf;
        if (resized_image.width > (settings.export_width / 2)) {
            // Keep the aspect ratio consistent.
            var w = (settings.export_width / 2);
            var h = (resized_image.height * w) / resized_image.width;
            resized_image = resized_image.scale_simple (w, h, Gdk.InterpType.BILINEAR);
        }

        image.set_from_pixbuf (resized_image);

        yield update_file_size ();
    }

    public async void update_file_size () {
        yield get_image_buffer_size ();

        double bytes = (double) imagedata.length;
        double full_bytes = imagedata.length > MB
            ? bytes / MB : bytes / KB;
        var size = imagedata.length > MB
            ? ("%0.1fMB").printf (full_bytes)
            : ("%0.1fKB").printf (full_bytes);

        info.label = _("%i × %i px · %s").printf (
            model.pixbuf.width,
            model.pixbuf.height,
            size);
    }

    private async void get_image_buffer_size () {
        info.label = _("Fetching image size…");
        SourceFunc callback = get_image_buffer_size.callback;

        new Thread<void*> (null, () => {
            try {
                if (settings.export_format == "png") {
                    model.pixbuf.save_to_buffer (
                        out imagedata,
                        "png",
                        "compression",
                        settings.export_compression.to_string (),
                        null);
                } else if (settings.export_format == "jpg") {
                    model.pixbuf.save_to_buffer (
                        out imagedata,
                        "jpeg",
                        "quality",
                        settings.export_quality.to_string (),
                        null);
                }
            } catch (Error e) {
                error ("Unable to create image buffer: %s", e.message);
            }

            Idle.add ((owned) callback);
            Thread.exit (null);

            return null;
        });

        yield;
    }
}
