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
    public Models.ExportModel model { get; set construct; }

    private Gtk.Entry input;
    private Gtk.Label info;
    private Gtk.Grid image_container;
    private Gtk.Image image;
    private uint8[]? imagedata;

    public ExportWidget (Models.ExportModel model) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            model: model
        );
    }

    construct {
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        row_spacing = 9;
        margin_top = margin_bottom = 6;
        expand = true;
        var ctx = get_style_context ();
        ctx.add_class ("export-widget");
        ctx.add_class (Granite.STYLE_CLASS_CARD);

        // Filename with editable entry.
        input = new Gtk.Entry () {
            placeholder_text = _("File name"),
            width_chars = 10,
            hexpand = true
        };
        input.secondary_icon_activatable = false;
        input.secondary_icon_tooltip_text = _("A file name is required to export this image");
        input.get_style_context ().add_class ("export-filename");
        input.changed.connect (on_input_changed);
        input.text = model.filename;
        input.bind_property ("text", model, "filename", BindingFlags.DEFAULT);

        // Image preview container with checker.
        image_container = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        var image_container_ctx = image_container.get_style_context ();
        image_container_ctx.add_class (Granite.STYLE_CLASS_CHECKERBOARD);
        image_container_ctx.add_class ("export-image");

        image = new Gtk.Image ();
        image_container.add (image);

        // Label for image size info.
        info = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END
        };
        info.get_style_context ().add_class ("export-info");

        // Fetch the image and its info after all the widgets have been created.
        get_image.begin ();

        attach (input, 0, 0);
        attach (image_container, 0, 1);
        attach (info, 0, 2);

        show_all ();

        settings.changed["export-quality"].connect (() => {
            update_file_size.begin ();
        });
        settings.changed["export-compression"].connect (() => {
            update_file_size.begin ();
        });

        // Trigger the detection of and empty file name filed on creation.
        //  on_input_changed ();
    }

    private void on_input_changed () {
        bool empty = input.text._strip () == "";
        model.toggle_export_button (!empty);
        if (empty) {
            input.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error");
            return;
        }

        if (input.get_icon_name (Gtk.EntryIconPosition.SECONDARY) != null) {
            input.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
        }
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

        info.label = _("%i × %i px · %s").printf (
            model.pixbuf.width,
            model.pixbuf.height,
            format_size (imagedata.length));
    }

    private async void get_image_buffer_size () {
        unowned var image = model.pixbuf;
        info.label = _("Fetching image size…");
        SourceFunc callback = get_image_buffer_size.callback;

        new Thread<void*> (null, () => {
            try {
                if (settings.export_format == "png") {
                    image.save_to_buffer (
                        out imagedata,
                        "png",
                        "compression",
                        settings.export_compression.to_string (),
                        null);
                }

                if (settings.export_format == "jpg") {
                    image.save_to_buffer (
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
