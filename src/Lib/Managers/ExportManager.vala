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
    public signal void preview_finished ();

    public enum Type {
        AREA,
        SELECTION,
        ARTBOARD
    }

    public unowned Akira.Lib.ViewCanvas canvas { get; construct; }
    public Akira.Dialogs.ExportDialog export_dialog;

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
        trigger_export_dialog ();
        // TODO: Generate the image from the current selection
        generating_preview (_("Generating preview, please wait…"));
        init_generate_preview ();
        preview_finished ();
    }

    private void init_generate_preview () {
        pixbufs.clear ();

        if (settings.export_format == "png") {
            format = Cairo.Format.ARGB32;
        } else if (settings.export_format == "jpg") {
            format = Cairo.Format.RGB24;
        }
    }

    private void trigger_export_dialog () {
        // Disable all those accels interfering with regular typing.
        canvas.window.event_bus.disconnect_typing_accel ();

        export_dialog = new Akira.Dialogs.ExportDialog (canvas, this);
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
}
