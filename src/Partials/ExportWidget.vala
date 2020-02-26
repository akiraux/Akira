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
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Partials.ExportWidget : Gtk.Grid {
    public Akira.Models.ExportModel model { get; set construct; }

    private Gtk.Grid image_container;

    public ExportWidget (Akira.Models.ExportModel model) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            model: model
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        column_spacing = 6;
        row_spacing = 6;
        expand = true;

        // Image preview container with checker.
        image_container = new Gtk.Grid ();
        image_container.get_style_context ().add_class (Granite.STYLE_CLASS_CHECKERBOARD);
        get_image.begin ();
        model.notify["pixbuf"].connect (() => {
            image_container.@foreach ((image) => {
                image_container.remove (image);
            });
            get_image.begin ();
            show_all ();
        });

        // Filename with editable entry.
        var input = new Gtk.Entry ();
        input.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        input.margin = 3;
        model.bind_property ("filename", input, "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

        attach (image_container, 0, 0);
        attach (input, 0, 1);

        show_all ();
    }

    public async void get_image () {
        var resized_image = model.pixbuf;
        if (resized_image.width > settings.export_width) {
            // Keep the aspect ratio consistent.
            var ratio = resized_image.width / resized_image.height;
            var new_width = settings.export_width;
            var new_height = (int) GLib.Math.round (new_width / ratio);

            resized_image = resized_image.scale_simple (new_width, new_height, Gdk.InterpType.BILINEAR);
        }

        var image = new Gtk.Image.from_pixbuf (resized_image);
        image_container.add (image);
    }
}
